# Advanced Latency Optimizations - Planning Document

**Date:** 2026-02-07  
**Status:** Planning Phase  
**Target:** Reduce latency from current ~25-45ms to ~15-30ms

---

## Overview

We've implemented the "easy wins" for latency reduction:
- ✅ MediaPipe Lite model
- ✅ Binary serialization  
- ✅ Threaded frame capture
- ✅ Frame skipping + interpolation
- ✅ UDP buffer tuning (in progress)

**Current expected latency:** 25-45ms

These remaining optimizations require more engineering effort but can push us into the 15-30ms range.

---

## Optimization 1: GPU Acceleration for MediaPipe

### Goal
Offload MediaPipe inference from CPU to GPU for 5-15ms improvement.

### Technical Details

**Current State:**
- MediaPipe runs on CPU via TensorFlow Lite
- Inference takes ~8-15ms on modern CPUs
- CPU load affects game performance

**Target State:**
- MediaPipe runs on GPU (CUDA/OpenCL)
- Inference potentially 3-8ms
- Reduced CPU load for Godot

### Implementation Options

**Option A: MediaPipe GPU Delegate (Recommended)**
```python
# Enable GPU delegate in MediaPipe
import mediapipe as mp

BaseOptions = mp.tasks.BaseOptions
PoseLandmarker = mp.tasks.vision.PoseLandmarker
PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions

options = PoseLandmarkerOptions(
    base_options=BaseOptions(
        model_asset_path='pose_landmarker.task',
        delegate=BaseOptions.Delegate.GPU  # GPU acceleration
    ),
    running_mode=VisionRunningMode.VIDEO
)
```

**Requirements:**
- NVIDIA GPU with CUDA support (GTX 900 series+)
- Or AMD GPU with ROCm support
- Additional Python dependencies: `mediapipe-gpu` or custom build

**Option B: ONNX Runtime with GPU**
- Convert MediaPipe model to ONNX format
- Use ONNX Runtime with CUDA execution provider
- More complex but potentially faster

### Challenges

1. **Hardware Dependency:** Only works on systems with compatible GPU
2. **Driver Requirements:** Need proper CUDA/cuDNN installation
3. **Fallback:** Must gracefully fall back to CPU if GPU unavailable
4. **Build Complexity:** May require custom MediaPipe build

### Implementation Plan

**Phase 1: Detection & Setup (2 hours)**
1. Add GPU detection in Python startup
2. Check for CUDA availability
3. Log GPU info if available
4. Add `--use-gpu` flag (default: auto-detect)

**Phase 2: GPU Integration (4 hours)**
1. Install mediapipe-gpu or build with GPU support
2. Modify MediaPipe initialization to use GPU delegate
3. Add graceful CPU fallback
4. Test inference timing with GPU vs CPU

**Phase 3: Optimization & Testing (2 hours)**
1. Tune GPU memory usage
2. Batch processing optimization
3. Compare latency: CPU vs GPU
4. Document hardware requirements

### Expected Results
- **GPU available:** 5-15ms improvement (3-8ms inference)
- **CPU only:** No regression (existing path)
- **CPU load:** Reduced, freeing cycles for Godot

### Files to Modify
- `python_mediapipe/main.py` - GPU detection and initialization
- `python_mediapipe/gpu_detector.py` - **NEW** - GPU capability detection
- `python_mediapipe/args.py` - Add `--use-gpu` argument
- `requirements.txt` - Add GPU dependencies

---

## Optimization 2: Kalman Filtering for Smooth Tracking

### Goal
Reduce jitter and noise in landmark positions without adding latency.

### Technical Details

**Current State:**
- Raw MediaPipe landmarks have jitter/noise
- Smoothing is disabled for low latency
- Visual "wobble" in tracking dots

**Target State:**
- Predictive filtering smooths noise
- Minimal added latency (< 2ms)
- Option to disable for testing

### Implementation

**One-Euro Filter** (Recommended for low latency):
```python
class OneEuroFilter:
    """Low-latency smoothing filter"""
    def __init__(self, min_cutoff=1.0, beta=0.0, d_cutoff=1.0):
        self.min_cutoff = min_cutoff
        self.beta = beta
        self.d_cutoff = d_cutoff
        self.x_prev = None
        self.dx_prev = None
        
    def filter(self, x, t):
        if self.x_prev is None:
            self.x_prev = x
            self.dx_prev = 0
            return x
        
        dx = (x - self.x_prev) / t
        dx_hat = self.low_pass(dx, self.dx_prev, self.alpha(self.d_cutoff, t))
        cutoff = self.min_cutoff + self.beta * abs(dx_hat)
        x_hat = self.low_pass(x, self.x_prev, self.alpha(cutoff, t))
        
        self.x_prev = x_hat
        self.dx_prev = dx_hat
        return x_hat
    
    def low_pass(self, x, x_prev, alpha):
        return alpha * x + (1 - alpha) * x_prev
    
    def alpha(self, cutoff, t):
        tau = 1.0 / (2 * np.pi * cutoff)
        return 1.0 / (1.0 + tau / t)
```

