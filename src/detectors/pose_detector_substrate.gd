class_name PoseDetectorSubstrate
extends RefCounted

const PoseLandmarkIds = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_landmark_ids.gd")
const LandmarkSmoother = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/landmark_smoother.gd")
const PoseMetrics = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd")

const TRACKING_TRACKING := &"tracking"
const TRACKING_DEGRADED := &"degraded"
const TRACKING_LOST := &"lost"
const TRACKING_REACQUIRING := &"reacquiring"

const PUNCH_READY_EXTENSION := 0.72
const PUNCH_FIRE_EXTENSION := 0.92
const PUNCH_ELBOW_STRAIGHT_MIN_DEG := 170.0
const PUNCH_LATERAL_VELOCITY_RATIO := 1.35

const HOOK_ELBOW_MIN_DEG := 55.0
const HOOK_ELBOW_MAX_DEG := 145.0
const UPPERCUT_ELBOW_MIN_DEG := 35.0
const UPPERCUT_ELBOW_MAX_DEG := 125.0

const FLOW_HISTORY_MAX_MS := 560
const FLOW_SWING_WINDOW_MIN_MS := 120
const FLOW_SWING_WINDOW_MAX_MS := 320
const FLOW_SWING_MIN_ARC_RATIO := 0.72
const FLOW_SWING_MIN_TRAVEL_RATIO := 0.42
const FLOW_SWING_MIN_SPEED_RATIO := 1.45
const FLOW_TRAIL_WINDOW_MIN_MS := 260
const FLOW_TRAIL_MIN_ARC_RATIO := 0.95
const FLOW_TRAIL_MIN_TRAVEL_RATIO := 0.34
const FLOW_TRAIL_MIN_SPEED_RATIO := 1.05
const FLOW_TRAIL_EMIT_INTERVAL_MS := 90
const FLOW_PLACEMENT_SIDE_THRESHOLD := 0.45

var _config = null
var _smoother: LandmarkSmoother = LandmarkSmoother.new()
var _latest_state: Dictionary = {}
var _baseline_accumulator := {
	"frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"hip_center_y": 0.0,
	"nose_y": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _baseline: Dictionary = {
	"is_calibrated": false,
	"sample_frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"hip_center_y": 0.0,
	"nose_y": 0.0,
	"left_knee_y": 0.0,
	"right_knee_y": 0.0,
	"left_ankle_y": 0.0,
	"right_ankle_y": 0.0,
}
var _previous_positions: Dictionary = {}
var _gesture_state := {}
var _consecutive_valid_frames := 0
var _consecutive_invalid_frames := 0
var _reacquire_frames_remaining := 0
var _last_processed_timestamp_ms := 0
var _frame_index := 0

func _init() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size())
	_latest_state = _build_empty_state()
	_reset_gesture_state()

func configure(config) -> PoseDetectorSubstrate:
	_config = config
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size())
	return self

func reset() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size())
	_previous_positions.clear()
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = 0
	_reacquire_frames_remaining = 0
	_last_processed_timestamp_ms = 0
	_frame_index = 0
	_baseline_accumulator = {
		"frames": 0,
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"hip_center_y": 0.0,
		"nose_y": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}
	_baseline = {
		"is_calibrated": false,
		"sample_frames": 0,
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"hip_center_y": 0.0,
		"nose_y": 0.0,
		"left_knee_y": 0.0,
		"right_knee_y": 0.0,
		"left_ankle_y": 0.0,
		"right_ankle_y": 0.0,
	}
	_reset_gesture_state()
	_latest_state = _build_empty_state()

func process_landmarks(landmarks: Array, timestamp_ms: int = 0) -> Dictionary:
	if timestamp_ms <= 0:
		timestamp_ms = Time.get_ticks_msec()
	_frame_index += 1
	var smoothed_landmarks: Dictionary = _smoother.push_landmarks(landmarks)
	var metrics: Dictionary = _build_metrics(smoothed_landmarks, timestamp_ms)
	var tracking_state: StringName = _update_tracking_state(smoothed_landmarks)
	_update_baseline(metrics, tracking_state, smoothed_landmarks)
	metrics["tracking_state"] = tracking_state
	metrics["baseline"] = _baseline.duplicate(true)
	var events: Array = []
	if tracking_state == TRACKING_TRACKING or tracking_state == TRACKING_REACQUIRING:
		events = _detect_intent_events(smoothed_landmarks, metrics, timestamp_ms)
	else:
		_clear_transient_gesture_state()
	_latest_state = {
		"frame_index": _frame_index,
		"timestamp_ms": timestamp_ms,
		"tracking_state": tracking_state,
		"landmarks_by_id": smoothed_landmarks.duplicate(true),
		"baseline": _baseline.duplicate(true),
		"metrics": metrics,
		"events": events.duplicate(true),
		"gesture_states": _gesture_state.get("states", {}).duplicate(true),
	}
	_last_processed_timestamp_ms = timestamp_ms
	return _latest_state

func mark_tracking_timeout(timestamp_ms: int) -> void:
	if _last_processed_timestamp_ms <= 0:
		return
	var timeout_ms := _get_tracking_timeout_ms()
	if timestamp_ms - _last_processed_timestamp_ms < timeout_ms:
		return
	_consecutive_valid_frames = 0
	_consecutive_invalid_frames = maxi(_consecutive_invalid_frames, 3)
	_reacquire_frames_remaining = _get_reacquire_window_frames()
	_clear_transient_gesture_state()
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
	_latest_state["tracking_state"] = TRACKING_LOST
	_latest_state["events"] = []
	_latest_state["gesture_states"] = _gesture_state.get("states", {}).duplicate(true)
	var metrics: Dictionary = _latest_state.get("metrics", {})
	metrics["tracking_state"] = TRACKING_LOST
	_latest_state["metrics"] = metrics

