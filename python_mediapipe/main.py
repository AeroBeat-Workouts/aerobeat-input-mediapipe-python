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
from platform_utils import setup_platform_optimizations
from camera_streamer import MJPEGStreamer

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

# Pose connections for drawing skeleton
POSE_CONNECTIONS = [
    (0, 1), (1, 2), (2, 3), (3, 7),  # Face left
    (0, 4), (4, 5), (5, 6), (6, 8),  # Face right
    (9, 10),  # Mouth
    (11, 12), (11, 13), (13, 15), (15, 17), (15, 19), (15, 21),  # Left arm
    (12, 14), (14, 16), (16, 18), (16, 20), (16, 22),  # Right arm
    (11, 23), (12, 24), (23, 24),  # Torso
    (23, 25), (25, 27), (27, 29), (29, 31),  # Left leg
    (24, 26), (26, 28), (28, 30), (30, 32),  # Right leg
]

def draw_landmarks_on_frame(frame, landmarks, connections=True, pose_id=0):
    """Draw landmarks and skeleton on frame for debug visualization"""
    if not landmarks:
        return frame
    
    h, w = frame.shape[:2]
    output = frame.copy()
    
    # Different colors for different poses
    pose_colors = [
        (0, 255, 0),    # Green - Player 1
        (255, 0, 255),  # Magenta - Player 2
    ]
    skeleton_color = pose_colors[pose_id % len(pose_colors)]
    
    # Draw connections (skeleton)
    if connections:
        for start_idx, end_idx in POSE_CONNECTIONS:
            if start_idx < len(landmarks) and end_idx < len(landmarks):
                start_lm = landmarks[start_idx]
                end_lm = landmarks[end_idx]
                
                # Only draw if both landmarks are visible
                if start_lm.get('v', 1.0) > 0.5 and end_lm.get('v', 1.0) > 0.5:
                    x1, y1 = int(start_lm['x'] * w), int(start_lm['y'] * h)
                    x2, y2 = int(end_lm['x'] * w), int(end_lm['y'] * h)
                    cv2.line(output, (x1, y1), (x2, y2), skeleton_color, 2)
    
    # Draw landmark points
    for lm in landmarks:
        x, y = int(lm['x'] * w), int(lm['y'] * h)
        visibility = lm.get('v', 1.0)
        
        # Color based on visibility
        if visibility > 0.8:
            color = skeleton_color
        elif visibility > 0.5:
            color = (0, 255, 255)  # Yellow - medium confidence
        else:
            color = (0, 0, 255)  # Red - low confidence
        
        cv2.circle(output, (x, y), 4, color, -1)
    
    # Draw pose ID label above head (landmark 0 is nose, move up further)
    if landmarks and len(landmarks) > 0:
        nose = landmarks[0]
        x, y = int(nose['x'] * w), int(nose['y'] * h)
        label = f"P{pose_id + 1}"
        # Move label 40px above nose to avoid facial landmarks
        cv2.putText(output, label, (x - 15, y - 40),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, skeleton_color, 2)
    
    return output

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
        self._ready = False  # Flag to indicate first frame captured
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()
        
        # Wait for first frame with timeout
        timeout = 5.0  # 5 seconds
        start_time = time.time()
        while not self._ready and time.time() - start_time < timeout:
            time.sleep(0.01)
        
        if not self._ready:
            raise RuntimeError("Camera failed to capture first frame within timeout")
        
    def _capture_loop(self):
        """Continuously capture frames in background thread"""
        while self._running:
            ret, frame = self.cap.read()
            if ret:
                with self.lock:
                    self.frame = frame
                    if not self._ready:
                        self._ready = True
    
    def get_frame(self):
        """Get the latest frame"""
        with self.lock:
            return self.frame.copy() if self.frame is not None else None
    
    def stop(self):
        self._running = False
        self._thread.join(timeout=1.0)
        self.cap.release()

