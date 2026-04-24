class_name AutoStartManager
extends Node

## Signals for progress and status updates
signal check_progress(percentage: int, message: String)
signal installation_progress(percentage: int, message: String)
signal installation_complete(success: bool)
signal server_started(pid: int)
signal server_stopped()
signal server_failed(error: String)
signal python_not_found
signal mediapipe_not_found

## Configuration
@export var server_port: int = 4242
@export var stream_port: int = 4243
@export var auto_start: bool = true
@export var use_camera_stream: bool = true
@export var model_complexity: int = 1
@export var preprocess_size: int = 480
@export var no_filter: bool = true
@export var heartbeat_interval_ms: int = 500  # Send heartbeat every 500ms

## Public variables
var python_path: String = ""
var server_pid: int = -1
var install_pid: int = -1
var is_installing: bool = false
var _is_running: bool = false
var _is_starting: bool = false  # Guard against concurrent starts
var _heartbeat_udp: PacketPeerUDP = null
var _heartbeat_timer: Timer = null

@onready var progress_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(progress_timer)
	progress_timer.timeout.connect(_check_install_progress)

	# Auto-start if configured (with delay to prevent race conditions)
	if auto_start:
		# Use call_deferred to ensure node is fully in tree first
		_start_if_not_running.call_deferred()

func _start_if_not_running() -> void:
	if not _is_running and not _is_starting:
		_check_and_start()

const RUNTIME_CONTRACT_VERSION := "unified-desktop-runtime-v1"
const RUNTIME_SCHEMA_VERSION := 1
const RUNTIME_MANIFEST_FILENAME := "runtime-manifest.json"
const RUNTIME_SENTINEL_FILENAME := ".runtime-ready"
const RUNTIME_ENTRYPOINT := "python_mediapipe/main.py"
const SUPPORTED_DESKTOP_PLATFORM_KEYS := ["linux-x64", "macos-x64", "windows-x64"]

## Find Python from the sidecar-owned unified desktop runtime only.
## We fail fast instead of silently falling back to a random system interpreter.
func _find_python() -> String:
	return _get_sidecar_python_path()

func _get_sidecar_assets_dir() -> String:
	return ProjectSettings.globalize_path(_resolve_package_path("../python_mediapipe/assets"))

func _get_sidecar_runtimes_dir() -> String:
	return ProjectSettings.globalize_path(_resolve_package_path("../python_mediapipe/assets/runtimes"))

func _is_mobile_platform() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

func _is_desktop_platform() -> bool:
	return OS.get_name() in ["Linux", "macOS", "Windows"]

func _get_runtime_mode() -> String:
	if OS.has_feature("template") and not OS.has_feature("editor"):
		return "release"
	return "dev"

func _get_platform_arch_key() -> String:
	if OS.has_feature("x86_64"):
		return "x64"
	if OS.has_feature("arm64"):
		return "arm64"
	if OS.has_feature("x86_32"):
		return "x86"

	var processor_name := OS.get_processor_name().to_lower().strip_edges()
	if processor_name.contains("x86_64") or processor_name.contains("amd64") or processor_name.contains("x64"):
		return "x64"
	if processor_name.contains("aarch64") or processor_name.contains("arm64"):
		return "arm64"
	if processor_name.contains("i386") or processor_name.contains("i686") or processor_name.contains("x86"):
		return "x86"
	return "unknown"

func _get_desktop_platform_key() -> String:
	if not _is_desktop_platform() or _is_mobile_platform():
		return ""

	var os_key := ""
	match OS.get_name():
		"Linux":
			os_key = "linux"
		"macOS":
			os_key = "macos"
		"Windows":
			os_key = "windows"
		_:
			return ""

	var platform_key := "%s-%s" % [os_key, _get_platform_arch_key()]
	if not SUPPORTED_DESKTOP_PLATFORM_KEYS.has(platform_key):
		return ""
	return platform_key

func _get_sidecar_runtime_root() -> String:
	var platform_key := _get_desktop_platform_key()
	if platform_key.is_empty():
		return ""
	return _get_sidecar_runtimes_dir().path_join(platform_key)

func _get_sidecar_runtime_manifest_path() -> String:
	var runtime_root := _get_sidecar_runtime_root()
	if runtime_root.is_empty():
		return ""
	return runtime_root.path_join(RUNTIME_MANIFEST_FILENAME)