func get_latest_state() -> Dictionary:
	return _latest_state.duplicate(true)

func get_landmark(landmark_id: int) -> Dictionary:
	var landmarks: Variant = _latest_state.get("landmarks_by_id", {})
	if landmarks is Dictionary:
		var landmark: Variant = landmarks.get(landmark_id, null)
		if landmark is Dictionary:
			return landmark
	return {}

func get_tracking_state() -> StringName:
	return StringName(_latest_state.get("tracking_state", TRACKING_LOST))

func get_velocity(body_part: StringName) -> Vector3:
	var velocities: Dictionary = _get_metric_dictionary("velocities")
	var velocity: Variant = velocities.get(String(body_part), Vector3.ZERO)
	if velocity is Vector3:
		return velocity
	return Vector3.ZERO

func get_tracking_confidence(body_part: StringName) -> float:
	var confidences: Dictionary = _get_metric_dictionary("confidences")
	return float(confidences.get(String(body_part), 0.0))

func get_measurements() -> Dictionary:
	return _get_metric_dictionary("measurements")

func _build_empty_state() -> Dictionary:
	return {
		"frame_index": 0,
		"timestamp_ms": 0,
		"tracking_state": TRACKING_LOST,
		"landmarks_by_id": {},
		"baseline": _baseline.duplicate(true),
		"metrics": {
			"tracking_state": TRACKING_LOST,
			"confidences": {},
			"velocities": {},
			"directions": {},
			"measurements": {},
			"baseline": _baseline.duplicate(true),
		},
		"events": [],
		"gesture_states": _gesture_state.get("states", {}).duplicate(true),
	}

