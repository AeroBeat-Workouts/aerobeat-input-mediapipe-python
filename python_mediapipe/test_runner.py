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
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from main import MediaPipeProcessor, LatencyTracker
from args import parse_args as main_parse_args
from one_euro_filter import LandmarkFilterBank, get_preset_params


def run_performance_test(video_path, args):
    """Run performance test on video file."""
    print(f"Starting performance test on: {video_path}")
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}")
        return None
    
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps if fps > 0 else 0
    
    print(f"Video: {total_frames} frames @ {fps:.1f} FPS ({duration:.1f}s)")
    
    # Initialize processor with test args
    processor = MediaPipeProcessor(args)
    
    # Metrics collection
    metrics = {
        'test_info': {
            'video': video_path,
            'total_frames': total_frames,
            'video_fps': fps,
            'test_date': time.strftime('%Y-%m-%d %H:%M:%S'),
        },
        'frame_metrics': [],
        'summary': {}
    }
    
    frame_count = 0
    start_time = time.time()
    
    print("Processing...")
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_start = time.time()
        
        # Process frame
        landmarks = processor.process(frame)
        
        frame_time = (time.time() - frame_start) * 1000  # ms
        
        metrics['frame_metrics'].append({
            'frame': frame_count,
            'latency_ms': frame_time,
            'landmarks_detected': len(landmarks) if landmarks else 0
        })
        
        frame_count += 1
        if frame_count % 100 == 0:
            print(f"  Processed {frame_count}/{total_frames} frames...")
    
    elapsed = time.time() - start_time
    
    # Calculate summary
    latencies = [m['latency_ms'] for m in metrics['frame_metrics']]
    landmarks_detected = [m['landmarks_detected'] for m in metrics['frame_metrics']]
    
    metrics['summary'] = {
        'frames_processed': frame_count,
        'elapsed_time_sec': elapsed,
        'achieved_fps': frame_count / elapsed if elapsed > 0 else 0,
        'avg_latency_ms': sum(latencies) / len(latencies) if latencies else 0,
        'min_latency_ms': min(latencies) if latencies else 0,
        'max_latency_ms': max(latencies) if latencies else 0,
        'avg_landmarks': sum(landmarks_detected) / len(landmarks_detected) if landmarks_detected else 0,
    }
    
    cap.release()
    
    print(f"\nTest Complete!")
    print(f"  Frames: {frame_count}")
    print(f"  Time: {elapsed:.2f}s")
    print(f"  Avg FPS: {metrics['summary']['achieved_fps']:.1f}")
    print(f"  Avg Latency: {metrics['summary']['avg_latency_ms']:.2f}ms")
    
    return metrics


def save_report(metrics, output_path):
    """Save test report to JSON file."""
    with open(output_path, 'w') as f:
        json.dump(metrics, f, indent=2)
    print(f"\nReport saved to: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='AeroBeat Automated Test Runner')
    parser.add_argument('--video', required=True, help='Path to test video file')
    parser.add_argument('--output', default='test_report.json', help='Output report path')
    parser.add_argument('--mode', choices=['performance', 'tracking', 'stress'], 
                       default='performance', help='Test mode')
    
    # Include args from main.py
    parser.add_argument('--model-complexity', type=int, default=0)
    parser.add_argument('--detection-confidence', type=float, default=0.3)
    parser.add_argument('--tracking-confidence', type=float, default=0.3)
    parser.add_argument('--use-filter', action='store_true', default=True)
    parser.add_argument('--no-filter', dest='use_filter', action='store_false')
    parser.add_argument('--filter-preset', default='balanced')
    parser.add_argument('--binary-protocol', action='store_true', default=True)
    parser.add_argument('--json-protocol', action='store_true')
    parser.add_argument('--threaded-capture', action='store_true', default=True)
    parser.add_argument('--no-threaded-capture', dest='threaded_capture', action='store_false')
    parser.add_argument('--skip-frames', type=int, default=1)
    parser.add_argument('--udp-buffer-size', type=int, default=4096)
    
    args = parser.parse_args()
    
    # Run test
    metrics = run_performance_test(args.video, args)
    
    if metrics:
        save_report(metrics, args.output)
        return 0
    else:
        return 1


if __name__ == '__main__':
    sys.exit(main())
