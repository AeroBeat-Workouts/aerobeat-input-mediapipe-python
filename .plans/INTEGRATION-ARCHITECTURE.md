# AeroBeat Input System Integration Architecture

**Document Date:** February 11, 2026  
**Project:** AeroBeat Multi-Input Integration  
**Godot Version:** 4.x  
**Status:** Definitive Source of Truth

---

## Overview

This document describes the comprehensive integration architecture for the AeroBeat input system—a unified abstraction layer that enables multiple input types (MediaPipe Python, MediaPipe Native Mobile, Joy-Con, GamePad, Keyboard, Mouse, XR/6DOF) to integrate seamlessly into the AeroBeat Core and Community Edition repositories.

The architecture follows a **symlink-based dependency model** (not Git submodules) to share code across repositories while maintaining standalone development capabilities for individual input drivers.

---

## Repository Structure

### Core Repositories

```
~/Documents/GitHub/AeroBeat/
├── aerobeat-core/                          # Shared contracts & interfaces (single source of truth)
│   └── src/
│       └── input/
│           └── input_provider.gd           # AeroInputProvider base class
│
├── aerobeat-assembly-community/            # Community Edition (all inputs)
│   └── addons/
│       ├── aerobeat-core/ → symlink to ../../aerobeat-core/
│       ├── aerobeat-input-mediapipe-python/
│       ├── aerobeat-input-mediapipe-native/
│       ├── aerobeat-input-joycon-hid/
│       ├── aerobeat-input-gamepad/
│       ├── aerobeat-input-keyboard/
│       ├── aerobeat-input-mouse/
│       └── aerobeat-input-xr/
│
└── aerobeat-assembly-*/                    # Other Editions
    └── addons/
        └── [...]
```

### Input Addon Repositories (Individual)

| Input Type | Repository Path | Target User |
|------------|-----------------|-------------|
| MediaPipe Python | `aerobeat-input-mediapipe-python/` | PC/Mac/Linux with camera |
| MediaPipe Native | `aerobeat-input-mediapipe-native/` | iOS/Android |
| Joy-Con | `aerobeat-input-joycon-hid/` | Switch controller users |
| GamePad | `aerobeat-input-gamepad/` | Console controller users |
| Keyboard | `aerobeat-input-keyboard/` | Accessibility/low-barrier |
| Mouse | `aerobeat-input-mouse/` | Quick play sessions |
| XR/6DOF | `aerobeat-input-xr/` | VR headset users |

### Key Design Decisions

1. **Standalone Repositories**: Each input driver is a standalone repository, NOT embedded within `assembly-community`. This allows independent versioning and development.

2. **Symlink to Core**: Both input drivers and assembly-community symlink to `aerobeat-core` to share the base contract (`AeroInputProvider`).

3. **No Git Submodules**: Symlinks are used instead of submodules to avoid complexity and allow flexible local development workflows.

---

## Base Class Contract

The input provider contract is defined in:

**Path**: `aerobeat-core/src/input/input_provider.gd` (root-level, not nested)

