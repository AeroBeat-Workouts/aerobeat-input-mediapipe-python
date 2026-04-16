# AeroBeat MediaPipe Input Module - Implementation Plan

**Document Version:** 1.0  
**Date:** 2026-02-06  
**Author:** Cookie (OpenClaw Agent)  
**Repository:** `aerobeat-input-mediapipe-python`

---

## 1. Executive Summary

### What This Repository Is

The `aerobeat-input-mediapipe-python` repository is an **Input Driver** in the AeroBeat ecosystem that enables full-body pose tracking via MediaPipe. It operates as a **sidecar process** that bridges computer vision hardware (webcams) to the AeroBeat Core contracts.

**Key Purpose:** Transform raw video input into normalized game input coordinates that can drive gameplay mechanics.

### Architecture Position

| Tier | Repository Type | License | Dependencies |
|------|-----------------|---------|--------------|
| **5 - Input** | Hardware Driver | MPL 2.0 | `aerobeat-core` (Required), Vendor SDKs (Allowed) |

### How It Works (High-Level)

```
Webcam → Python MediaPipe Process → UDP Socket → GDScript Strategy → AeroBeat Core
```

1. **Python Sidecar** (`python_mediapipe/main.py`): Captures video, runs MediaPipe inference, sends JSON-encoded landmark data via UDP
2. **GDScript Strategy** (`src/strategies/strategy_mediapipe.gd`): Listens on UDP, parses data, normalizes coordinates
3. **Core Integration**: Implements `AeroInputProvider` interface for hot-swappable input abstraction

---

## 2. Current State Analysis

### Existing Implementation ✅

| Component | Status | Notes |
|-----------|--------|-------|
| Python MediaPipe Script | ✅ Functional | Uses OpenCV + MediaPipe, sends 33 landmarks via UDP on port 4242 |
| GDScript UDP Listener | ✅ Basic | Receives packets, parses JSON, emits `pose_updated` signal |
| Testbed Setup | ✅ Present | `setup_dev.py` clones core + GUT, creates symlinks |
| Plugin Manifest | ✅ Present | `plugin.cfg` configured correctly |
| Unit Tests | ⚠️ Minimal | Only sanity checks, needs proper test coverage |

### Current Data Flow

```python
# Python sends:
{
    "timestamp": 1234567890.123,
    "landmarks": [
        {"id": 0, "x": 0.54, "y": 0.21, "z": -0.1, "v": 0.99},  # 33 landmarks
        ...
    ]
}
```

```gdscript
# GDScript receives and emits raw landmarks
signal pose_updated(landmarks: Array)  # Array of 33 landmark dictionaries
```

### Identified Gaps ❌

1. **No Interface Implementation**: Does not yet implement `AeroInputProvider` from `aerobeat-core`
2. **No Normalization**: Returns raw MediaPipe coordinates (0.0-1.0) but doesn't map to game viewport
3. **No Hand/Body Separation**: MediaPipe Pose tracks 33 body points, but game needs LeftHand, RightHand, Head
4. **Missing Configuration**: No runtime configuration for:
   - Camera selection
   - UDP port configuration
   - Detection confidence thresholds
   - Mirror/flip axes
5. **Error Handling**: Minimal error recovery (what if Python process dies?)
6. **Process Management**: Python sidecar must be launched/managed by the strategy
7. **Test Coverage**: Tests are placeholder only

---

## 3. Target Architecture Alignment

### Input Provider Contract

Per `aerobeat-docs/docs/architecture/input.md`, the `AeroInputProvider` interface must expose:

```gdscript
# Required interface methods
func get_left_hand_transform() -> Transform2D  # or Vector2 for 2D games
func get_right_hand_transform() -> Transform2D
func get_head_transform() -> Transform2D

# All values normalized to 0.0 - 1.0 viewport coordinates
```

### Strategy Pattern Requirements

| Requirement | Implementation Approach |
|-------------|------------------------|
| Hot-swappable | Strategy must be interchangeable with `StrategyKeyboard`, `StrategyMouse`, etc. |
| No direct hardware access | All hardware interaction through Python sidecar |
| Normalized output | Convert MediaPipe landmarks to viewport coordinates |
| Graceful degradation | If tracking lost, maintain last known position or return null |

### Normalization Flow

Per the docs, the proper flow is:

