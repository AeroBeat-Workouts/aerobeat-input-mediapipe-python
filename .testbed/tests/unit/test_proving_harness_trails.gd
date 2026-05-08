extends "res://addons/gut/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")

var harness: ProvingHarness = null

func before_each() -> void:
	harness = ProvingHarness.new()
	harness.overlay_visibility_threshold = 0.35

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

func test_out_of_bounds_point_still_clears_trail() -> void:
	var trail: Array = []
	var debug_state := _debug_state()
	harness._append_trail_point(trail, {"x": 0.40, "y": 0.45, "v": 0.99}, 1000, debug_state)
	harness._append_trail_point(trail, {"x": 1.10, "y": 0.45, "v": 0.99}, 1033, debug_state)
	assert_eq(trail.size(), 0)
	assert_eq(int(debug_state.get("out_of_bounds_clears", 0)), 1)
	assert_eq(String(debug_state.get("last_action", "")), "clear_oob")