```gdscript
class_name AeroInputProvider
extends Node

# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================

enum TrackingMode {
	MODE_2D,  # Screen-space coordinates (0.0 to 1.0)
	MODE_3D   # World-space coordinates (Meters)
}

enum Capability {
	SPATIAL_TRANSFORM,      # Supports tracking_updated / 6DOF
	GESTURE_RECOGNITION,    # Supports signals like punch_left, slice_detected
	LOWER_BODY,             # Supports foot_position / knee_strike
	HAPTICS,                # Supports trigger_haptic
	VELOCITY                # Supports get_velocity polling
}

# ============================================================================
# COMMANDS (Call these to control the provider)
# ============================================================================

## Initializes and starts the tracking backend.
## @param settings_json: Configuration for the specific driver (e.g. camera ID, XR passthrough toggles).
## Returns: bool indicating success/failure
func start(settings_json: String) -> bool:
	return false

## Shuts down tracking and releases hardware resources.
func stop() -> void:
	pass

## Returns true if the hardware is currently initialized and sending data.
func is_tracking() -> bool:
	return false

## Returns whether this specific provider supports a feature (e.g. if MediaPipe supports Knee Strikes).
func has_capability(capability: Capability) -> bool:
	return false

## Trigger haptics for feedback.
## @param side: 0=Left, 1=Right
## @param intensity: 0.0 to 1.0
## @param duration_ms: duration in milliseconds
func trigger_haptic(side: int, intensity: float, duration_ms: int) -> void:
	pass

# ============================================================================
# SIGNALS: LIFECYCLE CALLBACKS (Connect to these signals)
# ============================================================================

signal started      # Emitted when tracking successfully starts
signal stopped      # Emitted when tracking stops (normal shutdown)
signal failed(error: String)  # Emitted on error with description

# ============================================================================
# SIGNALS: DATA (Continuous / 6DOF)
# ============================================================================

## Emitted every physics frame with the latest spatial data.
## Useful for collision-based gameplay (Supernatural VR & BeatSaber style).
signal tracking_updated(
	head_transform: Transform3D,
	left_hand_transform: Transform3D,
	right_hand_transform: Transform3D,
	left_foot_transform: Transform3D,
	right_foot_transform: Transform3D
)

# ============================================================================
# SIGNALS: GESTURES (Discrete / Event-based Boxing Callbacks)
# ============================================================================

# Common - All Gameplay Modes
signal stance_orthodox              # Standard boxing stance (left foot forward)
signal stance_southpaw              # Southpaw stance (right foot forward)
signal location_changed(zone: StringName)  # "left", "center", "right"
signal height_changed(type: StringName)    # "stand", "squat"

# Flow Gameplay
## @param direction: "left", "right", "up", "down"
## @param angle: The Euler angle of the controller/hand during the slice
signal slice_detected(direction: StringName, angle: float)

# Boxing Gameplay - Offensive
signal punch_left(power: float)     # Left hand jab/straight
signal punch_right(power: float)    # Right hand jab/straight
signal uppercut_left(power: float)  # Left uppercut
signal uppercut_right(power: float) # Right uppercut
signal cross_left(power: float)     # Left cross (power punch from orthodox)
signal cross_right(power: float)    # Right cross (power punch from orthodox)

# Boxing Gameplay - Defensive
signal block_start                  # Guard up position
signal block_end                    # Guard down
signal weave_left                   # Head weave to left
signal weave_right                  # Head weave to right
signal duck_weave_left              # Combined duck + weave left
signal duck_weave_right             # Combined duck + weave right

# Special Moves
signal knee_strike_left(power: float)   # Left knee strike (Muay Thai/clinch)
signal knee_strike_right(power: float)  # Right knee strike
signal leg_lift_left
signal leg_lift_right
signal run_start                    # Begin running in place
signal run_end                      # End running in place

# ============================================================================
# STATE QUERIES (Check current state / Polling)
# ============================================================================

# Position getters (2D viewport or 3D world coordinates)
func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3
func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3
func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3
func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3

# Velocity getters (Meters/Sec). Critical for "hit" detection in XR.
func get_head_velocity() -> Vector3
func get_left_hand_velocity() -> Vector3
func get_right_hand_velocity() -> Vector3
func get_left_foot_velocity() -> Vector3
func get_right_foot_velocity() -> Vector3

# Rotation getters (6DOF rotation of the body part)
func get_head_rotation() -> Quaternion
func get_left_hand_rotation() -> Quaternion
func get_right_hand_rotation() -> Quaternion
func get_left_foot_rotation() -> Quaternion
func get_right_foot_rotation() -> Quaternion

# Tracking confidence
## @param body_part: "head", "left_hand", "right_hand", "left_foot", "right_foot"
func get_tracking_confidence(body_part: StringName) -> float

# ============================================================================
# SETTERS / CONFIG
# ============================================================================

func set_tracking_mode(mode: TrackingMode) -> void

## Bitmask for enabling specific tracking points (Head, Hands, Feet).
func set_body_track_flags(flags: int) -> void
```

### Signal Reference Table

