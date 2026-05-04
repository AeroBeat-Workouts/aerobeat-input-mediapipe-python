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
	for idx in range(5):
		var state := substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1000 + idx * 16)
		assert_eq(String(state["tracking_state"]), "tracking")
	var baseline: Dictionary = substrate.get_latest_state().get("baseline", {})
	assert_true(bool(baseline.get("is_calibrated", false)))
	assert_true(is_equal_approx(float(baseline.get("shoulder_width", 0.0)), 0.20))
	assert_true(is_equal_approx(float(baseline.get("torso_height", 0.0)), 0.30))

func test_reports_hand_velocity_and_direction_from_landmark_deltas() -> void:
	substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1000)
	var state := substrate.process_landmarks(_make_pose_frame(0.50, 0.05, 1.0), 1100)
	var velocities: Dictionary = state.get("metrics", {}).get("velocities", {})
	var directions: Dictionary = state.get("metrics", {}).get("directions", {})
	var left_hand_velocity: Vector3 = velocities.get("left_hand", Vector3.ZERO)
	assert_true(left_hand_velocity.x > 0.20)
	assert_true(left_hand_velocity.y > -0.05 and left_hand_velocity.y < 0.05)
	var left_direction: Vector2 = directions.get("left_hand", Vector2.ZERO)
	assert_true(left_direction.x > 0.99)

func test_reports_arm_extension_centerline_offset_and_height_state() -> void:
	for idx in range(5):
		substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1000 + idx * 16)
	var state := substrate.process_landmarks(_make_pose_frame(0.62, 0.0, 0.50), 1200)
	var measurements: Dictionary = state.get("metrics", {}).get("measurements", {})
	assert_true(float(measurements.get("left_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("right_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("lateral_offset", 0.0)) > 0.25)
	assert_eq(String(measurements.get("height_state", "unknown")), "lowered")
	assert_true(float(measurements.get("height_ratio", 1.0)) < 0.80)

func test_degrades_then_reacquires_tracking_when_confidence_drops() -> void:
	substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1000)
	var degraded := substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 0.2, 0.2), 1016)
	assert_eq(String(degraded["tracking_state"]), "degraded")
	var lost := substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 0.2, 0.2), 1032)
	lost = substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 0.2, 0.2), 1048)
	assert_eq(String(lost["tracking_state"]), "lost")
	var reacquiring := substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1064)
	assert_eq(String(reacquiring["tracking_state"]), "reacquiring")
	var tracking := substrate.process_landmarks(_make_pose_frame(0.50, 0.0, 1.0), 1080)
	assert_eq(String(tracking["tracking_state"]), "tracking")

func _make_pose_frame(center_x: float, wrist_x_offset: float, height_scale: float, visibility: float = 0.99) -> Array:
	var shoulder_y := 0.70
	var hip_y := shoulder_y - 0.30 * height_scale
	var ankle_y := hip_y - 0.40 * height_scale
	var nose_y := shoulder_y + 0.20 * height_scale
	return [
		{"id": PoseLandmarkIds.NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_SHOULDER, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_SHOULDER, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_ELBOW, "x": center_x - 0.18 + wrist_x_offset * 0.5, "y": shoulder_y - 0.01, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ELBOW, "x": center_x + 0.18 + wrist_x_offset * 0.5, "y": shoulder_y - 0.01, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_WRIST, "x": center_x - 0.26 + wrist_x_offset, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_WRIST, "x": center_x + 0.26 + wrist_x_offset, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_HIP, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_HIP, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.LEFT_ANKLE, "x": center_x - 0.06, "y": ankle_y, "z": 0.0, "v": visibility},
		{"id": PoseLandmarkIds.RIGHT_ANKLE, "x": center_x + 0.06, "y": ankle_y, "z": 0.0, "v": visibility},
	]