func _get_sidecar_runtime_sentinel_path() -> String:
	var runtime_root := _get_sidecar_runtime_root()
	if runtime_root.is_empty():
		return ""
	return runtime_root.path_join(RUNTIME_SENTINEL_FILENAME)

func _get_sidecar_python_path() -> String:
	var runtime_root := _get_sidecar_runtime_root()
	if runtime_root.is_empty():
		return ""

	var platform_key := _get_desktop_platform_key()
	if platform_key.begins_with("windows-"):
		return runtime_root.path_join("venv").path_join("Scripts").path_join("python.exe")
	return runtime_root.path_join("venv").path_join("bin").path_join("python")

func _get_expected_runtime_python_relpath() -> String:
	var platform_key := _get_desktop_platform_key()
	if platform_key.begins_with("windows-"):
		return "venv/Scripts/python.exe"
	return "venv/bin/python"

func _get_runtime_prepare_command_hint() -> String:
	var platform_key := _get_desktop_platform_key()
	if platform_key.is_empty():
		platform_key = "<platform>"
	return "python3 python_mediapipe/prepare_runtime.py --platform %s --mode %s --create-venv --validate" % [platform_key, _get_runtime_mode()]

func _get_requirements_path() -> String:
	return ProjectSettings.globalize_path(_resolve_package_path("../python_mediapipe/requirements.txt"))

func _get_model_asset_path() -> String:
	return ProjectSettings.globalize_path(_resolve_package_path("../python_mediapipe/assets/models/" + _get_required_model_name()))

func _read_json_file(path: String) -> Variant:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)

func _is_runtime_manifest_mode_acceptable(manifest_mode: String, expected_mode: String) -> bool:
	if expected_mode == "release":
		return manifest_mode == "release"
	return manifest_mode == "dev" or manifest_mode == "release"