| Signal | Parameters | Description |
|--------|------------|-------------|
| `started` | - | Tracking successfully started |
| `stopped` | - | Tracking stopped (normal shutdown) |
| `failed` | `error: String` | Error occurred with description |
| `tracking_updated` | 5× `Transform3D` | Continuous 6DOF data for all tracked points |
| `stance_orthodox` | - | Standard boxing stance (left foot forward) |
| `stance_southpaw` | - | Southpaw stance (right foot forward) |
| `location_changed` | `zone: StringName` | Player position: "left", "center", "right" |
| `height_changed` | `type: StringName` | Player height: "stand", "squat" |
| `slice_detected` | `direction: StringName, angle: float` | Slice gesture with direction and angle |
| `punch_left` | `power: float` | Left hand punch with power (0-1) |
| `punch_right` | `power: float` | Right hand punch with power (0-1) |
| `uppercut_left` | `power: float` | Left uppercut with power (0-1) |
| `uppercut_right` | `power: float` | Right uppercut with power (0-1) |
| `cross_left` | `power: float` | Left cross with power (0-1) |
| `cross_right` | `power: float` | Right cross with power (0-1) |
| `hook_left` | `power: float` | Left hook with power (0-1) |
| `hook_right` | `power: float` | Right hook with power (0-1) |
| `block_start` | - | Guard up position started |
| `block_end` | - | Guard down position ended |
| `weave_left` | - | Head weave to left detected |
| `weave_right` | - | Head weave to right detected |
| `duck_weave_left` | - | Combined duck and weave left |
| `duck_weave_right` | - | Combined duck and weave right |
| `knee_strike_left` | `power: float` | Left knee strike with power (0-1) |
| `knee_strike_right` | `power: float` | Right knee strike with power (0-1) |
| `leg_lift_detected` | `side: StringName` | Leg lift: "left" or "right" |
| `run_start` | - | Running in place started |
| `run_end` | - | Running in place ended |

### Method Reference Table

| Method | Returns | Description |
|--------|---------|-------------|
| `start(settings_json: String)` | `bool` | Initialize and start tracking |
| `stop()` | `void` | Stop tracking and release resources |
| `is_tracking()` | `bool` | Check if currently tracking |
| `has_capability(capability: Capability)` | `bool` | Check if provider supports a feature |
| `trigger_haptic(side, intensity, duration_ms)` | `void` | Trigger haptic feedback |
| `get_head_position(mode)` | `Vector3` | Get head position (2D or 3D) |
| `get_left_hand_position(mode)` | `Vector3` | Get left hand position (2D or 3D) |
| `get_right_hand_position(mode)` | `Vector3` | Get right hand position (2D or 3D) |
| `get_left_foot_position(mode)` | `Vector3` | Get left foot position (2D or 3D) |
| `get_right_foot_position(mode)` | `Vector3` | Get right foot position (2D or 3D) |
| `get_head_velocity()` | `Vector3` | Get head velocity (meters/sec) |
| `get_left_hand_velocity()` | `Vector3` | Get left hand velocity (meters/sec) |
| `get_right_hand_velocity()` | `Vector3` | Get right hand velocity (meters/sec) |
| `get_left_foot_velocity()` | `Vector3` | Get left foot velocity (meters/sec) |
| `get_right_foot_velocity()` | `Vector3` | Get right foot velocity (meters/sec) |
| `get_head_rotation()` | `Quaternion` | Get head rotation (6DOF) |
| `get_left_hand_rotation()` | `Quaternion` | Get left hand rotation (6DOF) |
| `get_right_hand_rotation()` | `Quaternion` | Get right hand rotation (6DOF) |
| `get_left_foot_rotation()` | `Quaternion` | Get left foot rotation (6DOF) |
| `get_right_foot_rotation()` | `Quaternion` | Get right foot rotation (6DOF) |
| `get_tracking_confidence(body_part)` | `float` | Get tracking confidence (0-1) |
| `set_tracking_mode(mode)` | `void` | Set tracking mode (2D or 3D) |
| `set_body_track_flags(flags)` | `void` | Set tracking point bitmask |

