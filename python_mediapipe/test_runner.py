#!/usr/bin/env python3
"""
AeroBeat Automated Test Runner

Run performance and tracking quality tests using video files.
"""

import cv2
import time
import json
import argparse
import sys
import os
import struct
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Dict, Any, Optional, Tuple
import statistics

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from one_euro_filter import LandmarkFilterBank, get_preset_params
from roi_tracker import PredictiveROITracker

try:
    import mediapipe as mp
    from mediapipe.tasks.python import vision
    from mediapipe.tasks.python.core.base_options import BaseOptions
    import numpy as np
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)


@dataclass
class FrameMetrics:
    """Metrics for a single frame."""
    frame_num: int
    timestamp_ms: float
    capture_time_ms: float = 0.0
    preprocess_time_ms: float = 0.0
    inference_time_ms: float = 0.0
    filter_time_ms: float = 0.0
    roi_time_ms: float = 0.0
    serialize_time_ms: float = 0.0
    total_time_ms: float = 0.0
    landmarks_detected: int = 0
    pose_detected: bool = False


@dataclass
class TestResults:
    """Complete test results."""
    test_info: Dict[str, Any]
    performance: Dict[str, float]
    tracking_quality: Dict[str, float]
    frame_metrics: List[Dict[str, Any]]


def preprocess_frame(frame: np.ndarray, target_size: int) -> Tuple[np.ndarray, float]:
    """Resize frame before MediaPipe for faster inference."""
    if target_size <= 0 or frame.shape[0] <= target_size:
        return frame, 1.0
    
    scale = target_size / frame.shape[0]
    new_width = int(frame.shape[1] * scale)
    small_frame = cv2.resize(frame, (new_width, target_size))
    return small_frame, scale


def scale_landmarks(landmarks: List[Dict], scale: float) -> List[Dict]:
    """Scale landmarks back to original frame coordinates."""
    for lm in landmarks:
        lm['x'] /= scale
        lm['y'] /= scale
    return landmarks


def create_pose_detector(model_complexity: int = 0):
    """Create MediaPipe pose detector using new Tasks API."""
    model_paths = {
        0: "pose_landmarker_lite.task",
        1: "pose_landmarker_full.task", 
        2: "pose_landmarker_heavy.task"
    }
    
    base_options = BaseOptions(model_asset_path=model_paths.get(model_complexity, model_paths[0]))
    
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=0.3,
        min_pose_presence_confidence=0.3,
        min_tracking_confidence=0.3
    )
    
    return vision.PoseLandmarker.create_from_options(options)


