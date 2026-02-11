# MJPEG Streaming Optimization Analysis

## Executive Summary

The MJPEG streaming pipeline has **multiple sources of latency** across Python (encoder) and Godot (decoder) sides. The estimated **current end-to-end latency is 50-100ms**, with potential to reduce to **20-40ms** with optimizations below.

## Current Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Camera Capture │────▶│  MJPEG Encoder   │────▶│  HTTP Server    │
│   (Python)      │     │  (OpenCV JPEG)   │     │  (TCP Port 4243)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                            │
                                                            ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Texture Display│◀────│  JPEG Decoder    │◀────│  TCP Receiver   │
│   (Godot)       │     │  (Godot Image)   │     │  (BG Thread)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

---

## Identified Latency Sources

### 1. Python Side - MJPEG Streamer (camera_streamer.py)

| Issue | Current | Impact | Priority |
|-------|---------|--------|----------|
| **Fixed 33ms Delay** | `threading.Event().wait(0.033)` forces 30 FPS max | ~16ms avg latency | 🔴 HIGH |
| **JPEG Quality** | Hardcoded at 70% | Encoding time + bandwidth | 🔴 HIGH |
| **No Frame Dropping** | Always sends latest frame, no timestamp | Stale frames in buffer | 🟡 MEDIUM |
| **HTTP Overhead** | Full headers per frame | ~200-500 bytes overhead | 🟢 LOW |
| **TCP Nagle** | No TCP_NODELAY set | 40ms buffering | 🔴 HIGH |

**Current estimated Python latency: 20-40ms**

### 2. Godot Side - Camera View (camera_view.gd)

| Issue | Current | Impact | Priority |
|-------|---------|--------|----------|
| **Fixed 33ms Update** | `update_interval_ms = 33.0` | Limits to 30 FPS | 🔴 HIGH |
| **Thread Sleep** | `OS.delay_msec(5)` | 5ms fixed delay | 🟡 MEDIUM |
| **Buffer Growth** | No explicit frame dropping | Memory, stale frames | 🔴 HIGH |
| **Texture Recreation** | New `ImageTexture` every frame | GC pressure, stutter | 🟡 MEDIUM |
| **Parse Per Frame** | ~150 lines of parsing code per frame | CPU + latency | 🟡 MEDIUM |

**Current estimated Godot latency: 20-40ms**

### 3. Sync Issues (Critical)

| Issue | Impact |
|-------|--------|
| **No Shared Timestamp** | MJPEG and UDP landmarks use different clocks |
| **Different Threads** | MJPEG streams from capture thread, landmarks from processing thread |
| **Frame Skip Divergence** | MJPEG streams all frames, landmarks skip N frames |

---

## Optimization Recommendations

### 🔴 HIGH PRIORITY (Expected 30-50% latency reduction)

#### 1. Remove Fixed Frame Rate Delay (Python)

**File:** `python_mediapipe/camera_streamer.py`

**Current:**
```python
# Small delay to control frame rate (~30 FPS max)
threading.Event().wait(0.033)
```

**Optimized:**
```python
# Minimize latency - let camera dictate pace, drop frames if encoding is slow
# Only minimal yield to prevent CPU starvation
threading.Event().wait(0.001)  # 1ms yield instead of 33ms
```

**Expected gain:** ~16ms average latency reduction

---

#### 2. Reduce JPEG Quality (Python)

**File:** `python_mediapipe/camera_streamer.py`

**Current:**
```python
jpeg_quality = 70
```

**Optimized:**
```python
jpeg_quality = 50  # Lower = faster encoding + smaller payload
# Optionally make configurable: 40 for low-latency, 70 for quality
```

**Expected gain:** 5-10ms encoding time, ~30% bandwidth reduction

---

#### 3. Enable TCP_NODELAY (Python)

**File:** `python_mediapipe/camera_streamer.py`