### Capability Enum Reference

| Capability | Description |
|------------|-------------|
| `SPATIAL_TRANSFORM` | Supports `tracking_updated` signal / 6DOF tracking |
| `GESTURE_RECOGNITION` | Supports gesture signals like `punch_left`, `slice_detected` |
| `LOWER_BODY` | Supports foot position and knee strike signals |
| `HAPTICS` | Supports `trigger_haptic()` method |
| `VELOCITY` | Supports velocity polling methods |

### TODO: Inheritance Update

**Current State**: `MediaPipeProvider` currently extends `Node` directly.

**Target State**: `MediaPipeProvider` SHOULD extend `AeroInputProvider` to properly implement the contract.

```gdscript
# Current (in src/providers/mediapipe_provider.gd)
class_name MediaPipeProvider
extends Node  # TODO: Change to extends AeroInputProvider

# Target
class_name MediaPipeProvider
extends AeroInputProvider
```

This inheritance ensures:
- Type safety across the AeroBeat ecosystem
- Consistent interface for all input drivers
- Proper signal emission (`started`, `stopped`, `failed`)

---

## Plugin Entry Point

### Configuration

**File**: `plugin.cfg` (root level of each input addon)

```ini
[plugin]
name="AeroBeat Input Driver For [Input Type]"
description="Hardware driver for AeroBeat's [Input Type] support."
author="AeroBeat Workouts"
version="0.0.1"
script="input_provider.gd"  # Root-level entry point
```

### Main Provider File Structure

Each input driver follows this structure (shown with MediaPipe Python as reference):

```
aerobeat-input-[name]/
├── plugin.cfg                          # Godot plugin configuration
├── input_provider.gd                   # Main entry point (root-level)
├── .gdignore                           # Godot ignore file
├── README.md                           # Project documentation
├── LICENSE.md                          # License file
├── .gitignore                          # Git ignore
├── .github/                            # GitHub workflows
│   └── workflows/
│
├── python_mediapipe/                   # Python sidecar (MediaPipe-specific)
│   ├── main.py                         # Main entry point
│   ├── args.py                         # Argument parsing
│   ├── one_euro_filter.py              # Smoothing filter for landmarks
│   ├── camera_streamer.py              # MJPEG streaming server
│   ├── metrics_collector.py            # Latency metrics tracking
│   ├── mock_server.py                  # Mock server for testing
│   ├── test_filter.py                  # Filter unit tests
│   ├── test_runner.py                  # Test runner
│   ├── roi_tracker.py                  # Region of interest tracking
│   └── platform_utils.py               # Platform detection utilities
│
├── src/                                # Godot implementation source
│   ├── providers/
│   │   └── [input_type]_provider.gd    # Provider implementation
│   ├── server/                         # Network/communication layer (if needed)
│   │   └── mediapipe_server.gd         # UDP server for receiving landmarks
│   ├── strategies/                     # Strategy pattern implementations
│   │   └── strategy_mediapipe.gd       # Input processing strategy
│   ├── config/                         # Configuration classes
│   │   └── mediapipe_config.gd         # Provider configuration
│   ├── process/                        # External process management
│   │   └── mediapipe_process.gd        # Python process launcher
│   ├── mediapipe_input_with_camera.gd  # Main camera input scene
│   ├── autostart_manager.gd            # Auto-start functionality
│   └── camera_view.gd                  # Camera view handling
│
├── tests/                              # Test suite
│   ├── unit/                           # Unit tests directory
│   ├── mocks/                          # Mock implementations
│   ├── mediapipe_provider_test.gd      # Provider integration tests
│   ├── test_mediapipe_logic.gd         # Logic unit tests
│   └── landmark_drawer.gd              # Debug landmark visualization
│
└── .testbed/                           # Test environment (.gdignore prevents this from appearing in assembly project that imports the input repos)
    ├── project.godot                   # Test Godot project file
    ├── addons/                         # Addons directory (symlinks)
    ├── python_mediapipe → symlink      # Symlink to python_mediapipe/
    ├── src → symlink                   # Symlink to src/
    ├── test/                           # Test resources
    ├── videos/                         # Test video files
    ├── venv/                           # Python virtual environment
    └── *.task                          # MediaPipe model files
```