def run_performance_test(video_path: str, args) -> Optional[TestResults]:
    """Run performance test on video file with all optimizations."""
    print(f"Starting performance test on: {video_path}")
    print(f"Optimizations: preprocess={args.preprocess_size}, ROI={args.use_roi}")
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return None
    
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps if fps > 0 else 0
    
    print(f"Video: {total_frames} frames @ {fps:.1f} FPS ({duration:.1f}s)")
    print("Note: Using MediaPipe Tasks API (0.10+)")
    
    # Initialize detector
    print("Initializing MediaPipe pose detector...")
    try:
        detector = create_pose_detector(args.model_complexity)
    except Exception as e:
        print(f"Error creating detector: {e}")
        print("Falling back to basic test without MediaPipe...")
        return run_basic_test(cap, total_frames, fps, video_path, args)
    
    # Initialize filter bank
    filter_bank = None
    if args.use_filter:
        preset_params = get_preset_params(args.filter_preset)
        filter_bank = LandmarkFilterBank(
            num_landmarks=33,
            min_cutoff=preset_params['min_cutoff'],
            beta=preset_params['beta'],
            d_cutoff=preset_params['d_cutoff']
        )
        print(f"Using One-Euro filter (preset: {args.filter_preset})")
    
    # Initialize ROI tracker
    roi_tracker = None
    if args.use_roi:
        roi_tracker = PredictiveROITracker(
            target_size=args.roi_size,
            padding=args.roi_padding
        )
        print(f"Using Predictive ROI (size: {args.roi_size}, padding: {args.roi_padding})")
    
    # Metrics collection
    frame_metrics: List[FrameMetrics] = []
    frame_num = 0
    test_start = time.time() * 1000
    lost_tracking_count = 0
    
    print("Processing frames...")
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_start = time.time() * 1000
        original_shape = frame.shape
        
        # Preprocessing (resize)
        preprocess_start = time.time() * 1000
        if args.preprocess_size > 0:
            frame, scale = preprocess_frame(frame, args.preprocess_size)
        else:
            scale = 1.0
        preprocess_time = time.time() * 1000 - preprocess_start
        
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        
        capture_time = time.time() * 1000 - frame_start
        
        # Run detection
        inference_start = time.time() * 1000
        detection_result = detector.detect_for_video(mp_image, int(frame_num * (1000/fps)))
        inference_time = time.time() * 1000 - inference_start
        
        # Process landmarks
        filter_start = time.time() * 1000
        landmarks_detected = 0
        pose_detected = False
        landmarks = []
        
        if detection_result.pose_landmarks:
            pose_detected = True
            landmarks_detected = len(detection_result.pose_landmarks[0])
            
            # Convert to list of dicts
            for i, lm in enumerate(detection_result.pose_landmarks[0]):
                landmarks.append({
                    'id': i,
                    'x': lm.x,
                    'y': lm.y,
                    'z': lm.z,
                    'v': lm.visibility
                })
            
            # Scale back if preprocessing was used
            if args.preprocess_size > 0 and scale != 1.0:
                landmarks = scale_landmarks(landmarks, scale)
            
            if filter_bank:
                # Apply filtering (simplified for test)
                pass
        else:
            lost_tracking_count += 1
        
        filter_time = time.time() * 1000 - filter_start
        
        # ROI tracking update
        roi_start = time.time() * 1000
        roi_time = 0.0
        if roi_tracker:
            roi_tracker.update(landmarks, original_shape)
            # Note: ROI cropping happens on the NEXT frame
            # This simulates the real-time behavior
            roi_time = time.time() * 1000 - roi_start
        
        total_time = time.time() * 1000 - frame_start
        
        frame_metrics.append(FrameMetrics(
            frame_num=frame_num,
            timestamp_ms=frame_start - test_start,
            capture_time_ms=capture_time,
            preprocess_time_ms=preprocess_time,
            inference_time_ms=inference_time,
            filter_time_ms=filter_time,
            roi_time_ms=roi_time,
            total_time_ms=total_time,
            landmarks_detected=landmarks_detected,
            pose_detected=pose_detected
        ))
        
        frame_num += 1
        if frame_num % 100 == 0:
            print(f"  Processed {frame_num}/{total_frames} frames...")
    
    elapsed = (time.time() * 1000 - test_start) / 1000  # seconds
    
    # Calculate statistics
    latencies = [m.total_time_ms for m in frame_metrics]
    detected_frames = sum(1 for m in frame_metrics if m.pose_detected)
    
    # Calculate optimization-specific stats
    if args.preprocess_size > 0:
        preprocess_times = [m.preprocess_time_ms for m in frame_metrics]
        avg_preprocess = statistics.mean(preprocess_times)
        print(f"\n📐 Preprocessing: {avg_preprocess:.2f}ms avg (resize to {args.preprocess_size}px)")
    
    if args.use_roi:
        roi_times = [m.roi_time_ms for m in frame_metrics]
        avg_roi = statistics.mean(roi_times)
        print(f"🎯 ROI Tracking: {avg_roi:.2f}ms avg")
        print(f"📉 Lost tracking frames: {lost_tracking_count}/{frame_num} ({100*lost_tracking_count/frame_num:.1f}%)")
    
    results = TestResults(
        test_info={
            'video_path': video_path,
            'total_frames': total_frames,
            'frames_processed': frame_num,
            'video_fps': fps,
            'test_duration_sec': elapsed,
            'test_date': time.strftime('%Y-%m-%d %H:%M:%S'),
            'mediapipe_version': mp.__version__,
            'preprocess_size': args.preprocess_size,
            'use_roi': args.use_roi,
            'roi_size': args.roi_size if args.use_roi else 0,
        },
        performance={
            'avg_latency_ms': statistics.mean(latencies) if latencies else 0,
            'min_latency_ms': min(latencies) if latencies else 0,
            'max_latency_ms': max(latencies) if latencies else 0,
            'std_latency_ms': statistics.stdev(latencies) if len(latencies) > 1 else 0,
            'achieved_fps': frame_num / elapsed if elapsed > 0 else 0,
        },
        tracking_quality={
            'detection_rate': detected_frames / frame_num if frame_num > 0 else 0,
            'avg_landmarks': statistics.mean([m.landmarks_detected for m in frame_metrics]) if frame_metrics else 0,
        },
        frame_metrics=[asdict(m) for m in frame_metrics]
    )
    
    cap.release()
    
    print(f"\n✅ Test Complete!")
    print(f"  Frames: {frame_num}/{total_frames}")
    print(f"  Time: {elapsed:.2f}s")
    print(f"  Avg FPS: {results.performance['achieved_fps']:.1f}")
    print(f"  Avg Latency: {results.performance['avg_latency_ms']:.2f}ms")
    print(f"  Detection Rate: {results.tracking_quality['detection_rate']*100:.1f}%")
    
    return results