# UDP Sender with batching support
class UDPSender:
    """UDP sender with optional batching for reduced network overhead"""
    def __init__(self, host, port, batch_size=1, buffer_size=4096):
        self.addr = (host, port)
        self.batch_size = batch_size
        self.buffer_size = buffer_size
        self.batch = []
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, buffer_size)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, buffer_size)
        self.frames_in_batch = 0
        
    def send(self, landmarks, timestamp, capture_ms=0.0, inference_ms=0.0,
             filter_ms=0.0, serialization_ms=0.0, frame_count=0,
             processing_fps=60.0, skip_frames=1, binary=True):
        """Queue a frame for sending (flushes if batch is full)"""
        # Serialize this frame
        if binary:
            frame_data = serialize_single_landmarks(
                landmarks, timestamp, capture_ms, inference_ms,
                filter_ms, serialization_ms, frame_count,
                processing_fps, skip_frames
            )
        else:
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
            frame_data = json.dumps(payload).encode()
        
        self.batch.append(frame_data)
        self.frames_in_batch += 1
        
        # Flush if batch is full
        if self.frames_in_batch >= self.batch_size:
            self.flush(binary)
            
    def flush(self, binary=True):
        """Send all queued frames"""
        if not self.batch:
            return
            
        try:
            if self.batch_size == 1:
                # Single frame - send directly with protocol marker
                packet = (b'\x01' if binary else b'\x00') + self.batch[0]
                self.sock.sendto(packet, self.addr)
            else:
                # Batched frames: format = marker + count + [frame_data...]
                # Marker: 0x02 = binary batch, 0x03 = JSON batch
                marker = b'\x02' if binary else b'\x03'
                data = struct.pack('!B', len(self.batch))  # 1 byte for batch count
                for frame_data in self.batch:
                    # Prepend size of each frame for parsing
                    data += struct.pack('!I', len(frame_data))  # 4 bytes for frame size
                    data += frame_data
                packet = marker + data
                self.sock.sendto(packet, self.addr)
        except Exception as e:
            print(f"UDP send error: {e}")
        
        self.batch = []
        self.frames_in_batch = 0
        
    def close(self):
        self.flush()
        self.sock.close()


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
        num_poses=2,
        min_pose_detection_confidence=min_detection_confidence,
        min_pose_presence_confidence=min_detection_confidence,
        min_tracking_confidence=min_tracking_confidence
    )
    
    return vision.PoseLandmarker.create_from_options(options)

def preprocess_frame(frame, target_size):
    """Resize frame before MediaPipe for faster inference"""
    if target_size <= 0 or frame.shape[0] <= target_size:
        return frame, 1.0
    
    scale = target_size / frame.shape[0]
    new_width = int(frame.shape[1] * scale)
    small_frame = cv2.resize(frame, (new_width, target_size))
    return small_frame, scale


def scale_landmarks(landmarks, scale_x, scale_y):
    """Scale landmarks back to original frame coordinates"""
    for lm in landmarks:
        lm['x'] *= scale_x
        lm['y'] *= scale_y
    return landmarks


def serialize_single_landmarks(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0,
                                filter_ms=0.0, serialization_ms=0.0, frame_count=0,
                                processing_fps=60.0, skip_frames=1):
    """Serialize a single frame of landmarks (internal use)"""
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


def serialize_landmarks_binary(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0, 
                               filter_ms=0.0, serialization_ms=0.0, frame_count=0, 
                               processing_fps=60.0, skip_frames=1):
    """Serialize landmarks using binary format for lower latency"""
    return serialize_single_landmarks(landmarks, timestamp, capture_ms, inference_ms,
                                       filter_ms, serialization_ms, frame_count,
                                       processing_fps, skip_frames)

def serialize_landmarks_json(landmarks, timestamp, capture_ms=0.0, inference_ms=0.0,
                             filter_ms=0.0, serialization_ms=0.0, frame_count=0, 
                             processing_fps=60.0, skip_frames=1, all_poses=None):
    """Serialize landmarks using JSON (fallback)
    
    Args:
        landmarks: Primary pose landmarks (for backward compatibility)
        all_poses: List of (pose_id, landmarks) tuples for multi-pose support
    """
    payload = {
        "timestamp": timestamp,
        "capture_ms": capture_ms,
        "inference_ms": inference_ms,
        "filter_ms": filter_ms,
        "serialization_ms": serialization_ms,
        "frame_count": frame_count,
        "processing_fps": processing_fps,
        "skip_frames": skip_frames,
        "landmarks": landmarks,  # Primary pose (backward compat)
        "num_poses": len(all_poses) if all_poses else (1 if landmarks else 0),
        "poses": []
    }
    
    # Add all poses
    if all_poses:
        for pose_id, pose_landmarks in all_poses:
            payload["poses"].append({
                "pose_id": pose_id,
                "landmarks": pose_landmarks
            })
    elif landmarks:
        # Single pose mode
        payload["poses"].append({
            "pose_id": 0,
            "landmarks": landmarks
        })
    
    return json.dumps(payload).encode()