func _build_metrics(landmarks_by_id: Dictionary, timestamp_ms: int) -> Dictionary:
	var nose := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.NOSE)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ELBOW)
	var right_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ELBOW)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	var left_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_HIP)
	var right_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_HIP)
	var left_knee := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_KNEE)
	var right_knee := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_KNEE)
	var left_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE)
	var right_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE)
	var shoulder_center := PoseMetrics.midpoint(left_shoulder, right_shoulder)
	var hip_center := PoseMetrics.midpoint(left_hip, right_hip)
	var ankle_center := PoseMetrics.midpoint(left_ankle, right_ankle)

	var shoulder_width := PoseMetrics.distance_2d(left_shoulder, right_shoulder)
	var torso_height := PoseMetrics.distance_2d(shoulder_center, hip_center)
	var athlete_height := PoseMetrics.distance_2d(nose, ankle_center)
	var left_elbow_bend := PoseMetrics.angle_degrees(left_shoulder, left_elbow, left_wrist)
	var right_elbow_bend := PoseMetrics.angle_degrees(right_shoulder, right_elbow, right_wrist)
	var left_arm_length := PoseMetrics.distance_2d(left_shoulder, left_elbow) + PoseMetrics.distance_2d(left_elbow, left_wrist)
	var right_arm_length := PoseMetrics.distance_2d(right_shoulder, right_elbow) + PoseMetrics.distance_2d(right_elbow, right_wrist)
	var left_arm_extension := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_2d(left_shoulder, left_wrist), left_arm_length))
	var right_arm_extension := PoseMetrics.clamp01(PoseMetrics.normalized_ratio(PoseMetrics.distance_2d(right_shoulder, right_wrist), right_arm_length))

	var confidences := {
		"head": PoseMetrics.visibility(nose),
		"left_hand": PoseMetrics.visibility(left_wrist),
		"right_hand": PoseMetrics.visibility(right_wrist),
		"left_foot": PoseMetrics.visibility(left_ankle),
		"right_foot": PoseMetrics.visibility(right_ankle),
		"torso": PoseMetrics.average_visibility(landmarks_by_id, [PoseLandmarkIds.LEFT_SHOULDER, PoseLandmarkIds.RIGHT_SHOULDER, PoseLandmarkIds.LEFT_HIP, PoseLandmarkIds.RIGHT_HIP]),
	}
	var velocities := _compute_velocities(timestamp_ms, {
		"head": nose,
		"left_hand": left_wrist,
		"right_hand": right_wrist,
		"left_foot": left_ankle,
		"right_foot": right_ankle,
	})
	var directions := {
		"left_hand": _direction_from_velocity(velocities.get("left_hand", Vector3.ZERO)),
		"right_hand": _direction_from_velocity(velocities.get("right_hand", Vector3.ZERO)),
		"left_foot": _direction_from_velocity(velocities.get("left_foot", Vector3.ZERO)),
		"right_foot": _direction_from_velocity(velocities.get("right_foot", Vector3.ZERO)),
	}

	var shoulder_center_vec := PoseMetrics.to_vector3(shoulder_center)
	var hip_center_vec := PoseMetrics.to_vector3(hip_center)
	var nose_vec := PoseMetrics.to_vector3(nose)
	var body_centerline_x := _average_x([nose, shoulder_center, hip_center])
	var head_lateral_offset := 0.0
	var hip_lateral_offset := 0.0
	var shoulder_lateral_offset := 0.0
	var lateral_offset := 0.0
	var height_ratio := 1.0
	var height_state: StringName = StringName("unknown")
	var squat_depth := 0.0
	var head_drop_ratio := 0.0
	var left_knee_rise := 0.0
	var right_knee_rise := 0.0
	var left_foot_rise := 0.0
	var right_foot_rise := 0.0

	if bool(_baseline.get("is_calibrated", false)):
		var baseline_shoulder_width := maxf(float(_baseline.get("shoulder_width", 0.0)), 0.000001)
		var baseline_torso_height := maxf(float(_baseline.get("torso_height", 0.0)), 0.000001)
		var baseline_shoulder_x := float(_baseline.get("shoulder_center_x", body_centerline_x))
		var baseline_hip_y := float(_baseline.get("hip_center_y", hip_center_vec.y))
		var baseline_nose_y := float(_baseline.get("nose_y", nose_vec.y))
		lateral_offset = PoseMetrics.normalized_ratio(body_centerline_x - baseline_shoulder_x, baseline_shoulder_width)
		head_lateral_offset = PoseMetrics.normalized_ratio(nose_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		hip_lateral_offset = PoseMetrics.normalized_ratio(hip_center_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		shoulder_lateral_offset = PoseMetrics.normalized_ratio(shoulder_center_vec.x - baseline_shoulder_x, baseline_shoulder_width)
		height_ratio = PoseMetrics.normalized_ratio(torso_height, baseline_torso_height)
		height_state = _estimate_height_state(height_ratio, hip_center_vec.y - baseline_hip_y)
		squat_depth = maxf(0.0, 1.0 - height_ratio)
		head_drop_ratio = maxf(0.0, (baseline_nose_y - nose_vec.y) / baseline_torso_height)
		left_knee_rise = maxf(0.0, (float(left_knee.get("y", 0.0)) - float(_baseline.get("left_knee_y", left_knee.get("y", 0.0)))) / baseline_torso_height)
		right_knee_rise = maxf(0.0, (float(right_knee.get("y", 0.0)) - float(_baseline.get("right_knee_y", right_knee.get("y", 0.0)))) / baseline_torso_height)
		left_foot_rise = maxf(0.0, (float(left_ankle.get("y", 0.0)) - float(_baseline.get("left_ankle_y", left_ankle.get("y", 0.0)))) / baseline_torso_height)
		right_foot_rise = maxf(0.0, (float(right_ankle.get("y", 0.0)) - float(_baseline.get("right_ankle_y", right_ankle.get("y", 0.0)))) / baseline_torso_height)

	var measurements := {
		"shoulder_width": shoulder_width,
		"torso_height": torso_height,
		"athlete_height": athlete_height,
		"normalized_shoulder_width": PoseMetrics.normalized_ratio(shoulder_width, maxf(_baseline.get("shoulder_width", shoulder_width), 0.000001)),
		"normalized_torso_height": PoseMetrics.normalized_ratio(torso_height, maxf(_baseline.get("torso_height", torso_height), 0.000001)),
		"left_elbow_bend_deg": left_elbow_bend,
		"right_elbow_bend_deg": right_elbow_bend,
		"left_arm_extension": left_arm_extension,
		"right_arm_extension": right_arm_extension,
		"head_center": nose_vec,
		"shoulder_center": shoulder_center_vec,
		"hip_center": hip_center_vec,
		"body_centerline_x": body_centerline_x,
		"lateral_offset": lateral_offset,
		"head_lateral_offset": head_lateral_offset,
		"shoulder_lateral_offset": shoulder_lateral_offset,
		"hip_lateral_offset": hip_lateral_offset,
		"height_ratio": height_ratio,
		"height_state": height_state,
		"squat_depth": squat_depth,
		"head_drop_ratio": head_drop_ratio,
		"left_knee_rise": left_knee_rise,
		"right_knee_rise": right_knee_rise,
		"left_foot_rise": left_foot_rise,
		"right_foot_rise": right_foot_rise,
		"left_leg_angle_from_core_deg": _leg_angle_from_core_deg(left_hip, left_ankle),
		"right_leg_angle_from_core_deg": _leg_angle_from_core_deg(right_hip, right_ankle),
	}

	return {
		"confidences": confidences,
		"velocities": velocities,
		"directions": directions,
		"measurements": measurements,
	}

func _compute_velocities(timestamp_ms: int, tracked_landmarks: Dictionary) -> Dictionary:
	var velocities: Dictionary = {}
	for body_part_variant: Variant in tracked_landmarks.keys():
		var body_part: String = String(body_part_variant)
		var landmark_variant: Variant = tracked_landmarks[body_part_variant]
		if not landmark_variant is Dictionary or landmark_variant.is_empty():
			velocities[body_part] = Vector3.ZERO
			continue
		var landmark: Dictionary = landmark_variant
		var current_position := PoseMetrics.to_vector3(landmark)
		var previous: Variant = _previous_positions.get(body_part, null)
		if previous is Dictionary and _last_processed_timestamp_ms > 0:
			var dt_ms: int = maxi(timestamp_ms - _last_processed_timestamp_ms, 1)
			var previous_position: Vector3 = previous.get("position", current_position)
			velocities[body_part] = (current_position - previous_position) / (float(dt_ms) / 1000.0)
		else:
			velocities[body_part] = Vector3.ZERO
		_previous_positions[body_part] = {
			"position": current_position,
			"timestamp_ms": timestamp_ms,
		}
	return velocities

func _direction_from_velocity(velocity_variant: Variant) -> Vector2:
	if not velocity_variant is Vector3:
		return Vector2.ZERO
	var planar := Vector2(velocity_variant.x, velocity_variant.y)
	if planar.length() <= 0.000001:
		return Vector2.ZERO
	return planar.normalized()

func _update_tracking_state(landmarks_by_id: Dictionary) -> StringName:
	var min_visibility := _get_min_visibility()
	var confidence_gate := _get_tracking_confidence_gate()
	var visible_key_count := PoseMetrics.count_visible(landmarks_by_id, PoseLandmarkIds.TRACKING_KEY_LANDMARKS, min_visibility)
	var average_visibility := PoseMetrics.average_visibility(landmarks_by_id, PoseLandmarkIds.TRACKING_KEY_LANDMARKS)
	var valid_frame := visible_key_count >= 5 and average_visibility >= confidence_gate
	if valid_frame:
		_consecutive_valid_frames += 1
		_consecutive_invalid_frames = 0
		if _reacquire_frames_remaining > 0:
			_reacquire_frames_remaining -= 1
			if _reacquire_frames_remaining <= 0:
				return TRACKING_TRACKING
			return TRACKING_REACQUIRING
		return TRACKING_TRACKING

	_consecutive_invalid_frames += 1
	_consecutive_valid_frames = 0
	_reacquire_frames_remaining = _get_reacquire_window_frames()
	if _consecutive_invalid_frames >= 3:
		return TRACKING_LOST
	return TRACKING_DEGRADED

func _update_baseline(metrics: Dictionary, tracking_state: StringName, landmarks_by_id: Dictionary) -> void:
	if tracking_state != TRACKING_TRACKING and tracking_state != TRACKING_REACQUIRING:
		return
	var measurements: Dictionary = metrics.get("measurements", {})
	if measurements.is_empty():
		return
	var shoulder_width := float(measurements.get("shoulder_width", 0.0))
	var torso_height := float(measurements.get("torso_height", 0.0))
	var athlete_height := float(measurements.get("athlete_height", 0.0))
	if shoulder_width <= 0.0 or torso_height <= 0.0:
		return
	_baseline_accumulator["frames"] += 1
	_baseline_accumulator["shoulder_width"] += shoulder_width
	_baseline_accumulator["torso_height"] += torso_height
	_baseline_accumulator["athlete_height"] += athlete_height
	_baseline_accumulator["shoulder_center_x"] += float(measurements.get("body_centerline_x", 0.0))
	var hip_center: Variant = measurements.get("hip_center", Vector3.ZERO)
	if hip_center is Vector3:
		_baseline_accumulator["hip_center_y"] += hip_center.y
	var head_center: Variant = measurements.get("head_center", Vector3.ZERO)
	if head_center is Vector3:
		_baseline_accumulator["nose_y"] += head_center.y
	_baseline_accumulator["left_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_KNEE).get("y", 0.0))
	_baseline_accumulator["right_knee_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_KNEE).get("y", 0.0))
	_baseline_accumulator["left_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE).get("y", 0.0))
	_baseline_accumulator["right_ankle_y"] += float(PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE).get("y", 0.0))
	var frames: int = int(_baseline_accumulator["frames"])
	if frames < 5:
		return
	_baseline = {
		"is_calibrated": true,
		"sample_frames": frames,
		"shoulder_width": float(_baseline_accumulator["shoulder_width"]) / float(frames),
		"torso_height": float(_baseline_accumulator["torso_height"]) / float(frames),
		"athlete_height": float(_baseline_accumulator["athlete_height"]) / float(frames),
		"shoulder_center_x": float(_baseline_accumulator["shoulder_center_x"]) / float(frames),
		"hip_center_y": float(_baseline_accumulator["hip_center_y"]) / float(frames),
		"nose_y": float(_baseline_accumulator["nose_y"]) / float(frames),
		"left_knee_y": float(_baseline_accumulator["left_knee_y"]) / float(frames),
		"right_knee_y": float(_baseline_accumulator["right_knee_y"]) / float(frames),
		"left_ankle_y": float(_baseline_accumulator["left_ankle_y"]) / float(frames),
		"right_ankle_y": float(_baseline_accumulator["right_ankle_y"]) / float(frames),
	}

func _estimate_height_state(height_ratio: float, hip_center_delta_y: float) -> StringName:
	if height_ratio <= 0.82 or hip_center_delta_y > 0.05:
		return &"lowered"
	if height_ratio >= 0.95:
		return &"standing"
	return &"transition"

func _average_x(points: Array) -> float:
	var total := 0.0
	var count := 0
	for point_variant: Variant in points:
		if not point_variant is Dictionary or point_variant.is_empty():
			continue
		total += float(point_variant.get("x", 0.0))
		count += 1
	if count == 0:
		return 0.0
	return total / float(count)

func _get_metric_dictionary(key: String) -> Dictionary:
	var metrics: Variant = _latest_state.get("metrics", {})
	if metrics is Dictionary:
		var value: Variant = metrics.get(key, {})
		if value is Dictionary:
			return value
	return {}

func _get_smoothing_window_size() -> int:
	if _config == null:
		return 4
	var smoothing_factor := clampf(float(_config.smoothing_factor), 0.0, 1.0)
	return maxi(int(round(1.0 + smoothing_factor * 4.0)), 1)

func _get_min_visibility() -> float:
	if _config == null:
		return 0.5
	return float(_config.min_visibility)

func _get_tracking_confidence_gate() -> float:
	if _config == null:
		return 0.5
	return float(_config.tracking_confidence)

func _get_tracking_timeout_ms() -> int:
	return 500

func _get_reacquire_window_frames() -> int:
	return 2

func _reset_gesture_state() -> void:
	_gesture_state = {
		"states": {
			"guard": false,
			"squat": false,
			"lean_left": false,
			"lean_right": false,
			"sidestep_left": false,
			"sidestep_right": false,
			"leg_lift_left": false,
			"leg_lift_right": false,
			"trail_left": false,
			"trail_right": false,
		},
		"ready": {
			"punch_left": true,
			"punch_right": true,
			"hook_left": true,
			"hook_right": true,
			"uppercut_left": true,
			"uppercut_right": true,
			"knee_left": true,
			"knee_right": true,
			"swing_left": true,
			"swing_right": true,
		},
		"flow": {
			"left_hand": [],
			"right_hand": [],
			"trail_left": {"last_emit_ms": 0},
			"trail_right": {"last_emit_ms": 0},
		},
	}

func _clear_transient_gesture_state() -> void:
	_reset_gesture_state()

func _detect_intent_events(landmarks_by_id: Dictionary, metrics: Dictionary, timestamp_ms: int) -> Array:
	var events: Array = []
	var measurements: Dictionary = metrics.get("measurements", {})
	if not bool(_baseline.get("is_calibrated", false)):
		return events
	var shoulder_width := maxf(float(measurements.get("shoulder_width", float(_baseline.get("shoulder_width", 0.0)))), 0.000001)
	var torso_height := maxf(float(measurements.get("torso_height", float(_baseline.get("torso_height", 0.0)))), 0.000001)
	var left_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_SHOULDER)
	var right_shoulder := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_SHOULDER)
	var left_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ELBOW)
	var right_elbow := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ELBOW)
	var left_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_WRIST)
	var right_wrist := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_WRIST)
	var left_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_HIP)
	var right_hip := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_HIP)
	var left_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.LEFT_ANKLE)
	var right_ankle := PoseMetrics.get_landmark(landmarks_by_id, PoseLandmarkIds.RIGHT_ANKLE)
	var velocities: Dictionary = metrics.get("velocities", {})
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	var right_hand_velocity: Vector3 = velocities.get("right_hand", Vector3.ZERO)
	_update_flow_hand_history("left", left_wrist, float(metrics.get("confidences", {}).get("left_hand", 0.0)), timestamp_ms)
	_update_flow_hand_history("right", right_wrist, float(metrics.get("confidences", {}).get("right_hand", 0.0)), timestamp_ms)

	_process_guard(events, left_shoulder, right_shoulder, left_elbow, right_elbow, left_wrist, right_wrist, shoulder_width)
	_process_squat(events, float(measurements.get("height_ratio", 1.0)))
	_process_lean(events, float(measurements.get("head_lateral_offset", 0.0)), float(measurements.get("hip_lateral_offset", 0.0)), float(measurements.get("head_drop_ratio", 0.0)))
	_process_sidestep(events, float(measurements.get("lateral_offset", 0.0)), float(measurements.get("head_lateral_offset", 0.0)), float(measurements.get("hip_lateral_offset", 0.0)))
	_process_knee(events, "left", float(measurements.get("left_knee_rise", 0.0)), float(measurements.get("left_foot_rise", 0.0)), float(measurements.get("right_knee_rise", 0.0)), left_hip, left_ankle, torso_height)
	_process_knee(events, "right", float(measurements.get("right_knee_rise", 0.0)), float(measurements.get("right_foot_rise", 0.0)), float(measurements.get("left_knee_rise", 0.0)), right_hip, right_ankle, torso_height)
	_process_leg_lift(events, "left", float(measurements.get("left_leg_angle_from_core_deg", 0.0)), left_hip, left_ankle, torso_height)
	_process_leg_lift(events, "right", float(measurements.get("right_leg_angle_from_core_deg", 0.0)), right_hip, right_ankle, torso_height)
	if not _get_state("guard"):
		_process_straight_punch(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), float(measurements.get("left_arm_extension", 0.0)), left_hand_velocity, shoulder_width)
		_process_straight_punch(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), float(measurements.get("right_arm_extension", 0.0)), right_hand_velocity, shoulder_width)
		_process_hook(events, "left", left_shoulder, left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), left_hand_velocity, shoulder_width)
		_process_hook(events, "right", right_shoulder, right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), right_hand_velocity, shoulder_width)
		_process_uppercut(events, "left", left_elbow, left_wrist, float(measurements.get("left_elbow_bend_deg", 0.0)), left_hand_velocity, shoulder_width)
		_process_uppercut(events, "right", right_elbow, right_wrist, float(measurements.get("right_elbow_bend_deg", 0.0)), right_hand_velocity, shoulder_width)
	if not _has_any_event(events, ["punch_left", "hook_left", "uppercut_left"]):
		_process_flow_trail(events, "left", left_hand_velocity, shoulder_width, timestamp_ms)
		_process_flow_swing(events, "left", left_hand_velocity, shoulder_width, timestamp_ms)
	if not _has_any_event(events, ["punch_right", "hook_right", "uppercut_right"]):
		_process_flow_trail(events, "right", right_hand_velocity, shoulder_width, timestamp_ms)
		_process_flow_swing(events, "right", right_hand_velocity, shoulder_width, timestamp_ms)
	return events

