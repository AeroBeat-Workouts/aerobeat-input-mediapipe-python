# Web Research Update: MediaPipe & Godot Optimization (2025-2026)

**Research Date:** February 2026  
**Focus:** Updates since 2024-2025 research for AeroBeat project

---

## Executive Summary

The 2025-2026 period has brought significant developments in both MediaPipe and Godot ecosystems. Key findings include:

1. **MediaPipe GPU/CPU Performance Paradox Still Valid**: The issue where GPU on Linux/Mac shows no performance benefit (or is slower) than CPU remains unresolved
2. **API Deprecation Warning**: Legacy `mp.solutions` API is being phased out in favor of Tasks API
3. **Godot 4.6 Released**: Major focus on workflow improvements, 2D renderer optimizations, and networking stability
4. **New Smoothing Research**: Emerging alternatives to One-Euro filter, including GNN-based approaches and event-driven tracking

---

## 1. MediaPipe Updates (2025-2026)

### 1.1 GPU vs CPU Performance - CONFIRMED ISSUE

**Status:** Issue persists as of July 2025

GitHub Issue #6041 (July 15, 2025) confirms the GPU/CPU performance paradox:
- **macOS 15.5, MediaPipe 0.10.21**: GPU and CPU both achieve ~27 FPS with identical performance
- **Expected**: GPU should be faster
- **Actual**: No performance increase with GPU delegate enabled

```python
# Example code from the issue showing identical FPS:
# GPU Delegate: 27.14 FPS
# CPU (XNNPACK): 27.14 FPS
```

**Implication for AeroBeat:** Continue using CPU inference on Linux - the GPU delegate doesn't provide benefits and may add overhead.

### 1.2 API Deprecation - CRITICAL FOR AEROBAT

**Status:** Active migration happening as of late 2025

MediaPipe is transitioning from the legacy `mp.solutions` API to the **Tasks API**:

| Legacy API (Deprecated) | New Tasks API |
|------------------------|---------------|
| `mp.solutions.pose` | `mp.tasks.vision.PoseLandmarker` |
| `mp.solutions.hands` | `mp.tasks.vision.HandLandmarker` |
| `mp.solutions.holistic` | Separate task-based solutions |

**Breaking Change (December 2025):**
- MediaPipe 0.10.31+ no longer contains `mediapipe.solutions` module
- Migration to Tasks API is mandatory

**AeroBeat Action Required:**
```python
# OLD (will break with 0.10.31+)
import mediapipe as mp
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(...)

# NEW (Tasks API)
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.core import BaseOptions

options = vision.PoseLandmarkerOptions(
    base_options=BaseOptions(model_asset_path=model_path),
    running_mode=vision.RunningMode.LIVE_STREAM,
    result_callback=callback
)
landmarker = vision.PoseLandmarker.create_from_options(options)
```

### 1.3 PyPI Release Delays

**Issue #6017 (June 2025):**
- MediaPipe stopped publishing to PyPI after v0.10.22
- Community reports difficulty getting latest versions
- Workaround: Install from GitHub or use pinned versions

**Recommendation:** Pin MediaPipe to `0.10.21` or `0.10.22` until migration path is clear.

### 1.4 Model Complexity Levels (Still Valid)

As confirmed in 2025 research:
- **Model 0 (Lite)**: Fastest, lower accuracy, good for older hardware
- **Model 1 (Full)**: Balanced - **Recommended for AeroBeat**
- **Model 2 (Heavy)**: Maximum precision, CPU-intensive

```python
# Recommended configuration based on 2025 findings
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,  # Full model
    smooth_landmarks=True,  # Temporal filtering
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5  # 0.6-0.7 for aggressive movements
)
```

### 1.5 Critical Performance Tips from 2025

From Medium article (December 2025):
1. **Color Space**: Always convert BGR → RGB
   ```python
   image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
   ```
2. **Buffer Management**: OpenCV's VideoCapture maintains internal frame buffer
   - If processing < camera framerate, buffer causes lag
   - Solution: Use separate thread for capture
3. **Writeable Flag**: Set `image_rgb.flags.writeable = False` before processing to prevent copying

---

## 2. Godot 4.6 Release Analysis (January 2026)

### 2.1 Godot 4.6 Status

**Released:** January 2026  
**Theme:** "All about your flow" - Polish, QoL, and performance

### 2.2 Key Performance Improvements

#### 2D Renderer Optimizations
- Major performance improvements in 2D rendering pipeline
- Reduced unnecessary redraws in TileMapLayer
- **Relevance:** Directly benefits AeroBeat's 2D UI and visualization

#### Networking Enhancements
- MultiplayerAPI 2.0 continues to mature
- Improved stability and reduced latency
- Built-in NAT traversal support
- Enhanced security features

#### Platform-Specific Optimizations
- **macOS/Wayland**: Non-interactive window resizing by default
- **Windows**: Direct3D 12 enabled by default (was Vulkan)
- **Android**: Dedicated Gradle build app

### 2.3 Godot 4.6 Features for AeroBeat

| Feature | Benefit for AeroBeat |
|---------|---------------------|
| 2D Renderer Optimization | Better UI performance for beat visualization |
| MultiplayerAPI Stability | More reliable WebSocket/socket communication |
| ObjectDB Profiler | Debug memory/reference issues in Python bridge |
| LibGodot (Engine as Library) | Potential for embedding Godot in Python app |

### 2.4 Multiplayer Best Practices (2025)

From GodotAwesome Networking Guide (November 2025):

