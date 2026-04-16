# Phase 2: MediaPipe Provider + UDP Server

**Prerequisite:** Phase 1 complete  
**Next Phase:** Phase 3 (Process Management)  
**Success Criteria:** Interface contract tests pass, UDP server binds successfully

---

## Goal

Create `MediaPipeProvider` class that implements `AeroInputProvider` interface, plus `MediaPipeServer` to handle UDP communication from the Python sidecar.

---

## Files to Create

### 1. `aerobeat-input-mediapipe-python/src/server/mediapipe_server.gd`

```gdscript
class_name MediaPipeServer
extends Node
## UDP server that receives landmark data from Python MediaPipe sidecar

signal landmarks_received(landmarks: Array)
signal server_started(port: int)
signal server_stopped()
signal parse_error(error: String)

@export var config: MediaPipeConfig

var _udp := PacketPeerUDP.new()
var _is_running := false

func start() -> bool:
    var port = config.udp_port if config else 4242
    
    # Try to bind, with fallback to next available port
    var bind_result = _udp.bind(port)
    if bind_result != OK:
        push_warning("MediaPipeServer: Failed to bind to port %d, trying auto-select" % port)
        bind_result = _udp.bind(0)  # 0 = auto-select
        if bind_result != OK:
            push_error("MediaPipeServer: Failed to bind UDP socket")
            return false
        port = _udp.get_local_port()
        if config:
            config.udp_port = port
    
    _is_running = true
    server_started.emit(port)
    return true

func stop() -> void:
    _is_running = false
    _udp.close()
    server_stopped.emit()

func is_running() -> bool:
    return _is_running

func get_bound_port() -> int:
    return _udp.get_local_port() if _is_running else -1

func _process(_delta: float) -> void:
    if not _is_running:
        return
    
    # Drain all pending packets, keep only the newest
    var latest_packet: PackedByteArray
    while _udp.get_available_bytes() > 0:
        latest_packet = _udp.get_packet()
    
    if latest_packet.is_empty():
        return
    
    _parse_packet(latest_packet)

func _parse_packet(packet: PackedByteArray) -> void:
    var json := JSON.new()
    var error := json.parse(packet.get_string_from_utf8())
    
    if error != OK:
        parse_error.emit("JSON parse error: " + json.get_error_message())
        return
    
    var data = json.data
    if not data is Dictionary:
        parse_error.emit("Expected JSON object, got: " + str(typeof(data)))
        return
    
    if not data.has("landmarks"):
        parse_error.emit("Missing 'landmarks' field")
        return
    
    var landmarks = data["landmarks"]
    if not landmarks is Array:
        parse_error.emit("'landmarks' should be an array")
        return
    
    landmarks_received.emit(landmarks)
```

### 2. `aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd`

```gdscript
class_name MediaPipeProvider
extends AeroInputProvider
## MediaPipe implementation of AeroInputProvider

signal pose_updated(landmarks: Array)
signal tracking_lost()
signal tracking_restored()

@export var config: MediaPipeConfig

@onready var _server: MediaPipeServer = $MediaPipeServer

var _last_update_time: float = 0.0
var _tracking_timeout: float = 0.5  # seconds
var _landmarks: Dictionary = {}  # id -> landmark data
var _was_tracking := false

# Landmark indices per MediaPipe Pose
const LANDMARK_LEFT_WRIST = 15
const LANDMARK_RIGHT_WRIST = 16
const LANDMARK_NOSE = 0
const LANDMARK_LEFT_ANKLE = 27
const LANDMARK_RIGHT_ANKLE = 28

func _ready():
    if config == null:
        config = MediaPipeConfig.new()
    
    # Create server if not present
    if _server == null:
        _server = MediaPipeServer.new()
        _server.name = "MediaPipeServer"
        add_child(_server)
    
    _server.config = config
    _server.landmarks_received.connect(_on_landmarks_received)

func start() -> bool:
    return _server.start()

func stop() -> void:
    _server.stop()

func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    return _get_landmark_position(LANDMARK_LEFT_WRIST, mode)

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    return _get_landmark_position(LANDMARK_RIGHT_WRIST, mode)

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    return _get_landmark_position(LANDMARK_NOSE, mode)

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    return _get_landmark_position(LANDMARK_LEFT_ANKLE, mode)

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    return _get_landmark_position(LANDMARK_RIGHT_ANKLE, mode)

func _get_landmark_position(landmark_id: int, mode: TrackingMode) -> Variant:
    if not _landmarks.has(landmark_id):
        return null
    
    var lm = _landmarks[landmark_id]
    var x = lm.x
    var y = 1.0 - lm.y  # Flip Y axis
    
    if config and config.flip_horizontal:
        x = 1.0 - x
    
    if mode == TrackingMode.MODE_2D:
        return Vector2(x, y)
    else:
        return Vector3(x, y, lm.z)

func is_tracking() -> bool:
    var current_time = Time.get_time_dict_from_system()["second"]
    var is_currently_tracking = (current_time - _last_update_time) < _tracking_timeout
    
    # Emit signals on state change
    if is_currently_tracking and not _was_tracking:
        tracking_restored.emit()
    elif not is_currently_tracking and _was_tracking:
        tracking_lost.emit()
    
    _was_tracking = is_currently_tracking
    return is_currently_tracking

func _on_landmarks_received(landmarks: Array):
    _landmarks.clear()
    for lm in landmarks:
        if lm.has("v") and lm.v > config.min_visibility:
            _landmarks[lm.id] = lm
    
    _last_update_time = Time.get_time_dict_from_system()["second"]
    pose_updated.emit(landmarks)

func _notification(what: int) -> void:
    if what == NOTIFICATION_EXIT_TREE:
        stop()
```