**Why One-Euro Filter:**
- Designed for motion tracking (used in VR/AR)
- Adaptive: smooths slow movements, follows fast movements
- Minimal latency penalty
- No phase delay (unlike moving average)

### Challenges

1. **Tuning:** Min-cutoff and beta parameters need tuning per use case
2. **Per-Landmark Filtering:** Need 33 separate filters (one per landmark)
3. **Coordinate Systems:** Must filter x, y, z separately

### Implementation Plan

**Phase 1: Filter Implementation (2 hours)**
1. Create `one_euro_filter.py` module
2. Implement filter for Vector3 landmarks
3. Unit tests with synthetic data
4. Performance benchmark

**Phase 2: Integration (2 hours)**
1. Add filter bank (33 landmarks × 3 coordinates)
2. Add `--use-kalman` flag (default: True)
3. Add tuning parameters to CLI
4. Log filter overhead

**Phase 3: Tuning & Testing (2 hours)**
1. Test with various movements (slow, fast, jerky)
2. Tune min_cutoff (start at 1.0, test 0.5-2.0)
3. Tune beta (start at 0.0, test 0.001-0.01)
4. A/B test: raw vs filtered visuals

### Expected Results
- **Jitter reduction:** 50-80% smoother visuals
- **Latency added:** < 2ms
- **Fast movements:** Still tracked accurately (adaptive filter)

### Files to Modify
- `python_mediapipe/one_euro_filter.py` - **NEW** - Filter implementation
- `python_mediapipe/main.py` - Integrate filtering
- `python_mediapipe/args.py` - Add filter parameters

---

## Optimization 3: Clock Synchronization for Accurate Network Latency

### Goal
Measure true network latency by synchronizing Python and Godot clocks.

### Technical Details

**Current State:**
- Latency measured as: receive_time - send_time
- Uses local system clocks
- Can show negative values if clocks differ
- Relative trends are useful, absolute values are not

**Target State:**
- Synchronized clocks using NTP or custom protocol
- Accurate network latency measurement
- Can detect network jitter vs processing delays

### Implementation

**Simple NTP Sync (Recommended):**
```python
import ntplib
from time import ctime

def sync_clock():
    """Sync with NTP server for accurate timing"""
    try:
        client = ntplib.NTPClient()
        response = client.request('pool.ntp.org', version=3)
        offset = response.offset  # Time difference from NTP
        return offset
    except:
        return 0  # Fallback to no offset
```

**Custom Protocol (More Accurate):**
```
1. Godot sends timestamp t0 to Python
2. Python receives at t1, sends back t1 + t2
3. Godot receives at t3
4. Calculate: round_trip = (t3 - t0) - (t2 - t1)
5. Clock offset = (t1 - t0) - round_trip / 2
```

### Challenges

1. **NTP Dependency:** Requires internet or local NTP server
2. **Precision:** NTP typically accurate to 1-10ms
3. **Fallback:** Must work without sync (current behavior)

### Implementation Plan

**Phase 1: Basic Sync (2 hours)**
1. Add `ntp_sync.py` module
2. Try NTP sync on startup
3. Log clock offset
4. Apply offset to all timing calculations

**Phase 2: Custom Protocol (Optional, 4 hours)**
1. Implement ping-pong timestamp protocol
2. Run multiple samples for accuracy
3. Calculate clock drift over time
4. Update offset periodically

**Phase 3: Latency Display Update (1 hour)**
1. Show "Network Latency" vs "Processing Latency"
2. Highlight if clocks are unsynchronized
3. Show sync status indicator

### Expected Results
- **Accurate measurements:** Know true network vs processing time
- **Debugging:** Easier to find bottlenecks
- **No performance impact:** Sync happens once at startup

### Files to Modify
- `python_mediapipe/ntp_sync.py` - **NEW** - Clock synchronization
- `python_mediapipe/main.py` - Apply clock offset
- `mediapipe_provider.gd` - Show sync status

---

