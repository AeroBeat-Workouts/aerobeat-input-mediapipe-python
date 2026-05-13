class_name MediaPipeProvider
extends Node
## MediaPipe implementation of the current AeroBeat camera input provider with multi-pose support
## Works within the aerobeat-input-core assembly contract while staying truthful to this repo's PC-first camera path


signal pose_updated(landmarks: Array)
signal multi_pose_updated(poses: Array)  # Array of {pose_id, landmarks}
signal tracking_lost()
signal tracking_restored()

signal punch_left(power: float)
signal punch_right(power: float)
signal uppercut_left(power: float)
signal uppercut_right(power: float)
signal hook_left(power: float)
signal hook_right(power: float)
signal swing_left(placement: int, direction: int)
signal swing_right(placement: int, direction: int)
signal trail_left(placement: int, direction: int)
signal trail_right(placement: int, direction: int)
signal guard_start()
signal guard_end()
signal squat_start()
signal squat_end()
signal weave_left_start()
signal weave_left_end()
signal weave_right_start()
signal weave_right_end()
signal sidestep_left_start()
signal sidestep_left_end()
signal sidestep_right_start()
signal sidestep_right_end()
signal knee_left(power: float)
signal knee_right(power: float)
signal leg_lift_left_start()
signal leg_lift_left_end()
signal leg_lift_right_start()
signal leg_lift_right_end()

@export var config = null

var _server = null
var _detector_substrate: PoseDetectorSubstrate = null

var _last_update_time_ms: int = 0
var _tracking_timeout_ms: int = 500  # milliseconds
var _landmarks: Dictionary = {}  # id -> smoothed landmark data (primary pose)
var _all_poses: Array = []  # Array of {pose_id, landmarks}
var _was_tracking := false

# Tracking mode enum
enum TrackingMode {
	MODE_2D,
	MODE_3D
}

# Landmark indices per MediaPipe Pose
const LANDMARK_LEFT_WRIST = PoseLandmarkIds.LEFT_WRIST
const LANDMARK_RIGHT_WRIST = PoseLandmarkIds.RIGHT_WRIST
const LANDMARK_NOSE = PoseLandmarkIds.NOSE
const LANDMARK_LEFT_ANKLE = PoseLandmarkIds.LEFT_ANKLE
const LANDMARK_RIGHT_ANKLE = PoseLandmarkIds.RIGHT_ANKLE

func _ready():
	config = _ensure_config()
	_ensure_detector_substrate()
	_ensure_server()
	if _server == null:
		return

	_server.config = config
	if not _server.landmarks_received.is_connected(_on_landmarks_received):
		_server.landmarks_received.connect(_on_landmarks_received)
	if not _server.multi_pose_received.is_connected(_on_multi_pose_received):
		_server.multi_pose_received.connect(_on_multi_pose_received)

func start() -> bool:
	_ensure_detector_substrate()
	_ensure_server()
	return _server != null and _server.start()

func stop() -> void:
	_ensure_server()
	if _server != null:
		_server.stop()

## Get number of detected poses
func get_num_poses() -> int:
	return _all_poses.size()

## Get all poses data
func get_all_poses() -> Array:
	return _all_poses.duplicate(true)

func get_detector_state() -> Dictionary:
	if _detector_substrate == null:
		return {}
	return _detector_substrate.get_latest_state()

func get_body_measurements() -> Dictionary:
	if _detector_substrate == null:
		return {}
	return _detector_substrate.get_measurements()

func get_tracking_state() -> StringName:
	if _detector_substrate == null:
		return &"lost"
	return _detector_substrate.get_tracking_state()

func get_landmark_velocity_for_body_part(body_part: StringName) -> Vector3:
	if _detector_substrate == null:
		return Vector3.ZERO
	return _detector_substrate.get_velocity(body_part)

