#!/usr/bin/env python3
"""MediaPipe Pose Tracker - UDP Sidecar for Godot with Latency Measurement"""

import signal
import sys
import socket
import json
import time
import struct
import threading
from collections import deque
from args import parse_args
from one_euro_filter import LandmarkFilterBank, get_preset_params

try:
    import cv2
    import mediapipe as mp
    from mediapipe.tasks.python import vision
    from mediapipe.tasks.python.core.base_options import BaseOptions
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

args = parse_args()

# Global flag for graceful shutdown
_running = True

# Model paths for different complexity levels
MODEL_PATHS = {
    0: 'pose_landmarker_lite.task',
    1: 'pose_landmarker_full.task',
    2: 'pose_landmarker_heavy.task'
}

# Threaded frame capture
class FrameCapture:
    """Threaded frame capture to always get the latest frame"""
    def __init__(self, camera_id, width, height, fps):
        self.cap = cv2.VideoCapture(camera_id)
        if not self.cap.isOpened():
            raise RuntimeError(f"Could not open camera {camera_id}")
        
        # Set camera properties
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
        self.cap.set(cv2.CAP_PROP_FPS, fps)
        
        self.frame = None
        self.lock = threading.Lock()
        self._running = True
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()
        
    def _capture_loop(self):
        """Continuously capture frames in background thread"""
        while self._running:
            ret, frame = self.cap.read()
            if ret:
                with self.lock:
                    self.frame = frame
    
    def get_frame(self):
        """Get the latest frame"""
        with self.lock:
            return self.frame.copy() if self.frame is not None else None
    
    def stop(self):
        self._running = False
        self._thread.join(timeout=1.0)
        self.cap.release()

# Latency tracking
class LatencyTracker:
    def __init__(self, window_size=60):
        self.frame_count = 0
        self.window_size = window_size
        self.capture_times = deque(maxlen=window_size)
        self.inference_times = deque(maxlen=window_size)
        self.serialization_times = deque(maxlen=window_size)
        self.filter_times = deque(maxlen=window_size)
        self.total_times = deque(maxlen=window_size)
        
    def record_frame(self, capture_ms, inference_ms, serialization_ms, filter_ms, total_ms):
        self.capture_times.append(capture_ms)
        self.inference_times.append(inference_ms)
        self.serialization_times.append(serialization_ms)
        self.filter_times.append(filter_ms)
        self.total_times.append(total_ms)
        self.frame_count += 1
        
        # Log every 60 frames
        if self.frame_count % 60 == 0:
            self._log_stats()
    
    def _log_stats(self):
        if len(self.total_times) == 0:
            return
        avg_capture = sum(self.capture_times) / len(self.capture_times)
        avg_inference = sum(self.inference_times) / len(self.inference_times)
        avg_serialization = sum(self.serialization_times) / len(self.serialization_times)
        avg_filter = sum(self.filter_times) / len(self.filter_times)
        avg_total = sum(self.total_times) / len(self.total_times)
        
        print(f"[LATENCY] Frame {self.frame_count}: "
              f"capture={avg_capture:.2f}ms | "
              f"inference={avg_inference:.2f}ms | "
              f"filter={avg_filter:.3f}ms | "
              f"serialization={avg_serialization:.2f}ms | "
              f"TOTAL={avg_total:.2f}ms")

def signal_handler(sig, frame):
    global _running
    print("\nShutting down gracefully...")
    _running = False

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def create_pose_detector(model_complexity: int = 0, 
                        min_detection_confidence: float = 0.3,
                        min_tracking_confidence: float = 0.3):
    """Create MediaPipe pose detector using new Tasks API."""
    model_path = MODEL_PATHS.get(model_complexity, MODEL_PATHS[0])
    
    base_options = BaseOptions(model_asset_path=model_path)
    
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=min_detection_confidence,
        min_pose_presence_confidence=min_detection_confidence,
        min_tracking_confidence=min_tracking_confidence
    )
    
    return vision.PoseLandmarker.create_from_options(options)