```
Raw Data → Adaptation → Delivery
```

1. **Raw Data**: MediaPipe landmark `{x: 0.54, y: 0.21, z: -0.1, v: 0.99}`
2. **Adaptation**: 
   - Flip Y-axis (OpenCV uses inverted Y)
   - Apply dead zones
   - Smoothing/filtering (optional)
3. **Delivery**: Return `Vector2(x, y)` in 0.0-1.0 viewport space

---

## 4. Implementation Plan

### Phase 1: Core Interface Implementation

**Goal**: Implement `AeroInputProvider` interface properly

#### 4.1.1 Create `src/providers/mediapipe_provider.gd`

```gdscript
class_name MediaPipeProvider
extends Node
## Implements AeroInputProvider interface for MediaPipe body tracking

# Required by AeroInputProvider interface
func get_left_hand_transform() -> Vector2:
    # Map from MediaPipe landmarks:
    # Left wrist = landmark 15
    # Left hand index = landmark 19
    pass

func get_right_hand_transform() -> Vector2:
    # Right wrist = landmark 16
    # Right hand index = landmark 20
    pass

func get_head_transform() -> Vector2:
    # Nose = landmark 0
    pass

func is_tracking() -> bool:
    # Return true if receiving valid data within last 500ms
    pass
```

#### 4.1.2 Refactor `strategy_mediapipe.gd`

- Extract UDP listener into a separate `MediaPipeClient` class
- Add landmark-to-body-part mapping
- Implement coordinate normalization with Y-flip
- Add tracking timeout detection

### Phase 2: Python Sidecar Management

**Goal**: Launch and manage the Python process from GDScript

#### 4.2.1 Create `src/process/mediapipe_process.gd`

```gdscript
class_name MediaPipeProcess
extends Node

## Manages the Python sidecar process

signal process_started()
signal process_stopped(exit_code: int)
signal process_error(error: String)

func start(camera_id: int = 0, port: int = 4242) -> bool:
    # Launch python_mediapipe/main.py as subprocess
    # Handle Python environment detection (venv, system, bundled)
    pass

func stop() -> void:
    # Gracefully terminate Python process
    pass

func is_running() -> bool:
    pass
```

#### 4.2.2 Update Python Script

- Add CLI argument parsing (camera ID, port, confidence thresholds)
- Add graceful shutdown handling (SIGTERM)
- Add heartbeat/keepalive mechanism
- Bundle `requirements.txt` dependencies

### Phase 3: Configuration & Runtime

**Goal**: Make the driver configurable at runtime

#### 4.3.1 Create `src/config/mediapipe_config.gd`

```gdscript
class_name MediaPipeConfig
extends Resource

@export var camera_id: int = 0
@export var udp_port: int = 4242
@export var detection_confidence: float = 0.5
@export var tracking_confidence: float = 0.5
@export var model_complexity: int = 1  # 0=fast, 1=balanced, 2=accurate
@export var flip_horizontal: bool = true  # Mirror the camera
@export var smoothing_factor: float = 0.3  # 0.0=no smoothing, 1.0=max
```

#### 4.3.2 Create Settings UI (for Testbed)

- Camera selection dropdown
- Confidence threshold sliders
- Calibration helper (show camera feed with skeleton overlay)

### Phase 4: Robustness & Error Handling

**Goal**: Production-ready error handling

| Scenario | Handling |
|----------|----------|
| Python not installed | Show user-friendly error dialog with install instructions |
| Camera in use | Retry with next available camera index |
| UDP port in use | Auto-increment port and retry |
| Tracking lost >2s | Emit `tracking_lost` signal, return last known positions |
| Python crash | Auto-restart with exponential backoff (max 3 retries) |
| Invalid landmark data | Validate visibility score > 0.5, skip low-confidence detections |

### Phase 5: Testing

**Goal**: Comprehensive test coverage

#### 4.5.1 Unit Tests (`test/`)

```gdscript
# test_mediapipe_provider.gd
func test_get_left_hand_returns_vector2()
func test_get_right_hand_returns_vector2()
func test_get_head_returns_vector2()
func test_is_tracking_returns_false_when_no_data()
func test_is_tracking_returns_true_when_recent_data()
func test_coordinate_normalization_flips_y_axis()
func test_landmark_mapping_correct_indices()
```

#### 4.5.2 Integration Tests