func _process_straight_punch(events: Array, side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, arm_extension: float, hand_velocity: Vector3, shoulder_width: float) -> void:
	var event_name := "punch_%s" % side
	if arm_extension <= PUNCH_READY_EXTENSION:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if shoulder.is_empty() or elbow.is_empty() or wrist.is_empty():
		return
	var outward_velocity := hand_velocity.x if side == "right" else -hand_velocity.x
	var lateral_speed := absf(hand_velocity.x)
	var vertical_speed := absf(hand_velocity.y)
	var outward_distance: float = float(shoulder.get("x", 0.0) - wrist.get("x", 0.0) if side == "left" else wrist.get("x", 0.0) - shoulder.get("x", 0.0))
	if arm_extension < PUNCH_FIRE_EXTENSION:
		return
	if elbow_bend_deg < PUNCH_ELBOW_STRAIGHT_MIN_DEG:
		return
	if outward_velocity <= shoulder_width * 1.35:
		return
	if lateral_speed <= vertical_speed * PUNCH_LATERAL_VELOCITY_RATIO:
		return
	if float(outward_distance) <= shoulder_width * 0.75:
		return
	_emit_power_event(events, event_name, clampf(0.55 + (arm_extension - PUNCH_FIRE_EXTENSION) * 2.5 + outward_velocity / maxf(shoulder_width * 6.0, 0.000001), 0.0, 1.0))
	_set_ready(event_name, false)