---

## Input Data Flow

The system uses a **two-layer architecture** for processing input data:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              LAYER 1: RAW INPUT                         │
│  Input Hardware → Driver → Normalized Position/Rotation Data            │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                           LAYER 2: GESTURE LAYER                        │
│  Position Data → Gesture Interpretation → Boxing Gesture Callbacks      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Example: MediaPipe Python Implementation (Layer 1)

Raw pose data flows from MediaPipe through the following path:

1. **Python Sidecar** (`python_mediapipe/main.py`)
   - Captures video from camera or file
   - Runs MediaPipe pose detection
   - Applies One-Euro filtering
   - Serializes to binary or JSON
   - Sends via UDP

2. **Godot Server** (`src/server/mediapipe_server.gd`)
   - UDP socket listener
   - Deserializes binary/JSON packets
   - Emits `landmarks_received` signal

3. **MediaPipe Provider** (`src/providers/mediapipe_provider.gd`)
   - Receives landmarks
   - Converts to position data (2D/3D)
   - Manages tracking state
   - Provides position getters

### Planned Implementation (Layer 2)

Gesture interpretation will be implemented as a separate layer that translates position data into boxing gestures:

```gdscript
# Conceptual future API
var gesture_interpreter = GestureInterpreter.new()
gesture_interpreter.pose_data = provider.get_all_poses()

# Gesture interpreter emits boxing callbacks based on movement patterns
if gesture_interpreter.detect_punch_left():
    punch_left.emit(calculated_power)
```

This separation allows:
- Input-agnostic gesture detection
- Swappable gesture recognition algorithms
- Testing without actual hardware
- Multiple input types to generate the same boxing gestures

---

## Input Manager (Central Coordinator)

The InputManager coordinates multiple input providers in the assembly editions:

```gdscript
# Conceptual InputManager (assembly-community)
class_name InputManager
extends Node

# Registered providers
var _providers: Dictionary = {}  # provider_id -> AeroInputProvider
var _active_provider: AeroInputProvider = null

# Configuration
@export var auto_switch_inputs: bool = true
@export var input_priority: Array[String] = [
    "xr_6dof",           # Highest priority
    "mediapipe_python",
    "mediapipe_native",
    "joycon_hid",
    "gamepad",
    "mouse",
    "keyboard"           # Lowest priority
]

# Signals
signal provider_registered(provider: AeroInputProvider)
signal provider_unregistered(provider_id: String)
signal active_provider_changed(provider: AeroInputProvider)

# All boxing gesture signals proxied from active provider
signal punch_left(power: float)
signal punch_right(power: float)
signal block_start
signal block_end
# ... etc

func register_provider(provider: AeroInputProvider) -> bool:
    # Provider must implement start(settings_json) and emit callbacks
    var test_settings = JSON.stringify({"test": true})
    if provider.start(test_settings):
        provider.stop()
        _providers[provider.get_instance_id()] = provider
        _connect_provider_signals(provider)
        provider_registered.emit(provider)
        if auto_switch_inputs:
            _evaluate_provider_priority()
        return true
    return false

func _connect_provider_signals(provider: AeroInputProvider) -> void:
    # Proxy all boxing callbacks through InputManager
    provider.punch_left.connect(func(p): punch_left.emit(p))
    provider.punch_right.connect(func(p): punch_right.emit(p))
    provider.block_start.connect(func(): block_start.emit())
    provider.block_end.connect(func(): block_end.emit())
    # ... etc for all gesture callbacks

func set_active_provider(provider: AeroInputProvider) -> bool:
    if _active_provider:
        _active_provider.stop()
    _active_provider = provider
    var settings = JSON.stringify(_get_settings_for_provider(provider))
    provider.start(settings)
    active_provider_changed.emit(provider)
    return true
```

---

## Cross-Platform Considerations

### Platform Matrix

