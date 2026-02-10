extends Node
## Standalone test version of MediaPipeProvider
## Extends Node instead of AeroInputProvider for independent testing
## This allows the addon to be tested without aerobeat-core dependency

class_name MediaPipeProviderTest

const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")
const MediaPipeServer = preload("res://src/server/mediapipe_server.gd")

signal pose_updated(landmarks: Array)
signal tracking_lost()
signal tracking_restored()

enum TrackingMode {
    MODE_2D,
    MODE_3D
}

@export var config: MediaPipeConfig

var _server: MediaPipeServer = null

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
    
    # Create server
    _server = MediaPipeServer.new()
    _server.name = "MediaPipeServer"
    add_child(_server)
    
    _server.config = config
    _server.landmarks_received.connect(_on_landmarks_received)
    
    print("[MediaPipeProviderTest] Ready on port %d" % config.udp_port)

func start() -> bool:
    print("[MediaPipeProviderTest] Starting server on port %d" % config.udp_port)
    var success = _server.start()
    if success:
        print("[MediaPipeProviderTest] Server started successfully on port %d" % _server.get_bound_port())
    else:
        print("[MediaPipeProviderTest] FAILED to start server")
    return success

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

func set_tracking_mode(mode: TrackingMode) -> void:
    # For compatibility with AeroInputProvider interface
    pass

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
    print("[MediaPipeProviderTest] Received ", landmarks.size(), " landmarks")
    _landmarks.clear()
    for lm in landmarks:
        if lm.has("v") and lm.v > config.min_visibility:
            _landmarks[lm.id] = lm
    
    _last_update_time = Time.get_time_dict_from_system()["second"]
    print("[MediaPipeProviderTest] After filtering: ", _landmarks.size(), " landmarks (min_visibility=", config.min_visibility, ")")
    pose_updated.emit(landmarks)

func _notification(what: int) -> void:
    if what == NOTIFICATION_EXIT_TREE:
        stop()