```gdscript
# test_mediapipe_integration.gd
func test_python_process_starts_and_stops()
func test_udp_communication_roundtrip()
func test_full_pipeline_receives_landmarks()
```

#### 4.5.3 Mock for Testing

Create `test/mocks/mock_mediapipe_server.py` to simulate Python sidecar for CI/CD.

---

## 5. Integration Points

### With `aerobeat-core`

```gdscript
# In Core, the InputManager selects strategies:
var provider: AeroInputProvider

func set_input_strategy(strategy: AeroInputProvider):
    provider = strategy

func _process(delta):
    if provider:
        var left_pos = provider.get_left_hand_transform()
        var right_pos = provider.get_right_hand_transform()
        # Use positions for gameplay...
```

### With Assembly

The Assembly repo (e.g., `aerobeat-assembly-community`) will:

1. Include this repo as a git submodule in `addons/`
2. Register `StrategyMediaPipe` in the InputManager
3. Provide UI for strategy selection (Settings → Input → Camera)

### With Features

Feature repos (e.g., `aerobeat-feature-boxing`) consume input via the abstract interface:

```gdscript
# In Boxing gameplay, no knowledge of MediaPipe:
var punch_position = InputManager.provider.get_left_hand_transform()
```

---

## 6. Technical Recommendations

### 6.1 Landmark Mapping Reference

MediaPipe Pose 33 landmarks → Game inputs:

| Game Input | MediaPipe Landmark ID | Body Part |
|------------|----------------------|-----------|
| `Head` | 0 | Nose |
| `LeftHand` | 15 or 19 | Left wrist or index |
| `RightHand` | 16 or 20 | Right wrist or index |
| `LeftElbow` | 13 | Left elbow (for reach detection) |
| `RightElbow` | 14 | Right elbow (for reach detection) |

### 6.2 Coordinate Transformation

```gdscript
# MediaPipe → Viewport
func normalize_landmark(landmark: Dictionary) -> Vector2:
    var x = landmark.x  # 0.0 (left) to 1.0 (right)
    var y = 1.0 - landmark.y  # Flip Y: 0.0 (top) to 1.0 (bottom)
    
    if flip_horizontal:
        x = 1.0 - x
    
    return Vector2(x, y)
```

### 6.3 Performance Considerations

- **UDP Buffer Size**: Process all pending packets in `_process()`, use only the most recent
- **Smoothing**: Apply exponential moving average to reduce jitter
- **Frame Rate**: Python runs at camera FPS (30-60), Godot runs independently
- **Threading**: UDP listening is single-threaded; consider moving to worker thread if jitter occurs

### 6.4 Security Considerations

- UDP is localhost-only (127.0.0.1) - no network exposure
- Validate all incoming JSON to prevent crashes
- Never execute Python code from external sources

---

## 7. Directory Structure (Target)

```
aerobeat-input-mediapipe-python/
├── src/
│   ├── providers/
│   │   └── mediapipe_provider.gd       # Implements AeroInputProvider
│   ├── strategies/
│   │   └── strategy_mediapipe.gd       # UDP listener + landmark parsing
│   ├── process/
│   │   └── mediapipe_process.gd        # Python sidecar management
│   ├── config/
│   │   └── mediapipe_config.gd         # Runtime configuration resource
│   └── utils/
│       └── landmark_mapper.gd          # Landmark ID → body part mapping
├── python_mediapipe/
│   ├── main.py                         # Entry point
│   ├── requirements.txt                # Dependencies
│   └── args.py                         # CLI argument parsing
├── test/
│   ├── unit/
│   │   ├── test_mediapipe_provider.gd
│   │   ├── test_strategy_mediapipe.gd
│   │   └── test_landmark_mapper.gd
│   ├── integration/
│   │   └── test_mediapipe_integration.gd
│   └── mocks/
│       └── mock_mediapipe_server.py
├── .testbed/                           # Development environment
│   ├── addons/
│   │   ├── aerobeat-core/              # Cloned by setup_dev.py
│   │   └── gut/                        # Cloned by setup_dev.py
│   ├── project.godot
│   └── ...
├── plugin.cfg                          # Godot plugin manifest
├── setup_dev.py                        # Dev environment setup
├── README.md
├── LICENSE.md
└── CLAUDE.md                           # Agent instructions
```

---