| Input Type | Windows | macOS | Linux | Android | iOS | Quest |
|------------|---------|-------|-------|---------|-----|-------|
| MediaPipe Python | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| MediaPipe Native | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| Joy-Con | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ |
| GamePad | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| Keyboard | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| Mouse | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| XR/6DOF | ✅ (SteamVR) | ⚠️ | ✅ (SteamVR) | ❌ | ❌ | ✅ |

### Platform-Specific Loading

```gdscript
# Platform-specific addon loading
func _ready():
    match OS.get_name():
        "Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
            # Desktop: Load MediaPipe Python
            _load_addon("aerobeat-input-mediapipe-python")
            _load_addon("aerobeat-input-joycon-hid")
            _load_addon("aerobeat-input-gamepad")
            _load_addon("aerobeat-input-keyboard")
            _load_addon("aerobeat-input-mouse")
            _load_addon("aerobeat-input-xr")
        
        "Android":
            # Android: Load MediaPipe Native
            _load_addon("aerobeat-input-mediapipe-native")
            _load_addon("aerobeat-input-gamepad")
        
        "iOS":
            # iOS: Load MediaPipe Native
            _load_addon("aerobeat-input-mediapipe-native")
```

---

## Working Features (MediaPipe Python Reference Implementation)

### Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| **Multi-pose Support** | ✅ Ready (needs testing) | Architecture supports multiple simultaneous poses; `get_num_poses()`, `get_all_poses()`, `get_player_*()` methods available |
| **One-Euro Filtering** | ✅ Implemented | Adaptive smoothing in Python sidecar reduces jitter while maintaining responsiveness |
| **MJPEG Camera Streaming** | ✅ Working | Camera streaming to Godot for preview/debugging; UTF-8 parsing fixed, coordinate alignment fixed, horizontal flip added |
| **Latency Metrics** | ✅ Implemented | Full timing breakdown: capture → detection → serialization → network → processing |
| **Dual Protocol** | ✅ Working | Binary and JSON serialization both implemented; Godot server parses binary protocol correctly |
| **Tracking State** | ✅ Working | `is_tracking()` now properly returns true/false based on landmark receipt timing |
| **Thread Cleanup** | ✅ Fixed | Thread lifecycle management fixed to prevent "destroyed without completion" warnings |
| **Process Cleanup** | 🔄 In Progress | Python sidecar process cleanup on scene exit; camera light sometimes stays on (see Known Issues) |

### Protocol Details

**Binary Protocol** (Default):
- Custom binary format for landmarks
- Lower bandwidth and CPU usage
- Used in production

**JSON Protocol**:
- Human-readable for debugging
- Higher overhead
- Enabled via `--json` flag

---

## Communication Protocol (MediaPipe Python Example)

### UDP Packet Structure

**Binary Format**:
```
[Header: 4 bytes magic "MPPB"]
[Count: 2 bytes num landmarks]
[Landmarks: N * (1 byte id + 4 bytes x + 4 bytes y + 4 bytes z + 4 bytes visibility)]
```

**JSON Format**:
```json
{
  "poses": [
    {
      "pose_id": 0,
      "landmarks": [
        {"id": 0, "x": 0.5, "y": 0.5, "z": 0.0, "v": 0.99}
      ]
    }
  ]
}
```

---

## Open Design Questions

### XR 6DOF Collision-Based System

**Question**: Should the XR 6DOF input provider use a collision-based system for detecting punches and blocks instead of gesture interpretation?

**Context**: Traditional XR games often use hand/controller collisions directly with hitboxes rather than interpreting gestures. This provides:
- More natural "feel" for VR users
- Direct physics feedback
- No gesture recognition latency

**Considerations**:
- Collision-based would bypass the unified gesture callback system
- Hybrid approach: collisions trigger gesture callbacks?
- Different gameplay balance for XR vs camera-based inputs

**Status**: Open for discussion. Current architecture supports both approaches since the boxing callbacks are input-agnostic.

---

## Testing Strategy

### Unit Tests (Per Addon)

