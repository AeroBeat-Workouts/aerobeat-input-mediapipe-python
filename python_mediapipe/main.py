#!/usr/bin/env python3
"""MediaPipe Pose Tracker - UDP Sidecar for Godot with Latency Measurement"""

import signal
import sys
import os
import socket
import json
import time
import struct
import threading
import zlib
from collections import deque
from args import parse_args
from one_euro_filter import LandmarkFilterBank, get_preset_params
from platform_utils import setup_platform_optimizations
from camera_streamer import MJPEGStreamer
from roi_tracker import PredictiveROITracker
from runtime_paths import get_model_filename, get_model_path

try:
    import cv2
    import mediapipe as mp
    from mediapipe.tasks.python import vision
    from mediapipe.tasks.python.core.base_options import BaseOptions
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r python_mediapipe/requirements.txt")
    sys.exit(1)

args = parse_args()

# Global flag for graceful shutdown
_running = True
_heartbeat_last_time = time.time()
_heartbeat_lock = threading.Lock()
_heartbeat_timeout_sec = 3.0  # Exit if no heartbeat for 3 seconds
_shutdown_lock = threading.Lock()
_shutdown_requested_at = None
_shutdown_reason = "normal exit"
_force_shutdown_after_sec = max(0.0, float(os.environ.get("AEROBEAT_MEDIAPIPE_FORCE_EXIT_AFTER_SEC", "0")))


def request_shutdown(source: str, detail: str | None = None):
    """Record the first shutdown request and transition the main loop to exit."""
    global _running, _shutdown_requested_at, _shutdown_reason

    message = f"[{source}] Shutdown requested"
    if detail:
        message += f": {detail}"

    with _shutdown_lock:
        first_request = _shutdown_requested_at is None
        if first_request:
            _shutdown_requested_at = time.time()
            _shutdown_reason = detail or source
            print(message)
        else:
            elapsed = time.time() - _shutdown_requested_at
            print(f"{message} (already shutting down for {_shutdown_reason}; +{elapsed:.2f}s)")

    _running = False