def serialize_landmarks_binary(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0, 
                               filter_ms=0.0, serialization_ms=0.0, frame_count=0, 
                               processing_fps=60.0, skip_frames=1):
    """Serialize landmarks using binary format for lower latency"""
    # Format: timestamp (double) + timing info (4 floats) + frame_count (uint32) + 
    #         processing_fps (float) + skip_frames (uint8) + count (uint16) + landmarks
    data = struct.pack('!d', timestamp)  # 8 bytes for timestamp
    data += struct.pack('!ffff', capture_ms, inference_ms, filter_ms, serialization_ms)  # 16 bytes
    data += struct.pack('!I', frame_count)  # 4 bytes for frame count
    data += struct.pack('!f', processing_fps)  # 4 bytes for processing FPS
    data += struct.pack('!B', skip_frames)  # 1 byte for skip frames
    data += struct.pack('!H', len(landmarks))  # 2 bytes for count
    
    for lm in landmarks:
        data += struct.pack('!B', lm['id'])  # 1 byte for id
        data += struct.pack('!ffff', lm['x'], lm['y'], lm['z'], lm['v'])  # 16 bytes per landmark
    
    return data

def serialize_landmarks_json(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0,
                             filter_ms=0.0, serialization_ms=0.0, frame_count=0, 
                             processing_fps=60.0, skip_frames=1):
    """Serialize landmarks using JSON (fallback)"""
    payload = {
        "timestamp": timestamp,
        "capture_ms": capture_ms,
        "inference_ms": inference_ms,
        "filter_ms": filter_ms,
        "serialization_ms": serialization_ms,
        "frame_count": frame_count,
        "processing_fps": processing_fps,
        "skip_frames": skip_frames,
        "landmarks": landmarks
    }
    return json.dumps(payload).encode()

