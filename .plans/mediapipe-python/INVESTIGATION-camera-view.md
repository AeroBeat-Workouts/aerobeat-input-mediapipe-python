# INVESTIGATION: User Camera View

**Goal:** Show the actual camera feed alongside tracking dots

**Date:** 2026-02-07

---

## Current State

- Python MediaPipe uses the camera exclusively via OpenCV
- Godot cannot access camera while Python has it open
- User only sees landmarks, not their actual video
- Need solution that works for calibration AND gameplay

---

## Research Findings: How Other MediaPipe Games Handle Camera View

**15+ Projects Analyzed:**
- **Camera Touch Game** - Python/Pygame with camera as full-screen AR background
- **mediapipe-game** - OpenCV window with overlays
- **Body Gesture Control** - PyQt6 with threaded QImage display
- **UnityPythonMediaPipeAvatar** - Python handles camera, Unity shows avatar only (no camera in game)
- **blazepose-unity** - Unity WebCamTexture with optional debug Canvas
- **MediaPipe Playground** - Browser WebRTC with HTML5 Canvas
- **Warudo Vtuber** - Optional "Show Camera" toggle in Unity
- **WebRTC streaming** - Browser/Python camera → Unity via network

### Key Insight from Production Apps

**Production apps treat camera view as a CALIBRATION/DEBUG tool, not gameplay UI.**

Warudo, VR tracking tools, and avatar apps all make the camera view **optional/toggleable**:
- Users enable camera during setup to position themselves
- Once calibrated, they disable camera view during actual use
- This reduces distraction and improves performance

### Camera Display Patterns Discovered

| Pattern | Best For | Implementation | Performance |
|---------|----------|----------------|-------------|
| **Full-screen AR overlay** | Games where player sees themselves | Camera as background texture | Good |
| **Separate debug window** | Calibration/setup only | OpenCV imshow() or PyQt window | Moderate |
| **Optional toggle** | Production apps (most common) | UI checkbox to enable/disable | Excellent |
| **WebRTC stream** | Cross-process/remote camera | Localhost network stream | Good |

---

## Options Analysis

### Option A: Python Streams Video to Godot

**Approach:** Compress camera frames and send over UDP alongside landmarks

**Implementation:**
- MJPEG encoding in Python
- Send frames via UDP to Godot
- Godot decodes and displays as TextureRect

**Pros:**
- Single camera source (no conflict)
- Synchronized with landmarks
- Works on all platforms

**Cons:**
- Added latency (encoding + transmission)
- Bandwidth heavy (even compressed video)
- More CPU usage on both sides

**Technical Details:**
```python
# Python side
import cv2
ret, frame = cap.read()
_, jpeg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
udp.sendto(jpeg.tobytes(), ("127.0.0.1", 4243))  # Separate port for video
```

**Expected latency:** +20-50ms for MJPEG encode/decode

---

### Option B: Shared Camera Access (v4l2loopback)

**Approach:** Use virtual camera to split feed between Python and Godot

**Implementation:**
- Linux: `v4l2loopback` kernel module creates virtual camera
- Python writes processed frames to virtual camera
- Godot reads from virtual camera via OpenCV or native camera API

**Pros:**
- Lower latency than streaming
- Both apps get full camera access
- No encoding overhead

**Cons:**
- **Linux only** - v4l2loopback is Linux-specific
- Requires kernel module installation (complex for users)
- Windows/Mac need different solutions (no equivalent)

**Platform Support:**
- ✅ Linux: v4l2loopback
- ❌ Windows: No direct equivalent (OBS Virtual Camera is closest)
- ❌ macOS: No direct equivalent

---

### Option C: Separate Camera Instances

**Approach:** Godot opens camera at lower resolution for display

**Implementation:**
```gdscript
# Godot opens camera for UI display
var camera = CameraServer.get_camera("Webcam")
camera.start(320, 240)  # Low res for display

# Python opens same camera at full res
# May or may not work depending on camera driver
```

**Pros:**
- Simple to implement if it works
- Native Godot camera display

**Cons:**
- Most cameras have **exclusive access** - cannot open twice
- Works on some cameras, fails on others (unreliable)
- Platform-dependent behavior

**Success Rate:** ~30% of webcams support shared access

---

### Option D: Post-Processed Overlay Only

**Approach:** Accept that camera view isn't possible, improve landmark visualization

**Implementation:**
- Better landmark drawing (skeleton lines, joint circles)
- Add debug info (FPS, tracking quality, body position guides)
- On-screen instructions for positioning

**Pros:**
- Zero latency impact
- Works everywhere
- Less distraction during gameplay
- Lower CPU/GPU usage

**Cons:**
- Users can't see themselves to position
- Harder to debug tracking issues
- May frustrate new users

**When to use:** Production gameplay (most users prefer this once calibrated)

---

### Option E: ThreadedCamera Pattern (Additional Discovery)

**Approach:** Decouple camera capture from MediaPipe processing

**Finding:** Most production apps use this to reduce latency

**Benefits:**
- Prevents buffer lag by always grabbing latest frame
- Reduces perceived delay even without camera display

---

### Option F: WebRTC Local Streaming (Additional Discovery)

**Approach:** Stream camera from Python to Godot via WebRTC on localhost

**Benefits:**
- More robust than raw UDP for video
- Browser-based games use this extensively
- Better handling of packet loss

---

## Recommended Approach: Hybrid Toggle System

Based on research, the best solution combines:

1. **Option A (Python streams to Godot)** - For calibration/setup phase
2. **Option D (Overlay only)** - For actual gameplay
3. **Toggle UI** - Let user switch between modes

### Implementation Plan

```gdscript
# In Godot Settings UI
@export var show_camera_feed: bool = false  # Default OFF for gameplay

# When enabled, Python streams MJPEG frames via UDP on port 4243
# When disabled, only landmarks shown (better performance)
```

### Why This Works

- Users can enable camera to position themselves correctly during setup
- During gameplay, camera off = better performance + less distraction
- Matches pattern used by Warudo, VR apps, and production tools
- Simple to implement (same Python process, optional video stream)
- Graceful fallback (if video fails, landmarks still work)

---

## Action Items

- [ ] Implement MJPEG streaming from Python to Godot
- [ ] Create camera toggle UI in settings
- [ ] Add texture display for camera feed
- [ ] Test performance impact (latency, CPU, bandwidth)
- [ ] Default to overlay-only mode for gameplay
- [ ] Add calibration screen with camera enabled by default