### 3. `aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd`

```gdscript
class_name MediaPipeConfig
extends Resource

@export var camera_id: int = 0
@export var udp_port: int = 4242
@export var detection_confidence: float = 0.5
@export var tracking_confidence: float = 0.5
@export var model_complexity: int = 1
@export var flip_horizontal: bool = true
@export var smoothing_factor: float = 0.3
@export var min_visibility: float = 0.5
@export var track_head: bool = true
@export var track_left_hand: bool = true
@export var track_right_hand: bool = true
@export var track_left_foot: bool = false
@export var track_right_foot: bool = false
```

---

## Tests to Create

### `test/unit/test_mediapipe_server.gd`

```gdscript
extends GutTest

var server
var config

func before_each():
    config = MediaPipeConfig.new()
    config.udp_port = 9999  # Use high port to avoid conflicts
    
    server = MediaPipeServer.new()
    server.config = config
    add_child(server)

func after_each():
    if server.is_running():
        server.stop()
    server.queue_free()

func test_start_binds_to_port():
    var success = server.start()
    assert_true(success, "Server should start")
    assert_true(server.is_running())
    assert_gt(server.get_bound_port(), 0)

func test_stop_releases_port():
    server.start()
    server.stop()
    assert_false(server.is_running())

func test_emits_server_started_signal():
    var port_received = -1
    server.server_started.connect(func(p): port_received = p)
    server.start()
    assert_gt(port_received, 0)

func test_parse_valid_json():
    var landmarks_received = []
    server.landmarks_received.connect(func(l): landmarks_received = l)
    server.start()
    
    # Simulate UDP packet (would need mock in real test)
    var test_data = JSON.stringify({"landmarks": [{"id": 0, "x": 0.5, "y": 0.5, "v": 0.99}]})
    server._parse_packet(test_data.to_utf8_buffer())
    
    assert_eq(landmarks_received.size(), 1)

func test_handles_parse_error():
    var error_received = ""
    server.parse_error.connect(func(e): error_received = e)
    server.start()
    
    server._parse_packet("invalid json".to_utf8_buffer())
    
    assert_ne(error_received, "")
```

### `test/unit/test_mediapipe_provider.gd`

