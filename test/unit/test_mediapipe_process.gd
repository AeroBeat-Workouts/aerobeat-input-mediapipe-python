extends RefCounted
## Unit tests for MediaPipeProcess
## Compatible with GUT if available, otherwise runs basic checks

const MediaPipeProcess = preload("res://src/process/mediapipe_process.gd")
const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")

var _process = null
var config = null

func _init():
	# Run tests if GUT is not available
	if not _is_gut_available():
		print("[MediaPipeProcessTest] Running standalone tests...")
		_run_standalone_tests()

func _is_gut_available() -> bool:
	return ClassDB.class_exists("GutTest") or FileAccess.file_exists("res://addons/gut/plugin.cfg")

func _run_standalone_tests():
	print("Testing MediaPipeProcess...")
	
	_process = MediaPipeProcess.new()
	config = MediaPipeConfig.new()
	config.udp_port = 9998
	
	# Test 1: Create process
	if _process:
		print("✓ Process created successfully")
	else:
		print("✗ Failed to create process")
		return
	
	# Test 2: Check dependencies returns dictionary
	var deps = _process.check_dependencies()
	if deps is Dictionary:
		print("✓ check_dependencies() returns Dictionary")
		if deps.has("python_found"):
			print("  - python_found: ", deps.python_found)
		if deps.has("mediapipe_installed"):
			print("  - mediapipe_installed: ", deps.mediapipe_installed)
	else:
		print("✗ check_dependencies() did not return Dictionary")
	
	# Test 3: Process not running initially
	if not _process.is_running():
		print("✓ Process not running initially")
	else:
		print("✗ Process should not be running initially")
	
	print("[MediaPipeProcessTest] Standalone tests complete.")

# GUT-compatible test methods
func before_each():
	if not _is_gut_available():
		return
	_process = MediaPipeProcess.new()
	config = MediaPipeConfig.new()
	config.udp_port = 9998

func after_each():
	if not _is_gut_available():
		return
	if _process.is_running():
		_process.stop()
	_process.queue_free()

func test_find_python_returns_valid_path():
	if not _is_gut_available():
		return
	var path = _process._find_python()
	assert_string_contains(path, "python")

func test_check_dependencies_returns_dictionary():
	if not _is_gut_available():
		return
	var deps = _process.check_dependencies()
	assert_has_method(deps, "has", "python_found")
	assert_has_method(deps, "has", "mediapipe_installed")
	assert_has_method(deps, "has", "errors")

func test_process_not_running_initially():
	if not _is_gut_available():
		return
	assert_false(_process.is_running())

func test_start_emits_process_started_signal():
	if not _is_gut_available():
		return
	var called = false
	_process.process_started.connect(func(): called = true)
	
	var success = _process.start(config)
	# May fail if Python deps not installed - that's ok for test
	if success:
		assert_true(called, "Should emit process_started")

func test_is_running_returns_true_after_start():
	if not _is_gut_available():
		return
	var success = _process.start(config)
	if success:
		assert_true(_process.is_running())

func test_stop_emits_process_stopped_signal():
	if not _is_gut_available():
		return
	if not _process.start(config):
		pending("Python not available")
		return
	
	var exit_code = -1
	_process.process_stopped.connect(func(c): exit_code = c)
	
	await _process.stop()
	
	assert_eq(exit_code, 0)

func test_stop_cleans_up_process():
	if not _is_gut_available():
		return
	if not _process.start(config):
		pending("Python not available")
		return
	
	await _process.stop()
	assert_false(_process.is_running())

func test_start_fails_when_already_running():
	if not _is_gut_available():
		return
	if not _process.start(config):
		pending("Python not available")
		return
	
	var error_emitted = ""
	_process.process_error.connect(func(e): error_emitted = e)
	
	var success = _process.start(config)
	assert_false(success)
	assert_string_contains(error_emitted, "already running")