def main():
    latency_tracker = LatencyTracker()
    
    # Initialize UDP socket with tuned buffer size for low latency
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, args.udp_buffer_size)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, args.udp_buffer_size)
    
    # Initialize MediaPipe Pose Landmarker with new Tasks API
    print(f"Initializing MediaPipe Pose Landmarker (model: {MODEL_PATHS.get(args.model_complexity, MODEL_PATHS[0])})...")
    detector = create_pose_detector(
        model_complexity=args.model_complexity,
        min_detection_confidence=args.detection_confidence,
        min_tracking_confidence=args.tracking_confidence
    )
    
    # Initialize One-Euro filter bank
    filter_bank = None
    if args.use_filter:
        # Get preset parameters
        preset_params = get_preset_params(args.filter_preset)
        
        # Override with CLI arguments if provided
        min_cutoff = args.filter_min_cutoff if args.filter_min_cutoff is not None else preset_params['min_cutoff']
        beta = args.filter_beta if args.filter_beta is not None else preset_params['beta']
        d_cutoff = args.filter_d_cutoff if args.filter_d_cutoff is not None else preset_params['d_cutoff']
        
        filter_bank = LandmarkFilterBank(
            num_landmarks=33,
            min_cutoff=min_cutoff,
            beta=beta,
            d_cutoff=d_cutoff
        )
        print(f"One-Euro filter enabled: preset='{args.filter_preset}', "
              f"min_cutoff={min_cutoff}Hz, beta={beta}, d_cutoff={d_cutoff}Hz")
    else:
        print("One-Euro filter disabled")
    
    # Initialize camera (with or without threading)
    if args.threaded_capture:
        print("Using threaded frame capture")
        frame_capture = FrameCapture(args.camera, args.width, args.height, args.max_fps)
        cap = None
    else:
        cap = cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            print(f"Error: Could not open camera {args.camera}")
            sys.exit(1)
        
        # Set camera buffer size to 1 for minimal latency
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)
        cap.set(cv2.CAP_PROP_FPS, args.max_fps)
        frame_capture = None
    
    # Frame skipping for performance
    skip_frames = args.skip_frames
    if skip_frames < 1:
        skip_frames = 1
    
    # Calculate processing FPS based on skip ratio
    processing_fps = args.max_fps / skip_frames
    
    print(f"MediaPipe started - Camera: {args.camera}, UDP: {args.host}:{args.port}")
    print(f"Resolution: {args.width}x{args.height}, Model: {args.model_complexity}, "
          f"Detection: {args.detection_confidence}, Tracking: {args.tracking_confidence}")
    print(f"Binary protocol: {args.binary_protocol}")
    print(f"UDP buffer size: {args.udp_buffer_size} bytes")
    print(f"Frame skipping: {skip_frames} (capture: {args.max_fps}fps → process: {processing_fps:.1f}fps)")
    
    # Frame counter for skipping and timestamp calculation
    frame_counter = 0
    start_time_ms = int(time.time() * 1000)
    
    while _running:
        frame_start = time.time()
        
        # Capture frame
        if frame_capture:
            frame = frame_capture.get_frame()
            ret = frame is not None
        else:
            ret, frame = cap.read()
        
        if not ret or frame is None:
            print("Warning: Failed to capture frame")
            continue
        
        capture_time = (time.time() - frame_start) * 1000  # ms
        
        # Frame skipping: process every Nth frame
        frame_counter += 1
        if frame_counter % skip_frames != 0:
            # Skip MediaPipe processing for this frame but continue to capture
            continue
        
        # Process frame with new Tasks API
        inference_start = time.time()
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Create MediaPipe Image object
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
        
        # Calculate timestamp in milliseconds for VIDEO running mode
        timestamp_ms = int((time.time() * 1000) - start_time_ms)
        
        # Run detection
        detection_result = detector.detect_for_video(mp_image, timestamp_ms)
        inference_time = (time.time() - inference_start) * 1000  # ms
        
        # Extract landmarks
        landmarks = []
        if detection_result.pose_landmarks:
            # pose_landmarks is a list of lists - get the first pose
            pose_landmarks = detection_result.pose_landmarks[0]
            for idx, landmark in enumerate(pose_landmarks):
                landmarks.append({
                    "id": idx,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "v": landmark.visibility if hasattr(landmark, 'visibility') else 1.0
                })
        
        # Apply One-Euro filtering
        filter_start = time.time()
        if filter_bank and landmarks:
            timestamp = time.time()
            landmarks = filter_bank.filter_landmarks(landmarks, timestamp)
        filter_time = (time.time() - filter_start) * 1000  # ms
        
        # Serialize and send
        serialization_start = time.time()
        timestamp = time.time()
        
        try:
            if args.binary_protocol and not args.json_protocol:
                packet = serialize_landmarks_binary(
                    landmarks, timestamp, capture_time, inference_time, 
                    filter_time, 0.0, latency_tracker.frame_count, 
                    processing_fps, skip_frames
                )
                packet = b'\x01' + packet  # Binary marker
            else:
                packet = serialize_landmarks_json(
                    landmarks, timestamp, capture_time, inference_time,
                    filter_time, 0.0, latency_tracker.frame_count, 
                    processing_fps, skip_frames
                )
                packet = b'\x00' + packet  # JSON marker
            
            sock.sendto(packet, (args.host, args.port))
        except Exception as e:
            print(f"UDP send error: {e}")
        
        serialization_time = (time.time() - serialization_start) * 1000  # ms
        total_time = (time.time() - frame_start) * 1000  # ms
        
        # Record latency metrics
        latency_tracker.record_frame(capture_time, inference_time, serialization_time, 
                                     filter_time, total_time)
        
        # Cap FPS
        elapsed = time.time() - frame_start
        sleep_time = max(0, (1.0 / args.max_fps) - elapsed)
        if sleep_time > 0:
            time.sleep(sleep_time)
    
    # Cleanup
    if frame_capture:
        frame_capture.stop()
    if cap:
        cap.release()
    # Close the detector (no explicit close method in Tasks API, let garbage collector handle it)
    sock.close()
    print("MediaPipe stopped")

if __name__ == "__main__":
    main()
