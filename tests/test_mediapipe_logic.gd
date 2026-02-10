extends RefCounted
## Basic logic tests for MediaPipe addon
## Compatible with GUT if available, otherwise runs basic checks

func _init():
	# Run tests if GUT is not available
	if not _is_gut_available():
		print("[MediaPipeLogicTest] Running standalone tests...")
		_run_standalone_tests()

func _is_gut_available() -> bool:
	return ClassDB.class_exists("GutTest") or FileAccess.file_exists("res://addons/gut/plugin.cfg")

func _run_standalone_tests():
	print("Testing MediaPipe Logic...")
	
	# Test 1: Sanity check
	if 1 == 1:
		print("✓ Math works")
	else:
		print("✗ Math is broken")
	
	# Test 2: Verify driver script exists
	var script = load("res://src/driver.gd")
	if script:
		print("✓ Driver script exists")
	else:
		print("✗ Driver script not found")
	
	# Test 3: Verify provider script exists
	var provider_script = load("res://src/providers/mediapipe_provider.gd")
	if provider_script:
		print("✓ Provider script exists")
	else:
		print("✗ Provider script not found")
	
	# Test 4: Verify server script exists
	var server_script = load("res://src/server/mediapipe_server.gd")
	if server_script:
		print("✓ Server script exists")
	else:
		print("✗ Server script not found")
	
	# Test 5: Verify config script exists
	var config_script = load("res://src/config/mediapipe_config.gd")
	if config_script:
		print("✓ Config script exists")
	else:
		print("✗ Config script not found")
	
	print("[MediaPipeLogicTest] Standalone tests complete.")

# GUT-compatible before_all/after_all
func before_all():
	if not _is_gut_available():
		return
	# Can't use gut.p without GUT, this is just for GUT compatibility
	print("Starting Input Driver Tests...")

func after_all():
	if not _is_gut_available():
		return
	print("Finished Input Driver Tests.")

# GUT-compatible test methods
func test_sanity_check():
	if not _is_gut_available():
		return
	assert_eq(1, 1, "Math should work")

func test_driver_structure():
	if not _is_gut_available():
		return
	var script = load("res://src/driver.gd")
	assert_not_null(script, "Driver script should exist")

func test_provider_script_exists():
	if not _is_gut_available():
		return
	var script = load("res://src/providers/mediapipe_provider.gd")
	assert_not_null(script, "Provider script should exist")

func test_server_script_exists():
	if not _is_gut_available():
		return
	var script = load("res://src/server/mediapipe_server.gd")
	assert_not_null(script, "Server script should exist")

func test_config_script_exists():
	if not _is_gut_available():
		return
	var script = load("res://src/config/mediapipe_config.gd")
	assert_not_null(script, "Config script should exist")
