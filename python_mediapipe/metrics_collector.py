#!/usr/bin/env python3
"""
Metrics Collector for AeroBeat Testing

Collects detailed timing and performance metrics during test runs.
"""

import time
import statistics
import psutil
import os
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Any, Optional
from collections import deque


@dataclass
class FrameMetrics:
    """Metrics for a single processed frame."""
    frame_num: int = 0
    timestamp_ms: float = 0.0
    
    # Timing breakdown (milliseconds)
    capture_time_ms: float = 0.0
    inference_time_ms: float = 0.0
    filter_time_ms: float = 0.0
    serialize_time_ms: float = 0.0
    send_time_ms: float = 0.0
    total_time_ms: float = 0.0
    
    # Tracking quality
    landmarks_detected: int = 0
    avg_confidence: float = 0.0
    pose_detected: bool = False
    
    # System metrics
    memory_mb: float = 0.0
    cpu_percent: float = 0.0


@dataclass
class TestSummary:
    """Aggregated test results."""
    # Test info
    video_path: str = ""
    total_frames: int = 0
    test_duration_sec: float = 0.0
    test_date: str = ""
    
    # Performance
    avg_latency_ms: float = 0.0
    min_latency_ms: float = 0.0
    max_latency_ms: float = 0.0
    std_latency_ms: float = 0.0
    avg_fps: float = 0.0
    frame_drops: int = 0
    
    # Tracking quality
    detection_rate: float = 0.0
    avg_confidence: float = 0.0
    avg_landmarks: float = 0.0
    
    # Pass/fail
    passed: bool = False
    failures: List[str] = field(default_factory=list)


class MetricsCollector:
    """
    Collects and analyzes metrics from MediaPipe test runs.
    """
    
    def __init__(self):
        self.frame_metrics: List[FrameMetrics] = []
        self.errors: List[Dict[str, Any]] = []
        self.process = psutil.Process(os.getpid())
        self.start_time: float = 0.0
        self._current_frame: Optional[FrameMetrics] = None
        
    def start_test(self):
        """Mark the start of a test run."""
        self.start_time = time.time() * 1000
        self.frame_metrics = []
        self.errors = []
        
    def start_frame(self, frame_num: int) -> FrameMetrics:
        """Start timing a new frame."""
        self._current_frame = FrameMetrics(
            frame_num=frame_num,
            timestamp_ms=time.time() * 1000,
            memory_mb=self.process.memory_info().rss / 1024 / 1024,
            cpu_percent=self.process.cpu_percent()
        )
        return self._current_frame
    
    def record_timing(self, phase: str, duration_ms: float):
        """Record timing for a specific processing phase."""
        if self._current_frame:
            setattr(self._current_frame, f"{phase}_time_ms", duration_ms)
    
    def record_landmarks(self, landmarks: List[Any]):
        """Record landmark detection results."""
        if not self._current_frame:
            return
        
        if landmarks:
            self._current_frame.landmarks_detected = len(landmarks)
            confidences = [getattr(lm, 'visibility', 1.0) for lm in landmarks]
            if confidences:
                self._current_frame.avg_confidence = sum(confidences) / len(confidences)
            self._current_frame.pose_detected = True
        else:
            self._current_frame.pose_detected = False
    
    def end_frame(self):
        """Finalize current frame metrics."""
        if self._current_frame:
            self._current_frame.total_time_ms = (
                self._current_frame.capture_time_ms +
                self._current_frame.inference_time_ms +
                self._current_frame.filter_time_ms +
                self._current_frame.serialize_time_ms +
                self._current_frame.send_time_ms
            )
            self.frame_metrics.append(self._current_frame)
            self._current_frame = None
    
    def record_error(self, error_type: str, message: str, frame_num: Optional[int] = None):
        """Record an error or warning."""
        self.errors.append({
            "timestamp": time.time() * 1000,
            "frame_num": frame_num,
            "type": error_type,
            "message": message
        })
    
    def calculate_summary(self) -> TestSummary:
        """Calculate aggregate statistics from collected metrics."""
        if not self.frame_metrics:
            return TestSummary()
        
        summary = TestSummary()
        summary.total_frames = len(self.frame_metrics)
        summary.test_duration_sec = (time.time() * 1000 - self.start_time) / 1000
        
        # Performance stats
        latencies = [m.total_time_ms for m in self.frame_metrics]
        summary.avg_latency_ms = statistics.mean(latencies)
        summary.min_latency_ms = min(latencies)
        summary.max_latency_ms = max(latencies)
        if len(latencies) > 1:
            summary.std_latency_ms = statistics.stdev(latencies)
        summary.avg_fps = summary.total_frames / summary.test_duration_sec if summary.test_duration_sec > 0 else 0
        
        # Tracking quality
        detected_frames = sum(1 for m in self.frame_metrics if m.pose_detected)
        summary.detection_rate = detected_frames / len(self.frame_metrics) if self.frame_metrics else 0
        summary.avg_confidence = statistics.mean([m.avg_confidence for m in self.frame_metrics if m.pose_detected]) if detected_frames > 0 else 0
        summary.avg_landmarks = statistics.mean([m.landmarks_detected for m in self.frame_metrics])
        
        # Pass/fail criteria
        failures = []
        if summary.avg_latency_ms > 50:
            failures.append(f"Avg latency {summary.avg_latency_ms:.1f}ms exceeds 50ms threshold")
        if summary.avg_fps < 25:
            failures.append(f"Avg FPS {summary.avg_fps:.1f} below 25 threshold")
        if summary.detection_rate < 0.90:
            failures.append(f"Detection rate {summary.detection_rate*100:.1f}% below 90% threshold")
        
        summary.passed = len(failures) == 0
        summary.failures = failures
        
        return summary
    
    def get_full_report(self, video_path: str) -> Dict[str, Any]:
        """Generate complete test report."""
        summary = self.calculate_summary()
        summary.video_path = video_path
        summary.test_date = time.strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            'test_info': {
                'video_path': summary.video_path,
                'total_frames': summary.total_frames,
                'test_duration_sec': summary.test_duration_sec,
                'test_date': summary.test_date,
            },
            'performance': {
                'avg_latency_ms': summary.avg_latency_ms,
                'min_latency_ms': summary.min_latency_ms,
                'max_latency_ms': summary.max_latency_ms,
                'std_latency_ms': summary.std_latency_ms,
                'avg_fps': summary.avg_fps,
                'frame_drops': summary.frame_drops,
            },
            'tracking_quality': {
                'detection_rate': summary.detection_rate,
                'avg_confidence': summary.avg_confidence,
                'avg_landmarks': summary.avg_landmarks,
            },
            'pass_fail': {
                'passed': summary.passed,
                'failures': summary.failures,
            },
            'frame_metrics': [asdict(m) for m in self.frame_metrics],
            'errors': self.errors,
        }


# Simple timer context manager
class Timer:
    """Context manager for timing code blocks."""
    def __init__(self, collector: MetricsCollector, phase: str):
        self.collector = collector
        self.phase = phase
        self.start = 0
        
    def __enter__(self):
        self.start = time.time() * 1000
        return self
        
    def __exit__(self, *args):
        duration = (time.time() * 1000) - self.start
        self.collector.record_timing(self.phase, duration)
