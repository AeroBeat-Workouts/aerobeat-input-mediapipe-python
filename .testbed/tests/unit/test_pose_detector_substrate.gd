extends "res://addons/gut/test.gd"

const PoseDetectorSubstrate = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_detector_substrate.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")
const PoseLandmarkIds = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_landmark_ids.gd")

var substrate: PoseDetectorSubstrate = null
var config: MediaPipeConfig = null

func before_each() -> void:
	config = MediaPipeConfig.new()
	config.flip_horizontal = false
	config.min_visibility = 0.5
	config.tracking_confidence = 0.5
	config.smoothing_factor = 0.0
	substrate = PoseDetectorSubstrate.new().configure(config)

func test_builds_session_baseline_after_stable_frames() -> void:
	_calibrate_stance()
	var baseline: Dictionary = substrate.get_latest_state().get("baseline", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_true(is_equal_approx(float(baseline.get("shoulder_width", 0.0)), 0.20))
	assert_true(is_equal_approx(float(baseline.get("torso_height", 0.0)), 0.30))

func test_reports_hand_velocity_and_direction_from_landmark_deltas() -> void:
	substrate.process_landmarks(_make_pose_frame(), 1000)
	var moving := _make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.36, "y": 0.66},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.60},
	})
	var state := substrate.process_landmarks(moving, 1100)
	var velocities: Dictionary = state.get("metrics", {}).get("velocities", {})
	var directions: Dictionary = state.get("metrics", {}).get("directions", {})
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	assert_true(left_hand_velocity.x > 0.20)
	assert_true(left_hand_velocity.y > -0.05 and left_hand_velocity.y < 0.80)
	var left_direction: Vector2 = directions.get("left_hand", Vector2.ZERO)
	assert_true(left_direction.x > 0.55)

func test_reports_arm_extension_centerline_offset_and_height_state() -> void:
	_calibrate_stance()
	var lowered := _make_pose_frame({}, 0.62, 0.50)
	lowered = _with_overrides(lowered, {
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.46, "y": 0.695},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.78, "y": 0.695},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.36, "y": 0.70},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.88, "y": 0.70},
	})
	var state := substrate.process_landmarks(lowered, 1200)
	var measurements: Dictionary = state.get("metrics", {}).get("measurements", {})
	assert_true(float(measurements.get("left_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("right_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("lateral_offset", 0.0)) > 0.25)
	assert_eq(String(measurements.get("height_state", "unknown")), "lowered")
	assert_true(float(measurements.get("height_ratio", 1.0)) < 0.80)

func test_degrades_then_reacquires_tracking_when_confidence_drops() -> void:
	substrate.process_landmarks(_make_pose_frame(), 1000)
	var degraded := substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1016)
	assert_eq(String(degraded["tracking_state"]), "degraded")
	var lost := substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1032)
	lost = substrate.process_landmarks(_make_pose_frame({}, 0.50, 1.0, 0.2, 0.2), 1048)
	assert_eq(String(lost["tracking_state"]), "lost")
	var reacquiring := substrate.process_landmarks(_make_pose_frame(), 1064)
	assert_eq(String(reacquiring["tracking_state"]), "reacquiring")
	var tracking := substrate.process_landmarks(_make_pose_frame(), 1080)
	assert_eq(String(tracking["tracking_state"]), "tracking")

func test_detects_straight_hook_and_uppercut_events_truthfully() -> void:
	_calibrate_stance()
	substrate.process_landmarks(_make_pose_frame(), 1100)
	var punch_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.26, "y": 0.70},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.12, "y": 0.70},
	}), 1200)
	assert_eq(_event_names(punch_state.get("events", [])), ["punch_left"])

	substrate.process_landmarks(_make_pose_frame(), 1300)
	var hook_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.68, "y": 0.62},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.84, "y": 0.60},
	}), 1400)
	assert_eq(_event_names(hook_state.get("events", [])), ["hook_right"])

	substrate.process_landmarks(_make_pose_frame(), 1500)
	var uppercut_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.34, "y": 0.62},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.33, "y": 0.76},
	}), 1600)
	assert_eq(_event_names(uppercut_state.get("events", [])), ["uppercut_left"])