func _validate_sidecar_runtime() -> Dictionary:
	var errors := PackedStringArray()
	var result: Dictionary = {
		"valid": false,
		"platform_key": _get_desktop_platform_key(),
		"runtime_mode": _get_runtime_mode(),
		"runtime_root": _get_sidecar_runtime_root(),
		"python_path": _get_sidecar_python_path(),
		"errors": errors,
	}

	if _is_mobile_platform():
		errors.append("Mobile platforms stay on the native MediaPipe path; the desktop Python runtime contract is intentionally excluded here.")
		return result

	if not _is_desktop_platform():
		errors.append("Unsupported host platform for the desktop MediaPipe sidecar: %s" % OS.get_name())
		return result

	if String(result.get("platform_key", "")).is_empty():
		errors.append("Could not derive a supported desktop runtime platform key for OS=%s arch=%s" % [OS.get_name(), _get_platform_arch_key()])
		return result

	if String(result.get("runtime_root", "")).is_empty() or not DirAccess.dir_exists_absolute(String(result.get("runtime_root", ""))):
		errors.append("Missing sidecar runtime root: %s" % result.get("runtime_root", ""))
		errors.append("Prepare it first with: %s" % _get_runtime_prepare_command_hint())
		return result

	var manifest_path := _get_sidecar_runtime_manifest_path()
	var sentinel_path := _get_sidecar_runtime_sentinel_path()
	if not FileAccess.file_exists(manifest_path):
		errors.append("Missing sidecar runtime manifest: %s" % manifest_path)
	if not FileAccess.file_exists(sentinel_path):
		errors.append("Missing sidecar runtime sentinel: %s" % sentinel_path)
	if not FileAccess.file_exists(String(result.get("python_path", ""))):
		errors.append("Missing sidecar runtime Python executable: %s" % result.get("python_path", ""))
	if errors.size() > 0:
		errors.append("Repair or regenerate the runtime with: %s" % _get_runtime_prepare_command_hint())
		return result

	var manifest_data = _read_json_file(manifest_path)
	if typeof(manifest_data) != TYPE_DICTIONARY:
		errors.append("Unreadable sidecar runtime manifest JSON: %s" % manifest_path)
		return result

	var sentinel_data = _read_json_file(sentinel_path)
	if typeof(sentinel_data) != TYPE_DICTIONARY:
		errors.append("Unreadable sidecar runtime sentinel JSON: %s" % sentinel_path)
		return result

	var manifest: Dictionary = manifest_data
	var sentinel: Dictionary = sentinel_data
	var expected_mode := String(result.get("runtime_mode", ""))
	var expected_platform_key := String(result.get("platform_key", ""))
	var expected_python_relpath := _get_expected_runtime_python_relpath()

	if manifest.get("contract_version", "") != RUNTIME_CONTRACT_VERSION:
		errors.append("Runtime contract_version mismatch: expected %s, got %s" % [RUNTIME_CONTRACT_VERSION, manifest.get("contract_version", "<missing>")])
	if int(manifest.get("schema_version", -1)) != RUNTIME_SCHEMA_VERSION:
		errors.append("Runtime schema_version mismatch: expected %d, got %s" % [RUNTIME_SCHEMA_VERSION, str(manifest.get("schema_version", "<missing>"))])
	if String(manifest.get("platform_key", "")) != expected_platform_key:
		errors.append("Runtime platform_key mismatch: expected %s, got %s" % [expected_platform_key, manifest.get("platform_key", "<missing>")])

	var manifest_mode := String(manifest.get("mode", ""))
	if not _is_runtime_manifest_mode_acceptable(manifest_mode, expected_mode):
		errors.append("Runtime mode mismatch: expected %s-compatible runtime, got %s" % [expected_mode, manifest_mode if not manifest_mode.is_empty() else "<missing>"])

	if String(manifest.get("entrypoint", "")) != RUNTIME_ENTRYPOINT:
		errors.append("Runtime entrypoint mismatch: expected %s, got %s" % [RUNTIME_ENTRYPOINT, manifest.get("entrypoint", "<missing>")])
	if String(manifest.get("python_executable", "")) != expected_python_relpath:
		errors.append("Runtime python_executable mismatch: expected %s, got %s" % [expected_python_relpath, manifest.get("python_executable", "<missing>")])

	if String(sentinel.get("platform_key", "")) != expected_platform_key:
		errors.append("Runtime sentinel platform_key mismatch: expected %s, got %s" % [expected_platform_key, sentinel.get("platform_key", "<missing>")])
	if String(sentinel.get("contract_version", "")) != RUNTIME_CONTRACT_VERSION:
		errors.append("Runtime sentinel contract_version mismatch: expected %s, got %s" % [RUNTIME_CONTRACT_VERSION, sentinel.get("contract_version", "<missing>")])

	var model_assets = manifest.get("model_assets", [])
	if typeof(model_assets) != TYPE_ARRAY or model_assets.is_empty():
		errors.append("Runtime manifest missing model_assets inventory")
	else:
		for model_variant in model_assets:
			if typeof(model_variant) != TYPE_DICTIONARY:
				errors.append("Runtime manifest has malformed model_assets entry: %s" % str(model_variant))
				continue
			var model_entry: Dictionary = model_variant
			var relative_path := String(model_entry.get("relative_path", ""))
			if relative_path.is_empty():
				errors.append("Runtime manifest has model_assets entry without relative_path")
				continue
			var absolute_path := ProjectSettings.globalize_path("res://../" + relative_path)
			if not FileAccess.file_exists(absolute_path):
				errors.append("Required model asset listed in runtime manifest is missing: %s" % absolute_path)

	result["valid"] = errors.is_empty()
	return result

## Get the server PID for display
func get_server_pid() -> int:
	return server_pid

## Check if server is running
func is_server_running() -> bool:
	# Safety: PID 0 and 1 are never valid for our server
	if server_pid <= 1:
		return false

	# Method 1: Check if process group is alive using negative PGID
	var output: Array = []
	var exit_code: int = OS.execute("/bin/kill", ["-0", "-" + str(server_pid)], output, false)
	if exit_code == 0:
		return true

	# Method 2: Check server log for recent activity (more reliable during startup)
	# This handles the case where process group detection fails but server is actually running
	output.clear()
	OS.execute("grep", ["-c", "MediaPipe started", "/tmp/aerobeat_server.log"], output, false)
	if output.size() > 0:
		var count_str: String = output[0].strip_edges()
		if count_str.is_valid_int() and int(count_str) > 0:
			return true

	return false

## Start the server (public API)
func start_server() -> bool:
	if _is_running:
		print("[AutoStartManager] Server already running")
		return true
	if _is_starting:
		print("[AutoStartManager] Server start already in progress")
		return false

	_is_starting = true
	var result: bool = await _check_and_start()
	_is_starting = false
	return result

