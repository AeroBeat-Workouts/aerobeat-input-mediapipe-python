class_name AutoStartManager
extends Node

var _desktop_sidecar_runtime_script: GDScript = null
var _desktop_sidecar_launcher_script: GDScript = null

func _desktop_sidecar_runtime() -> GDScript:
	if _desktop_sidecar_runtime_script == null:
		_desktop_sidecar_runtime_script = load("%s/runtime/desktop_sidecar_runtime.gd" % get_script().resource_path.get_base_dir())
	return _desktop_sidecar_runtime_script

func _desktop_sidecar_launcher() -> GDScript:
	if _desktop_sidecar_launcher_script == null:
		_desktop_sidecar_launcher_script = load("%s/process/desktop_sidecar_launcher.gd" % get_script().resource_path.get_base_dir())
	return _desktop_sidecar_launcher_script

signal check_progress(percentage: int, message: String)
signal installation_progress(percentage: int, message: String)
signal installation_complete(success: bool)
signal server_started(pid: int)
signal server_stopped()
signal server_failed(error: String)
signal python_not_found
signal mediapipe_not_found

@export var server_port: int = 4242
@export var stream_port: int = 4243
@export var auto_start: bool = true
@export var use_camera_stream: bool = true
@export var model_complexity: int = 1
@export var preprocess_size: int = 480
@export var no_filter: bool = true
@export var heartbeat_interval_ms: int = 500
@export var camera_source_override: String = ""
@export var debug_logging: bool = false
@export var skip_sidecar_stop_on_close_debug: bool = false
@export var skip_sidecar_terminate_sync_on_close_debug: bool = false
@export var skip_linux_pkill_main_py_on_close_debug: bool = false

var python_path: String = ""
var server_pid: int = -1
var install_pid: int = -1
var is_installing: bool = false
var _is_running: bool = false
var _is_starting: bool = false
var _heartbeat_udp: PacketPeerUDP = null
var _heartbeat_timer: Timer = null
var _launch_info: Dictionary = {}
var _runtime_validation: Dictionary = {}
var _is_stopping: bool = false
var _shutdown_summary_logged: bool = false

@onready var progress_timer: Timer = Timer.new()

func _debug_log(message: String) -> void:
	if not debug_logging:
		return
	print("[AutoStartManager] %s" % message)

func _log_shutdown_summary_once(reason: String) -> void:
	if _shutdown_summary_logged:
		_debug_log("Duplicate shutdown notification ignored (%s)" % reason)
		return
	_shutdown_summary_logged = true
	var stop_mode := _get_close_path_stop_mode_label()
	print("[AutoStartManager] Shutdown summary: reason=%s stop_mode=%s pid=%d running=%s launch=%s" % [
		reason,
		stop_mode,
		server_pid,
		str(_is_running),
		str(not _launch_info.is_empty()),
	])

func _ready() -> void:
	add_child(progress_timer)
	progress_timer.timeout.connect(_check_install_progress)
	if auto_start:
		_start_if_not_running.call_deferred()

func _start_if_not_running() -> void:
	if not _is_running and not _is_starting:
		_check_and_start()

func _find_python() -> String:
	return _desktop_sidecar_runtime().get_sidecar_python_path(get_script().resource_path)

func _resolve_package_path(relative_path: String) -> String:
	return _desktop_sidecar_runtime().resolve_package_path(get_script().resource_path, relative_path)

func _get_runtime_mode() -> String:
	return _desktop_sidecar_runtime().get_runtime_mode()

func _get_platform_arch_key() -> String:
	return _desktop_sidecar_runtime().get_platform_arch_key()

func _get_desktop_platform_key() -> String:
	return _desktop_sidecar_runtime().get_desktop_platform_key()

func _get_sidecar_runtime_root() -> String:
	return _desktop_sidecar_runtime().get_sidecar_runtime_root(get_script().resource_path)

func _get_runtime_prepare_command_hint() -> String:
	return _desktop_sidecar_runtime().get_runtime_prepare_command_hint(get_script().resource_path, _get_runtime_mode())

func _get_required_model_name() -> String:
	return _desktop_sidecar_runtime().get_required_model_name(model_complexity)

func _get_model_asset_path() -> String:
	return _desktop_sidecar_runtime().get_model_asset_path(get_script().resource_path, _get_required_model_name())

func _validate_sidecar_runtime() -> Dictionary:
	return _desktop_sidecar_runtime().validate_runtime(get_script().resource_path, _get_required_model_name())

func get_server_pid() -> int:
	return server_pid

func is_server_running() -> bool:
	if _launch_info.is_empty():
		return false
	if _desktop_sidecar_launcher().is_process_alive(_launch_info):
		return true
	if OS.get_name() == "Linux":
		var log_path := _get_server_log_path()
		if FileAccess.file_exists(log_path):
			var output: Array = []
			OS.execute("grep", ["-c", "MediaPipe started", log_path], output, false)
			if output.size() > 0:
				var count_str: String = output[0].strip_edges()
				if count_str.is_valid_int() and int(count_str) > 0:
					return true
	return false