def main():
    global _running
    
    # Platform-specific setup for optimal performance
    setup_platform_optimizations()
    
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
    
    # Initialize MJPEG streamer if enabled
    mjpeg_streamer = None
    if args.stream_camera:
        mjpeg_streamer = MJPEGStreamer(port=args.stream_port, quality=args.stream_quality)
        if mjpeg_streamer.start():
            print(f"Camera streaming enabled on port {args.stream_port}")
        else:
            print("Warning: Failed to start camera streamer")
            mjpeg_streamer = None
    
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
    print(f"Multi-pose: 2 people max (Player 1 = Green, Player 2 = Magenta)")
    print(f"Binary protocol: {args.binary_protocol}")
    print(f"UDP buffer size: {args.udp_buffer_size} bytes")
    print(f"Frame skipping: {skip_frames} (capture: {args.max_fps}fps → process: {processing_fps:.1f}fps)")
    if args.stream_camera:
        print(f"Camera streaming: enabled at http://127.0.0.1:{args.stream_port}/camera")
    else:
        print("Camera streaming: disabled (use --stream-camera to enable)")
    if args.show_window:
        print(f"Debug window: enabled (scale: {args.window_scale}x)")
        print("Press 'q' in the window to quit")
    else:
        print("Debug window: disabled (use --show-window to enable)")
    
    # Create debug window if enabled
    if args.show_window:
        cv2.namedWindow("MediaPipe Pose", cv2.WINDOW_NORMAL)
        if args.window_scale != 1.0:
            cv2.resizeWindow("MediaPipe Pose", int(args.width * args.window_scale), int(args.height * args.window_scale))
    
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
        
        # Update MJPEG streamer with raw frame (before any processing)
        if mjpeg_streamer and mjpeg_streamer.is_running():
            mjpeg_streamer.update_frame(frame)
        
        capture_time = (time.time() - frame_start) * 1000  # ms
        
        # Frame skipping: process every Nth frame
        frame_counter += 1
        if frame_counter % skip_frames != 0:
            # Skip MediaPipe processing for this frame but continue to capture
            # Still show the frame in debug window if enabled
            if args.show_window:
                display_frame = frame.copy()
                cv2.putText(display_frame, "Processing skipped (frame skip)", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
                cv2.imshow("MediaPipe Pose", display_frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    _running = False
                    break
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
        
        # Extract landmarks for all detected poses
        all_landmarks = []  # List of (pose_id, landmarks) tuples
        num_poses_detected = 0
        if detection_result.pose_landmarks:
            num_poses_detected = len(detection_result.pose_landmarks)
            for pose_idx, pose_landmarks in enumerate(detection_result.pose_landmarks):
                pose_landmarks_list = []
                for idx, landmark in enumerate(pose_landmarks):
                    pose_landmarks_list.append({
                        "id": idx,
                        "x": landmark.x,
                        "y": landmark.y,
                        "z": landmark.z,
                        "v": landmark.visibility if hasattr(landmark, 'visibility') else 1.0
                    })
                all_landmarks.append((pose_idx, pose_landmarks_list))
        
        # For now, use first pose for UDP (Godot side needs update for multi-pose)
        landmarks = all_landmarks[0][1] if all_landmarks else []
        
        # Apply One-Euro filtering (only to first pose for now)
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
                # Binary mode: for now just send primary pose (multi-pose binary needs protocol update)
                packet = serialize_landmarks_binary(
                    landmarks, timestamp, capture_time, inference_time, 
                    filter_time, 0.0, latency_tracker.frame_count, 
                    processing_fps, skip_frames
                )
                packet = b'\x01' + packet  # Binary marker
            else:
                # JSON mode: send all poses
                packet = serialize_landmarks_json(
                    landmarks, timestamp, capture_time, inference_time,
                    filter_time, 0.0, latency_tracker.frame_count, 
                    processing_fps, skip_frames, all_landmarks
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
        
        # Show debug window with landmarks
        if args.show_window:
            display_frame = frame.copy()
            
            # Draw all detected poses
            for pose_id, pose_landmarks in all_landmarks:
                display_frame = draw_landmarks_on_frame(display_frame, pose_landmarks, pose_id=pose_id)
            
            # Add FPS and pose count overlay
            total_landmarks = sum(len(lm) for _, lm in all_landmarks)
            status_text = f"Poses: {num_poses_detected} | Total Landmarks: {total_landmarks} | Press 'q' to quit"
            cv2.putText(display_frame, status_text, (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
            
            # Add inference time
            time_text = f"Inference: {inference_time:.1f}ms"
            cv2.putText(display_frame, time_text, (10, 60),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
            
            cv2.imshow("MediaPipe Pose", display_frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                _running = False
                break
        
        # Cap FPS
        elapsed = time.time() - frame_start
        sleep_time = max(0, (1.0 / args.max_fps) - elapsed)
        if sleep_time > 0:
            time.sleep(sleep_time)
    
    # Cleanup
    if args.show_window:
        cv2.destroyAllWindows()
    if frame_capture:
        frame_capture.stop()
    if cap:
        cap.release()
    if mjpeg_streamer:
        mjpeg_streamer.stop()
    # Close the detector (no explicit close method in Tasks API, let garbage collector handle it)
    sock.close()
    print("MediaPipe stopped")

if __name__ == "__main__":
    main()
