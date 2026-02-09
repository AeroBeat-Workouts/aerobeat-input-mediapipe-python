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

## Start the MediaPipe server with proper arguments
func _start_server() -> bool:
	# This is now a coroutine due to await calls
	python_path = _find_python()
	
	# Use repo path (not workspace - sandbox/permission issues)
	var possible_paths = [
		"/home/derrick/Github/AeroBeat/aerobeat-input-mediapipe-python/.testbed/python_mediapipe/main.py",
		"/home/derrick/.openclaw/workspace/addons/aerobeat-input-mediapipe/python_mediapipe/main.py"
	]
	
	var server_script = ""
	for path in possible_paths:
		print("AutoStartManager: Checking for script at: " + path)
		if FileAccess.file_exists(path):
			server_script = path
			print("AutoStartManager: Found script at: " + path)
			break
	
	if server_script == "":
		emit_signal("server_failed", "Server script not found in any location")
		return false
	
	# Build argument list
	var args = [
		server_script,
		"--camera", "0",
		"--port", str(server_port),
		"--model-complexity", str(model_complexity),
		"--preprocess-size", str(preprocess_size),
	]
	
	if use_camera_stream:
		args.append("--stream-camera")
		args.append("--stream-port")
		args.append(str(stream_port))
	
	if no_filter:
		args.append("--no-filter")
	
	print("AutoStartManager: Starting server with args: ", args)
	print("AutoStartManager: Using Python: " + python_path)
	print("AutoStartManager: Using script: " + server_script)
	
	# Check if Python exists
	if not FileAccess.file_exists(python_path):
		print("AutoStartManager: ERROR - Python not found at: " + python_path)
		emit_signal("server_failed", "Python not found at: " + python_path)
		return false
	
	# Try OS.create_process first (more reliable for spawning)
	print("AutoStartManager: Calling OS.create_process...")
	var pid = OS.create_process(python_path, args)
	print("AutoStartManager: create_process returned PID: " + str(pid))
	
	# Fall back to OS.execute if create_process fails
	if pid <= 0:
		print("AutoStartManager: create_process failed (returned " + str(pid) + "), trying execute...")
		pid = OS.execute(python_path, args, [], false)
		print("AutoStartManager: execute returned PID: " + str(pid))
	
	# Validate PID - must be > 1 (PID 1 is init, would crash system if killed)
	if pid > 1:
		server_pid = pid
		_is_running = true
		emit_signal("server_started", pid)
		print("AutoStartManager: Server started with PID: ", pid)
		
		# Verify process started by checking if it's still alive after a moment
		await get_tree().create_timer(1.0).timeout
		if not is_server_running():
			print("AutoStartManager: WARNING - Process started but exited immediately")
			server_pid = -1
			_is_running = false
			emit_signal("server_failed", "Server process exited immediately - check Python script")
			return false
		
		return true
	else:
		print("AutoStartManager: Failed to start server, got PID: ", pid)
		emit_signal("server_failed", "Failed to start server (PID: %d). Check Python is installed and script exists." % pid)
		return false

## Helper to emit progress
func _emit_progress(percentage: int, message: String) -> void:
	print("[AutoStartManager] ", percentage, "% - ", message)
	emit_signal("check_progress", percentage, message)

## Cleanup on exit
func _exit_tree():
	stop_server()
	progress_timer.stop()