func start_server() -> bool:
	if _is_running:
		_debug_log("Server already running")
		return true
	if _is_starting:
		_debug_log("Server start already in progress")
		return false

	_is_starting = true
	var result: bool = await _check_and_start()
	_is_starting = false
	return result

func stop_server() -> void:
	if _is_stopping:
		return
	if not _has_active_server_state():
		return

	_is_stopping = true
	_log_shutdown_summary_once("stop_server")
	_stop_heartbeat()
	OS.delay_msec(200)

	if not _launch_info.is_empty():
		var termination_result: Dictionary = await _desktop_sidecar_launcher().terminate(self, _launch_info, 2000)
		for note in termination_result.get("notes", PackedStringArray()):
			push_warning("[AutoStartManager] %s" % note)

	if OS.get_name() == "Linux":
		await _run_linux_cleanup_patterns()

	_cleanup_server_state()
	_is_stopping = false
	emit_signal("server_stopped")
	_debug_log("Server stopped")

func _has_active_server_state() -> bool:
	return _is_running or server_pid > 1 or not _launch_info.is_empty()

func _get_close_path_stop_mode_label() -> String:
	if skip_sidecar_stop_on_close_debug:
		return "heartbeat_only"
	var parts: PackedStringArray = ["normal_stop"]
	if skip_sidecar_terminate_sync_on_close_debug:
		parts.append("skip_terminate_sync")
	if OS.get_name() == "Linux" and skip_linux_pkill_main_py_on_close_debug:
		parts.append("skip_linux_pkill_main_py")
	return "+".join(parts)

func _run_linux_cleanup_patterns() -> void:
	var output: Array = []
	if skip_linux_pkill_main_py_on_close_debug:
		_debug_log("Close-path debug enabled: skipping Linux pkill -9 -f python_mediapipe/main.py")
	else:
		OS.execute("pkill", ["-9", "-f", "python_mediapipe/main.py"], output, false)
		OS.delay_msec(100)
	OS.execute("pkill", ["-9", "-f", "main.py"], output, false)
	OS.delay_msec(100)
	OS.execute("fuser", ["-k", "-9", "/dev/video0"], output, false)
	OS.delay_msec(100)

func _cleanup_server_state() -> void:
	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null
	_launch_info = {}
	_runtime_validation = {}
	server_pid = -1
	_is_running = false
	_is_stopping = false

func _is_process_alive(pid: int) -> bool:
	if pid <= 1:
		return false
	return _desktop_sidecar_launcher().is_process_alive(_launch_info)

func _check_and_start() -> bool:
	_emit_progress(0, "Starting sidecar runtime validation...")
	if not check_python_installed():
		return false
	if not check_mediapipe_installed():
		return false
	if not check_model_asset_available():
		return false
	return await _start_server()

func check_python_installed() -> bool:
	_emit_progress(25, "Resolving desktop sidecar runtime...")
	_runtime_validation = _validate_sidecar_runtime()
	if not bool(_runtime_validation.get("valid", false)):
		var runtime_errors: PackedStringArray = _runtime_validation.get("errors", PackedStringArray())
		var runtime_message: String = " | ".join(runtime_errors)
		_emit_progress(0, runtime_message)
		if runtime_message.contains("Python executable"):
			emit_signal("python_not_found")
		emit_signal("server_failed", runtime_message)
		return false

	python_path = String(_runtime_validation.get("python_path", ""))
	var output: Array = []
	var exit_code: int = OS.execute(python_path, ["--version"], output, true)
	if exit_code == 0:
		_emit_progress(50, "Runtime Python found at " + python_path)
		return true

	var message := "Prepared sidecar runtime Python failed to execute at %s. Repair it with: %s" % [python_path, _get_runtime_prepare_command_hint()]
	_emit_progress(0, message)
	emit_signal("python_not_found")
	emit_signal("server_failed", message)
	return false

func check_mediapipe_installed() -> bool:
	_emit_progress(75, "Checking MediaPipe installation in resolved runtime...")
	var output: Array = []
	var exit_code: int = OS.execute(python_path, ["-c", "import mediapipe; print('OK')"], output, true)
	if exit_code == 0 and output.size() > 0 and "OK" in output[0]:
		_emit_progress(100, "Python dependencies ready")
		return true

	var message := "MediaPipe is not importable from the prepared sidecar runtime at %s. Rebuild the runtime and install python_mediapipe/requirements.txt with: %s" % [_get_sidecar_runtime_root(), _get_runtime_prepare_command_hint()]
	_emit_progress(100, message)
	emit_signal("mediapipe_not_found")
	emit_signal("server_failed", message)
	return false

