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

## Public variables
var python_path: String = ""
var server_pid: int = -1
var install_pid: int = -1
var is_installing: bool = false
var _is_running: bool = false

@onready var progress_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(progress_timer)
	progress_timer.timeout.connect(_check_install_progress)
	
	# Auto-start if configured
	if auto_start:
		_check_and_start()

## Find Python - prefer project venv in repo, fallback to system
func _find_python() -> String:
	# Prefer project venv in the repo (not workspace - sandbox issues)
	var repo_venv: String = ProjectSettings.globalize_path("res://venv/bin/python")
	if FileAccess.file_exists(repo_venv):
		return repo_venv
	
	# Check for system python3
	var output: Array = []
	var exit_code: int = OS.execute("which", ["python3"], output, true)
	if exit_code == 0 and output.size() > 0:
		var system_python: String = output[0].strip_edges()
		return system_python
	
	return "python3"

## Get the server PID for display
func get_server_pid() -> int:
	return server_pid

## Check if server is running
func is_server_running() -> bool:
	# Safety: PID 0 and 1 are never valid for our server
	if server_pid <= 1:
		return false
	
	# Check if process is alive (Linux/Mac) - non-blocking
	var output: Array = []
	var exit_code: int = OS.execute("kill", ["-0", str(server_pid)], output, false)
	return exit_code == 0

## Start the server (public API)
func start_server() -> bool:
	if _is_running:
		return true
	var result: bool = await _check_and_start()
	return result

## Stop the server
func stop_server() -> void:
	# Safety check: NEVER kill PID 0 or 1 (kernel/init)
	if server_pid <= 1:
		server_pid = -1
		_is_running = false
		return
	
	if server_pid > 1:
		# Kill the Python process and any children (non-blocking)
		var output: Array = []
		OS.execute("pkill", ["-P", str(server_pid)], output, false)  # Kill children first
		OS.execute("kill", [str(server_pid)], output, false)  # Kill parent
		OS.execute("pkill", ["-f", "python_mediapipe/main.py"], output, false)  # Kill any stragglers
		
		server_pid = -1
		_is_running = false
		emit_signal("server_stopped")

## Main entry point - check and start
func _check_and_start() -> bool:
	_emit_progress(0, "Starting dependency check...")
	
	if not check_python_installed():
		emit_signal("server_failed", "Python 3 not found")
		return false
	
	if not check_mediapipe_installed():
		install_dependencies()
		return false  # Will restart after install
	
	# All good, start server
	var result: bool = await _start_server()
	return result

## Check if Python is available
func check_python_installed() -> bool:
	_emit_progress(25, "Looking for Python...")
	python_path = _find_python()
	
	var output: Array = []
	var exit_code: int = OS.execute(python_path, ["--version"], output, true)
	
	if exit_code == 0:
		_emit_progress(50, "Python found at " + python_path)
		return true
	else:
		_emit_progress(0, "Python not found")
		emit_signal("python_not_found")
		return false

## Check if MediaPipe is installed
func check_mediapipe_installed() -> bool:
	_emit_progress(75, "Checking MediaPipe installation...")
	
	var output: Array = []
	var exit_code: int = OS.execute(python_path, ["-c", "import mediapipe; print('OK')"], output, true)
	
	if exit_code == 0 and output.size() > 0 and "OK" in output[0]:
		_emit_progress(100, "All dependencies ready - starting server...")
		return true
	else:
		_emit_progress(100, "MediaPipe not found - will attempt auto-install")
		emit_signal("mediapipe_not_found")
		return false

## Install dependencies automatically
func install_dependencies() -> void:
	if is_installing:
		return
	
	is_installing = true
	python_path = _find_python()
	
	emit_signal("installation_progress", 0, "Starting installation...")
	
	# Install using pip directly
	_ensure_venv_and_install()

func _ensure_venv_and_install() -> void:
	emit_signal("installation_progress", 10, "Creating virtual environment...")
	
	# Create venv in repo location (not workspace - sandbox issues)
	var venv_path: String = ProjectSettings.globalize_path("res://venv")
	var output: Array = []
	var exit_code: int = OS.execute("python3", ["-m", "venv", venv_path], output, true)
	
	if exit_code != 0:
		is_installing = false
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Failed to create virtual environment")
		return
	
	# Update python path after venv creation
	python_path = _find_python()
	
	emit_signal("installation_progress", 25, "Installing dependencies from requirements.txt...")
	
	# Install packages from requirements.txt
	var requirements_path: String = ProjectSettings.globalize_path("res://python_mediapipe/requirements.txt")
	var args: PackedStringArray = ["-m", "pip", "install", "-r", requirements_path]
	var pid: int = OS.execute(python_path, args, [], false)
	install_pid = pid
	
	if pid > 0:
		progress_timer.start(2.0)
	else:
		is_installing = false
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Failed to start pip install")