## Stop the server
func stop_server() -> void:
	print("[AutoStartManager] stop_server() called, PID: ", server_pid)

	# Stop heartbeat first (Python will self-terminate if no heartbeat)
	_stop_heartbeat()

	# Small delay to let Python detect missing heartbeat
	OS.delay_msec(200)

	var output: Array = []

	# Use process group termination for reliable cleanup
	# This handles the case where OpenCV VideoCapture is in uninterruptible sleep (D state)

	# Step 1: Graceful SIGTERM to process group
	if server_pid > 1:
		print("[AutoStartManager] Sending SIGTERM to process group...")
		OS.execute("/bin/kill", ["-TERM", "-" + str(server_pid)], output, false)
		OS.delay_msec(300)

	# Step 2: Force kill with SIGKILL if still running
	if server_pid > 1 and _is_process_alive(server_pid):
		print("[AutoStartManager] Process still alive, sending SIGKILL...")
		OS.execute("/bin/kill", ["-KILL", "-" + str(server_pid)], output, false)
		OS.delay_msec(200)

	# Step 3: Fallback pkill patterns
	print("[AutoStartManager] Running cleanup patterns...")
	OS.execute("pkill", ["-9", "-f", "python_mediapipe/main.py"], output, false)
	OS.delay_msec(100)
	OS.execute("pkill", ["-9", "-f", "main.py"], output, false)
	OS.delay_msec(100)

	# Release camera as last resort
	OS.execute("fuser", ["-k", "-9", "/dev/video0"], output, false)
	OS.delay_msec(100)

	# Cleanup PID file
	var pid_file: String = "/tmp/aerobeat_autostart.pid"
	if FileAccess.file_exists(pid_file):
		DirAccess.remove_absolute(pid_file)

	# Close heartbeat socket
	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null

	server_pid = -1
	_is_running = false
	emit_signal("server_stopped")
	print("[AutoStartManager] Server stopped")

func _is_process_alive(pid: int) -> bool:
	if pid <= 1:
		print("[AutoStartManager] _is_process_alive: PID %d <= 1, returning false" % pid)
		return false
	var output: Array = []
	# Use negative PID to check process group
	print("[AutoStartManager] _is_process_alive: Running kill -0 -%d" % pid)
	var exit_code := OS.execute("/bin/kill", ["-0", "-" + str(pid)], output, false)
	print("[AutoStartManager] _is_process_alive: kill returned exit code %d" % exit_code)
	return exit_code == 0

## Main entry point - check and start
func _check_and_start() -> bool:
	_emit_progress(0, "Starting sidecar runtime validation...")

	if not check_python_installed():
		return false

	if not check_mediapipe_installed():
		return false

	if not check_model_asset_available():
		return false

	# All good, start server
	var result: bool = await _start_server()
	return result

## Check if the prepared sidecar runtime exists and Python is usable
func check_python_installed() -> bool:
	_emit_progress(25, "Resolving desktop sidecar runtime...")

	var runtime_validation := _validate_sidecar_runtime()
	if not bool(runtime_validation.get("valid", false)):
		var runtime_errors: PackedStringArray = runtime_validation.get("errors", PackedStringArray())
		var runtime_message: String = " | ".join(runtime_errors)
		_emit_progress(0, runtime_message)
		if runtime_message.contains("Python executable"):
			emit_signal("python_not_found")
		emit_signal("server_failed", runtime_message)
		return false

	python_path = String(runtime_validation.get("python_path", ""))
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

## Check if MediaPipe is installed in the resolved runtime
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

func _get_required_model_name() -> String:
	match model_complexity:
		2:
			return "pose_landmarker_heavy.task"
		1:
			return "pose_landmarker_full.task"
		_:
			return "pose_landmarker_lite.task"

## The legacy auto-install flow has been retired for the unified runtime contract.
## Desktop startup now fails fast and points callers at explicit runtime preparation.
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

## Kill any existing Python sidecar processes
func _kill_existing_servers() -> void:
	var output: Array = []
	# Use blocking=false to avoid freezing editor
	OS.execute("pkill", ["-f", "python_mediapipe/main.py"], output, false)
	# Small delay to let ports free up
	await get_tree().create_timer(0.5).timeout

