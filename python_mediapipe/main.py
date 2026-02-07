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

try:
    import cv2
    import mediapipe as mp
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

args = parse_args()

# Global flag for graceful shutdown
_running = True

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
        self.total_times = deque(maxlen=window_size)
        
    def record_frame(self, capture_ms, inference_ms, serialization_ms, total_ms):
        self.capture_times.append(capture_ms)
        self.inference_times.append(inference_ms)
        self.serialization_times.append(serialization_ms)
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
        avg_total = sum(self.total_times) / len(self.total_times)
        
        print(f"[LATENCY] Frame {self.frame_count}: "
              f"capture={avg_capture:.2f}ms | "
              f"inference={avg_inference:.2f}ms | "
              f"serialization={avg_serialization:.2f}ms | "
              f"TOTAL={avg_total:.2f}ms")

def signal_handler(sig, frame):
    global _running
    print("\nShutting down gracefully...")
    _running = False

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def serialize_landmarks_binary(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0, serialization_ms=0.0, frame_count=0, processing_fps=60.0, skip_frames=1):
    """Serialize landmarks using binary format for lower latency"""
    # Format: timestamp (double) + timing info (3 floats) + frame_count (uint32) + 
    #         processing_fps (float) + skip_frames (uint8) + count (uint16) + landmarks
    data = struct.pack('!d', timestamp)  # 8 bytes for timestamp
    data += struct.pack('!fff', capture_ms, inference_ms, serialization_ms)  # 12 bytes for timing
    data += struct.pack('!I', frame_count)  # 4 bytes for frame count
    data += struct.pack('!f', processing_fps)  # 4 bytes for processing FPS
    data += struct.pack('!B', skip_frames)  # 1 byte for skip frames
    data += struct.pack('!H', len(landmarks))  # 2 bytes for count
    
    for lm in landmarks:
        data += struct.pack('!B', lm['id'])  # 1 byte for id
        data += struct.pack('!ffff', lm['x'], lm['y'], lm['z'], lm['v'])  # 16 bytes per landmark
    
    return data

def serialize_landmarks_json(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0, serialization_ms=0.0, frame_count=0, processing_fps=60.0, skip_frames=1):
    """Serialize landmarks using JSON (fallback)"""
    payload = {
        "timestamp": timestamp,
        "capture_ms": capture_ms,
        "inference_ms": inference_ms,
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
    
    # Initialize MediaPipe with optimized settings
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        min_detection_confidence=args.detection_confidence,
        min_tracking_confidence=args.tracking_confidence,
        model_complexity=args.model_complexity,
        static_image_mode=False,  # Enable tracking mode for lower latency
        smooth_landmarks=True
    )
    
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
    
    print(f"MediaPipe started - Camera: {args.camera}, UDP: {args.host}:{args.port}")
    print(f"Resolution: {args.width}x{args.height}, Model: {args.model_complexity}, "
          f"Detection: {args.detection_confidence}, Tracking: {args.tracking_confidence}")
    print(f"Binary protocol: {args.binary_protocol}")
    print(f"UDP buffer size: {args.udp_buffer_size} bytes")
    print(f"Frame skipping: {skip_frames} (capture: {args.max_fps}fps → process: {processing_fps:.1f}fps)")
    
    # Frame skipping for performance
    frame_counter = 0
    skip_frames = args.skip_frames
    if skip_frames < 1:
        skip_frames = 1  # Default to processing every frame (1 = no skip)
    
    # Calculate processing FPS based on skip ratio
    processing_fps = args.max_fps / skip_frames
    last_process_time = time.time()
    
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
            # We don't sleep here to maintain capture loop responsiveness
            continue
        
        # Process frame
        inference_start = time.time()
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(frame_rgb)
        inference_time = (time.time() - inference_start) * 1000  # ms
        
        # Extract landmarks
        landmarks = []
        if results.pose_landmarks:
            for idx, landmark in enumerate(results.pose_landmarks.landmark):
                landmarks.append({
                    "id": idx,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "v": landmark.visibility
                })
        
        # Serialize and send
        serialization_start = time.time()
        timestamp = time.time()
        
        try:
            if args.binary_protocol and not args.json_protocol:
                packet = serialize_landmarks_binary(
                    landmarks, timestamp, capture_time, inference_time, 
                    0.0, latency_tracker.frame_count, processing_fps, skip_frames
                )
                packet = b'\x01' + packet  # Binary marker
            else:
                packet = serialize_landmarks_json(
                    landmarks, timestamp, capture_time, inference_time,
                    0.0, latency_tracker.frame_count, processing_fps, skip_frames
                )
                packet = b'\x00' + packet  # JSON marker
            
            sock.sendto(packet, (args.host, args.port))
        except Exception as e:
            print(f"UDP send error: {e}")
        
        serialization_time = (time.time() - serialization_start) * 1000  # ms
        total_time = (time.time() - frame_start) * 1000  # ms
        
        # Record latency metrics
        latency_tracker.record_frame(capture_time, inference_time, serialization_time, total_time)
        
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
    pose.close()
    sock.close()
    print("MediaPipe stopped")

if __name__ == "__main__":
    main()
