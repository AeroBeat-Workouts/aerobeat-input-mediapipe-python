extends "res://addons/gut/test.gd"

const ProvingHarness = preload("res://scripts/proving_harness.gd")

var harness: ProvingHarness = null

func before_each() -> void:
	harness = ProvingHarness.new()
	harness.overlay_visibility_threshold = 0.35

func after_each() -> void:
	if harness != null:
		harness.free()
		harness = null

func test_appends_contiguous_in_bounds_wrist_samples() -> void:
	var trail: Array = []
	harness._append_trail_point(trail, {"x": 0.30, "y": 0.40, "v": 0.99}, 1000)
	harness._append_trail_point(trail, {"x": 0.38, "y": 0.44, "v": 0.99}, 1033)
	assert_eq(trail.size(), 2)
	assert_true(is_equal_approx(float(trail[1].get("x", 0.0)), 0.38))
	assert_true(is_equal_approx(float(trail[1].get("y", 0.0)), 0.44))

func test_clears_then_reseeds_trail_on_implausible_in_bounds_jump() -> void:
	var trail: Array = []
	harness._append_trail_point(trail, {"x": 0.24, "y": 0.28, "v": 0.99}, 1000)
	harness._append_trail_point(trail, {"x": 0.82, "y": 0.86, "v": 0.99}, 1033)
	assert_eq(trail.size(), 1)
	assert_true(is_equal_approx(float(trail[0].get("x", 0.0)), 0.82))
	assert_true(is_equal_approx(float(trail[0].get("y", 0.0)), 0.86))

func test_out_of_bounds_point_still_clears_trail() -> void:
	var trail: Array = []
	harness._append_trail_point(trail, {"x": 0.40, "y": 0.45, "v": 0.99}, 1000)
	harness._append_trail_point(trail, {"x": 1.10, "y": 0.45, "v": 0.99}, 1033)
	assert_eq(trail.size(), 0)