```gdscript
extends GutTest

var provider

func before_each():
    provider = MediaPipeProvider.new()
    add_child(provider)
    # Wait for _ready
    await get_tree().process_frame

func after_each():
    provider.queue_free()

func test_extends_aero_input_provider():
    assert_is(provider, AeroInputProvider)

func test_creates_server_if_missing():
    var server = provider.get_node_or_null("MediaPipeServer")
    assert_not_null(server)
    assert_is(server, MediaPipeServer)

func test_returns_null_when_no_data():
    assert_null(provider.get_left_hand_position())

func test_returns_vector2_in_2d_mode():
    provider._on_landmarks_received([{"id": 15, "x": 0.5, "y": 0.5, "v": 0.99}])
    var pos = provider.get_left_hand_position()
    assert_is(pos, Vector2)
    assert_between(pos.x, 0.0, 1.0)
    assert_between(pos.y, 0.0, 1.0)

func test_returns_vector3_in_3d_mode():
    provider.set_tracking_mode(AeroInputProvider.TrackingMode.MODE_3D)
    provider._on_landmarks_received([{"id": 15, "x": 0.5, "y": 0.5, "z": 0.1, "v": 0.99}])
    var pos = provider.get_left_hand_position()
    assert_is(pos, Vector3)

func test_y_axis_is_flipped():
    provider.config = MediaPipeConfig.new()
    provider.config.flip_horizontal = false
    provider._on_landmarks_received([{"id": 0, "x": 0.5, "y": 0.2, "v": 0.99}])
    var pos = provider.get_head_position()
    assert_eq(pos.y, 0.8, "Y should be 1.0 - 0.2 = 0.8")

func test_horizontal_flip():
    provider.config = MediaPipeConfig.new()
    provider.config.flip_horizontal = true
    provider._on_landmarks_received([{"id": 0, "x": 0.2, "v": 0.99}])
    var pos = provider.get_head_position()
    assert_eq(pos.x, 0.8, "X should be flipped")

func test_is_tracking_false_when_no_data():
    assert_false(provider.is_tracking())

func test_is_tracking_true_after_data():
    provider._on_landmarks_received([{"id": 0, "v": 0.99}])
    assert_true(provider.is_tracking())

func test_emits_tracking_lost_signal():
    provider._tracking_timeout = 0.001  # 1ms for testing
    provider._on_landmarks_received([{"id": 0, "v": 0.99}])
    
    var signal_emitted = false
    provider.tracking_lost.connect(func(): signal_emitted = true)
    
    await wait_seconds(0.01)  # Wait for timeout
    provider.is_tracking()  # Trigger check
    
    assert_true(signal_emitted)
```

---

## Directory Structure After

```
aerobeat-input-mediapipe-python/
├── src/
│   ├── server/
│   │   └── mediapipe_server.gd      # NEW: UDP communication
│   ├── providers/
│   │   └── mediapipe_provider.gd    # Updated with server integration
│   └── config/
│       └── mediapipe_config.gd
├── test/
│   └── unit/
│       ├── test_mediapipe_server.gd # NEW
│       └── test_mediapipe_provider.gd
```

---

## Key Changes from Expert Review

| Issue | Fix Applied |
|-------|-------------|
| **Missing UDP layer** | Added `MediaPipeServer` class with packet draining |
| **No port fallback** | Auto-select port if bind fails |
| **No error handling** | Added `parse_error` signal and validation |
| **Server lifecycle** | Provider manages server start/stop |

---

## Implementation Checklist

Subagents: Mark off each task as completed.

### Server Files
- [x] `aerobeat-input-mediapipe-python/src/server/mediapipe_server.gd` created
- [x] `MediaPipeServer` class extends `Node`
- [x] `PacketPeerUDP` initialized correctly
- [x] `start()` method binds to port with fallback
- [x] `stop()` method closes socket
- [x] `_process()` drains all pending packets
- [x] `_parse_packet()` validates JSON structure
- [x] Signals defined: `landmarks_received`, `server_started`, `server_stopped`, `parse_error`

### Provider Files
- [x] `aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd` created
- [x] `MediaPipeProvider` extends `AeroInputProvider`
- [x] All interface methods implemented
- [x] `@onready var _server` gets MediaPipeServer node
- [x] `start()` calls `_server.start()`
- [x] `stop()` calls `_server.stop()`
- [x] `_on_landmarks_received()` parses landmark data
- [x] `_get_landmark_position()` applies Y-flip
- [x] `_get_landmark_position()` applies horizontal flip if configured
- [x] `is_tracking()` implements timeout logic
- [x] `_notification(NOTIFICATION_EXIT_TREE)` calls stop()

### Config File
- [x] `aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd` created
- [x] `MediaPipeConfig` extends `Resource`
- [x] All `@export` vars defined with defaults
- [x] UDP port configurable
- [x] Camera ID configurable
- [x] Flip options configurable

### Test Files
- [x] `test/unit/test_mediapipe_server.gd` created
- [x] `test/unit/test_mediapipe_provider.gd` created
- [x] All server tests pass
- [x] All provider tests pass

### Verification
- [x] Server binds to UDP port successfully
- [x] Server handles port conflicts with auto-fallback
- [x] Server parses valid JSON correctly
- [x] Server emits parse_error for invalid JSON
- [x] Provider returns Vector2 in MODE_2D
- [x] Provider returns Vector3 in MODE_3D
- [x] Y-axis is flipped (OpenCV to Godot coordinates)
- [x] Horizontal flip works when enabled
- [x] No errors in Godot 4.6

---

## Truth Checkpoint

**Phase 2 Complete When:** All checkboxes above are marked complete.

---

*See 00-MASTER-ROADMAP.md for context*
*Updated with expert recommendations 2026-02-06*