**Add to MJPEGHTTPHandler.do_GET:**
```python
def _serve_mjpeg_stream(self):
    self.send_response(200)
    # ... headers ...
    self.end_headers()
    
    # Disable Nagle's algorithm for low latency
    if hasattr(self.request, 'setsockopt'):
        self.request.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
```

**Expected gain:** Up to 40ms latency reduction (eliminates TCP buffering)

---

#### 4. Remove Fixed Update Interval (Godot)

**File:** `src/camera_view.gd`

**Current:**
```gdscript
@export var update_interval_ms: float = 33.0

func _process(delta: float) -> void:
    if not _is_streaming:
        return
    _update_timer += delta * 1000.0
    if _update_timer >= update_interval_ms:
        _update_timer = 0.0
        _update_texture()
```

**Optimized - Stream-Driven Updates:**
```gdscript
# Remove update_interval_ms entirely - update when new frame arrives

func _stream_loop() -> void:
    # ... existing code ...
    while _thread_running and _tcp:
        # ... parsing ...
        if jpeg_data.size() > 0 and _parse_mjpeg_frame():
            # Update immediately on new frame (thread-safe)
            call_deferred("_update_texture_now")
        
        # Minimal sleep to prevent busy-waiting
        OS.delay_msec(1)  # Reduced from 5ms

func _update_texture_now() -> void:
    # Called from main thread via call_deferred
    _frame_mutex.lock()
    var frame := _current_frame
    _frame_mutex.unlock()
    if frame and frame.get_width() > 0:
        self.texture = ImageTexture.create_from_image(frame)
```

**Expected gain:** ~16ms average latency reduction

---

#### 5. Add Buffer Size Limit with Frame Dropping (Godot)

**File:** `src/camera_view.gd`

**Add to _stream_loop:**
```gdscript
const MAX_BUFFER_SIZE := 65536  # 64KB max buffer
const MAX_BUFFERED_FRAMES := 3    # Drop frames if too many buffered

func _stream_loop() -> void:
    var frames_in_buffer := 0
    
    while _thread_running and _tcp:
        # ... read data ...
        if _mjpeg_buffer.size() > MAX_BUFFER_SIZE:
            # Buffer growing too large - drop to latest frame
            print("[CameraView] Buffer overflow, dropping frames")
            _mjpeg_buffer.clear()
            header_parsed = false
            continue
```

**Expected gain:** Prevents bursty latency spikes (can be 100ms+ in worst case)

---

### 🟡 MEDIUM PRIORITY (Expected 10-20% latency reduction)

#### 6. Optimize JPEG Decoding in Godot

**File:** `src/camera_view.gd`

**Current:**
```gdscript
var img := Image.new()
var err := img.load_jpg_from_buffer(jpeg_data)
if err == OK:
    _frame_mutex.lock()
    _current_frame = img
    _frame_mutex.unlock()
```

**Optimized - Reuse Image object:**
```gdscript
var _decode_img: Image  # Pre-allocated

func _ready() -> void:
    # ... existing code ...
    _decode_img = Image.new()

func _parse_mjpeg_frame() -> bool:
    # ... extract jpeg_data ...
    
    # Reuse image object instead of creating new one
    var err := _decode_img.load_jpg_from_buffer(jpeg_data)
    if err == OK:
        _frame_mutex.lock()
        _current_frame = _decode_img.duplicate()  # Copy to avoid reuse issues
        _frame_mutex.unlock()
```

**Expected gain:** 2-5ms per frame

---

#### 7. Add Frame Timestamp Synchronization

**File:** `python_mediapipe/camera_streamer.py`

