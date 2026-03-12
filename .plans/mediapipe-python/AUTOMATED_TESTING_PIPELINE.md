# Automated Testing Pipeline for AeroBeat

## Overview

Automated testing pipeline for MediaPipe body tracking using test videos.

**Goals:**
- Performance benchmarking with reproducible results
- Tracking quality validation
- Regression detection on code changes

---

## 1. Pipeline Architecture

```
Test Video → MediaPipe Processor → Metrics Collection → Report Generation
                 ↓
          Ground Truth Comparison (optional)
```

**Components:**
| Component | Purpose | File |
|-----------|---------|------|
| Video Input | Load and stream test videos | `test_input.py` |
| Test Runner | Orchestrate test execution | `test_runner.py` |
| Metrics Collector | Capture timing and quality data | `metrics_collector.py` |
| Report Generator | Create JSON/HTML reports | `report_generator.py` |

---

## 2. Test Scenarios

### A. Performance Baseline
- Process video at maximum speed (no FPS limiting)
- Measure: FPS, latency per frame, CPU usage
- **Pass:** avg FPS ≥ 30, avg latency < 50ms

### B. Real-Time Simulation  
- Process at video's native FPS (e.g., 30 FPS)
- Measure: Frame drops, jitter, UDP packet loss
- **Pass:** frame drops < 1%, jitter < 5ms std dev

### C. Tracking Quality
- Record landmark detection rates and confidence
- Measure tracking continuity and jitter
- **Pass:** detection rate > 90%, avg confidence > 0.75

### D. Stress Test
- Loop video 10x (~5 minutes continuous)
- Monitor memory and performance over time
- **Pass:** memory growth < 10MB, no performance degradation

---

## 3. Key Metrics

**Performance:**
- `capture_time_ms` - Frame capture/decode time
- `inference_time_ms` - MediaPipe model inference
- `filter_time_ms` - Smoothing filter processing
- `serialize_time_ms` - JSON/binary serialization
- `send_time_ms` - UDP packet transmission
- `total_latency_ms` - End-to-end processing time
- `achieved_fps` - Actual frames processed per second

**Tracking Quality:**
- `detection_rate` - % frames with valid landmarks
- `avg_confidence` - Average landmark confidence score
- `tracking_continuity` - % of time with continuous tracking
- `jitter_reduction_pct` - Filter effectiveness

---

## 4. Implementation Phases

### Phase 1: Basic Test Runner (2 hours)
```python
# test_runner.py - Minimal implementation
import cv2
import time
import json
from python_mediapipe.main import MediaPipeProcessor

def run_performance_test(video_path):
    cap = cv2.VideoCapture(video_path)
    processor = MediaPipeProcessor()
    
    metrics = []
    frame_num = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        start = time.time()
        landmarks = processor.process(frame)
        elapsed = (time.time() - start) * 1000
        
        metrics.append({
            'frame': frame_num,
            'latency_ms': elapsed,
            'landmarks_detected': len(landmarks) if landmarks else 0
        })
        frame_num += 1
    
    # Save report
    with open('test_report.json', 'w') as f:
        json.dump({
            'avg_latency': sum(m['latency_ms'] for m in metrics) / len(metrics),
            'total_frames': frame_num,
            'metrics': metrics
        }, f, indent=2)

if __name__ == '__main__':
    run_performance_test('test_boxing.mp4')
```

### Phase 2: Metrics Collector (2 hours)
- Add detailed timing breakdown per processing phase
- Track landmark detection rates and confidence
- Monitor CPU and memory usage with psutil

### Phase 3: Report Generation (2 hours)
- JSON report with full metrics
- HTML report with charts (matplotlib)
- Pass/fail summary with threshold comparison

### Phase 4: CI Integration (2 hours)
- pytest fixtures for video testing
- GitHub Actions workflow
- Artifact upload for reports

---

## 5. Usage Examples

```bash
# Run performance test
python -m python_mediapipe.test_runner --video test_boxing.mp4 --mode performance

# Run tracking quality test
python -m python_mediapipe.test_runner --video test_boxing.mp4 --mode tracking

# Run stress test (10 loops)
python -m python_mediapipe.test_runner --video test_boxing.mp4 --mode stress --loops 10

# Generate HTML report
python -m python_mediapipe.test_runner --video test_boxing.mp4 --report html --output reports/

# pytest integration
pytest tests/test_performance.py --video=test_boxing.mp4 --benchmark
```

---

## 6. Pass/Fail Criteria

| Metric | Target | Critical |
|--------|--------|----------|
| Avg Latency | < 50ms | < 100ms |
| Min FPS | > 25 | > 15 |
| Detection Rate | > 90% | > 75% |
| Memory Growth | < 10MB/5min | < 50MB/5min |
| Frame Drops | < 1% | < 5% |

---

## 7. Next Steps

1. **Implement Phase 1** - Basic test runner with video input
2. **Add metrics collection** - Timing breakdowns, CPU/memory monitoring
3. **Create report generator** - JSON + HTML output
4. **Integrate with CI** - pytest + GitHub Actions
5. **Add more test videos** - Different poses, lighting, speeds

**Estimated Total Effort:** 8 hours (4 phases × 2 hours)