func _process_hook(events: Array, side: String, shoulder: Dictionary, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, hand_velocity: Vector3, shoulder_width: float) -> void:
	var event_name := "hook_%s" % side
	if absf(hand_velocity.x) <= shoulder_width * 1.10:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if shoulder.is_empty() or elbow.is_empty() or wrist.is_empty():
		return
	var outward_velocity := hand_velocity.x if side == "right" else -hand_velocity.x
	var lateral_speed := absf(hand_velocity.x)
	var vertical_speed := absf(hand_velocity.y)
	if elbow_bend_deg < HOOK_ELBOW_MIN_DEG or elbow_bend_deg > HOOK_ELBOW_MAX_DEG:
		return
	if absf(float(wrist.get("y", 0.0)) - float(elbow.get("y", 0.0))) > shoulder_width * 0.40:
		return
	if outward_velocity <= shoulder_width * 1.50:
		return
	if lateral_speed <= vertical_speed * 1.6:
		return
	var outward_distance: float = float(shoulder.get("x", 0.0) - wrist.get("x", 0.0) if side == "left" else wrist.get("x", 0.0) - shoulder.get("x", 0.0))
	if float(outward_distance) <= shoulder_width * 0.45:
		return
	_emit_power_event(events, event_name, clampf(0.45 + outward_velocity / maxf(shoulder_width * 5.5, 0.000001), 0.0, 1.0))
	_set_ready(event_name, false)