```gdscript
# Server Authority Pattern - Always validate on server
@rpc("any_peer", "reliable")
func request_pickup_item(item_id: String, player_pos: Vector3):
    if not multiplayer.is_server():
        return
    var sender_id = multiplayer.get_remote_sender_id()
    # Validate player position before accepting action
    if player_pos.distance_to(item.global_position) < 2.0:
        confirm_pickup.rpc(item_id, sender_id)
```

**RPC Types for AeroBeat:**
| RPC Type | Use Case |
|----------|----------|
| `reliable` | Beat events, calibration data |
| `unreliable` | Position updates (if needed) |
| `unreliable_ordered` | Animation states |

---

## 3. Pose Estimation Smoothing & Latency (2025-2026)

### 3.1 One-Euro Filter Status

**Status:** Still the industry standard for real-time smoothing

No major breakthrough replacing One-Euro in 2025-2026. However, several research directions emerged:

### 3.2 Emerging Alternatives (Research Stage)

#### GraphEnet (October 2025)
- **Type**: Graph Neural Network for event cameras
- **Performance**: 250 Hz update rate (2.5× faster than previous SOTA)
- **Accuracy**: 74% PCK@0.4 on Human 3.6M
- **Status**: Research paper, not production-ready
- **Relevance**: Shows direction of low-latency pose estimation

#### Kalman Filtering Still Relevant
From 2025 research papers:
- Kalman filters remain effective for predicting motion
- Often combined with pose estimation for latency reduction
- RGBTrack (June 2025): Uses Kalman filter + XMem for 22 FPS on RTX 3090

### 3.3 Latency Reduction Techniques (2025)

From Cell Reports Methods (February 2025):
1. **Separate Processes**: Run NN inference and 3D rendering in different processes
2. **Event-Driven Architecture**: Process only changed pixels (event cameras)
3. **Prediction + Estimation Blend**: Combine temporal prediction with current estimation

**For AeroBeat:**
```python
# Current architecture already follows best practices:
# 1. MediaPipe runs in separate thread
# 2. UDP socket for non-blocking communication
# 3. One-Euro filter for smoothing

# Potential improvement: Add motion prediction
# Predict next pose based on velocity/acceleration
```

---

## 4. Updated Recommendations for AeroBeat

### 4.1 Immediate Actions (February 2026)

1. **Pin MediaPipe Version**
   ```bash
   pip install mediapipe==0.10.21  # Last stable with mp.solutions
   ```

2. **Plan API Migration**
   - Research Tasks API documentation
   - Test migration in development branch
   - Timeline: Before MediaPipe 0.10.31+ requirement

3. **Update Godot to 4.6**
   - 2D renderer improvements benefit visualization
   - Networking stability improvements

### 4.2 Performance Optimizations

| Current | Recommended | Impact |
|---------|-------------|--------|
| Model complexity: 1 | Keep at 1 | Baseline |
| min_tracking_confidence: 0.5 | Try 0.6-0.7 for stability | Better tracking |
| Use CPU delegate | Continue CPU on Linux | No GPU benefit |
| smooth_landmarks: True | Keep True | Essential for jitter |

### 4.3 Architecture Recommendations

```
Current AeroBeat Stack (Verified 2026):
├── MediaPipe 0.10.21 (CPU inference)
├── One-Euro Filter (smoothing)
├── Python UDP Bridge
├── Godot 4.6 (recommended upgrade)
└── WebSocket/Socket communication
```

**No changes needed** to core architecture based on 2025-2026 research.

---

## 5. Comparison: Previous vs Current Findings

| Finding | 2024-2025 Status | 2025-2026 Status |
|---------|-----------------|------------------|
| MediaPipe GPU slower on Linux | ✅ Confirmed | ✅ Still valid |
| One-Euro filter recommended | ✅ Recommended | ✅ Still best practice |
| N-euro Predictor alternative | 🆕 Found in 2024 | ❌ No adoption in 2025 |
| MediaPipe Tasks API | 🆕 Emerging | ⚠️ Now mandatory |
| Godot 4.3/4.4 networking | ✅ Good | ✅ Improved in 4.6 |
| Model complexity levels | ✅ 0=Lite, 1=Full, 2=Heavy | ✅ Unchanged |

---

## 6. Sources & References

### MediaPipe
1. GitHub Issue #6041 - GPU/CPU performance parity (July 2025)
2. GitHub Issue #6192 - mp.solutions deprecation (December 2025)
3. Medium: "Real-Time Body Tracking in Your Browser" (December 2025)
4. Roboflow: "Best Pose Estimation Models" (November 2025)
5. LearnOpenCV: "MediaPipe Ultimate Guide" (November 2025)

### Godot
1. Jettelly: "Godot 4.6 First Look" (November 2025)
2. 80.lv: "Godot 4.6 Nears Feature Freeze" (December 2025)
3. GodotAwesome: "Multiplayer Networking Guide 2025" (November 2025)
4. Reddit: r/godot 4.6 Release Discussion (January 2026)

### Pose Estimation Research
1. arXiv: GraphEnet - Event-driven HPE with GNN (October 2025)
2. ScienceDirect: Real-time HPE Systematic Review (August 2025)
3. Cell Reports Methods: Multi-subject 3D pose tracking (February 2025)

---

## 7. Next Research Cycle (Mid-2026)

**Watch for:**
1. MediaPipe Tasks API stabilization
2. Godot 4.7/5.0 announcements
3. Transformer-based pose estimation maturity (DETRPose)
4. Event camera availability for consumer hardware

---

*Document compiled: February 8, 2026*
*For: AeroBeat Motion-Controlled Rhythm Game Project*
