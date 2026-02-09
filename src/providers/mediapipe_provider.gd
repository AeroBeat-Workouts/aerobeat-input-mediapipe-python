class_name MediaPipeProvider
extends Node
## MediaPipe implementation of input provider with multi-pose support
## Works standalone OR as part of aerobeat-core assembly

signal pose_updated(landmarks: Array)
signal multi_pose_updated(poses: Array)  # Array of {pose_id, landmarks}
signal tracking_lost()
signal tracking_restored()

@export var config: MediaPipeConfig

@onready var _server: MediaPipeServer = $MediaPipeServer

var _last_update_time: float = 0.0
var _tracking_timeout: float = 0.5  # seconds
var _landmarks: Dictionary = {}  # id -> landmark data (primary pose)
var _all_poses: Array = []  # Array of {pose_id, landmarks}
var _was_tracking := false

# Tracking mode enum
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
	_server.multi_pose_received.connect(_on_multi_pose_received)

func start() -> bool:
	return _server.start()

func stop() -> void:
	_server.stop()

## Get number of detected poses
func get_num_poses() -> int:
	return _all_poses.size()

## Get all poses data
func get_all_poses() -> Array:
	return _all_poses.duplicate()

## Get position for a specific pose and landmark
func get_landmark_position_for_pose(pose_idx: int, landmark_id: int, 
									mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	if pose_idx < 0 or pose_idx >= _all_poses.size():
		return null
	
	var pose_data = _all_poses[pose_idx]
	if not pose_data is Dictionary:
		return null
	
	var landmarks = pose_data.get("landmarks", [])
	if not landmarks is Array:
		return null
	
	# Find landmark by id
	for lm in landmarks:
		if lm is Dictionary and lm.get("id") == landmark_id:
			if lm.has("v") and lm.v > config.min_visibility:
				return _convert_landmark_to_position(lm, mode)
			break
	
	return null

## Primary pose methods (backward compatible)
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

## Multi-pose convenience methods
func get_player_left_hand(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_LEFT_WRIST, mode)

func get_player_right_hand(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_RIGHT_WRIST, mode)

func get_player_head(player_idx: int, mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	return get_landmark_position_for_pose(player_idx, LANDMARK_NOSE, mode)

func set_tracking_mode(mode: TrackingMode) -> void:
	pass

func _get_landmark_position(landmark_id: int, mode: TrackingMode) -> Variant:
	return get_landmark_position_for_pose(0, landmark_id, mode)

func _convert_landmark_to_position(lm: Dictionary, mode: TrackingMode) -> Variant:
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

func is_tracking_player(player_idx: int) -> bool:
	if player_idx < 0 or player_idx >= _all_poses.size():
		return false
	
	var pose_data = _all_poses[player_idx]
	if not pose_data is Dictionary:
		return false
	
	var landmarks = pose_data.get("landmarks", [])
	return landmarks is Array and landmarks.size() > 0

func _on_landmarks_received(landmarks: Array):
	_landmarks.clear()
	for lm in landmarks:
		if lm.has("v") and lm.v > config.min_visibility:
			_landmarks[lm.id] = lm
	
	_last_update_time = Time.get_time_dict_from_system()["second"]
	pose_updated.emit(landmarks)

func _on_multi_pose_received(poses: Array):
	_all_poses = poses
	
	# Update primary landmarks from first pose
	if poses.size() > 0 and poses[0] is Dictionary:
		var primary_landmarks = poses[0].get("landmarks", [])
		_on_landmarks_received(primary_landmarks)
	
	multi_pose_updated.emit(poses)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		stop()
