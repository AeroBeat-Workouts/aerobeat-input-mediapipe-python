extends RefCounted
## Unit tests for MediaPipeProvider
## Compatible with GUT if available, otherwise runs basic checks

const MediaPipeProvider = preload("res://src/providers/mediapipe_provider.gd")
const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")
const MediaPipeServer = preload("res://src/server/mediapipe_server.gd")

var provider = null

func _init():
	# Run tests if GUT is not available
	if not _is_gut_available():
		print("[MediaPipeProviderTest] Running standalone tests...")
		_run_standalone_tests()

func _is_gut_available() -> bool:
	return ClassDB.class_exists("GutTest") or FileAccess.file_exists("res://addons/gut/plugin.cfg")

func _run_standalone_tests():
	print("Testing MediaPipeProvider...")
	
	# Test 1: Create provider
	provider = MediaPipeProvider.new()
	if provider:
		print("✓ Provider created successfully")
	else:
		print("✗ Failed to create provider")
		return
	
	# Test 2: Check default config
	if provider.config == null:
		print("✗ Config is null by default")
	else:
		print("✓ Config initialized")
	
	# Test 3: Test landmark processing
	provider.config = MediaPipeConfig.new()
	provider._on_landmarks_received([{"id": 15, "x": 0.5, "y": 0.5, "v": 0.99}])
	var pos = provider.get_left_hand_position()
	if pos is Vector2:
		print("✓ Returns Vector2 in 2D mode")
	else:
		print("✗ Expected Vector2, got: ", typeof(pos))
	
	# Test 4: Y-axis flip
	provider._landmarks.clear()
	provider._on_landmarks_received([{"id": 0, "x": 0.5, "y": 0.2, "v": 0.99}])
	var head_pos = provider.get_head_position()
	if head_pos and abs(head_pos.y - 0.8) < 0.01:
		print("✓ Y-axis is correctly flipped")
	else:
		print("✗ Y-axis flip incorrect")
	
	print("[MediaPipeProviderTest] Standalone tests complete.")

# GUT-compatible test methods (only run when GUT is available)
func before_each():
	if not _is_gut_available():
		return
	provider = MediaPipeProvider.new()
	# Note: Can't use add_child without Node, tests would need refactor for full GUT compatibility

func after_each():
	if provider and is_instance_valid(provider):
		provider.queue_free()

func test_extends_node():
	if not _is_gut_available():
		return
	# In standalone mode, extends Node instead of AeroInputProvider
	assert_is(provider, Node)

func test_creates_server_if_missing():
	if not _is_gut_available():
		return
	# Server creation test would require Node functionality
	pass

func test_returns_null_when_no_data():
	if not _is_gut_available():
		return
	assert_null(provider.get_left_hand_position())

func test_returns_vector2_in_2d_mode():
	if not _is_gut_available():
		return
	provider._on_landmarks_received([{"id": 15, "x": 0.5, "y": 0.5, "v": 0.99}])
	var pos = provider.get_left_hand_position()
	assert_is(pos, Vector2)

func test_y_axis_is_flipped():
	if not _is_gut_available():
		return
	provider.config = MediaPipeConfig.new()
	provider.config.flip_horizontal = false
	provider._on_landmarks_received([{"id": 0, "x": 0.5, "y": 0.2, "v": 0.99}])
	var pos = provider.get_head_position()
	assert_eq(pos.y, 0.8, "Y should be 1.0 - 0.2 = 0.8")

func test_horizontal_flip():
	if not _is_gut_available():
		return
	provider.config = MediaPipeConfig.new()
	provider.config.flip_horizontal = true
	provider._on_landmarks_received([{"id": 0, "x": 0.2, "v": 0.99}])
	var pos = provider.get_head_position()
	assert_eq(pos.x, 0.8, "X should be flipped")

func test_is_tracking_false_when_no_data():
	if not _is_gut_available():
		return
	assert_false(provider.is_tracking())

func test_is_tracking_true_after_data():
	if not _is_gut_available():
		return
	provider._on_landmarks_received([{"id": 0, "v": 0.99}])
	assert_true(provider.is_tracking())