## Optimization 4: Shared Memory (Localhost Alternative to UDP)

### Goal
Replace UDP loopback with shared memory for 5-15ms improvement.

### Technical Details

**Current State:**
- UDP over localhost (127.0.0.1)
- Network stack overhead: ~5-15ms
- Kernel copies data multiple times
- Packet-based (396 bytes per packet)

**Target State:**
- Shared memory (mmap) or POSIX queues
- Zero-copy data transfer
- ~0.1ms latency
- Same-machine only (perfect for our use case)

### Implementation Options

**Option A: POSIX Message Queues (Recommended)**
```python
import posix_ipc

# Python side (writer)
mq = posix_ipc.MessageQueue("/aerobeat_landmarks", 
                            posix_ipc.O_CREAT, 
                            max_message_size=4096)
mq.send(packet_bytes)
```

```gdscript
# Godot side (reader) via GDExtension or external library
# Would need a C++ GDExtension or use existing library
```

**Option B: Memory-Mapped Files**
```python
import mmap
import os

# Create shared memory buffer
shm = mmap.mmap(-1, 4096, tagname="aerobeat_shm")
shm.write(packet)
```

**Option C: Unix Domain Sockets**
- Still socket-based but no network stack
- Faster than UDP localhost
- Godot has native support

### Challenges

1. **GDExtension Required:** Godot doesn't natively support POSIX queues
2. **Platform Specific:** Linux only (macOS/Windows need different approaches)
3. **Complexity:** Much more complex than UDP
4. **Fallback:** Must keep UDP as backup

### Implementation Plan

**Phase 1: Research & Prototype (4 hours)**
1. Evaluate GDExtension vs external process
2. Prototype with Python + C++ bridge
3. Benchmark: UDP vs shared memory
4. Decide: worth the complexity?

**Phase 2: GDExtension Development (8 hours)**
1. Create `aerobeat_shm` GDExtension
2. Implement POSIX queue reader
3. Implement memory-mapped file reader
4. Add fallback to UDP if SHM fails

**Phase 3: Integration (2 hours)**
1. Modify Python to use SHM when available
2. Modify Godot to use SHM extension
3. Add `--use-shm` flag (default: auto)
4. Test fallback to UDP

### Expected Results
- **Shared memory available:** 5-15ms improvement
- **Fallback to UDP:** No regression
- **Complexity:** High (GDExtension maintenance)

### Files to Modify
- `aerobeat-shm-gdextension/` - **NEW** - GDExtension project
- `python_mediapipe/shm_writer.py` - **NEW** - Shared memory writer
- `python_mediapipe/main.py` - SHM/UDP selection
- `mediapipe_provider.gd` - SHM reader integration

---

## Priority & Sequencing

### Recommended Order

1. **UDP Tuning** (In Progress) - Easy win, 2-5ms
2. **GPU Acceleration** - Biggest potential gain, 5-15ms
3. **Kalman Filtering** - Quality improvement, minimal latency
4. **Clock Synchronization** - Debugging aid, no performance gain
5. **Shared Memory** - Last resort, high complexity

### Parallelization Options

**Track A (Performance):**
- GPU Acceleration
- Shared Memory

**Track B (Quality):**
- Kalman Filtering
- Clock Synchronization

---

## Success Metrics

**Current:** 25-45ms (after initial optimizations)  
**Target:** 15-30ms (after advanced optimizations)

**Per-Optimization Goals:**
- GPU: 5-15ms improvement (when GPU available)
- Shared Memory: 5-15ms improvement (if implemented)
- UDP Tuning: 2-5ms improvement
- Kalman: 0ms (quality only)
- Clock Sync: 0ms (debugging only)

---

## Risk Assessment

| Optimization | Risk | Mitigation |
|--------------|------|------------|
| GPU Accel. | Hardware dependent | Graceful CPU fallback |
| Kalman | Over-smoothing | Tune parameters, disable option |
| Clock Sync | NTP dependency | Local sync protocol fallback |
| Shared Mem. | Complexity | Keep UDP as primary, SHM optional |

---

## Next Steps

1. ✅ **UDP Tuning** - Implement (in progress)
2. 🔲 **Expert Review** - Have Godot expert review this doc
3. 🔲 **GPU Investigation** - Test MediaPipe GPU on Derrick's machine
4. 🔲 **Implement GPU** - If hardware supports it
5. 🔲 **Kalman Filter** - Implement One-Euro filter
6. 🔲 **Final Testing** - Measure complete optimization stack

---

*Planning document for advanced AeroBeat latency optimizations.*