func _process_uppercut(events: Array, side: String, elbow: Dictionary, wrist: Dictionary, elbow_bend_deg: float, hand_velocity: Vector3, shoulder_width: float) -> void:
	var event_name := "uppercut_%s" % side
	if absf(hand_velocity.y) <= shoulder_width * 1.10:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if elbow.is_empty() or wrist.is_empty():
		return
	if elbow_bend_deg < UPPERCUT_ELBOW_MIN_DEG or elbow_bend_deg > UPPERCUT_ELBOW_MAX_DEG:
		return
	if absf(float(wrist.get("x", 0.0)) - float(elbow.get("x", 0.0))) > shoulder_width * 0.28:
		return
	if hand_velocity.y <= shoulder_width * 1.40:
		return
	if absf(hand_velocity.y) <= absf(hand_velocity.x) * 1.2:
		return
	_emit_power_event(events, event_name, clampf(0.45 + hand_velocity.y / maxf(shoulder_width * 5.0, 0.000001), 0.0, 1.0))
	_set_ready(event_name, false)

func _process_flow_swing(events: Array, side: String, hand_velocity: Vector3, shoulder_width: float, timestamp_ms: int) -> void:
	var event_name := "swing_%s" % side
	if hand_velocity.length() <= shoulder_width * 0.90:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if _get_state("trail_%s" % side):
		return
	var analysis := _analyze_flow_motion(side, shoulder_width, FLOW_SWING_WINDOW_MAX_MS)
	if analysis.is_empty():
		return
	var duration_ms := int(analysis.get("duration_ms", 0))
	if duration_ms < FLOW_SWING_WINDOW_MIN_MS or duration_ms > FLOW_SWING_WINDOW_MAX_MS:
		return
	if float(analysis.get("avg_confidence", 0.0)) < 0.62:
		return
	if float(analysis.get("arc_length", 0.0)) < shoulder_width * FLOW_SWING_MIN_ARC_RATIO:
		return
	if float(analysis.get("net_distance", 0.0)) < shoulder_width * FLOW_SWING_MIN_TRAVEL_RATIO:
		return
	if float(analysis.get("directional_consistency", 0.0)) < 0.52:
		return
	if hand_velocity.length() < shoulder_width * FLOW_SWING_MIN_SPEED_RATIO:
		return
	var direction := StringName(analysis.get("direction", StringName()))
	if direction == StringName():
		return
	_emit_flow_event(events, event_name, StringName(analysis.get("placement", &"center")), direction)
	_set_ready(event_name, false)

func _process_flow_trail(events: Array, side: String, hand_velocity: Vector3, shoulder_width: float, timestamp_ms: int) -> void:
	var state_name := "trail_%s" % side
	var trail_meta: Dictionary = _get_flow_meta(state_name)
	var analysis := _analyze_flow_motion(side, shoulder_width, FLOW_HISTORY_MAX_MS)
	var active := _get_state(state_name)
	if analysis.is_empty():
		if active:
			_gesture_state["states"][state_name] = false
		return
	var sustained := int(analysis.get("duration_ms", 0)) >= FLOW_TRAIL_WINDOW_MIN_MS
	sustained = sustained and float(analysis.get("avg_confidence", 0.0)) >= 0.60
	sustained = sustained and float(analysis.get("arc_length", 0.0)) >= shoulder_width * FLOW_TRAIL_MIN_ARC_RATIO
	sustained = sustained and float(analysis.get("net_distance", 0.0)) >= shoulder_width * FLOW_TRAIL_MIN_TRAVEL_RATIO
	sustained = sustained and float(analysis.get("directional_consistency", 0.0)) >= 0.76
	sustained = sustained and float(analysis.get("lane_spread", 0.0)) <= shoulder_width * 0.82
	sustained = sustained and hand_velocity.length() >= shoulder_width * FLOW_TRAIL_MIN_SPEED_RATIO
	if not sustained:
		if active and (hand_velocity.length() <= shoulder_width * 0.75 or float(analysis.get("directional_consistency", 0.0)) < 0.55):
			_gesture_state["states"][state_name] = false
		return
	var direction := StringName(analysis.get("direction", StringName()))
	if direction == StringName():
		return
	if not active:
		_gesture_state["states"][state_name] = true
	var last_emit_ms := int(trail_meta.get("last_emit_ms", 0))
	if active and timestamp_ms - last_emit_ms < FLOW_TRAIL_EMIT_INTERVAL_MS and StringName(trail_meta.get("direction", StringName())) == direction and StringName(trail_meta.get("placement", StringName())) == StringName(analysis.get("placement", &"center")):
		return
	trail_meta["last_emit_ms"] = timestamp_ms
	trail_meta["placement"] = StringName(analysis.get("placement", &"center"))
	trail_meta["direction"] = direction
	_set_flow_meta(state_name, trail_meta)
	_emit_flow_event(events, state_name, StringName(analysis.get("placement", &"center")), direction)

