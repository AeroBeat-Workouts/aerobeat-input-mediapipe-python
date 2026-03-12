# Optimization Expert Review - AeroBeat MediaPipe + Godot 4.6

**Date:** 2026-02-07  
**Status:** Expert Analysis Complete  
**Platform:** Linux (Zorin 18 Pro)  

---

## Current State Assessment

### Implemented Optimizations ✅

| Optimization | Status | Impact | Latency |
|-------------|--------|--------|---------|
| MediaPipe Lite model | ✅ | ~10-20ms | 50→30ms |
| Binary serialization | ✅ | ~0.1ms + bandwidth | - |
| Threaded frame capture | ✅ | Eliminates buffer delay | 5-10ms |
| Frame skipping + Godot interp | ✅ | Variable | Configurable |
| One-Euro filtering | ✅ | Quality only | +0.1ms |
| UDP buffer tuning | ✅ | 2-5ms improvement | 30→25ms |
| Real-time latency display | ✅ | Debugging only | - |

**Current Achieved Latency:** 25-45ms

---

## Recommended Optimizations (Priority Order)

### 1. Godot 4.6 Side - HIGH PRIORITY

#### A. UDP Packet Batching
**Effort:** Low (2 hours)  
**Impact:** Medium (3-8ms)

Current: One packet per frame  
Recommended: Batch 2-3 frames per packet

```gdscript
# Godot: Receive batched packets
func _process(delta):
    while udp.get_available_bytes() > 0:
        var packets = udp.get_packet().split(b"|DELIM|")
        for packet in packets:
            _parse_landmarks(packet)
```

#### B. Scene Tree Optimization
**Effort:** Low (1 hour)  
**Impact:** Medium (2-5ms)

```gdscript
# Use call_deferred for avatar updates
func _on_landmarks_received(landmarks):
    # Instead of direct update:
    # update_avatar(landmarks)
    
    # Use deferred to avoid blocking:
    call_deferred("update_avatar", landmarks)

func update_avatar(landmarks):
    # Batch node updates
    for landmark in landmarks:
        _landmark_nodes[landmark.id].position = _convert_pos(landmark)
```

#### C. GDScript Math Optimization
**Effort:** Low (30 min)  
**Impact:** Low (1-2ms)

```gdscript
# Cache calculations
var _flip_y := 1.0
var _flip_x := -1.0

func _ready():
    if config.flip_vertical:
        _flip_y = -1.0
    if config.flip_horizontal:
        _flip_x = 1.0

func convert_position(lm):
    # Avoid repeated calculations
    return Vector2(
        lm.x * _flip_x + config.offset_x,
        lm.y * _flip_y + config.offset_y
    )
```

---

### 2. MediaPipe Python Side - MEDIUM PRIORITY

#### A. ROI (Region of Interest) Tracking
**Effort:** Medium (4 hours)  
**Impact:** High (5-10ms)

Track only the region where the user is detected, reducing image size for inference.

```python
class ROITracker:
    def __init__(self, padding=50):
        self.roi = None
        self.padding = padding
    
    def update(self, landmarks, frame_shape):
        if landmarks:
            xs = [lm.x * frame_shape[1] for lm in landmarks]
            ys = [lm.y * frame_shape[0] for lm in landmarks]
            self.roi = (
                max(0, int(min(xs)) - self.padding),
                max(0, int(min(ys)) - self.padding),
                min(frame_shape[1], int(max(xs)) + self.padding),
                min(frame_shape[0], int(max(ys)) + self.padding)
            )
    
    def crop_frame(self, frame):
        if self.roi:
            x1, y1, x2, y2 = self.roi
            return frame[y1:y2, x1:x2]
        return frame
```

#### B. Frame Preprocessing Pipeline
**Effort:** Low (2 hours)  
**Impact:** Medium (3-5ms)

```python
import cv2
import numpy as np

class FramePreprocessor:
    def __init__(self, target_size=(320, 240)):
        self.target_size = target_size
    
    def preprocess(self, frame):
        # Resize first (reduces data for all ops)
        small = cv2.resize(frame, self.target_size)
        # Convert to RGB (MediaPipe expects RGB)
        rgb = cv2.cvtColor(small, cv2.COLOR_BGR2RGB)
        return rgb
```