func check_model_asset_available() -> bool:
	var model_name := _get_required_model_name()
	var model_path := _get_model_asset_path()
	if FileAccess.file_exists(model_path):
		_emit_progress(100, "Model asset ready - starting server...")
		return true

	var message := "Missing MediaPipe model asset: %s (expected at %s)" % [model_name, model_path]
	_emit_progress(100, message)
	emit_signal("server_failed", message)
	return false

func install_dependencies() -> void:
	if is_installing:
		return
	is_installing = true
	var message := "Automatic sidecar runtime installation is disabled. Prepare the %s runtime first with: %s" % [_get_desktop_platform_key(), _get_runtime_prepare_command_hint()]
	emit_signal("installation_progress", 0, message)
	is_installing = false
	install_pid = -1
	emit_signal("installation_complete", false)
	emit_signal("server_failed", message)

func _ensure_venv_and_install() -> void:
	install_dependencies()

func _check_install_progress() -> void:
	progress_timer.stop()

func _finish_install_check() -> void:
	is_installing = false
	install_pid = -1
	emit_signal("installation_complete", false)

func _kill_existing_servers() -> void:
	if OS.get_name() == "Linux":
		var output: Array = []
		OS.execute("pkill", ["-f", "python_mediapipe/main.py"], output, false)
		await get_tree().create_timer(0.5).timeout

func _build_linux_prelaunch_commands() -> PackedStringArray:
	return PackedStringArray([
		"export DISPLAY=:1",
		"xdpyinfo >/dev/null 2>&1 || export DISPLAY=:0",
		"xdpyinfo >/dev/null 2>&1 || export DISPLAY=:2",
		"xdpyinfo >/dev/null 2>&1 || export DISPLAY=:1",
	])

func _get_server_log_path() -> String:
	if _launch_info.has("log_file"):
		return String(_launch_info.get("log_file", ""))
	return _desktop_sidecar_launcher().get_state_dir().path_join("autostart-last.log")

func _normalize_camera_source_value(raw_value: String) -> String:
	var normalized_value := raw_value.strip_edges()
	if normalized_value.is_empty():
		return ""
	return ProjectSettings.globalize_path(normalized_value) if not normalized_value.is_valid_int() else normalized_value