func _update_flow_hand_history(side: String, wrist: Dictionary, confidence: float, timestamp_ms: int) -> void:
	var history_name := "%s_hand" % side
	var history: Array = _get_flow_history(history_name)
	if wrist.is_empty() or confidence < 0.35:
		history.clear()
		_set_flow_history(history_name, history)
		return
	history.append({
		"timestamp_ms": timestamp_ms,
		"position": PoseMetrics.to_vector2(wrist),
		"confidence": confidence,
	})
	while history.size() > 0 and timestamp_ms - int(history[0].get("timestamp_ms", timestamp_ms)) > FLOW_HISTORY_MAX_MS:
		history.remove_at(0)
	_set_flow_history(history_name, history)

func _analyze_flow_motion(side: String, shoulder_width: float, max_window_ms: int) -> Dictionary:
	var history: Array = _get_flow_history("%s_hand" % side)
	if history.size() < 3:
		return {}
	var latest_timestamp := int(history[history.size() - 1].get("timestamp_ms", 0))
	var samples: Array = []
	for sample_variant: Variant in history:
		if not sample_variant is Dictionary:
			continue
		var sample: Dictionary = sample_variant
		if latest_timestamp - int(sample.get("timestamp_ms", latest_timestamp)) <= max_window_ms:
			samples.append(sample)
	if samples.size() < 3:
		return {}
	var first: Dictionary = samples[0]
	var last: Dictionary = samples[samples.size() - 1]
	var first_pos: Vector2 = first.get("position", Vector2.ZERO)
	var last_pos: Vector2 = last.get("position", Vector2.ZERO)
	var arc_length := 0.0
	var confidence_total := 0.0
	var direction_sum := Vector2.ZERO
	var min_x := first_pos.x
	var max_x := first_pos.x
	var avg_x_total := 0.0
	for idx in range(samples.size()):
		var sample: Dictionary = samples[idx]
		var position: Vector2 = sample.get("position", Vector2.ZERO)
		confidence_total += float(sample.get("confidence", 0.0))
		avg_x_total += position.x
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
		if idx == 0:
			continue
		var previous: Dictionary = samples[idx - 1]
		var previous_position: Vector2 = previous.get("position", Vector2.ZERO)
		var delta := position - previous_position
		var segment_length := delta.length()
		arc_length += segment_length
		if segment_length > 0.000001:
			direction_sum += delta.normalized() * segment_length
	var net_delta := last_pos - first_pos
	var direction_name := _flow_direction_name(net_delta)
	if direction_name == StringName():
		return {}
	return {
		"duration_ms": maxi(int(last.get("timestamp_ms", 0)) - int(first.get("timestamp_ms", 0)), 0),
		"arc_length": arc_length,
		"net_distance": net_delta.length(),
		"net_delta": net_delta,
		"avg_confidence": confidence_total / float(samples.size()),
		"directional_consistency": direction_sum.length() / maxf(arc_length, 0.000001),
		"placement": _flow_placement_name(avg_x_total / float(samples.size()), shoulder_width),
		"direction": direction_name,
		"lane_spread": max_x - min_x,
	}

func _flow_direction_name(net_delta: Vector2) -> StringName:
	if net_delta.length() <= 0.000001:
		return StringName()
	if absf(net_delta.x) >= absf(net_delta.y):
		return &"right" if net_delta.x > 0.0 else &"left"
	return &"up" if net_delta.y > 0.0 else &"down"

func _flow_placement_name(avg_x: float, shoulder_width: float) -> StringName:
	var center_x := float(_baseline.get("shoulder_center_x", avg_x))
	var offset := PoseMetrics.normalized_ratio(avg_x - center_x, maxf(shoulder_width, 0.000001))
	if offset <= -FLOW_PLACEMENT_SIDE_THRESHOLD:
		return &"left"
	if offset >= FLOW_PLACEMENT_SIDE_THRESHOLD:
		return &"right"
	return &"center"

func _emit_flow_event(events: Array, event_name: String, placement: StringName, direction: StringName) -> void:
	events.append({
		"name": StringName(event_name),
		"placement": placement,
		"direction": direction,
	})

func _has_any_event(events: Array, event_names: Array) -> bool:
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event_name := String(event_variant.get("name", ""))
		if event_names.has(event_name):
			return true
	return false

func _get_flow_history(history_name: String) -> Array:
	return (_gesture_state.get("flow", {}).get(history_name, []) as Array).duplicate(true)

func _set_flow_history(history_name: String, history: Array) -> void:
	var flow: Dictionary = _gesture_state.get("flow", {})
	flow[history_name] = history
	_gesture_state["flow"] = flow

func _get_flow_meta(state_name: String) -> Dictionary:
	return (_gesture_state.get("flow", {}).get(state_name, {}) as Dictionary).duplicate(true)

func _set_flow_meta(state_name: String, data: Dictionary) -> void:
	var flow: Dictionary = _gesture_state.get("flow", {})
	flow[state_name] = data
	_gesture_state["flow"] = flow

func _process_guard(events: Array, left_shoulder: Dictionary, right_shoulder: Dictionary, left_elbow: Dictionary, right_elbow: Dictionary, left_wrist: Dictionary, right_wrist: Dictionary, shoulder_width: float) -> void:
	if left_shoulder.is_empty() or right_shoulder.is_empty() or left_elbow.is_empty() or right_elbow.is_empty() or left_wrist.is_empty() or right_wrist.is_empty():
		_set_state_toggle(events, "guard", false)
		return
	var aligned := absf(float(left_wrist.get("x", 0.0)) - float(left_elbow.get("x", 0.0))) <= shoulder_width * 0.32
	aligned = aligned and absf(float(right_wrist.get("x", 0.0)) - float(right_elbow.get("x", 0.0))) <= shoulder_width * 0.32
	var raised := float(left_wrist.get("y", 0.0)) >= float(left_shoulder.get("y", 0.0)) - shoulder_width * 0.10
	raised = raised and float(right_wrist.get("y", 0.0)) >= float(right_shoulder.get("y", 0.0)) - shoulder_width * 0.10
	var wrist_near_head := absf(float(left_wrist.get("x", 0.0)) - float(left_shoulder.get("x", 0.0))) <= shoulder_width * 0.55
	wrist_near_head = wrist_near_head and absf(float(right_wrist.get("x", 0.0)) - float(right_shoulder.get("x", 0.0))) <= shoulder_width * 0.55
	_set_state_toggle(events, "guard", aligned and raised and wrist_near_head)