# Model filenames for different complexity levels (stored under python_mediapipe/assets/models/)
MODEL_PATHS = {
    0: get_model_filename(0),
    1: get_model_filename(1),
    2: get_model_filename(2)
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


def update_heartbeat():
    """Update the last heartbeat timestamp"""
    global _heartbeat_last_time
    with _heartbeat_lock:
        _heartbeat_last_time = time.time()


def check_heartbeat() -> bool:
    """Check if heartbeat is still valid"""
    with _heartbeat_lock:
        elapsed = time.time() - _heartbeat_last_time
        return elapsed < _heartbeat_timeout_sec


def heartbeat_monitor():
    """Monitor heartbeat and trigger shutdown if Godot stops responding"""
    print(f"[Heartbeat] Monitor started - timeout: {_heartbeat_timeout_sec}s")
    while _running:
        time.sleep(0.5)
        if not check_heartbeat():
            request_shutdown("Heartbeat", f"timeout after {time.time() - _heartbeat_last_time:.1f}s without heartbeat")
            break
    print("[Heartbeat] Monitor stopped")


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
    """Threaded frame capture to always get the latest frame."""

    FILE_PREVIEW_BANNER = "FILE PREVIEW"

    def __init__(self, camera_id, width, height, fps):
        self.camera_id = camera_id
        self.cap = cv2.VideoCapture(camera_id)
        if not self.cap.isOpened():
            raise RuntimeError(f"Could not open camera {camera_id}")

        self._is_file_source = isinstance(camera_id, str) and os.path.isfile(camera_id)
        self._requested_fps = max(float(fps), 1.0)
        self._source_fps = 0.0
        self._frame_interval_sec = 0.0
        self._next_frame_due = None
        self._loop_count = 0
        self._captured_frame_count = 0
        self._unique_frame_count = 0
        self._last_signature = None
        self._repeat_signature_run = 0
        self._source_total_frames = 0

        if self._is_file_source:
            detected_fps = float(self.cap.get(cv2.CAP_PROP_FPS) or 0.0)
            self._source_fps = detected_fps if detected_fps > 0.1 else self._requested_fps
            self._frame_interval_sec = 1.0 / self._source_fps if self._source_fps > 0 else 0.0
            self._next_frame_due = time.monotonic()
            self._source_total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
            print(
                f"[FrameCapture] File source detected: {camera_id} | "
                f"source_fps={self._source_fps:.3f} | total_frames={self._source_total_frames}"
            )
        else:
            # Set live camera properties
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

    def is_file_source(self):
        return self._is_file_source

    def decorate_preview_frame(self, frame):
        if not self._is_file_source or frame is None:
            return frame

        preview = frame.copy()
        frame_number = max(int(self.cap.get(cv2.CAP_PROP_POS_FRAMES) or 0), 0)
        pos_msec = float(self.cap.get(cv2.CAP_PROP_POS_MSEC) or 0.0)
        total = self._source_total_frames
        progress = 0.0
        if total > 0:
            progress = max(0.0, min(frame_number / float(total), 1.0))

        cv2.rectangle(preview, (12, 12), (560, 94), (0, 0, 0), -1)
        cv2.rectangle(preview, (12, 12), (560, 94), (0, 200, 255), 2)
        cv2.putText(
            preview,
            self.FILE_PREVIEW_BANNER,
            (24, 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (0, 200, 255),
            2,
        )
        cv2.putText(
            preview,
            f"loop {self._loop_count} | frame {frame_number}/{total if total > 0 else '?'} | t={pos_msec / 1000.0:.2f}s",
            (24, 68),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.65,
            (255, 255, 255),
            2,
        )
        bar_left, bar_top, bar_width, bar_height = 24, 76, 520, 10
        cv2.rectangle(preview, (bar_left, bar_top), (bar_left + bar_width, bar_top + bar_height), (70, 70, 70), -1)
        cv2.rectangle(preview, (bar_left, bar_top), (bar_left + max(1, int(bar_width * progress)), bar_top + bar_height), (0, 200, 255), -1)
        return preview

    def _capture_loop(self):
        """Continuously capture frames in background thread."""
        while self._running:
            if self._is_file_source and self._frame_interval_sec > 0 and self._next_frame_due is not None:
                now = time.monotonic()
                if now < self._next_frame_due:
                    time.sleep(min(self._next_frame_due - now, 0.01))
                    continue

            ret, frame = self.cap.read()
            if not ret:
                if self._is_file_source and self._rewind_file_source():
                    continue
                time.sleep(0.01)
                continue

            self._captured_frame_count += 1
            if self._is_file_source:
                self._record_file_frame_stats(frame)
                if self._frame_interval_sec > 0:
                    if self._next_frame_due is None:
                        self._next_frame_due = time.monotonic() + self._frame_interval_sec
                    else:
                        self._next_frame_due += self._frame_interval_sec
                        if time.monotonic() - self._next_frame_due > self._frame_interval_sec * 4.0:
                            self._next_frame_due = time.monotonic() + self._frame_interval_sec

            with self.lock:
                self.frame = frame
                if not self._ready:
                    self._ready = True

    def _rewind_file_source(self):
        self._loop_count += 1
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        self._next_frame_due = time.monotonic()
        print(f"[FrameCapture] File source reached EOF; rewinding to frame 0 (loop={self._loop_count})")
        return True

    def _record_file_frame_stats(self, frame):
        sample = cv2.resize(frame, (16, 16), interpolation=cv2.INTER_AREA)
        signature = zlib.crc32(sample.tobytes())
        if signature != self._last_signature:
            self._unique_frame_count += 1
            self._repeat_signature_run = 0
            self._last_signature = signature
        else:
            self._repeat_signature_run += 1

        if self._captured_frame_count <= 5 or self._captured_frame_count % 30 == 0:
            pos_frames = int(self.cap.get(cv2.CAP_PROP_POS_FRAMES) or 0)
            pos_msec = float(self.cap.get(cv2.CAP_PROP_POS_MSEC) or 0.0)
            print(
                f"[FrameCapture] File preview advance: captured={self._captured_frame_count} "
                f"unique={self._unique_frame_count} repeat_run={self._repeat_signature_run} "
                f"loop={self._loop_count} pos_frame={pos_frames} pos_sec={pos_msec / 1000.0:.2f} "
                f"sig={signature:08x}"
            )

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
             processing_fps=60.0, skip_frames=1, binary=True, all_poses=None):
        """Queue a frame for sending (flushes if batch is full)"""
        # Serialize this frame
        if binary:
            frame_data = serialize_single_landmarks(
                landmarks, timestamp, capture_ms, inference_ms,
                filter_ms, serialization_ms, frame_count,
                processing_fps, skip_frames
            )
        else:
            frame_data = serialize_landmarks_json(
                landmarks,
                timestamp,
                capture_ms,
                inference_ms,
                filter_ms,
                serialization_ms,
                frame_count,
                processing_fps,
                skip_frames,
                all_poses=all_poses,
            )

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
    signal_name = signal.Signals(sig).name if hasattr(signal, 'Signals') else 'unknown'
    print(f"\n[Signal] Received signal {sig} ({signal_name}), initiating orderly shutdown...")
    request_shutdown("Signal", f"received {signal_name}")

    try:
        sys.stderr.flush()
        sys.stdout.flush()
    except Exception:
        pass


signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)