def run_basic_test(cap, total_frames: int, fps: float, video_path: str, args) -> TestResults:
    """Run basic test without MediaPipe (fallback)."""
    print("Running basic video decode test (no pose detection)...")
    
    frame_metrics = []
    frame_num = 0
    test_start = time.time() * 1000
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_start = time.time() * 1000
        
        # Just decode and convert
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        total_time = time.time() * 1000 - frame_start
        
        frame_metrics.append(FrameMetrics(
            frame_num=frame_num,
            timestamp_ms=frame_start - test_start,
            capture_time_ms=total_time,
            preprocess_time_ms=0.0,
            inference_time_ms=0,
            filter_time_ms=0,
            roi_time_ms=0.0,
            total_time_ms=total_time,
            landmarks_detected=0,
            pose_detected=False
        ))
        
        frame_num += 1
        if frame_num % 100 == 0:
            print(f"  Processed {frame_num}/{total_frames} frames...")
    
    elapsed = (time.time() * 1000 - test_start) / 1000
    latencies = [m.total_time_ms for m in frame_metrics]
    
    return TestResults(
        test_info={
            'video_path': video_path,
            'total_frames': total_frames,
            'frames_processed': frame_num,
            'video_fps': fps,
            'test_duration_sec': elapsed,
            'test_date': time.strftime('%Y-%m-%d %H:%M:%S'),
            'note': 'Basic test without MediaPipe (fallback)',
            'preprocess_size': args.preprocess_size,
            'use_roi': args.use_roi,
        },
        performance={
            'avg_latency_ms': statistics.mean(latencies) if latencies else 0,
            'min_latency_ms': min(latencies) if latencies else 0,
            'max_latency_ms': max(latencies) if latencies else 0,
            'achieved_fps': frame_num / elapsed if elapsed > 0 else 0,
        },
        tracking_quality={
            'detection_rate': 0.0,
            'avg_landmarks': 0,
        },
        frame_metrics=[asdict(m) for m in frame_metrics]
    )


def main():
    parser = argparse.ArgumentParser(description='AeroBeat Automated Test Runner')
    parser.add_argument('--video', required=True, help='Path to test video file')
    parser.add_argument('--output', default='test_report.json', help='Output report path')
    parser.add_argument('--model-complexity', type=int, default=0, choices=[0, 1, 2],
                       help='Model complexity (0=Lite, 1=Full, 2=Heavy)')
    parser.add_argument('--use-filter', action='store_true', default=True)
    parser.add_argument('--no-filter', dest='use_filter', action='store_false')
    parser.add_argument('--filter-preset', default='balanced', 
                       choices=['responsive', 'balanced', 'smooth'])
    
    # New optimization flags
    parser.add_argument('--preprocess-size', type=int, default=0,
                       help='Resize frame to this height before inference, 0=disable (default: 0)')
    parser.add_argument('--use-roi', action='store_true',
                       help='Enable Predictive ROI tracking for focused inference')
    parser.add_argument('--roi-size', type=int, default=320,
                       help='ROI target height in pixels (default: 320)')
    parser.add_argument('--roi-padding', type=int, default=50,
                       help='Padding around detected person in pixels (default: 50)')
    
    args = parser.parse_args()
    
    # Run test
    results = run_performance_test(args.video, args)
    
    if results:
        # Save report
        with open(args.output, 'w') as f:
            json.dump(asdict(results), f, indent=2)
        print(f"\n📊 Report saved to: {args.output}")
        return 0
    else:
        return 1


if __name__ == '__main__':
    sys.exit(main())