func _process_squat(events: Array, height_ratio: float) -> void:
	var active: bool = _get_state("squat")
	if not active and height_ratio <= 0.82:
		_set_state_toggle(events, "squat", true)
	elif active and height_ratio >= 0.92:
		_set_state_toggle(events, "squat", false)

func _process_lean(events: Array, head_offset: float, hip_offset: float, head_drop_ratio: float) -> void:
	var relative_offset := head_offset - hip_offset
	var leaning_left := head_offset <= -0.30 and relative_offset <= -0.12 and head_drop_ratio >= 0.05
	var leaning_right := head_offset >= 0.30 and relative_offset >= 0.12 and head_drop_ratio >= 0.05
	var neutral := absf(head_offset) <= 0.12 and absf(relative_offset) <= 0.08
	if leaning_left:
		_set_state_toggle(events, "lean_right", false)
		_set_state_toggle(events, "lean_left", true)
	elif leaning_right:
		_set_state_toggle(events, "lean_left", false)
		_set_state_toggle(events, "lean_right", true)
	elif neutral:
		_set_state_toggle(events, "lean_left", false)
		_set_state_toggle(events, "lean_right", false)

func _process_sidestep(events: Array, lateral_offset: float, head_offset: float, hip_offset: float) -> void:
	var body_aligned := absf(head_offset - hip_offset) <= 0.18
	if lateral_offset <= -0.45 and body_aligned:
		_set_state_toggle(events, "sidestep_right", false)
		_set_state_toggle(events, "sidestep_left", true)
	elif lateral_offset >= 0.45 and body_aligned:
		_set_state_toggle(events, "sidestep_left", false)
		_set_state_toggle(events, "sidestep_right", true)
	elif absf(lateral_offset) <= 0.14:
		_set_state_toggle(events, "sidestep_left", false)
		_set_state_toggle(events, "sidestep_right", false)

func _process_knee(events: Array, side: String, knee_rise: float, foot_rise: float, opposite_knee_rise: float, hip: Dictionary, ankle: Dictionary, torso_height: float) -> void:
	var event_name := "knee_%s" % side
	var lateral_offset := 0.0
	if not hip.is_empty() and not ankle.is_empty() and torso_height > 0.0:
		lateral_offset = absf(float(ankle.get("x", 0.0)) - float(hip.get("x", 0.0))) / torso_height
	var foot_fallback := foot_rise * 0.85 if lateral_offset <= 0.30 else 0.0
	var rise := maxf(knee_rise, foot_fallback)
	if rise <= 0.10:
		_set_ready(event_name, true)
	if not _is_ready(event_name):
		return
	if opposite_knee_rise >= 0.18 and absf(knee_rise - opposite_knee_rise) <= 0.08:
		return
	if rise < 0.22:
		return
	_emit_power_event(events, event_name, clampf((rise - 0.22) / 0.25 + 0.45, 0.0, 1.0))
	_set_ready(event_name, false)

func _process_leg_lift(events: Array, side: String, leg_angle_from_core_deg: float, hip: Dictionary, ankle: Dictionary, torso_height: float) -> void:
	var state_name := "leg_lift_%s" % side
	if hip.is_empty() or ankle.is_empty() or torso_height <= 0.0:
		_set_state_toggle(events, state_name, false)
		return
	var ankle_raise := maxf(0.0, (float(ankle.get("y", 0.0)) - float(hip.get("y", 0.0))) / torso_height + 1.0)
	var should_start := leg_angle_from_core_deg >= 32.0 and ankle_raise >= 0.32
	var should_end := leg_angle_from_core_deg <= 18.0 or ankle_raise <= 0.18
	if not _get_state(state_name) and should_start:
		_set_state_toggle(events, state_name, true)
	elif _get_state(state_name) and should_end:
		_set_state_toggle(events, state_name, false)

func _set_state_toggle(events: Array, state_name: String, active: bool) -> void:
	if _get_state(state_name) == active:
		return
	_gesture_state["states"][state_name] = active
	var suffix := "start" if active else "end"
	events.append({"name": StringName("%s_%s" % [state_name, suffix])})

func _emit_power_event(events: Array, event_name: String, power: float) -> void:
	events.append({
		"name": StringName(event_name),
		"power": clampf(power, 0.0, 1.0),
	})

func _get_state(state_name: String) -> bool:
	return bool(_gesture_state.get("states", {}).get(state_name, false))

func _set_ready(event_name: String, ready: bool) -> void:
	var ready_map: Dictionary = _gesture_state.get("ready", {})
	ready_map[event_name] = ready
	_gesture_state["ready"] = ready_map

func _is_ready(event_name: String) -> bool:
	return bool(_gesture_state.get("ready", {}).get(event_name, true))

func _leg_angle_from_core_deg(hip: Dictionary, ankle: Dictionary) -> float:
	if hip.is_empty() or ankle.is_empty():
		return 0.0
	var vector := PoseMetrics.to_vector2(ankle) - PoseMetrics.to_vector2(hip)
	if vector.length() <= 0.000001:
		return 0.0
	return absf(rad_to_deg(vector.angle_to(Vector2.UP)))