#### C. Alternative Models (MoveNet)
**Effort:** Medium (4 hours)  
**Impact:** High (10-20ms)

Consider TensorFlow MoveNet as alternative to MediaPipe:
- Thunder variant: ~10ms inference (vs 8-15ms MediaPipe Lite)
- Lightning variant: ~5ms inference (lower accuracy)
- Single-pose optimized

---

### 3. Network/Protocol - LOW PRIORITY

#### A. Compression
**Effort:** Low (2 hours)  
**Impact:** Low (bandwidth only, not latency)

```python
import zlib

# Compress binary payload
def compress_landmarks(data: bytes) -> bytes:
    return zlib.compress(data, level=1)  # Fast compression

# Current: ~550 bytes
# Compressed: ~300-400 bytes (40% reduction)
```

#### B. Connection Reliability
**Effort:** Low (1 hour)  
**Impact:** Low (quality of life)

Add heartbeat/ping to detect disconnects:
```python
# Python side: Send heartbeat every 1s
if frame_count % 30 == 0:
    send_heartbeat()

# Godot side: Track last heartbeat
func _process(delta):
    if Time.get_ticks_msec() - last_heartbeat > 2000:
        emit_signal("connection_lost")
```

---

### 4. System-Level - OPTIONAL

#### A. Linux Process Priorities
**Effort:** Low (1 hour)  
**Impact:** Low-Medium (2-5ms variance reduction)

```python
import os
import psutil

def set_high_priority():
    """Set MediaPipe process to high priority"""
    p = psutil.Process(os.getpid())
    p.nice(-10)  # Higher priority (Linux)
    
    # CPU affinity (pin to specific cores)
    p.cpu_affinity([0, 1])  # Use cores 0 and 1
```

**Trade-off:** May impact Godot performance if on same cores.

#### B. Real-Time Kernel (Advanced)
**Effort:** High (System-level)  
**Impact:** High (5-15ms variance reduction)

Install PREEMPT_RT kernel patch for Linux:
```bash
# Check current kernel
uname -r

# For Zorin/Ubuntu, would need custom kernel build
# Significant effort, only if latency variance is critical
```

**Not recommended** unless consistent sub-20ms is absolutely required.

---

## Priority Matrix

| Optimization | Effort | Impact | Risk | Priority |
|-------------|--------|--------|------|----------|
| UDP Batching (Godot) | Low | Medium | Low | **1** |
| Scene Tree Opt (Godot) | Low | Medium | Low | **2** |
| ROI Tracking (Python) | Medium | High | Medium | **3** |
| Frame Preprocessing | Low | Medium | Low | **4** |
| Process Priority | Low | Low | Low | **5** |
| MoveNet Evaluation | Medium | High | Medium | **6** |
| Compression | Low | Low | None | **7** |
| Real-Time Kernel | High | High | High | **Last** |

---

## Quick Wins (Do These First)

1. **Godot UDP batching** - 2 hours, 3-8ms improvement
2. **Scene tree optimization** - 1 hour, smoother updates
3. **Frame preprocessing** - 2 hours, 3-5ms improvement

**Combined potential:** 6-13ms additional reduction (target: 15-30ms)

---

## Expert Recommendations

### For Immediate Implementation:
1. **Godot-side batching** - Easy win, minimal risk
2. **ROI tracking** - Biggest potential gain on Python side

### For Future Evaluation:
1. **MoveNet comparison** - If 15ms target not met with other opts
2. **Real-time kernel** - Only if variance is unacceptable

### Skip (Not Worth It):
1. Shared memory - UDP localhost already <1ms
2. Kalman filtering - One-Euro is sufficient
3. GPU acceleration - Only if CPU becomes bottleneck

---

## Next Steps

1. Implement Godot UDP batching
2. Test ROI tracking on boxing video
3. Measure improvement vs 25-45ms baseline
4. Decide on MoveNet evaluation based on results

---

*Expert review complete. Recommend starting with Godot-side optimizations for immediate gains.*
