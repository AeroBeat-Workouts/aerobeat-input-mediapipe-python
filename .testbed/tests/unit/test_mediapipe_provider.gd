extends "res://addons/gut/test.gd"

const MediaPipeProvider = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

var provider: MediaPipeProvider = null

func before_each() -> void:
	provider = add_child_autoqfree(MediaPipeProvider.new())
	provider.config = MediaPipeConfig.new()
	provider.config.flip_horizontal = false
	provider.config.smoothing_factor = 0.0

func test_extends_node() -> void:
	assert_is(provider, Node)

func test_creates_default_config_when_missing() -> void:
	provider.config = null
	var resolved_config = provider._ensure_config()
	assert_is(resolved_config, MediaPipeConfig)
	assert_is(provider.config, MediaPipeConfig)

func test_returns_null_when_no_data() -> void:
	assert_null(provider.get_left_hand_position())

func test_returns_vector2_in_2d_mode() -> void:
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.5, "y": 0.5, "v": 0.99},
		{"id": provider.LANDMARK_NOSE, "x": 0.5, "y": 0.7, "v": 0.99},
		{"id": 11, "x": 0.4, "y": 0.6, "v": 0.99},
		{"id": 12, "x": 0.6, "y": 0.6, "v": 0.99},
		{"id": 23, "x": 0.42, "y": 0.3, "v": 0.99},
		{"id": 24, "x": 0.58, "y": 0.3, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": 0.7, "y": 0.5, "v": 0.99},
	])
	var pos = provider.get_left_hand_position()
	assert_typeof(pos, TYPE_VECTOR2)
	assert_eq(pos, Vector2(0.5, 0.5))

func test_y_axis_is_flipped_during_normalization() -> void:
	provider.config.flip_horizontal = false
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.5, "y": 0.2, "v": 0.99},
		{"id": 11, "x": 0.4, "y": 0.3, "v": 0.99},
		{"id": 12, "x": 0.6, "y": 0.3, "v": 0.99},
		{"id": 23, "x": 0.42, "y": 0.6, "v": 0.99},
		{"id": 24, "x": 0.58, "y": 0.6, "v": 0.99},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.35, "y": 0.3, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": 0.65, "y": 0.3, "v": 0.99},
	])
	var pos = provider.get_head_position()
	assert_true(is_equal_approx(pos.y, 0.8), "Y should be 1.0 - 0.2 = 0.8")

func test_horizontal_flip() -> void:
	provider.config.flip_horizontal = true
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.2, "y": 0.2, "v": 0.99},
		{"id": 11, "x": 0.1, "y": 0.3, "v": 0.99},
		{"id": 12, "x": 0.3, "y": 0.3, "v": 0.99},
		{"id": 23, "x": 0.12, "y": 0.6, "v": 0.99},
		{"id": 24, "x": 0.28, "y": 0.6, "v": 0.99},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.05, "y": 0.3, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": 0.35, "y": 0.3, "v": 0.99},
	])
	var pos = provider.get_head_position()
	assert_true(is_equal_approx(pos.x, 0.8), "X should be flipped")

func test_missing_visibility_defaults_to_visible() -> void:
	provider.config.flip_horizontal = false
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.25, "y": 0.75},
		{"id": 11, "x": 0.15, "y": 0.6, "v": 0.99},
		{"id": 12, "x": 0.35, "y": 0.6, "v": 0.99},
		{"id": 23, "x": 0.17, "y": 0.3, "v": 0.99},
		{"id": 24, "x": 0.33, "y": 0.3, "v": 0.99},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.10, "y": 0.55, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": 0.40, "y": 0.55, "v": 0.99},
	])
	var pos = provider.get_head_position()
	assert_eq(pos, Vector2(0.25, 0.25))

func test_is_tracking_false_when_no_data() -> void:
	assert_false(provider.is_tracking())

func test_is_tracking_true_after_data() -> void:
	provider._on_landmarks_received(_make_pose_frame(0.50, 0.0, 1.0))
	assert_true(provider.is_tracking())

func test_get_landmark_position_for_pose_handles_invalid_shapes() -> void:
	provider._all_poses = [
		{"landmarks": "bad-shape"},
		"also-bad"
	]
	assert_null(provider.get_landmark_position_for_pose(1, provider.LANDMARK_NOSE))

func test_get_landmark_position_for_pose_filters_by_visibility() -> void:
	provider.config.min_visibility = 0.5
	provider.config.flip_horizontal = false
	provider._all_poses = [
		{
			"landmarks": [
				{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.1, "y": 0.9, "v": 0.2},
				{"id": provider.LANDMARK_RIGHT_WRIST, "x": 0.9, "y": 0.1, "v": 0.8}
			]
		}
	]
	assert_null(provider.get_landmark_position_for_pose(0, provider.LANDMARK_LEFT_WRIST))
	assert_eq(provider.get_landmark_position_for_pose(0, provider.LANDMARK_RIGHT_WRIST), Vector2(0.9, 0.1))

func test_detector_substrate_populates_velocity_and_measurements() -> void:
	for _idx in range(5):
		provider._on_landmarks_received(_make_pose_frame(0.50, 0.0, 1.0))
	provider._on_landmarks_received(_make_pose_frame(0.62, 0.04, 0.50))
	var state: Dictionary = provider.get_detector_state()
	var measurements: Dictionary = state.get("metrics", {}).get("measurements", {})
	var velocities: Dictionary = state.get("metrics", {}).get("velocities", {})
	assert_true(float(measurements.get("left_arm_extension", 0.0)) > 0.95)
	assert_true(float(measurements.get("lateral_offset", 0.0)) > 0.0)
	assert_true(velocities.get("left_hand", Vector3.ZERO).x > 0.0)

func _make_pose_frame(center_x: float, wrist_x_offset: float, height_scale: float) -> Array:
	var shoulder_y := 0.70
	var hip_y := shoulder_y - 0.30 * height_scale
	var ankle_y := hip_y - 0.40 * height_scale
	var nose_y := shoulder_y + 0.20 * height_scale
	return [
		{"id": provider.LANDMARK_NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": 0.99},
		{"id": 11, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": 0.99},
		{"id": 12, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": 0.99},
		{"id": 13, "x": center_x - 0.18 + wrist_x_offset * 0.5, "y": shoulder_y - 0.01, "z": 0.0, "v": 0.99},
		{"id": 14, "x": center_x + 0.18 + wrist_x_offset * 0.5, "y": shoulder_y - 0.01, "z": 0.0, "v": 0.99},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": center_x - 0.26 + wrist_x_offset, "y": shoulder_y, "z": 0.0, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": center_x + 0.26 + wrist_x_offset, "y": shoulder_y, "z": 0.0, "v": 0.99},
		{"id": 23, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": 0.99},
		{"id": 24, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": 0.99},
		{"id": provider.LANDMARK_LEFT_ANKLE, "x": center_x - 0.06, "y": ankle_y, "z": 0.0, "v": 0.99},
		{"id": provider.LANDMARK_RIGHT_ANKLE, "x": center_x + 0.06, "y": ankle_y, "z": 0.0, "v": 0.99},
	]