def create_pose_detector(model_complexity: int = 0,
                        min_detection_confidence: float = 0.3,
                        min_tracking_confidence: float = 0.3):
    """Create MediaPipe pose detector using new Tasks API."""
    model_path = get_model_path(model_complexity)
    if not model_path.exists():
        raise FileNotFoundError(
            f"Missing MediaPipe model asset: {model_path.name} (expected at {model_path})"
        )

    base_options = BaseOptions(model_asset_path=str(model_path))

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


def remap_landmarks_from_roi(all_landmarks, roi, frame_shape):
    """Map ROI-relative normalized landmarks back to full-frame normalized coordinates."""
    if not roi:
        return all_landmarks

    roi_x, roi_y, roi_w, roi_h = roi
    frame_h, frame_w = frame_shape[:2]
    if roi_w <= 0 or roi_h <= 0 or frame_w <= 0 or frame_h <= 0:
        return all_landmarks

    remapped = []
    for pose_id, pose_landmarks in all_landmarks:
        pose_copy = []
        for lm in pose_landmarks:
            mapped = dict(lm)
            mapped['x'] = (roi_x + (lm['x'] * roi_w)) / frame_w
            mapped['y'] = (roi_y + (lm['y'] * roi_h)) / frame_h
            pose_copy.append(mapped)
        remapped.append((pose_id, pose_copy))
    return remapped


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
    global _running, _heartbeat_last_time, _shutdown_requested_at, _shutdown_reason

    _running = True
    _heartbeat_last_time = time.time()
    _shutdown_requested_at = None
    _shutdown_reason = "normal exit"

    # Platform-specific setup for optimal performance
    setup_platform_optimizations()

    latency_tracker = LatencyTracker()

    # Initialize heartbeat socket (receives heartbeat from Godot)
    heartbeat_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    heartbeat_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    heartbeat_sock.setblocking(False)
    try:
        # Bind to heartbeat port (main port + 2, avoiding conflict with stream port at +1)
        heartbeat_port = args.port + 2
        heartbeat_sock.bind((args.host, heartbeat_port))
        print(f"[Heartbeat] Listening on port {heartbeat_port}")
    except Exception as e:
        print(f"[Heartbeat] Warning: Could not bind heartbeat port: {e}")
        heartbeat_sock = None

    # Initialize UDP sender with tuned buffer size for low latency
    binary_mode = args.binary_protocol and not args.json_protocol
    udp_sender = UDPSender(
        args.host,
        args.port,
        batch_size=max(1, min(args.udp_batch_size, 10)),
        buffer_size=args.udp_buffer_size,
    )

    # Initialize MediaPipe Pose Landmarker with new Tasks API
    model_path = get_model_path(args.model_complexity)
    print(f"Initializing MediaPipe Pose Landmarker (model: {model_path})...")
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

    roi_tracker = None
    if args.use_roi:
        roi_tracker = PredictiveROITracker(
            target_size=args.roi_size,
            padding=args.roi_padding,
        )
        print(f"Predictive ROI enabled: size={args.roi_size}, padding={args.roi_padding}")
    else:
        print("Predictive ROI disabled")

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
    print(f"Resolution: {args.width}x{args.height}, Model: {args.model_complexity} ({model_path.name}), "
          f"Detection: {args.detection_confidence}, Tracking: {args.tracking_confidence}")
    print(f"Multi-pose: 2 people max (Player 1 = Green, Player 2 = Magenta)")
    print(f"Protocol: {'binary' if binary_mode else 'json'}")
    print(f"UDP buffer size: {args.udp_buffer_size} bytes | batch size: {max(1, min(args.udp_batch_size, 10))}")
    print(f"Frame skipping: {skip_frames} (capture: {args.max_fps}fps -> process: {processing_fps:.1f}fps)")
    print(f"Preprocess size: {args.preprocess_size if args.preprocess_size > 0 else 'disabled'}")
    if args.stream_camera:
        print(f"Camera streaming: enabled at http://127.0.0.1:{args.stream_port}/camera")
    else:
        print("Camera streaming: disabled (use --stream-camera to enable)")
    if args.show_window:
        print(f"Debug window: enabled (scale: {args.window_scale}x)")
        print("Press 'q' in the window to quit")
    else:
        print("Debug window: disabled (use --show-window to enable)")

    # Start heartbeat monitor thread
    heartbeat_thread = threading.Thread(target=heartbeat_monitor, daemon=True)
    heartbeat_thread.start()

    # Start watchdog thread to surface stuck shutdowns.
    # By default it only logs; an opt-in SIGKILL fuse can be armed via
    # AEROBEAT_MEDIAPIPE_FORCE_EXIT_AFTER_SEC for environments that truly need it.
    def watchdog():
        shutdown_start = None
        announced_force_policy = False
        while True:
            if not _running:
                if shutdown_start is None:
                    shutdown_start = time.time()
                    print(f"[Watchdog] Shutdown requested, monitoring orderly exit (reason: {_shutdown_reason})...")
                else:
                    elapsed = time.time() - shutdown_start
                    if _force_shutdown_after_sec > 0 and elapsed > _force_shutdown_after_sec:
                        print(f"[Watchdog] Shutdown still stuck after {elapsed:.1f}s; sending SIGKILL as configured by AEROBEAT_MEDIAPIPE_FORCE_EXIT_AFTER_SEC={_force_shutdown_after_sec}")
                        os.kill(os.getpid(), signal.SIGKILL)
                    elif _force_shutdown_after_sec <= 0 and not announced_force_policy:
                        print("[Watchdog] Force-exit fuse disabled; waiting for cleanup to finish naturally")
                        announced_force_policy = True
            time.sleep(0.5)

    watchdog_thread = threading.Thread(target=watchdog, daemon=True)
    watchdog_thread.start()

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

        # Check for heartbeat messages from Godot
        if heartbeat_sock:
            try:
                while True:
                    data, addr = heartbeat_sock.recvfrom(1024)
                    if data:
                        update_heartbeat()
            except BlockingIOError:
                pass  # No data available
            except Exception as e:
                pass  # Ignore other errors

        # Capture frame
        if frame_capture:
            frame = frame_capture.get_frame()
            ret = frame is not None
        else:
            ret, frame = cap.read()

        if not ret or frame is None:
            print("Warning: Failed to capture frame")
            continue

        # Update MJPEG streamer with a truthful preview frame before processing.
        # File-backed sources get a small playback HUD so subtle motion still reads as advancing.
        if mjpeg_streamer and mjpeg_streamer.is_running():
            preview_frame = frame_capture.decorate_preview_frame(frame) if frame_capture else frame
            mjpeg_streamer.update_frame(preview_frame)

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
                    request_shutdown("UI", "debug window quit requested")
                    break
            continue

        # Process frame with new Tasks API
        inference_start = time.time()
        inference_frame = frame
        active_roi = None
        if roi_tracker and roi_tracker.roi is not None:
            roi_x, roi_y, roi_w, roi_h = roi_tracker.roi
            if roi_w > 0 and roi_h > 0:
                inference_frame = frame[roi_y:roi_y + roi_h, roi_x:roi_x + roi_w]
                active_roi = roi_tracker.roi

        inference_frame, _preprocess_scale = preprocess_frame(inference_frame, args.preprocess_size)
        frame_rgb = cv2.cvtColor(inference_frame, cv2.COLOR_BGR2RGB)

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

        if active_roi is not None:
            all_landmarks = remap_landmarks_from_roi(all_landmarks, active_roi, frame.shape)

        # For now, use first pose for UDP (Godot side needs update for multi-pose)
        landmarks = all_landmarks[0][1] if all_landmarks else []

        # Apply One-Euro filtering (only to first pose for now)
        filter_start = time.time()
        if filter_bank and landmarks:
            timestamp = time.time()
            landmarks = filter_bank.filter_landmarks(landmarks, timestamp)
        filter_time = (time.time() - filter_start) * 1000  # ms

        if all_landmarks:
            all_landmarks[0] = (all_landmarks[0][0], landmarks)
        if roi_tracker:
            roi_tracker.update(landmarks, frame.shape)

        # Serialize and send
        serialization_start = time.time()
        timestamp = time.time()

        try:
            udp_sender.send(
                landmarks,
                timestamp,
                capture_ms=capture_time,
                inference_ms=inference_time,
                filter_ms=filter_time,
                serialization_ms=0.0,
                frame_count=latency_tracker.frame_count,
                processing_fps=processing_fps,
                skip_frames=skip_frames,
                binary=binary_mode,
                all_poses=all_landmarks,
            )
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
                request_shutdown("UI", "debug window quit requested")
                break

        # Cap FPS
        elapsed = time.time() - frame_start
        sleep_time = max(0, (1.0 / args.max_fps) - elapsed)
        if sleep_time > 0:
            time.sleep(sleep_time)

    # Cleanup
    shutdown_elapsed = None
    if _shutdown_requested_at is not None:
        shutdown_elapsed = time.time() - _shutdown_requested_at
    elapsed_text = f" after {shutdown_elapsed:.2f}s" if shutdown_elapsed is not None else ""
    print(f"[Main] Cleaning up{elapsed_text} (reason: {_shutdown_reason})...")
    if args.show_window:
        cv2.destroyAllWindows()
    if frame_capture:
        frame_capture.stop()
    if cap:
        cap.release()
    if mjpeg_streamer:
        mjpeg_streamer.stop()
    if heartbeat_sock:
        heartbeat_sock.close()
    udp_sender.close()
    if detector and hasattr(detector, 'close'):
        detector.close()
    heartbeat_thread.join(timeout=1.0)
    print("[Main] Cleanup complete")
    print("MediaPipe stopped")


if __name__ == "__main__":
    main()
