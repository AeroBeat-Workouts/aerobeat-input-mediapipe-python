extends "res://addons/gut/test.gd"

const MediaPipeProcess = preload("res://addons/aerobeat-input-mediapipe-python/src/process/mediapipe_process.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

var _process: MediaPipeProcess = null
var config: MediaPipeConfig = null

func before_each() -> void:
	_process = add_child_autoqfree(MediaPipeProcess.new())
	config = MediaPipeConfig.new()
	config.udp_port = 9998

func after_each() -> void:
	if _process != null and is_instance_valid(_process) and _process.is_running():
		await _process.stop()

func test_find_python_returns_prepared_runtime_path() -> void:
	var path := _process._find_python()
	assert_string_contains(path, "python", true)

func test_check_dependencies_returns_dictionary() -> void:
	var deps := _process.check_dependencies()
	assert_true(deps is Dictionary)
	assert_true(deps.has("python_found"))
	assert_true(deps.has("mediapipe_installed"))
	assert_true(deps.has("errors"))

func test_process_not_running_initially() -> void:
	assert_false(_process.is_running())

func test_start_emits_process_started_signal() -> void:
	watch_signals(_process)
	var success := await _process.start(config)
	if success:
		assert_signal_emitted(_process, "process_started")
	else:
		pending("Prepared runtime is unavailable on this host")

func test_is_running_returns_true_after_start() -> void:
	var success := await _process.start(config)
	if success:
		assert_true(_process.is_running())
	else:
		pending("Prepared runtime is unavailable on this host")

func test_stop_emits_process_stopped_signal() -> void:
	if not await _process.start(config):
		pending("Prepared runtime is unavailable on this host")
		return

	watch_signals(_process)
	await _process.stop()
	assert_signal_emitted(_process, "process_stopped")
	assert_signal_emitted_with_parameters(_process, "process_stopped", [0])

func test_stop_cleans_up_process() -> void:
	if not await _process.start(config):
		pending("Prepared runtime is unavailable on this host")
		return

	await _process.stop()
	assert_false(_process.is_running())

func test_start_fails_when_already_running() -> void:
	if not await _process.start(config):
		pending("Prepared runtime is unavailable on this host")
		return

	watch_signals(_process)
	var success := await _process.start(config)
	assert_false(success)
	assert_signal_emitted(_process, "process_error")
	assert_signal_emitted_with_parameters(_process, "process_error", ["Process already running"])