```gdscript
# tests/unit/test_input_provider.gd
extends GutTest

var _provider: AeroInputProvider

func before_each():
    _provider = preload("../../input_provider.gd").new()

func test_start_stop():
    var settings = JSON.stringify({"port": 9999})
    
    # Test start
    var started = false
    _provider.started.connect(func(): started = true)
    var result = _provider.start(settings)
    
    if not result:
        pass_test("Provider not available, skipping")
        return
    
    assert_true(started, "Should emit started callback")
    assert_true(_provider.is_tracking(), "Should report tracking")
    
    # Test stop
    var stopped = false
    _provider.stopped.connect(func(): stopped = true)
    _provider.stop()
    
    assert_true(stopped, "Should emit stopped callback")
    assert_false(_provider.is_tracking(), "Should report not tracking")

func test_punch_callback():
    watch_signals(_provider)
    
    # Simulate punch detection (implementation-specific)
    _provider._test_inject_punch_left(0.8)
    
    assert_signal_emitted_with_parameters(
        _provider, "punch_left", [0.8])
```

### Integration Tests (Input Manager)

```gdscript
# tests/test_input_manager.gd
extends GutTest

var _manager: InputManager

func before_each():
    _manager = preload("res://aerobeat-core/src/input/input_manager.gd").new()
    add_child(_manager)

func test_provider_registration():
    var mock_provider = MockInputProvider.new()
    
    watch_signals(_manager)
    var result = _manager.register_provider(mock_provider)
    
    assert_true(result)
    assert_signal_emitted(_manager, "provider_registered")

func test_auto_priority_switching():
    var camera_provider = MockCameraProvider.new()
    var keyboard_provider = MockKeyboardProvider.new()
    
    _manager.register_provider(keyboard_provider)
    _manager.register_provider(camera_provider)
    
    # Camera should take priority
    assert_eq(_manager._active_provider, camera_provider)
```

---

## Performance Considerations

### Input Polling Rates

| Input Type | Recommended Rate | Reason |
|------------|------------------|--------|
| MediaPipe Python | 30 FPS | Camera + AI processing |
| MediaPipe Native | 30-60 FPS | Hardware acceleration |
| Joy-Con | 60-90 FPS | IMU data rate |
| GamePad | 60 FPS | Standard gamepad rate |
| Keyboard | 60 FPS | Standard input rate |
| Mouse | 60-125 FPS | High precision tracking |
| XR/6DOF | 72-144 Hz | Match headset refresh |

### Threading Model

```gdscript
# For high-rate inputs, use separate threads
func _ready():
    # MediaPipe runs on background thread
    _python_server.set_threading_mode(true)
    
    # Joy-Con runs on main thread (low latency)
    _joycon_driver.set_threading_mode(false)
    
    # XR runs on main thread (synchronized with render)
    _xr_interface.set_threading_mode(false)
```

---

## Development Guide

### Adding a New Input Provider

To add a new input provider following this architecture:

1. **Create Repository**: `aerobeat-input-[name]/`

2. **Symlink Core**: Create symlink to `aerobeat-core` in `addons/`

3. **Create Entry Point**: `input_provider.gd` (root level)
   ```gdscript
   extends "res://addons/aerobeat-core/src/input/input_provider.gd"
   class_name MyInputProvider
   ```

4. **Implement Required Methods**:
   - `start(settings_json: String) -> bool`
   - `stop() -> void`
   - `is_tracking() -> bool`
   - Position getters (as applicable)

5. **Emit Callbacks**:
   - Lifecycle: `started`, `stopped`, `failed`
   - Boxing gestures as supported by hardware

6. **Create `plugin.cfg`** with `script="input_provider.gd"`

7. **Add Tests** in `tests/` directory

### Using the Mock Server

For testing without hardware:

```bash
python python_mediapipe/mock_server.py
```

---

## Future Enhancements & TODOs

### High Priority

- [ ] **Complete MediaPipeProvider inheritance**: Change `extends Node` to `extends AeroInputProvider`
- [ ] **Implement gesture interpretation layer (Layer 2)**: Translate positions to boxing gestures
- [ ] **Multi-pose testing and optimization**: Verify multi-player support
- [x] **MJPEG camera streaming**: ✅ Fixed UTF-8 parsing, coordinate alignment, horizontal flip
- [x] **Python sidecar cleanup**: ✅ FIXED - Heartbeat/keepalive mechanism implemented

