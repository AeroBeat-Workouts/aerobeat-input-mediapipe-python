extends "res://addons/gut/test.gd"

const MediaPipeProvider = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")
const PoseLandmarkIds = preload("res://addons/aerobeat-input-mediapipe-python/src/detectors/pose_landmark_ids.gd")

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
	provider._on_landmarks_received(_make_pose_frame())
	var pos = provider.get_left_hand_position()
	assert_typeof(pos, TYPE_VECTOR2)
	assert_eq(pos, Vector2(0.28, 0.60))

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
	provider._on_landmarks_received(_make_pose_frame())
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

func test_detector_substrate_populates_velocity_measurements_and_events() -> void:
	for idx in range(5):
		provider._process_primary_landmarks(_make_pose_frame(), false, true, 1000 + idx * 16)
	var punch_calls: Array = []
	provider.punch_left.connect(func(power: float) -> void:
		punch_calls.append(power)
	)
	provider._process_primary_landmarks(_make_pose_frame(), false, true, 1100)
	provider._process_primary_landmarks(_make_pose_frame({
		PoseLandmarkIds.LEFT_ELBOW: {"x": 0.26, "y": 0.30},
		PoseLandmarkIds.LEFT_WRIST: {"x": 0.12, "y": 0.30},
	}), false, true, 1200)
	var state: Dictionary = provider.get_detector_state()
	var measurements: Dictionary = state.get("metrics", {}).get("measurements", {})
	var velocities: Dictionary = state.get("metrics", {}).get("velocities", {})
	assert_true(float(measurements.get("left_arm_extension", 0.0)) > 0.95)
	assert_true(velocities.get("left_hand", Vector3.ZERO).x < 0.0)
	assert_eq(_event_names(state.get("events", [])), ["punch_left"])
	assert_eq(punch_calls.size(), 1)
	assert_true(float(punch_calls[0]) > 0.0)

func _event_names(events: Array) -> Array:
	var names: Array = []
	for event_variant: Variant in events:
		if event_variant is Dictionary:
			names.append(String(event_variant.get("name", "")))
	return names

func _make_pose_frame(overrides: Dictionary = {}, center_x: float = 0.50, height_scale: float = 1.0, visibility: float = 0.99) -> Array:
	var shoulder_y := 0.30
	var hip_y := shoulder_y + 0.30 * height_scale
	var knee_y := hip_y + 0.18 * height_scale
	var ankle_y := hip_y + 0.36 * height_scale
	var nose_y := shoulder_y - 0.20 * height_scale
	var frame := [
		{"id": provider.LANDMARK_NOSE, "x": center_x, "y": nose_y, "z": 0.0, "v": visibility},
		{"id": 11, "x": center_x - 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": 12, "x": center_x + 0.10, "y": shoulder_y, "z": 0.0, "v": visibility},
		{"id": 13, "x": center_x - 0.16, "y": shoulder_y + 0.04, "z": 0.0, "v": visibility},
		{"id": 14, "x": center_x + 0.16, "y": shoulder_y + 0.04, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_LEFT_WRIST, "x": center_x - 0.22, "y": shoulder_y + 0.10, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_RIGHT_WRIST, "x": center_x + 0.22, "y": shoulder_y + 0.10, "z": 0.0, "v": visibility},
		{"id": 23, "x": center_x - 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": 24, "x": center_x + 0.08, "y": hip_y, "z": 0.0, "v": visibility},
		{"id": 25, "x": center_x - 0.06, "y": knee_y, "z": 0.0, "v": visibility},
		{"id": 26, "x": center_x + 0.06, "y": knee_y, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_LEFT_ANKLE, "x": center_x - 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
		{"id": provider.LANDMARK_RIGHT_ANKLE, "x": center_x + 0.04, "y": ankle_y, "z": 0.0, "v": visibility},
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