## Start the MediaPipe server (detached mode - NON-BLOCKING)
## Uses setsid to create isolated process group for reliable termination
func _start_detached_server() -> int:
	# First kill any existing servers
	await _kill_existing_servers()

	var python: String = _find_python()
	# Use package-relative paths instead of hardcoded absolute paths
	var script: String = ProjectSettings.globalize_path(_resolve_package_path("../python_mediapipe/main.py"))
	var project_dir: String = ProjectSettings.globalize_path(_resolve_package_path(".."))

	# Store PID file for cleanup tracking
	var pid_file: String = "/tmp/aerobeat_autostart.pid"

	# Build the command with setsid for process group isolation
	# setsid creates a new session, making Python the session leader
	# This allows us to kill the entire group with kill -PID
	var bash_cmd: String = ""

	# Linux: Auto-detect DISPLAY environment variable
	if OS.get_name() == "Linux":
		bash_cmd += 'export DISPLAY=:1; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:0; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:2; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:1; '

	bash_cmd += "export HOME=/home/derrick && cd " + project_dir + " && "

	# Use setsid to create new session/process group
	# This is KEY for reliable termination even when OpenCV blocks
	bash_cmd += "setsid nohup " + python + " -u " + script + " "
	bash_cmd += "--camera 0 --port %d --model-complexity %d " % [server_port, model_complexity]
	if preprocess_size > 0:
		bash_cmd += "--preprocess-size %d " % preprocess_size
	if use_camera_stream:
		bash_cmd += "--stream-camera --stream-port %d " % stream_port
	if no_filter:
		bash_cmd += "--no-filter "
	bash_cmd += "> /tmp/aerobeat_server.log 2>&1 &"

	# Capture the PGID (process group ID) for later cleanup
	bash_cmd += " PGID=$!; "
	bash_cmd += " echo $PGID > " + pid_file + "; "
	bash_cmd += " wait $PGID; "
	bash_cmd += " rm -f " + pid_file

	# NON-BLOCKING execute - returns immediately (bash forks and continues)
	var bash_pid: int = OS.create_process("/bin/bash", ["-c", bash_cmd])

	if bash_pid <= 0:
		print("[AutoStartManager] ERROR: Failed to create bash process")
		return -1

	print("[AutoStartManager] Bash process created, PID: %d" % bash_pid)

	# Wait briefly for setsid to complete and PID file to be written
	print("[AutoStartManager] Waiting 0.5s for PID file...")
	if get_tree() == null:
		print("[AutoStartManager] ERROR: get_tree() is null!")
		return -1
	await get_tree().create_timer(0.5).timeout
	print("[AutoStartManager] Wait complete, reading PID file...")

	# Read the actual Python process group ID
	var pgid := _read_pid_file(pid_file)
	print("[AutoStartManager] Read PGID from file: %d" % pgid)

	if pgid > 0:
		print("[AutoStartManager] Started Python in process group ", pgid)
	else:
		print("[AutoStartManager] Warning: Could not read PGID, using bash PID ", bash_pid)
		pgid = bash_pid

	# Server is starting - return PGID immediately so heartbeats can begin
	# The caller (_start_server) will handle waiting and verification
	print("[AutoStartManager] Returning PGID %d immediately for heartbeat" % pgid)
	return pgid

func _resolve_package_path(relative_path: String) -> String:
	return "%s/%s" % [get_script().resource_path.get_base_dir(), relative_path]

func _read_pid_file(path: String) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text().strip_edges()
		file.close()
		if content.is_valid_int():
			return content.to_int()
	return -1

## Setup heartbeat to keep Python process alive
func _setup_heartbeat(heartbeat_port: int) -> void:
	print("[AutoStartManager] Setting up heartbeat on port %d" % heartbeat_port)

	if _heartbeat_udp == null:
		_heartbeat_udp = PacketPeerUDP.new()
		var err := _heartbeat_udp.set_dest_address("127.0.0.1", heartbeat_port)
		if err != OK:
			print("[AutoStartManager] ERROR: Failed to set heartbeat destination, error: %d" % err)
		else:
			print("[AutoStartManager] Heartbeat target: 127.0.0.1:%d" % heartbeat_port)

	if _heartbeat_timer == null:
		_heartbeat_timer = Timer.new()
		_heartbeat_timer.wait_time = heartbeat_interval_ms / 1000.0
		_heartbeat_timer.autostart = true
		_heartbeat_timer.timeout.connect(_send_heartbeat)
		add_child(_heartbeat_timer)
		print("[AutoStartManager] Heartbeat timer started (interval: %dms)" % heartbeat_interval_ms)
	else:
		_heartbeat_timer.start()

func _send_heartbeat() -> void:
	if _heartbeat_udp == null:
		return

	# Always send heartbeat if we have a valid PID
	# Don't check is_server_running() here - it can fail during startup
	# Python will self-terminate if it doesn't receive heartbeats
	if server_pid <= 1:
		return

	var packet := PackedByteArray()
	packet.append(0x01)  # Heartbeat marker
	_heartbeat_udp.put_packet(packet)

