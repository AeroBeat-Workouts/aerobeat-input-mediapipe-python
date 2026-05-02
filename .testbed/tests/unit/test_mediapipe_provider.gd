extends "res://addons/gut/test.gd"

const MediaPipeProvider = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

var provider: MediaPipeProvider = null

func before_each() -> void:
	provider = add_child_autoqfree(MediaPipeProvider.new())
	provider.config = MediaPipeConfig.new()

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
		{"id": provider.LANDMARK_LEFT_WRIST, "x": 0.5, "y": 0.5, "v": 0.99}
	])
	var pos = provider.get_left_hand_position()
	assert_typeof(pos, TYPE_VECTOR2)
	assert_eq(pos, Vector2(0.5, 0.5))

func test_y_axis_is_flipped() -> void:
	provider.config.flip_horizontal = false
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.5, "y": 0.2, "v": 0.99}
	])
	var pos = provider.get_head_position()
	assert_true(is_equal_approx(pos.y, 0.8), "Y should be 1.0 - 0.2 = 0.8")

func test_horizontal_flip() -> void:
	provider.config.flip_horizontal = true
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.2, "y": 0.2, "v": 0.99}
	])
	var pos = provider.get_head_position()
	assert_true(is_equal_approx(pos.x, 0.8), "X should be flipped")

func test_missing_visibility_defaults_to_visible() -> void:
	provider.config.flip_horizontal = false
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.25, "y": 0.75}
	])
	var pos = provider.get_head_position()
	assert_eq(pos, Vector2(0.25, 0.25))

func test_is_tracking_false_when_no_data() -> void:
	assert_false(provider.is_tracking())

func test_is_tracking_true_after_data() -> void:
	provider._on_landmarks_received([
		{"id": provider.LANDMARK_NOSE, "x": 0.5, "y": 0.5, "v": 0.99}
	])
	assert_true(provider.is_tracking())

func test_get_landmark_position_for_pose_handles_invalid_shapes() -> void:
	provider._all_poses = [
		{"landmarks": "bad-shape"},
		"also-bad"
	]
	assert_null(provider.get_landmark_position_for_pose(0, provider.LANDMARK_NOSE))
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
	assert_eq(provider.get_landmark_position_for_pose(0, provider.LANDMARK_RIGHT_WRIST), Vector2(0.9, 0.9))