## Get position for a specific pose and landmark
func get_landmark_position_for_pose(pose_idx: int, landmark_id: int,
									mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
	if pose_idx < 0 or pose_idx >= _all_poses.size():
		return null

	if pose_idx == 0:
		var primary_landmark := _landmarks.get(landmark_id, null)
		if primary_landmark is Dictionary and _passes_visibility_threshold(primary_landmark):
			return _convert_landmark_to_position(primary_landmark, mode)

	var pose_data = _all_poses[pose_idx]
	if not pose_data is Dictionary:
		return null

	var landmarks: Variant = pose_data.get("landmarks", [])
	if not landmarks is Array:
		return null

	for lm: Variant in landmarks:
		if lm is Dictionary and lm.get("id") == landmark_id:
			if _passes_visibility_threshold(lm):
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

func set_tracking_mode(_mode: TrackingMode) -> void:
	pass

func _get_landmark_position(landmark_id: int, mode: TrackingMode) -> Variant:
	return get_landmark_position_for_pose(0, landmark_id, mode)

func _convert_landmark_to_position(lm: Dictionary, mode: TrackingMode) -> Variant:
	var x: float = lm.get("x", 0.0)
	var y: float = lm.get("y", 0.0)
	var z: float = lm.get("z", 0.0)

	if mode == TrackingMode.MODE_2D:
		return Vector2(x, y)
	return Vector3(x, y, z)

func is_tracking() -> bool:
	var current_time_ms: int = Time.get_ticks_msec()
	var is_currently_tracking: bool = (current_time_ms - _last_update_time_ms) < _tracking_timeout_ms
	if _detector_substrate != null:
		_detector_substrate.mark_tracking_timeout(current_time_ms)
		is_currently_tracking = is_currently_tracking and _detector_substrate.get_tracking_state() != &"lost"

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

	var landmarks: Variant = pose_data.get("landmarks", [])
	return landmarks is Array and landmarks.size() > 0

func _on_landmarks_received(landmarks: Array):
	_process_primary_landmarks(landmarks, true, true)

func _on_multi_pose_received(poses: Array):
	var normalized_poses: Array = []
	for pose_variant: Variant in poses:
		if not pose_variant is Dictionary:
			continue
		var pose_dict: Dictionary = pose_variant.duplicate(true)
		var raw_landmarks: Variant = pose_dict.get("landmarks", [])
		if raw_landmarks is Array:
			pose_dict["landmarks"] = _normalize_landmarks(raw_landmarks)
		normalized_poses.append(pose_dict)

	_all_poses = normalized_poses.duplicate(true)

	if normalized_poses.size() > 0:
		var first_pose: Variant = normalized_poses[0]
		if first_pose is Dictionary:
			var primary_landmarks: Variant = first_pose.get("landmarks", [])
			if primary_landmarks is Array:
				_process_primary_landmarks(primary_landmarks, true, false)

	multi_pose_updated.emit(_all_poses.duplicate(true))

func _process_primary_landmarks(landmarks: Array, emit_signal: bool, overwrite_all_poses: bool, timestamp_ms: int = 0) -> void:
	_ensure_detector_substrate()
	var normalized_landmarks := _normalize_landmarks(landmarks)
	var state: Dictionary = {}
	if _detector_substrate != null:
		state = _detector_substrate.process_landmarks(normalized_landmarks, timestamp_ms)
		_landmarks = state.get("landmarks_by_id", {}).duplicate(true)
		_emit_detector_events(state.get("events", []))
	else:
		_landmarks.clear()
		for landmark: Variant in normalized_landmarks:
			if landmark is Dictionary:
				_landmarks[int(landmark.get("id", 0))] = landmark.duplicate(true)

	if overwrite_all_poses:
		_all_poses = [{
			"pose_id": 0,
			"landmarks": normalized_landmarks.duplicate(true),
		}]

	_last_update_time_ms = Time.get_ticks_msec()
	if emit_signal:
		pose_updated.emit(normalized_landmarks)

func _emit_detector_events(events: Array) -> void:
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_data: Dictionary = event_variant
		var event_name := StringName(event_data.get("name", StringName()))
		if event_name == StringName():
			continue
		match String(event_name):
			"punch_left":
				punch_left.emit(float(event_data.get("power", 0.0)))
			"punch_right":
				punch_right.emit(float(event_data.get("power", 0.0)))
			"uppercut_left":
				uppercut_left.emit(float(event_data.get("power", 0.0)))
			"uppercut_right":
				uppercut_right.emit(float(event_data.get("power", 0.0)))
			"hook_left":
				hook_left.emit(float(event_data.get("power", 0.0)))
			"hook_right":
				hook_right.emit(float(event_data.get("power", 0.0)))
			"swing_left":
				swing_left.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"swing_right":
				swing_right.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"trail_left":
				trail_left.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"trail_right":
				trail_right.emit(int(event_data.get("placement", -1)), int(event_data.get("direction", -1)))
			"guard_start":
				guard_start.emit()
			"guard_end":
				guard_end.emit()
			"squat_start":
				squat_start.emit()
			"squat_end":
				squat_end.emit()
			"weave_left_start":
				weave_left_start.emit()
			"weave_left_end":
				weave_left_end.emit()
			"weave_right_start":
				weave_right_start.emit()
			"weave_right_end":
				weave_right_end.emit()
			"sidestep_left_start":
				sidestep_left_start.emit()
			"sidestep_left_end":
				sidestep_left_end.emit()
			"sidestep_right_start":
				sidestep_right_start.emit()
			"sidestep_right_end":
				sidestep_right_end.emit()
			"knee_left":
				knee_left.emit(float(event_data.get("power", 0.0)))
			"knee_right":
				knee_right.emit(float(event_data.get("power", 0.0)))
			"leg_lift_left_start":
				leg_lift_left_start.emit()
			"leg_lift_left_end":
				leg_lift_left_end.emit()
			"leg_lift_right_start":
				leg_lift_right_start.emit()
			"leg_lift_right_end":
				leg_lift_right_end.emit()

func _normalize_landmarks(landmarks: Array) -> Array:
	var normalized: Array = []
	var resolved_config := _ensure_config()
	for landmark: Variant in landmarks:
		if not landmark is Dictionary:
			continue
		var landmark_dict: Dictionary = landmark.duplicate(true)
		var x: float = float(landmark_dict.get("x", 0.0))
		var y: float = 1.0 - float(landmark_dict.get("y", 0.0))
		if resolved_config != null and resolved_config.flip_horizontal:
			x = 1.0 - x
		landmark_dict["x"] = x
		landmark_dict["y"] = y
		landmark_dict["z"] = float(landmark_dict.get("z", 0.0))
		landmark_dict["v"] = float(landmark_dict.get("v", 1.0))
		normalized.append(landmark_dict)
	return normalized

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		print("[MediaPipeProvider] EXIT_TREE - stopping server")
		stop()

func _ensure_server() -> void:
	if _server != null and is_instance_valid(_server):
		return

	var existing_server := get_node_or_null("MediaPipeServer")
	if existing_server != null:
		_server = existing_server
		return

	_server = _new_local_script_instance("../server/mediapipe_server.gd")
	if _server == null:
		return

	_server.name = "MediaPipeServer"
	add_child(_server)

func _ensure_detector_substrate() -> void:
	if _detector_substrate != null:
		return
	_detector_substrate = PoseDetectorSubstrate.new().configure(_ensure_config())

func _ensure_config() -> Variant:
	if config != null:
		return config
	config = _new_local_script_instance("../config/mediapipe_config.gd")
	return config

func _passes_visibility_threshold(landmark: Dictionary, resolved_config: Variant = null) -> bool:
	var active_config := resolved_config if resolved_config != null else _ensure_config()
	if active_config == null:
		return true
	return float(landmark.get("v", 1.0)) >= float(active_config.min_visibility)

func _new_local_script_instance(relative_path: String) -> Variant:
	var script_path := "%s/%s" % [get_script().resource_path.get_base_dir(), relative_path]
	var script: Variant = load(script_path)
	if script == null:
		push_error("Failed to load MediaPipe provider dependency: %s" % script_path)
		return null
	return script.new()