func _stop_heartbeat() -> void:
	if _heartbeat_timer:
		_heartbeat_timer.stop()

## Poll for the Python server PID after giving it time to start
func _poll_for_server_pid() -> int:
	# Try multiple times with delay
	for i in range(20):  # Try 20 times with 0.5s delay = 10 seconds max
		# Check if server log shows it's running (more reliable than pgrep)
		var log_check: Array = []
		OS.execute("grep", ["-c", "Initializing MediaPipe", "/tmp/aerobeat_server.log"], log_check, true)

		if log_check.size() > 0:
			var count_str: String = log_check[0].strip_edges()
			if count_str.is_valid_int() and int(count_str) > 0:
				# Server is running! Now get the PID
				var pgrep_output: Array = []
				OS.execute("pgrep", ["-f", "python_mediapipe/main.py"], pgrep_output, true)

				if pgrep_output.size() > 0:
					var lines: PackedStringArray = pgrep_output[0].split("\n")
					for line: String in lines:
						line = line.strip_edges()
						if line.is_valid_int():
							var found_pid: int = int(line)
							if found_pid > 0:
								return found_pid

		await get_tree().create_timer(0.5).timeout

	return -1

## Start the MediaPipe server with proper arguments
func _start_server() -> bool:
	print("[AutoStartManager] _start_server() called")

	# Try detached mode first (prevents stdout pipe blocking)
	print("[AutoStartManager] Calling _start_detached_server()...")

	# Start server and get PGID immediately
	var detached_pid: int = await _start_detached_server()
	print("[AutoStartManager] _start_detached_server() returned PID: %d" % detached_pid)

	if detached_pid <= 0:
		emit_signal("server_failed", "Failed to start detached server")
		return false

	server_pid = detached_pid
	_is_running = true

	# CRITICAL: Start heartbeat IMMEDIATELY before Python times out (3s timeout)
	print("[AutoStartManager] Starting heartbeat immediately...")
	_setup_heartbeat(server_port + 2)

	# Send first heartbeat right away
	_send_heartbeat()
	print("[AutoStartManager] First heartbeat sent")

	emit_signal("server_started", detached_pid)

	# Now wait for server to fully initialize (but heartbeats are already flowing)
	print("[AutoStartManager] Waiting 2.0s for server to stabilize...")
	await get_tree().create_timer(2.0).timeout

	if is_server_running():
		print("[AutoStartManager] Server is running after wait!")
		return true
	else:
		var log_output: Array = []
		OS.execute("cat", ["/tmp/aerobeat_server.log"], log_output, false)
		if log_output.size() > 0:
			print("[AutoStartManager] Server log:\n" + log_output[0])
		server_pid = -1
		_is_running = false
		_stop_heartbeat()
		emit_signal("server_failed", "Server exited - check /tmp/aerobeat_server.log")
		return false

## Helper to emit progress
func _emit_progress(percentage: int, message: String) -> void:
	print("[AutoStartManager] ", percentage, "% - ", message)
	emit_signal("check_progress", percentage, message)

## Cleanup on exit - ensure server stops when scene/game ends
func _exit_tree() -> void:
	stop_server()
	progress_timer.stop()

## Also cleanup when node is removed from tree
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			print("[AutoStartManager] PREDELETE - emergency cleanup")
			_stop_sync()
		NOTIFICATION_EXIT_TREE:
			print("[AutoStartManager] EXIT_TREE - stopping server")
			_stop_sync()
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("[AutoStartManager] WM_CLOSE_REQUEST - stopping server")
			_stop_sync()

func _stop_sync() -> void:
	## Synchronous stop for notifications
	_stop_heartbeat()
	OS.delay_msec(200)  # Let Python detect missing heartbeat

	if server_pid > 1:
		var output: Array = []
		OS.execute("/bin/kill", ["-TERM", "-" + str(server_pid)], output, true)
		OS.delay_msec(300)

		if _is_process_alive(server_pid):
			OS.execute("/bin/kill", ["-KILL", "-" + str(server_pid)], output, true)
			OS.delay_msec(100)

	# Cleanup PID file
	var pid_file: String = "/tmp/aerobeat_autostart.pid"
	if FileAccess.file_exists(pid_file):
		DirAccess.remove_absolute(pid_file)

	# Close UDP
	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null

	_is_running = false
	server_pid = -1
