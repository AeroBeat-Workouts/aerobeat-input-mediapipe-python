class_name AutoStartManager
extends Node

## Signals for progress and status updates
signal check_progress(percentage: int, message: String)
signal installation_progress(percentage: int, message: String)
signal installation_complete(success: bool)
signal server_started
signal server_stopped
signal server_failed(error: String)
signal python_not_found
signal mediapipe_not_found

## Public variables
var python_path: String = ""
var server_pid: int = -1
var install_pid: int = -1
var is_installing: bool = false

@onready var progress_timer: Timer = Timer.new()

func _ready():
	add_child(progress_timer)
	progress_timer.timeout.connect(_check_install_progress)
	
	# Auto-start the dependency check
	_check_and_start()

## Find Python - prefer venv, fallback to system
func _find_python() -> String:
	var venv_python = ProjectSettings.globalize_path("res://venv/bin/python")
	
	if FileAccess.file_exists(venv_python):
		return venv_python
	
	# Check for python3
	var output: Array = []
	var exit_code = OS.execute("which", ["python3"], output, true)
	if exit_code == 0 and output.size() > 0:
		return output[0].strip_edges()
	
	return "python3"

## Get the server PID for display
func get_server_pid() -> int:
	return server_pid

## Check if server is running (approximate)
func is_server_running() -> bool:
	return server_pid > 0

## Get install instructions for manual installation
func get_install_instructions() -> String:
	return """MediaPipe Installation Required

Auto-install failed. Please install manually:

1. Create virtual environment:
   python3 -m venv venv

2. Activate it:
   source venv/bin/activate

3. Install packages:
   pip install mediapipe opencv-python numpy

4. Restart Godot

Or check the install_deps.sh script."""

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
	python_path = _find_python()
	
	var output: Array = []
	var exit_code = OS.execute(python_path, ["-c", "import mediapipe; print('OK')"], output, true)
	
	if exit_code == 0 and output.size() > 0 and "OK" in output[0]:
		_emit_progress(100, "All dependencies ready - starting server...")
		return true
	else:
		_emit_progress(100, "MediaPipe not found - will attempt auto-install")
		emit_signal("mediapipe_not_found")
		return false

## Main entry point - check and start
func _check_and_start() -> void:
	_emit_progress(0, "Starting dependency check...")
	
	if not check_python_installed():
		emit_signal("server_failed", "Python 3 not found")
		return
	
	if not check_mediapipe_installed():
		# Try auto-install
		print("AutoStartManager: MediaPipe not found, attempting auto-install...")
		install_dependencies()
		return
	
	# All good, start server
	_start_server()

## Install dependencies automatically
func install_dependencies() -> void:
	if is_installing:
		print("AutoStartManager: Installation already in progress")
		return
	
	is_installing = true
	python_path = _find_python()
	
	emit_signal("installation_progress", 0, "Starting installation...")
	
	var install_script = ProjectSettings.globalize_path("res://install_deps.sh")
	
	if not FileAccess.file_exists(install_script):
		# Create venv and install manually
		_ensure_venv_and_install()
	else:
		# Run install script
		_run_install_script(install_script)

func _ensure_venv_and_install() -> void:
	"""Create venv and install packages directly."""
	emit_signal("installation_progress", 10, "Creating virtual environment...")
	
	var venv_path = ProjectSettings.globalize_path("res://venv")
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

func _run_install_script(script_path: String) -> void:
	"""Run the install_deps.sh script."""
	emit_signal("installation_progress", 10, "Running install_deps.sh...")
	
	var output: Array = []
	var exit_code = OS.execute("bash", [script_path], output, true)
	
	# Script ran - now check if it worked
	_finish_install_check()

func _check_install_progress() -> void:
	"""Check if installation is complete."""
	if install_pid <= 0:
		progress_timer.stop()
		return
	
	# Simulate progress
	emit_signal("installation_progress", 50, "Installing packages (this may take a few minutes)...")
	
	# Wait a bit then check completion
	progress_timer.stop()
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_finish_install_check)

func _finish_install_check() -> void:
	"""Verify installation succeeded."""
	is_installing = false
	install_pid = -1
	
	if check_mediapipe_installed():
		emit_signal("installation_complete", true)
		print("AutoStartManager: Dependencies installed successfully")
		_start_server()
	else:
		emit_signal("installation_complete", false)
		emit_signal("server_failed", "Installation completed but MediaPipe still not available")
		printerr("AutoStartManager: Auto-install failed")

## Start the MediaPipe server
func _start_server() -> void:
	python_path = _find_python()
	
	var server_script = ProjectSettings.globalize_path("res://python_mediapipe/main.py")
	
	if not FileAccess.file_exists(server_script):
		# Try alternative paths
		server_script = ProjectSettings.globalize_path("res://python-mediapipe/main.py")
	
	if not FileAccess.file_exists(server_script):
		emit_signal("server_failed", "Server script not found: " + server_script)
		return
	
	var args = [server_script]
	var pid = OS.execute(python_path, args, [], false)
	
	if pid > 0:
		server_pid = pid
		emit_signal("server_started")
		print("AutoStartManager: Server started with PID: ", pid)
	else:
		emit_signal("server_failed", "Failed to start server process")

## Stop the server
func stop_server() -> void:
	if server_pid > 0:
		# Try to kill the process
		var output: Array = []
		OS.execute("kill", [str(server_pid)], output, true)
		server_pid = -1
		emit_signal("server_stopped")
		print("AutoStartManager: Server stopped")

## Helper to emit progress
func _emit_progress(percentage: int, message: String) -> void:
	print("[AutoStartManager] ", percentage, "% - ", message)
	emit_signal("check_progress", percentage, message)

## Cleanup on exit
func _exit_tree():
	stop_server()
	progress_timer.stop()
