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

func _ready():
	add_child(progress_timer)
	progress_timer.timeout.connect(_check_install_progress)
	
	# Auto-start if configured
	if auto_start:
		_check_and_start()

## Find Python - prefer project venv in repo, fallback to system
func _find_python() -> String:
	# Prefer project venv in the repo (not workspace - sandbox issues)
	var repo_venv = "/home/derrick/Github/AeroBeat/aerobeat-input-mediapipe-python/.testbed/venv/bin/python"
	if FileAccess.file_exists(repo_venv):
		print("AutoStartManager: Found repo venv Python: " + repo_venv)
		return repo_venv
	
	# Check for system python3
	var output: Array = []
	var exit_code = OS.execute("which", ["python3"], output, true)
	if exit_code == 0 and output.size() > 0:
		var system_python = output[0].strip_edges()
		print("AutoStartManager: Found system Python: " + system_python)
		return system_python
	
	print("AutoStartManager: Falling back to 'python3'")
	return "python3"

## Get the server PID for display
func get_server_pid() -> int:
	return server_pid

## Check if server is running
func is_server_running() -> bool:
	# Safety: PID 0 and 1 are never valid for our server
	if server_pid <= 1:
		return false
	
	# Check if process is alive (Linux/Mac)
	var output: Array = []
	var exit_code = OS.execute("kill", ["-0", str(server_pid)], output, true)
	return exit_code == 0

## Start the server (public API)
func start_server() -> bool:
	if _is_running:
		return true
	var result = await _check_and_start()
	return result

## Stop the server
func stop_server() -> void:
	# Safety check: NEVER kill PID 0 or 1 (kernel/init)
	if server_pid <= 1:
		server_pid = -1
		_is_running = false
		return
	
	if server_pid > 1:
		# Kill the Python process and any children
		var output: Array = []
		OS.execute("pkill", ["-P", str(server_pid)], output, true)  # Kill children first
		OS.execute("kill", [str(server_pid)], output, true)  # Kill parent
		
		server_pid = -1
		_is_running = false
		emit_signal("server_stopped")
		print("AutoStartManager: Server stopped")

## Main entry point - check and start
func _check_and_start() -> bool:
	_emit_progress(0, "Starting dependency check...")
	
	if not check_python_installed():
		emit_signal("server_failed", "Python 3 not found")
		return false
	
	if not check_mediapipe_installed():
		print("AutoStartManager: MediaPipe not found, attempting auto-install...")
		install_dependencies()
		return false  # Will restart after install
	
	# All good, start server
	var result = await _start_server()
	return result

## Check if Python is available
func check_python_installed() -> bool:
	_emit_progress(25, "Looking for Python...")
	python_path = _find_python()
	
	var output: Array = []
	var exit_code = OS.execute(python_path, ["--version"], output, true)
	
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
	var exit_code = OS.execute(python_path, ["-c", "import mediapipe; print('OK')"], output, true)
	
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
		print("AutoStartManager: Installation already in progress")
		return
	
	is_installing = true
	python_path = _find_python()
	
	emit_signal("installation_progress", 0, "Starting installation...")
	
	# Install using pip directly
	_ensure_venv_and_install()

func _ensure_venv_and_install() -> void:
	"""Create venv and install packages directly."""
	emit_signal("installation_progress", 10, "Creating virtual environment...")
	
	# Create venv in repo location (not workspace - sandbox issues)
	var venv_path = "/home/derrick/Github/AeroBeat/aerobeat-input-mediapipe-python/.testbed/venv"
	var output: Array = []
	var exit_code = OS.execute("python3", ["-m", "venv", venv_path], output, true)
	
	if exit_code != 0:
		is_installing = false
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Failed to create virtual environment")
		return
	
	# Update python path after venv creation
	python_path = _find_python()
	
	emit_signal("installation_progress", 25, "Installing MediaPipe...")
	
	# Install packages
	var args = ["-m", "pip", "install", "mediapipe", "opencv-python", "numpy"]
	var pid = OS.execute(python_path, args, [], false)
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
	
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_finish_install_check)

func _finish_install_check() -> void:
	is_installing = false
	install_pid = -1
	
	if check_mediapipe_installed():
		emit_signal("installation_complete", true)
		print("AutoStartManager: Dependencies installed successfully")
		await _start_server()
	else:
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Installation completed but MediaPipe still not available")

## Start the MediaPipe server (detached mode to avoid stdout blocking)
func _start_detached_server() -> int:
	"""Start server detached from Godot's stdout/stderr to prevent pipe blocking."""
	var python = _find_python()
	var script = _find_script()
	
	# Build arguments
	var args = PackedStringArray()
	args.append("/bin/bash")
	args.append("-c")
	# Redirect ALL output to files to prevent blocking
	var bash_cmd = python + " " + script + " " + _build_args_string() + " > /tmp/aerobeat_server.log 2>&1 &"
	bash_cmd += "; echo $!"  # Print PID
	args.append(bash_cmd)
	
	print("AutoStartManager: Starting detached server...")
	print("AutoStartManager: Command: bash -c '" + bash_cmd + "'")
	
	var output = []
	var result = OS.execute("/bin/bash", args, output, true)
	
	if result == OK and output.size() > 0:
		var pid = int(output[0].strip_edges())
		print("AutoStartManager: Detached server started with PID: " + str(pid))
		return pid
	else:
		print("AutoStartManager: Failed to start detached server: " + str(result))
		return -1

## Start the MediaPipe server with proper arguments
func _find_script() -> String:
	# Try multiple possible script locations
	var possible_paths = [
		"/home/derrick/.openclaw/workspace/addons/aerobeat-input-mediapipe/python_mediapipe/main.py"
	]
	
	for path in possible_paths:
		print("AutoStartManager: Checking for script at: " + path)
		if FileAccess.file_exists(path):
			print("AutoStartManager: Found script at: " + path)
			return path
	
	push_error("AutoStartManager: Script not found")
	return ""

func _build_args_string() -> String:
	var arg_str = "--camera 0 "
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
	print("AutoStartManager: Attempting detached server start...")
	var detached_pid = _start_detached_server()
	
	if detached_pid > 0:
		server_pid = detached_pid
		_is_running = true
		emit_signal("server_started", detached_pid)
		print("AutoStartManager: Detached server started with PID: ", detached_pid)
		
		# Wait briefly then verify it's still running
		await get_tree().create_timer(2.0).timeout
		if is_server_running():
			print("AutoStartManager: Server confirmed running")
			return true
		else:
			print("AutoStartManager: Detached server exited, trying to read log...")
			var log_output = []
			OS.execute("cat", ["/tmp/aerobeat_server.log"], log_output)
			if log_output.size() > 0:
				print("AutoStartManager: Server log:\n" + log_output[0])
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

## Cleanup on exit
func _exit_tree():
	stop_server()
	progress_timer.stop()
