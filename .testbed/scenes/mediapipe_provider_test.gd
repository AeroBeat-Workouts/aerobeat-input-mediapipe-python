extends Node
class_name MediaPipeProviderTest
## Standalone test version of MediaPipeProvider
## Extends Node instead of AeroInputProvider for independent testing

signal pose_updated(landmarks: Array)
signal tracking_lost()
signal tracking_restored()

enum TrackingMode {
	MODE_2D,
	MODE_3D
}

@export var config: MediaPipeConfig

var _server: MediaPipeServer = null

var _last_update_time_ms: int = 0
var _tracking_timeout_ms: int = 1000  # Increased to 1 second for more lenient tracking
var _landmarks: Dictionary = {}
var _was_tracking: bool = false

const LANDMARK_LEFT_WRIST: int = 15
const LANDMARK_RIGHT_WRIST: int = 16
const LANDMARK_NOSE: int = 0
const LANDMARK_LEFT_ANKLE: int = 27
const LANDMARK_RIGHT_ANKLE: int = 28

func _ready() -> void:
	if config == null:
		config = MediaPipeConfig.new()
		config.min_visibility = 0.3  # More lenient default for testing
		config.flip_horizontal = true
	
	_server = MediaPipeServer.new()
	_server.name = "MediaPipeServer"
	add_child(_server)
	
	_server.config = config
	_server.landmarks_received.connect(_on_landmarks_received)
	_server.multi_pose_received.connect(_on_multi_pose_received)

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

func set_tracking_mode(_mode: TrackingMode) -> void:
	pass

func _get_landmark_position(landmark_id: int, mode: TrackingMode) -> Variant:
	if not _landmarks.has(landmark_id):
		return null
	
	var lm: Dictionary = _landmarks[landmark_id]
	var x: float = lm.get("x", 0.0)
	var y: float = 1.0 - lm.get("y", 0.0)
	var z: float = lm.get("z", 0.0)
	
	if config and config.flip_horizontal:
		x = 1.0 - x
	
	if mode == TrackingMode.MODE_2D:
		return Vector2(x, y)
	else:
		return Vector3(x, y, z)

func is_tracking() -> bool:
	var current_time_ms: int = Time.get_ticks_msec()
	var diff_ms: int = current_time_ms - _last_update_time_ms
	var is_currently_tracking: bool = diff_ms < _tracking_timeout_ms
	
	if is_currently_tracking and not _was_tracking:
		tracking_restored.emit()
	elif not is_currently_tracking and _was_tracking:
		tracking_lost.emit()
	
	_was_tracking = is_currently_tracking
	return is_currently_tracking

func _on_landmarks_received(landmarks: Array) -> void:
	_landmarks.clear()
	
	for item: Variant in landmarks:
		if not item is Dictionary:
			continue
		
		var landmark: Dictionary = item
		var visibility: float = landmark.get("v", 1.0)
		var threshold: float = config.min_visibility if config else 0.3
		var lm_id: int = landmark.get("id", 0)
		
		if visibility >= threshold:
			_landmarks[lm_id] = landmark
	
	_last_update_time_ms = Time.get_ticks_msec()
	pose_updated.emit(landmarks)

func _on_multi_pose_received(poses: Array) -> void:
	# Handle multi-pose data - extract first pose landmarks
	if poses.size() > 0:
		var first_pose: Variant = poses[0]
		if first_pose is Dictionary:
			var first_pose_dict: Dictionary = first_pose
			var landmarks: Variant = first_pose_dict.get("landmarks", [])
			if landmarks is Array:
				_on_landmarks_received(landmarks)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		stop()