## 8. Success Criteria

✅ **MVP (Phase 1-2)**
- [ ] `MediaPipeProvider` implements `AeroInputProvider` interface
- [ ] Returns normalized hand/head positions in viewport coordinates
- [ ] Python process auto-launches when strategy activated
- [ ] Basic error handling (process crash detection)
- [ ] 80% test coverage for provider logic

✅ **Complete (Phase 3-5)**
- [ ] Runtime configuration system
- [ ] Calibration/camera preview UI
- [ ] Robust error recovery (auto-restart, fallback cameras)
- [ ] 100% test coverage
- [ ] Integration tested with `aerobeat-core`

---

## 9. Next Steps

1. **Review this plan** with the team
2. **Create sub-tasks** in project tracker for each phase
3. **Set up development environment**: Run `python setup_dev.py`
4. **Begin Phase 1**: Implement `MediaPipeProvider` class
5. **Test integration** with `aerobeat-core` interface

---

## 10. References

- [AeroBeat Input Architecture](../../../aerobeat-docs/docs/architecture/input.md)
- [AeroBeat Topology](../../../aerobeat-docs/docs/architecture/topology.md)
- [MediaPipe Pose Documentation](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker)
- [Godot UDP Documentation](https://docs.godotengine.org/en/stable/classes/class_packetpeerudp.html)

---

## 11. Addendum: Revised Requirements (2026-02-06)

Based on review feedback, the following critical updates have been identified:

### 11.1 aerobeat-core Interface Definition

**Status**: `aerobeat-core` is currently a skeleton repository. The `AeroInputProvider` interface must be **defined in core first** before implementation.

**Required Core Additions** (`aerobeat-core/src/interfaces/input_provider.gd`):

```gdscript
class_name AeroInputProvider
extends Node
## Abstract interface for all input strategies
## All input drivers must implement this interface

enum TrackingMode {
    MODE_2D,      # 2D viewport coordinates (x, y)
    MODE_3D       # 3D world coordinates (x, y, z)
}

enum BodyTrackFlags {
    NONE = 0,
    HEAD = 1,
    LEFT_HAND = 2,
    RIGHT_HAND = 4,
    LEFT_FOOT = 8,    # NEW: Toggleable feet tracking
    RIGHT_FOOT = 16,  # NEW: Toggleable feet tracking
    ALL = 31
}

# Core interface methods - must be implemented by all providers
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    ## Returns Vector2 for MODE_2D, Vector3 for MODE_3D
    push_error("AeroInputProvider: get_left_hand_position() must be overridden")
    return null

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    ## Returns Vector2 for MODE_2D, Vector3 for MODE_3D
    push_error("AeroInputProvider: get_right_hand_position() must be overridden")
    return null

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    ## Returns Vector2 for MODE_2D, Vector3 for MODE_3D
    push_error("AeroInputProvider: get_head_position() must be overridden")
    return null

# NEW: Feet tracking (toggleable)
func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    ## Returns Vector2 for MODE_2D, Vector3 for MODE_3D
    ## Only tracked if BodyTrackFlags.LEFT_FOOT is enabled
    push_error("AeroInputProvider: get_left_foot_position() must be overridden")
    return null

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    ## Returns Vector2 for MODE_2D, Vector3 for MODE_3D
    ## Only tracked if BodyTrackFlags.RIGHT_FOOT is enabled
    push_error("AeroInputProvider: get_right_foot_position() must be overridden")
    return null

# Configuration
func set_tracking_mode(mode: TrackingMode) -> void:
    push_error("AeroInputProvider: set_tracking_mode() must be overridden")

func set_body_track_flags(flags: int) -> void:
    ## Bitmask of BodyTrackFlags to enable/disable specific tracking
    push_error("AeroInputProvider: set_body_track_flags() must be overridden")

# State
func is_tracking() -> bool:
    push_error("AeroInputProvider: is_tracking() must be overridden")
    return false

func get_tracking_confidence(body_part: int) -> float:
    ## Returns 0.0-1.0 confidence score for requested body part
    push_error("AeroInputProvider: get_tracking_confidence() must be overridden")
    return 0.0
```

### 11.2 2D vs 3D Support

**Requirement**: MediaPipe system must support both 2D and 3D positioning.

| Mode | Use Case | Data Source |
|------|----------|-------------|
| **2D** | Standard webcams, gesture-based gameplay | MediaPipe `x`, `y` coordinates |
| **3D** | Advanced webcams, depth sensors, collider-based gameplay | MediaPipe `x`, `y`, `z` coordinates |

**Implementation Notes**:
- Boxing example: 2D = positioning/gesture detection, 3D = collider-based hit detection with depth
- MediaPipe Pose provides `z` (relative depth) but it's not absolute distance
- For true 3D, may need additional depth camera (Intel RealSense, etc.)

**Updated Python Payload**:
```python
# Include z-coordinate for 3D support
payload = {
    "timestamp": time.time(),
    "mode": "3d",  # or "2d"
    "landmarks": [
        {
            "id": 0,
            "x": 0.54,   # 0.0-1.0 normalized
            "y": 0.21,   # 0.0-1.0 normalized
            "z": -0.1,   # Relative depth (negative = closer to camera)
            "v": 0.99    # Visibility confidence
        },
        ...
    ]
}
```

### 11.3 Toggleable Body Part Tracking

**Goal**: Never track more than needed to reduce CPU/GPU workload.

**Configuration**:
```gdscript
# MediaPipeConfig additions
@export var track_head: bool = true
@export var track_left_hand: bool = true
@export var track_right_hand: bool = true
@export var track_left_foot: bool = false   # Default off for most games
@export var track_right_foot: bool = false  # Default off for most games

# Computed property
func get_track_flags() -> int:
    var flags = 0
    if track_head: flags |= AeroInputProvider.BodyTrackFlags.HEAD
    if track_left_hand: flags |= AeroInputProvider.BodyTrackFlags.LEFT_HAND
    if track_right_hand: flags |= AeroInputProvider.BodyTrackFlags.RIGHT_HAND
    if track_left_foot: flags |= AeroInputProvider.BodyTrackFlags.LEFT_FOOT
    if track_right_foot: flags |= AeroInputProvider.BodyTrackFlags.RIGHT_FOOT
    return flags
```

**Performance Optimization**:
- When feet not tracked, Python sidecar can skip processing lower body landmarks
- Reduces MediaPipe inference load
- Reduces UDP bandwidth

### 11.4 Updated Landmark Mapping

Including feet tracking:

| Body Part | MediaPipe ID | Notes |
|-----------|--------------|-------|
| Head | 0 | Nose |
| Left Hand | 15 or 19 | Wrist (15) or Index (19) |
| Right Hand | 16 or 20 | Wrist (16) or Index (20) |
| **Left Foot** | **27** | **Left ankle** |
| **Right Foot** | **28** | **Right ankle** |

### 11.5 aerobeat-assembly-community Integration

**Integration Flow**:
```
aerobeat-assembly-community/
├── addons/
│   ├── aerobeat-core/              # Core interfaces (git submodule)
│   ├── aerobeat-input-mediapipe/   # This repo (git submodule)
│   └── aerobeat-feature-boxing/    # Feature using input
```

**Assembly Setup Requirements**:
1. Clone `aerobeat-core` into `addons/`
2. Clone `aerobeat-input-mediapipe` into `addons/`
3. Enable both plugins in Project Settings
4. InputManager in Assembly selects active strategy

### 11.6 Revised Implementation Phases

**Phase 0: Core Interface** (NEW - prerequisite)
- [ ] Create `AeroInputProvider` interface in `aerobeat-core`
- [ ] Define `TrackingMode` and `BodyTrackFlags` enums
- [ ] Tag `aerobeat-core` with version bump

**Phase 1: Basic Implementation** (Updated)
- [ ] Implement `MediaPipeProvider` extending `AeroInputProvider`
- [ ] Support 2D mode only initially
- [ ] Support head + hands tracking only

**Phase 2: 3D Support** (NEW)
- [ ] Add 3D coordinate support (`Vector3` return type)
- [ ] Update Python to include z-coordinate
- [ ] Test with depth-capable cameras

**Phase 3: Feet Tracking** (NEW)
- [ ] Add feet landmark mapping
- [ ] Implement toggleable tracking
- [ ] Optimize Python to skip untracked landmarks

---

*This plan was generated by Cookie 🍪🐱‍💻 as part of the AeroBeat orchestration workflow.*
*Updated with feedback on core interfaces, 2D/3D support, and toggleable tracking.*