func test_detects_guard_squat_lean_and_sidestep_state_events() -> void:
	_calibrate_stance()
	var guard_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.42, "y": 0.69},
		PoseLandmarkIds.RIGHT_ELBOW: {"x": 0.58, "y": 0.69},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.41, "y": 0.80},
		PoseLandmarkIds.RIGHT_WRIST: {"x": 0.59, "y": 0.80},
	}), 1200)
	assert_eq(_event_names(guard_start_state.get("events", [])), ["guard_start"])
	var guard_end_state := substrate.process_landmarks(_make_pose_frame(), 1300)
	assert_eq(_event_names(guard_end_state.get("events", [])), ["guard_end"])

	var squat_start_state := substrate.process_landmarks(_make_pose_frame({}, 0.50, 0.78), 1400)
	assert_eq(_event_names(squat_start_state.get("events", [])), ["squat_start"])
	var squat_end_state := substrate.process_landmarks(_make_pose_frame(), 1500)
	assert_eq(_event_names(squat_end_state.get("events", [])), ["squat_end"])

	var lean_left_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.NOSE: {"x": 0.43, "y": 0.85},
	}), 1600)
	assert_eq(_event_names(lean_left_state.get("events", [])), ["lean_left_start"])
	var lean_end_state := substrate.process_landmarks(_make_pose_frame(), 1700)
	assert_eq(_event_names(lean_end_state.get("events", [])), ["lean_left_end"])

	var sidestep_right_state := substrate.process_landmarks(_make_pose_frame({}, 0.60, 1.0), 1800)
	assert_eq(_event_names(sidestep_right_state.get("events", [])), ["sidestep_right_start"])
	var sidestep_end_state := substrate.process_landmarks(_make_pose_frame(), 1900)
	assert_eq(_event_names(sidestep_end_state.get("events", [])), ["sidestep_right_end"])

func test_detects_knee_and_leg_lift_events_with_reset_behavior() -> void:
	_calibrate_stance()
	var knee_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.34},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.18},
	}), 1200)
	assert_eq(_event_names(knee_state.get("events", [])), ["knee_left"])
	var no_refire_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.35},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.19},
	}), 1300)
	assert_eq(_event_names(no_refire_state.get("events", [])), [])
	var knee_reset_state := substrate.process_landmarks(_make_pose_frame(), 1400)
	assert_eq(_event_names(knee_reset_state.get("events", [])), [])
	var knee_refire_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_KNEE: {"x": 0.44, "y": 0.34},
		PoseLandmarkIds.LEFT_ANKLE: {"x": 0.46, "y": 0.18},
	}), 1500)
	assert_eq(_event_names(knee_refire_state.get("events", [])), ["knee_left"])

	var leg_lift_start_state := substrate.process_landmarks(_make_pose_frame({
		PoseLandmarkIds.RIGHT_ANKLE: {"x": 0.73, "y": 0.20},
	}), 1600)
	assert_eq(_event_names(leg_lift_start_state.get("events", [])), ["leg_lift_right_start"])
	var leg_lift_end_state := substrate.process_landmarks(_make_pose_frame(), 1700)
	assert_eq(_event_names(leg_lift_end_state.get("events", [])), ["leg_lift_right_end"])

func _calibrate_stance() -> void:
	for idx in range(5):
		var state := substrate.process_landmarks(_make_pose_frame(), 1000 + idx * 16)
		assert_eq(String(state["tracking_state"]), "tracking")

func _event_names(events: Array) -> Array:
	var names: Array = []
	for event_variant: Variant in events:
		if event_variant is Dictionary:
			names.append(String(event_variant.get("name", "")))
	return names

func _make_pose_frame(overrides: Dictionary = {}, center_x: float = 0.50, height_scale: float = 1.0, visibility: float = 0.99, knee_visibility: float = 0.99) -> Array:
	var shoulder_y := 0.70
	var hip_y := shoulder_y - 0.30 * height_scale
	var knee_y := hip_y - 0.18 * height_scale
	var ankle_y := hip_y - 0.36 * height_scale
	var nose_y := shoulder_y + 0.20 * height_scale
	var frame := [
		{"id": PoseLandmarkIds.NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_SHOULDER, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_SHOULDER, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_ELBOW, "x": center_x - 0.16, "y": shoulder_y - 0.04, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ELBOW, "x": center_x + 0.16, "y": shoulder_y - 0.04, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_WRIST, "x": center_x - 0.22, "y": shoulder_y - 0.10, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_WRIST, "x": center_x + 0.22, "y": shoulder_y - 0.10, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_HIP, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_HIP, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_KNEE, "x": center_x - 0.06, "y": knee_y, "z": 0.0, "v": knee_visibility},
		{"id": PoseLandmarkIds.RIGHT_KNEE, "x": center_x + 0.06, "y": knee_y, "z": 0.0, "v": knee_visibility},
		{"id": PoseLandmarkIds.LEFT_ANKLE, "x": center_x - 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ANKLE, "x": center_x + 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
	]
	return _with_overrides(frame, overrides)

func _with_overrides(frame: Array, overrides: Dictionary) -> Array:
	if overrides.is_empty():
		return frame
	var updated: Array = []
	for landmark_variant: Variant in frame:
		var landmark: Dictionary = (landmark_variant as Dictionary).duplicate(true)
		var landmark_id: int = int(landmark.get("id", -1))
		if overrides.has(landmark_id):
			var override_variant: Variant = overrides[landmark_id]
			if override_variant is Dictionary:
				for key_variant: Variant in override_variant.keys():
					landmark[key_variant] = override_variant[key_variant]
		updated.append(landmark)
	return updated