func _check_install_progress() -> void:
	if install_pid <= 0:
		progress_timer.stop()
		return
	
	emit_signal("installation_progress", 50, "Installing packages (this may take a few minutes)...")
	progress_timer.stop()
	
	var timer: SceneTreeTimer = get_tree().create_timer(5.0)
	timer.timeout.connect(_finish_install_check)

func _finish_install_check() -> void:
	is_installing = false
	install_pid = -1
	
	if check_mediapipe_installed():
		emit_signal("installation_complete", true)
		await _start_server()
	else:
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Installation completed but MediaPipe still not available")

## Kill any existing Python sidecar processes
func _kill_existing_servers() -> void:
	var output: Array = []
	# Use blocking=false to avoid freezing editor
	OS.execute("pkill", ["-f", "python_mediapipe/main.py"], output, false)
	# Small delay to let ports free up
	await get_tree().create_timer(0.5).timeout

## Start the MediaPipe server (detached mode - NON-BLOCKING)
func _start_detached_server() -> int:
	# First kill any existing servers
	await _kill_existing_servers()
	
	var python: String = "/usr/bin/python3"
	# Use project-relative paths instead of hardcoded absolute paths
	var script: String = ProjectSettings.globalize_path("res://python_mediapipe/main.py")
	var venv_packages: String = ProjectSettings.globalize_path("res://venv/lib/python3.12/site-packages")
	var project_dir: String = ProjectSettings.globalize_path("res://")
	
	# Build the command - auto-detect DISPLAY on Linux (required for OpenCV camera access)
	var bash_cmd: String = ""
	
	# Linux: Auto-detect DISPLAY environment variable
	if OS.get_name() == "Linux":
		bash_cmd += 'export DISPLAY=:1; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:0; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:2; xdpyinfo >/dev/null 2>&1 || export DISPLAY=:1; '
	
	bash_cmd += "export HOME=/home/derrick && cd " + project_dir + " && "
	bash_cmd += "PYTHONPATH=" + venv_packages + " "
	bash_cmd += python + " -u " + script + " "
	bash_cmd += "--camera 0 --port 4242 --model-complexity 1 --preprocess-size 480 --stream-camera --stream-port 4243 --no-filter"
	bash_cmd += " > /tmp/aerobeat_server.log 2>&1 &"
	
	# NON-BLOCKING execute - returns immediately
	var pid: int = OS.create_process("/bin/bash", ["-c", bash_cmd])
	
	if pid <= 0:
		return -1
	
	# Wait asynchronously for server to start, then poll for the actual Python PID
	await get_tree().create_timer(3.0).timeout
	
	# Now poll for the actual Python server PID
	var server_pid_result: int = await _poll_for_server_pid()
	return server_pid_result

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
func _find_script() -> String:
	# Try multiple possible script locations
	var possible_paths: Array = [
		ProjectSettings.globalize_path("res://python_mediapipe/main.py")
	]
	
	for path: String in possible_paths:
		if FileAccess.file_exists(path):
			return path
	
	push_error("AutoStartManager: Script not found")
	return ""

func _build_args_string() -> String:
	var arg_str: String = "--camera 0 "
	arg_str += "--port " + str(server_port) + " "
	arg_str += "--model-complexity " + str(model_complexity) + " "
	arg_str += "--preprocess-size " + str(preprocess_size) + " "
	
	if use_camera_stream:
		arg_str += "--stream-camera --stream-port " + str(stream_port) + " "
	
	if no_filter:
		arg_str += "--no-filter"
	
	return arg_str

func _start_server() -> bool:
	# Try detached mode first (prevents stdout pipe blocking)
	var detached_pid: int = await _start_detached_server()
	
	if detached_pid > 0:
		server_pid = detached_pid
		_is_running = true
		emit_signal("server_started", detached_pid)
		
		# Wait briefly then verify it's still running
		await get_tree().create_timer(2.0).timeout
		
		if is_server_running():
			return true
		else:
			var log_output: Array = []
			OS.execute("cat", ["/tmp/aerobeat_server.log"], log_output, false)
			if log_output.size() > 0:
				print("[AutoStartManager] Server log:\n" + log_output[0])
			server_pid = -1
			_is_running = false
			emit_signal("server_failed", "Server exited - check /tmp/aerobeat_server.log")
			return false
	
	emit_signal("server_failed", "Failed to start detached server")
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
	if what == NOTIFICATION_PREDELETE:
		stop_server()
