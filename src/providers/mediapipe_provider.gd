class_name MediaPipeProvider
extends Node
## MediaPipe implementation of input provider
## Works standalone OR as part of aerobeat-core assembly
## When aerobeat-core is available, this can be wrapped to extend AeroInputProvider

signal pose_updated(landmarks: Array)
signal tracking_lost()
signal tracking_restored()

@export var config: MediaPipeConfig

@onready var _server: MediaPipeServer = $MediaPipeServer

var _last_update_time: float = 0.0
var _tracking_timeout: float = 0.5  # seconds
var _landmarks: Dictionary = {}  # id -> landmark data
var _was_tracking := false

# Tracking mode enum (duplicated here for standalone compatibility)
enum TrackingMode {
	MODE_2D,
	MODE_3D
}

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

## Set tracking mode (for API compatibility with AeroInputProvider)
func set_tracking_mode(mode: TrackingMode) -> void:
	# Mode is handled per-call in get_*_position functions
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
	_landmarks.clear()
	for lm in landmarks:
		if lm.has("v") and lm.v > config.min_visibility:
			_landmarks[lm.id] = lm
	
	_last_update_time = Time.get_time_dict_from_system()["second"]
	pose_updated.emit(landmarks)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		stop()