func _get_camera_source_override() -> String:
	var explicit_override := _normalize_camera_source_value(camera_source_override)
	if not explicit_override.is_empty():
		return explicit_override
	var env_override := _normalize_camera_source_value(OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE"))
	if not env_override.is_empty():
		return env_override
	return "0"

func get_active_camera_source() -> String:
	return _get_camera_source_override()

func _sidecar_show_window_requested() -> bool:
	var raw_value := OS.get_environment("AEROBEAT_MEDIAPIPE_SHOW_WINDOW").strip_edges().to_lower()
	return raw_value in ["1", "true", "yes", "on"]

func _start_detached_server() -> int:
	await _kill_existing_servers()

	var python: String = _find_python()
	var script: String = ProjectSettings.globalize_path(_resolve_package_path("python_mediapipe/main.py"))
	var project_dir: String = ProjectSettings.globalize_path(_desktop_sidecar_runtime().get_package_root(get_script().resource_path))
	var camera_source := _get_camera_source_override()
	var args := PackedStringArray([
		"-u",
		script,
		"--camera", camera_source,
		"--port", str(server_port),
		"--model-complexity", str(model_complexity),
	])
	if preprocess_size > 0:
		args.append_array(PackedStringArray(["--preprocess-size", str(preprocess_size)]))
	if use_camera_stream:
		args.append_array(PackedStringArray(["--stream-camera", "--stream-port", str(stream_port)]))
	if no_filter:
		args.append("--no-filter")
	if _sidecar_show_window_requested():
		args.append("--show-window")

	var options := {
		"working_directory": project_dir,
		"redirect_to_log": true,
		"startup_probe_delay_sec": 0.5,
	}
	if OS.get_name() == "Linux":
		options["prelaunch_commands"] = _build_linux_prelaunch_commands()

	_launch_info = await _desktop_sidecar_launcher().launch_detached(self, "autostart-mediapipe", python, args, options)
	if not bool(_launch_info.get("ok", false)):
		print("[AutoStartManager] ERROR: Failed to create detached sidecar launch")
		for note in _launch_info.get("notes", PackedStringArray()):
			print("[AutoStartManager] %s" % note)
		return -1

	server_pid = int(_launch_info.get("process_group_id", _launch_info.get("pid", -1)))
	print("[AutoStartManager] Started sidecar with strategy %s and server PID %d" % [String(_launch_info.get("strategy", "unknown")), server_pid])
	for note in _launch_info.get("notes", PackedStringArray()):
		print("[AutoStartManager] %s" % note)
	return server_pid

func _setup_heartbeat(heartbeat_port: int) -> void:
	_debug_log("Setting up heartbeat on port %d" % heartbeat_port)
	if _heartbeat_udp == null:
		_heartbeat_udp = PacketPeerUDP.new()
		var err := _heartbeat_udp.set_dest_address("127.0.0.1", heartbeat_port)
		if err != OK:
			push_warning("[AutoStartManager] Failed to set heartbeat destination, error: %d" % err)
		else:
			_debug_log("Heartbeat target: 127.0.0.1:%d" % heartbeat_port)

	if _heartbeat_timer == null:
		_heartbeat_timer = Timer.new()
		_heartbeat_timer.wait_time = heartbeat_interval_ms / 1000.0
		_heartbeat_timer.autostart = true
		_heartbeat_timer.timeout.connect(_send_heartbeat)
		add_child(_heartbeat_timer)
		_debug_log("Heartbeat timer started (interval: %dms)" % heartbeat_interval_ms)
	else:
		_heartbeat_timer.start()

func _send_heartbeat() -> void:
	if _heartbeat_udp == null:
		return
	if server_pid <= 1:
		return
	var packet := PackedByteArray()
	packet.append(0x01)
	_heartbeat_udp.put_packet(packet)

func _stop_heartbeat() -> void:
	if _heartbeat_timer:
		_heartbeat_timer.stop()

func _poll_for_server_pid() -> int:
	return server_pid

func _start_server() -> bool:
	_debug_log("_start_server() called")
	var detached_pid: int = await _start_detached_server()
	_debug_log("_start_detached_server() returned PID: %d" % detached_pid)
	if detached_pid <= 0:
		emit_signal("server_failed", "Failed to start detached server")
		return false

	server_pid = detached_pid
	_is_running = true
	_debug_log("Starting heartbeat immediately...")
	_setup_heartbeat(server_port + 2)
	_send_heartbeat()
	_debug_log("First heartbeat sent")
	emit_signal("server_started", detached_pid)

	_debug_log("Waiting 2.0s for server to stabilize...")
	await get_tree().create_timer(2.0).timeout
	if is_server_running():
		_debug_log("Server is running after wait!")
		return true

	var log_path := _get_server_log_path()
	if FileAccess.file_exists(log_path):
		var file := FileAccess.open(log_path, FileAccess.READ)
		if file:
			print("[AutoStartManager] Server log:\n" + file.get_as_text())
			file.close()
	_cleanup_server_state()
	_stop_heartbeat()
	emit_signal("server_failed", "Server exited - check %s" % log_path)
	return false

func _emit_progress(percentage: int, message: String) -> void:
	print("[AutoStartManager] %d%% - %s" % [percentage, message])
	emit_signal("check_progress", percentage, message)

func _exit_tree() -> void:
	if _has_active_server_state():
		if _should_skip_close_path_stop("EXIT_TREE"):
			_log_shutdown_summary_once("exit_tree/heartbeat_only")
		else:
			_log_shutdown_summary_once("exit_tree/stop_sync")
			_stop_sync()
	progress_timer.stop()

func _notification(what: int) -> void:
	if not _has_active_server_state():
		return
	match what:
		NOTIFICATION_PREDELETE:
			if _should_skip_close_path_stop("PREDELETE"):
				_log_shutdown_summary_once("predelete/heartbeat_only")
			else:
				_log_shutdown_summary_once("predelete/stop_sync")
				_stop_sync()
		NOTIFICATION_EXIT_TREE:
			if _should_skip_close_path_stop("EXIT_TREE"):
				_log_shutdown_summary_once("notification_exit_tree/heartbeat_only")
			else:
				_log_shutdown_summary_once("notification_exit_tree/stop_sync")
				_stop_sync()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _should_skip_close_path_stop("WM_CLOSE_REQUEST"):
				_log_shutdown_summary_once("wm_close_request/heartbeat_only")
			else:
				_log_shutdown_summary_once("wm_close_request/stop_sync")
				_stop_sync()

func _should_skip_close_path_stop(reason: String) -> bool:
	if not skip_sidecar_stop_on_close_debug:
		return false
	_debug_log("Close-path isolation active (%s): skipping normal sidecar stop; sidecar should self-exit after heartbeat timeout (~3s)" % reason)
	return true

func _stop_sync() -> void:
	if _is_stopping or not _has_active_server_state():
		return
	_stop_heartbeat()
	OS.delay_msec(200)
	if skip_sidecar_terminate_sync_on_close_debug:
		_debug_log("Close-path debug enabled: skipping DesktopSidecarLauncher.terminate_sync(_launch_info)")
	else:
		_desktop_sidecar_launcher().terminate_sync(_launch_info)
	if OS.get_name() == "Linux":
		_run_linux_cleanup_patterns()
	_cleanup_server_state()
