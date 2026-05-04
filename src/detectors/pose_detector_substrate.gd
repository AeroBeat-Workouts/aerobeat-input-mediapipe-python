class_name PoseDetectorSubstrate
extends RefCounted

const PoseLandmarkIds = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_landmark_ids.gd")
const LandmarkSmoother = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/landmark_smoother.gd")
const PoseMetrics = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_metrics.gd")

const TRACKING_TRACKING := &"tracking"
const TRACKING_DEGRADED := &"degraded"
const TRACKING_LOST := &"lost"
const TRACKING_REACQUIRING := &"reacquiring"

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
}
var _baseline: Dictionary = {
	"is_calibrated": false,
	"sample_frames": 0,
	"shoulder_width": 0.0,
	"torso_height": 0.0,
	"athlete_height": 0.0,
	"shoulder_center_x": 0.0,
	"hip_center_y": 0.0,
}
var _previous_positions: Dictionary = {}
var _consecutive_valid_frames := 0
var _consecutive_invalid_frames := 0
var _reacquire_frames_remaining := 0
var _last_processed_timestamp_ms := 0
var _frame_index := 0

func _init() -> void:
	_smoother = LandmarkSmoother.new(_get_smoothing_window_size())
	_latest_state = _build_empty_state()

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
	}
	_baseline = {
		"is_calibrated": false,
		"sample_frames": 0,
		"shoulder_width": 0.0,
		"torso_height": 0.0,
		"athlete_height": 0.0,
		"shoulder_center_x": 0.0,
		"hip_center_y": 0.0,
	}
	_latest_state = _build_empty_state()

func process_landmarks(landmarks: Array, timestamp_ms: int = 0) -> Dictionary:
	if timestamp_ms <= 0:
		timestamp_ms = Time.get_ticks_msec()
	_frame_index += 1
	var smoothed_landmarks: Dictionary = _smoother.push_landmarks(landmarks)
	var metrics: Dictionary = _build_metrics(smoothed_landmarks, timestamp_ms)
	var tracking_state: StringName = _update_tracking_state(smoothed_landmarks)
	_update_baseline(metrics, tracking_state)
	metrics["tracking_state"] = tracking_state
	metrics["baseline"] = _baseline.duplicate(true)
	_latest_state = {
		"frame_index": _frame_index,
		"timestamp_ms": timestamp_ms,
		"tracking_state": tracking_state,
		"landmarks_by_id": smoothed_landmarks.duplicate(true),
		"baseline": _baseline.duplicate(true),
		"metrics": metrics,
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
	if _latest_state.is_empty():
		_latest_state = _build_empty_state()
	_latest_state["tracking_state"] = TRACKING_LOST
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
		"head_center": PoseMetrics.to_vector3(nose),
		"shoulder_center": PoseMetrics.to_vector3(shoulder_center),
		"hip_center": PoseMetrics.to_vector3(hip_center),
		"body_centerline_x": _average_x([nose, shoulder_center, hip_center]),
		"lateral_offset": 0.0,
		"height_ratio": 1.0,
		"height_state": StringName("unknown"),
	}

	if bool(_baseline.get("is_calibrated", false)):
		var baseline_shoulder_x := float(_baseline.get("shoulder_center_x", measurements["body_centerline_x"]))
		var baseline_hip_y := float(_baseline.get("hip_center_y", PoseMetrics.to_vector3(hip_center).y))
		measurements["lateral_offset"] = PoseMetrics.normalized_ratio(measurements["body_centerline_x"] - baseline_shoulder_x, maxf(float(_baseline.get("shoulder_width", 0.0)), 0.000001))
		measurements["height_ratio"] = PoseMetrics.normalized_ratio(torso_height, maxf(float(_baseline.get("torso_height", 0.0)), 0.000001))
		measurements["height_state"] = _estimate_height_state(float(measurements["height_ratio"]), PoseMetrics.to_vector3(hip_center).y - baseline_hip_y)

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

func _update_baseline(metrics: Dictionary, tracking_state: StringName) -> void:
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
	return maxi(int(round(2.0 + smoothing_factor * 4.0)), 2)

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