### Medium Priority

- [ ] **Create InputManager reference implementation**: Complete central coordinator
- [ ] **XR 6DOF provider**: Implement with collision vs gesture decision
- [ ] **MediaPipe Native Mobile provider**: iOS/Android native implementation
- [ ] **Joy-Con provider**: Complete GDExtension implementation

### Low Priority

- [ ] **Automated CI/CD**: Python sidecar builds and testing
- [ ] **Comprehensive documentation**: Video tutorials and examples
- [ ] **Performance optimization**: Profile and optimize hot paths

### Known Issues

1. **MediaPipeProvider inheritance**: Currently extends Node instead of AeroInputProvider
2. **Multi-pose untested**: Architecture supports it but not validated
3. **XR collision question**: Open design question on collision vs gesture approach
4. **Python sidecar cleanup**: Process sometimes survives scene exit (camera light stays on). Manual `pkill -9 -f "python_mediapipe"` works. Issue likely related to OpenCV VideoCapture blocking in uninterruptible sleep (D state).

---

## Documentation & Resources

### For Input Developers

1. **Read**: `aerobeat-core/src/input/input_provider.gd` (base interface)
2. **Reference**: `aerobeat-input-mediapipe-python/` (complete example)
3. **Copy**: Create from template following this document
4. **Test**: Use `tests/` directory with GUT framework

### For Game Developers

1. **Use**: Connect to `AeroInputProvider` signals directly, or use `InputManager` for multi-input
2. **Listen**: Connect to boxing gesture callbacks (`punch_left`, `block_start`, etc.)
3. **Configure**: Pass JSON settings to `start(settings_json)` for provider-specific options
4. **Debug**: All providers emit `started`, `stopped`, `failed` for lifecycle tracking

---

## Recent Changes (2026-02-11 Session)

### Completed
- **Contract System**: Updated `aerobeat-core` with full `AeroInputProvider` base class, `BoxingInput` and `FlowInput` interfaces, and `InputManager` reference implementation
- **Python Process Cleanup**: ✅ FIXED - Implemented heartbeat/keepalive mechanism. Python self-terminates when heartbeats stop. No more zombie processes!
- **MJPEG Optimization**: Partial - Python side optimized (1ms sleep, quality 50, TCP_NODELAY). Godot side reverted due to stuttering issues.
- **Port Conflict Fix**: Heartbeat port changed from +1 to +2 to avoid MJPEG streamer conflict

### Fixes
- **MJPEG Streaming**: Fixed UTF-8 parsing errors by using byte-level parsing instead of `get_string_from_utf8()` on binary JPEG data
- **Thread Cleanup**: Fixed "Thread object destroyed without completion" warnings with proper lifecycle management and guard variables
- **Binary Protocol**: Implemented `_parse_binary_packet()` in `mediapipe_server.gd` to handle Python binary protocol (marker 0x01)
- **Tracking State**: Fixed `is_tracking()` always returning false by switching from wall-clock seconds to millisecond timestamps
- **Coordinate Alignment**: Fixed landmark dots misaligned with video by calculating displayed image bounds for letterboxed video
- **Horizontal Flip**: Added `flip_horizontal` export var to `MediaPipeCameraView` with shader-based video flip and coordinate flipping
- **Double-Start Prevention**: Added `_is_starting` guard to prevent concurrent `start_stream()` calls causing duplicate threads
- **Static Type Warnings**: Fixed GDScript static type warnings throughout codebase

### Outstanding Issues
- **MJPEG Latency**: Improved but still perceptible. Further gains require architectural changes (UDP streaming, hardware encoding) or accepting current state as "good enough"

---

## License

See individual repository LICENSE.md files for details.

---

*Document prepared for AeroBeat development team. Last updated: 2026-02-11*  
*This document is the definitive source of truth for AeroBeat input architecture.*