**Track frame timestamps in MJPEG stream:**
```python
class MJPEGStreamer:
    def __init__(self, ...):
        # ... existing ...
        self.frame_timestamp = 0.0
        
    def update_frame(self, frame, timestamp=None):
        # ... existing encoding ...
        
        # Add timestamp to frame buffer (first 8 bytes)
        import struct
        timestamp = timestamp or time.time()
        timestamp_bytes = struct.pack('!d', timestamp)
        
        with self._lock:
            MJPEGHTTPHandler.frame_buffer = timestamp_bytes + jpeg_buffer.tobytes()
            MJPEGHTTPHandler.frame_timestamp = timestamp
```

**File:** `src/camera_view.gd`

**Parse timestamps in Godot:**
```gdscript
func _parse_mjpeg_frame() -> bool:
    # ... after extracting jpeg_data ...
    
    # Extract timestamp from first 8 bytes
    if jpeg_data.size() >= 8:
        var timestamp_bytes := jpeg_data.slice(0, 8)
        var jpeg_actual := jpeg_data.slice(8)
        var timestamp := timestamp_bytes.decode_double(0)
        
        # Calculate latency
        var now := Time.get_unix_time_from_system()
        var latency_ms := (now - timestamp) * 1000.0
        
        # Use jpeg_actual for decoding
        jpeg_data = jpeg_actual
```

**Expected gain:** Enables sync with tracking data, no direct latency reduction

---

#### 8. Reduce Thread Sleep (Godot)

**File:** `src/camera_view.gd`

**Current:**
```gdscript
OS.delay_msec(5)
```

**Optimized:**
```gdscript
OS.delay_msec(1)  # 1ms sleep reduces latency by 4ms
```

**Expected gain:** 4ms per frame

---

## Specific Code Changes

### Summary of Changed Lines

**camera_streamer.py:**
- Line 114: Change `wait(0.033)` to `wait(0.001)` 
- Line 28: Change `jpeg_quality = 70` to `jpeg_quality = 50`
- Add TCP_NODELAY in `_serve_mjpeg_stream`

**camera_view.gd:**
- Remove `_update_timer` logic entirely (lines 63-67)
- Change `OS.delay_msec(5)` to `OS.delay_msec(1)` (line ~280)
- Add buffer overflow protection (new lines ~155)
- Add frame timestamp extraction (new lines in `_parse_mjpeg_frame`)

---

## Expected Performance Improvements

| Metric | Current | Optimized | Gain |
|--------|---------|-----------|------|
| **End-to-end Latency** | 50-100ms | 20-40ms | 50-60% |
| **Frame Rate Cap** | 30 FPS | 60+ FPS | 100% |
| **Encoding Time** | 10-15ms | 5-8ms | 40% |
| **Bandwidth Usage** | Baseline | -30% | - |
| **Perceived Sync** | Slight lag | Near 1:1 | Improve |

---

## Trade-offs

| Optimization | Latency | Quality | CPU | Complexity |
|-------------|---------|---------|-----|------------|
| Remove 33ms delay | ✅ Better | Same | Higher | Low |
| JPEG 50% | ✅ Better | Slight loss | Same | Low |
| TCP_NODELAY | ✅ Better | Same | Same | Low |
| Buffer limits | ✅ Better | Same | Same | Low |
| Frame dropping | ✅ Better | Frame skip | Lower | Medium |
| Timestamp sync | No change | Better sync | Same | Medium |

---

## Testing Recommendations

1. **Latency Measurement:** Add timestamp logging to measure actual end-to-end latency
2. **Frame Drop Monitoring:** Log when frames are dropped due to buffer overflow
3. **Quality Comparison:** Compare player experience at quality 50 vs 70
4. **Network Profiling:** Use Wireshark to verify TCP_NODELAY effect

---

## Quick Wins (Apply First)

For immediate results with minimal risk:

1. **Change sleep in camera_streamer.py:** `0.033` → `0.001`
2. **Change sleep in camera_view.gd:** `5` → `1`
3. **Add TCP_NODELAY** to Python HTTP handler
4. **Reduce JPEG quality** to 50 for testing

These 4 changes alone should reduce latency by **30-50ms**.
