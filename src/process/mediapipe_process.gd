class_name MediaPipeProcess
extends Node
## Manages the Python MediaPipe sidecar process.
## Linux keeps the proven setsid/process-group launcher path for reliable teardown.
## macOS and Windows now have explicit direct-PID launch/stop scaffolding instead of
## silently inheriting Linux-only shell assumptions. Those non-Linux paths are structure,
## not parity claims; they remain unvalidated on this Linux host.

const DesktopSidecarRuntime = preload("res://addons/aerobeat-input-mediapipe-python/src/runtime/desktop_sidecar_runtime.gd")
const DesktopSidecarLauncher = preload("res://addons/aerobeat-input-mediapipe-python/src/process/desktop_sidecar_launcher.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

signal process_started()
signal process_stopped(exit_code: int)
signal process_error(error: String)
signal process_output(line: String)

@export var python_script_path: String = "python_mediapipe/main.py"
@export var termination_timeout_ms: int = 2000
@export var heartbeat_interval_ms: int = 500

var _pid: int = -1
var _pgid: int = -1
var _python_path: String = ""
var _config: MediaPipeConfig
var _is_shutting_down := false
var _launch_info: Dictionary = {}
var _runtime_validation: Dictionary = {}

var _heartbeat_timer: Timer = null
var _heartbeat_udp: PacketPeerUDP = null

func start(config: MediaPipeConfig) -> bool:
	if is_running():
		process_error.emit("Process already running")
		return false

	_config = config
	_is_shutting_down = false

	_runtime_validation = _validate_sidecar_runtime()
	if not bool(_runtime_validation.get("valid", false)):
		process_error.emit(" | ".join(_runtime_validation.get("errors", PackedStringArray())))
		return false

	_python_path = String(_runtime_validation.get("python_path", ""))
	if _python_path.is_empty():
		process_error.emit("Prepared sidecar runtime Python not found. Expected runtime root: %s" % _get_sidecar_runtime_root())
		return false

	var resolved_python_script_path := ProjectSettings.globalize_path(_resolve_package_path(python_script_path))
	if not FileAccess.file_exists(resolved_python_script_path):
		process_error.emit("Python script not found: " + resolved_python_script_path)
		return false

	var args := PackedStringArray([
		resolved_python_script_path,
		"--camera", str(config.camera_id),
		"--port", str(config.udp_port),
		"--host", "127.0.0.1",
		"--detection-confidence", str(config.detection_confidence),
		"--tracking-confidence", str(config.tracking_confidence),
		"--model-complexity", str(config.model_complexity),
	])

	_launch_info = await DesktopSidecarLauncher.launch_detached(
		self,
		"mediapipe-process",
		_python_path,
		args,
		{
			"working_directory": ProjectSettings.globalize_path(DesktopSidecarRuntime.get_package_root(get_script().resource_path)),
			"redirect_to_log": false,
			"startup_probe_delay_sec": 0.2,
		}
	)

	if not bool(_launch_info.get("ok", false)):
		var launch_notes: PackedStringArray = _launch_info.get("notes", PackedStringArray())
		var launch_message := "Failed to start MediaPipe sidecar for platform strategy %s" % String(_launch_info.get("platform", OS.get_name()))
		if not launch_notes.is_empty():
			launch_message += ": " + " | ".join(launch_notes)
		process_error.emit(launch_message)
		return false

	_pid = int(_launch_info.get("pid", -1))
	_pgid = int(_launch_info.get("process_group_id", -1))
	var strategy := String(_launch_info.get("strategy", "unknown"))
	print("[MediaPipeProcess] Started Python sidecar - Strategy: %s, PID: %d, PGID: %d" % [strategy, _pid, _pgid])
	var notes: PackedStringArray = _launch_info.get("notes", PackedStringArray())
	for note in notes:
		print("[MediaPipeProcess] %s" % note)

	_setup_heartbeat(config.udp_port + 2)
	process_started.emit()
	return true

func _get_required_model_name() -> String:
	if _config == null:
		return DesktopSidecarRuntime.get_required_model_name(1)
	return DesktopSidecarRuntime.get_required_model_name(_config.model_complexity)

func _validate_sidecar_runtime() -> Dictionary:
	return DesktopSidecarRuntime.validate_runtime(get_script().resource_path, _get_required_model_name())

func _setup_heartbeat(heartbeat_port: int) -> void:
	if _heartbeat_udp == null:
		_heartbeat_udp = PacketPeerUDP.new()
		_heartbeat_udp.set_dest_address("127.0.0.1", heartbeat_port)
		print("[MediaPipeProcess] Heartbeat target: 127.0.0.1:%d" % heartbeat_port)

	if _heartbeat_timer == null:
		_heartbeat_timer = Timer.new()
		_heartbeat_timer.wait_time = heartbeat_interval_ms / 1000.0
		_heartbeat_timer.autostart = true
		_heartbeat_timer.timeout.connect(_send_heartbeat)
		add_child(_heartbeat_timer)
	else:
		_heartbeat_timer.start()

func _send_heartbeat() -> void:
	if _heartbeat_udp and is_running():
		var packet := PackedByteArray()
		packet.append(0x01)
		_heartbeat_udp.put_packet(packet)

func _stop_heartbeat() -> void:
	if _heartbeat_timer:
		_heartbeat_timer.stop()

func stop() -> void:
	if _is_shutting_down:
		return
	if not _has_active_process_state():
		return

	_is_shutting_down = true
	print("[MediaPipeProcess] Stopping Python sidecar (PID: %d, PGID: %d)..." % [_pid, _pgid])
	_stop_heartbeat()
	OS.delay_msec(100)

	var termination_result := await DesktopSidecarLauncher.terminate(self, _launch_info, termination_timeout_ms)
	var termination_notes: PackedStringArray = termination_result.get("notes", PackedStringArray())
	for note in termination_notes:
		push_warning("[MediaPipeProcess] %s" % note)

	_cleanup_process_state()
	_is_shutting_down = false
	process_stopped.emit(0)

func _cleanup_process_state() -> void:
	_pid = -1
	_pgid = -1
	_launch_info = {}
	_runtime_validation = {}

	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null

func _has_active_process_state() -> bool:
	return _pid > 0 or _pgid > 0 or not _launch_info.is_empty()

func is_running() -> bool:
	if _launch_info.is_empty():
		return false
	return DesktopSidecarLauncher.is_process_alive(_launch_info)

func get_pid() -> int:
	return _pid

func get_process_group_id() -> int:
	return _pgid

func _resolve_package_path(relative_path: String) -> String:
	return DesktopSidecarRuntime.resolve_package_path(get_script().resource_path, relative_path)

func _get_platform_arch_key() -> String:
	return DesktopSidecarRuntime.get_platform_arch_key()

func _get_desktop_platform_key() -> String:
	return DesktopSidecarRuntime.get_desktop_platform_key()

func _get_sidecar_runtime_root() -> String:
	return DesktopSidecarRuntime.get_sidecar_runtime_root(get_script().resource_path)

func _find_python() -> String:
	var validation := _validate_sidecar_runtime()
	if bool(validation.get("valid", false)):
		return String(validation.get("python_path", ""))
	return ""

func _test_python(cmd: String) -> bool:
	var output: Array = []
	var exit_code: int = OS.execute(cmd, PackedStringArray(["--version"]), output, true)
	return exit_code == 0

func _notification(what: int) -> void:
	if not _has_active_process_state():
		return
	match what:
		NOTIFICATION_PREDELETE:
			print("[MediaPipeProcess] PREDELETE notification - force stopping process")
			_force_kill_immediate()
		NOTIFICATION_EXIT_TREE:
			print("[MediaPipeProcess] EXIT_TREE notification - stopping process")
			_stop_sync()
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("[MediaPipeProcess] WM_CLOSE_REQUEST notification - stopping process")
			_stop_sync()

func _stop_sync() -> void:
	if _is_shutting_down or not _has_active_process_state():
		return
	_stop_heartbeat()
	OS.delay_msec(200)
	DesktopSidecarLauncher.terminate_sync(_launch_info)
	_cleanup_process_state()

func _force_kill_immediate() -> void:
	if not _has_active_process_state():
		return
	_stop_heartbeat()
	DesktopSidecarLauncher.terminate_sync(_launch_info)
	_cleanup_process_state()

func check_dependencies() -> Dictionary:
	var result := {
		"python_found": false,
		"python_version": "",
		"mediapipe_installed": false,
		"opencv_installed": false,
		"errors": PackedStringArray(),
		"runtime_valid": false,
		"runtime_platform_key": _get_desktop_platform_key(),
	}

	var runtime_validation := _validate_sidecar_runtime()
	result.runtime_valid = bool(runtime_validation.get("valid", false))
	if not result.runtime_valid:
		result.errors = runtime_validation.get("errors", PackedStringArray())
		return result

	var python: String = String(runtime_validation.get("python_path", ""))
	if python.is_empty():
		result.errors.append("Prepared sidecar runtime Python not found at %s" % _get_sidecar_runtime_root())
		return result

	result.python_found = true

	var output: Array = []
	OS.execute(python, PackedStringArray(["--version"]), output, true)
	if output.size() > 0:
		result.python_version = output[0]

	output.clear()
	var exit: int = OS.execute(python, PackedStringArray(["-c", "import mediapipe; print('ok')"]), output, true)
	result.mediapipe_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
	if not result.mediapipe_installed:
		result.errors.append("MediaPipe not installed in the prepared sidecar runtime. Rebuild or refresh python_mediapipe/assets/runtimes/<platform>/ with python_mediapipe/prepare_runtime.py and install python_mediapipe/requirements.txt there.")

	output.clear()
	exit = OS.execute(python, PackedStringArray(["-c", "import cv2; print('ok')"]), output, true)
	result.opencv_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
	if not result.opencv_installed:
		result.errors.append("OpenCV not installed in the prepared sidecar runtime. Rebuild or refresh python_mediapipe/assets/runtimes/<platform>/ with python_mediapipe/prepare_runtime.py and install python_mediapipe/requirements.txt there.")

	return result
