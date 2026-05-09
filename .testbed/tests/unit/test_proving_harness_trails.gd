extends "res://addons/gut/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")

var harness: ProvingHarness = null

func before_each() -> void:
	harness = ProvingHarness.new()
	harness.overlay_visibility_threshold = 0.35
	harness._reset_last_flow_events()
	harness._reset_event_tracking()
	harness._left_trail_debug = harness._make_trail_debug_state("left")
	harness._right_trail_debug = harness._make_trail_debug_state("right")

func _debug_state(side: String = "test") -> Dictionary:
	return harness._make_trail_debug_state(side)

func after_each() -> void:
	if harness != null:
		harness.free()
		harness = null

func test_appends_contiguous_in_bounds_wrist_samples() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.30, "y": 0.40, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.38, "y": 0.44, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(is_equal_approx(float(trail[1].get("x", 0.0)), 0.38))
	assert_true(is_equal_approx(float(trail[1].get("y", 0.0)), 0.44))
	assert_eq(int(debug_state.get("reseeds", 0)), 1)
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 0)

func test_breaks_then_reseeds_trail_on_implausible_in_bounds_jump() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.24, "y": 0.28, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.82, "y": 0.86, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 3)
	assert_true(is_equal_approx(float(trail[0].get("x", 0.0)), 0.24))
	assert_true(is_equal_approx(float(trail[0].get("y", 0.0)), 0.28))
	assert_true(float(trail[1].get("x", 0.0)) < 0.0)
	assert_true(float(trail[1].get("y", 0.0)) < 0.0)
	assert_true(is_equal_approx(float(trail[2].get("x", 0.0)), 0.82))
	assert_true(is_equal_approx(float(trail[2].get("y", 0.0)), 0.86))
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 1)
	assert_eq(int(debug_state.get("reseeds", 0)), 2)
	assert_gt(float(debug_state.get("last_jump_distance", 0.0)), 0.28)

func test_preserves_shorter_boxing_jump_as_contiguous_motion() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.30, "y": 0.40, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 0.47, "y": 0.52, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 2)
	assert_true(is_equal_approx(float(trail[1].get("x", 0.0)), 0.47))
	assert_true(is_equal_approx(float(trail[1].get("y", 0.0)), 0.52))
	assert_eq(int(debug_state.get("continuity_breaks", 0)), 0)
	assert_lt(float(debug_state.get("last_jump_distance", 0.0)), 0.28)

func test_resolves_trail_hand_point_from_visible_finger_landmarks_when_wrist_is_low_visibility() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 15, "x": 0.25, "y": 0.40, "v": 0.10},
		{"id": 19, "x": 0.31, "y": 0.46, "v": 0.62},
		{"id": 17, "x": 0.29, "y": 0.44, "v": 0.58},
		{"id": 21, "x": 0.33, "y": 0.42, "v": 0.54},
	], harness.LEFT_WRIST_ID, [harness.LEFT_INDEX_ID, harness.LEFT_PINKY_ID, harness.LEFT_THUMB_ID])
	assert_false(resolved.is_empty())
	assert_true(float(resolved.get("v", 0.0)) >= 0.54)
	assert_true(float(resolved.get("x", 0.0)) > 0.29 and float(resolved.get("x", 0.0)) < 0.32)
	assert_true(float(resolved.get("y", 0.0)) > 0.43 and float(resolved.get("y", 0.0)) < 0.45)

func test_resolves_trail_hand_point_by_clamping_near_edge_jitter() -> void:
	var resolved := harness._resolve_trail_hand_point([
		{"id": 16, "x": 1.03, "y": 0.41, "v": 0.44},
		{"id": 20, "x": 0.99, "y": 0.43, "v": 0.61},
		{"id": 18, "x": 1.02, "y": 0.39, "v": 0.57},
	], harness.RIGHT_WRIST_ID, [harness.RIGHT_INDEX_ID, harness.RIGHT_PINKY_ID, harness.RIGHT_THUMB_ID])
	assert_false(resolved.is_empty())
	assert_true(float(resolved.get("x", 0.0)) >= 0.98 and float(resolved.get("x", 0.0)) <= 1.0)
	assert_true(float(resolved.get("y", 0.0)) >= 0.39 and float(resolved.get("y", 0.0)) <= 0.43)

func test_out_of_bounds_point_still_clears_trail() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.40, "y": 0.45, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 1.10, "y": 0.45, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 0)
	assert_eq(int(debug_state.get("out_of_bounds_clears", 0)), 1)
	assert_eq(String(debug_state.get("last_action", "")), "clear_oob")

func test_preview_only_audit_defaults_to_provider_disabled() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	assert_eq(harness._preview_only_audit_text(), "provider=disabled (expected)")
	assert_true(harness._build_live_status_text().contains("audit=provider=disabled (expected)"))

func test_preview_only_pose_activity_invalidates_surface_and_clears_overlay_state() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	harness._latest_landmarks = [{"id": 15, "x": 0.25, "y": 0.40, "v": 0.99}]
	harness._left_trail = [{"x": 0.25, "y": 0.40, "v": 0.99, "timestamp_ms": 1000}]
	harness._right_trail = [{"x": 0.75, "y": 0.40, "v": 0.99, "timestamp_ms": 1000}]
	harness._on_pose_updated([{"id": 16, "x": 0.75, "y": 0.40, "v": 0.99}])
	assert_eq(harness._preview_only_invalid_reason, "pose/provider activity reached preview-only rung")
	assert_eq(harness._event_count("preview_only_invalid"), 1)
	assert_eq(harness._latest_landmarks.size(), 0)
	assert_eq(harness._left_trail.size(), 0)
	assert_eq(harness._right_trail.size(), 0)
	assert_true(harness._preview_only_audit_text().contains("INVALID:"))

func test_preview_only_provider_node_drift_invalidates_surface() -> void:
	harness.startup_mode = harness.StartupMode.PREVIEW_ONLY_DEBUG
	var drift_node := Node.new()
	drift_node.name = "MediaPipeProvider"
	harness.add_child(drift_node)
	harness._audit_preview_only_surface()
	assert_eq(harness._preview_only_invalid_reason, "provider node active in preview-only rung")
	assert_eq(harness._event_count("preview_only_invalid"), 1)
