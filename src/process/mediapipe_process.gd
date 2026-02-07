class_name MediaPipeProcess
extends Node
## Manages the Python MediaPipe sidecar process

signal process_started()
signal process_stopped(exit_code: int)
signal process_error(error: String)
signal process_output(line: String)

@export var python_script_path: String = "python_mediapipe/main.py"

var _pid: int = -1
var _python_path: String = ""
var _config: MediaPipeConfig
var _stdout_thread: Thread
var _stderr_thread: Thread
var _is_shutting_down := false

func start(config: MediaPipeConfig) -> bool:
	if is_running():
		process_error.emit("Process already running")
		return false
	
	_config = config
	
	# Find Python executable
	_python_path = _find_python()
	if _python_path.is_empty():
		process_error.emit("Python not found. Install Python 3.8+ and ensure it's in PATH")
		return false
	
	# Verify Python script exists
	if not FileAccess.file_exists(python_script_path):
		process_error.emit("Python script not found: " + python_script_path)
		return false
	
	# Build arguments
	var args := PackedStringArray([
		python_script_path,
		"--camera", str(config.camera_id),
		"--port", str(config.udp_port),
		"--host", "127.0.0.1",
		"--detection-confidence", str(config.detection_confidence),
		"--tracking-confidence", str(config.tracking_confidence),
		"--model-complexity", str(config.model_complexity)
	])
	
	# Start process
	_pid = OS.create_process(_python_path, args)
	if _pid == -1:
		process_error.emit("Failed to start Python process. Check Python installation.")
		return false
	
	process_started.emit()
	return true

func stop() -> void:
	if not is_running() or _is_shutting_down:
		return
	
	_is_shutting_down = true
	
	# Send SIGTERM for graceful shutdown
	var result = OS.kill(_pid)
	if result != OK:
		push_warning("Failed to send SIGTERM to process " + str(_pid))
	
	# Give process time to shut down gracefully
	await get_tree().create_timer(1.0).timeout
	
	# Force kill if still running
	if is_running():
		OS.kill(_pid)  # Second kill forces termination
	
	_pid = -1
	_is_shutting_down = false
	process_stopped.emit(0)

func is_running() -> bool:
	if _pid == -1:
		return false
	# Check if process is actually running
	return OS.is_process_running(_pid)

func get_pid() -> int:
	return _pid

func _find_python() -> String:
	# Check for virtual environment first
	if OS.has_environment("VIRTUAL_ENV"):
		var venv_python = OS.get_environment("VIRTUAL_ENV") + "/bin/python"
		if _test_python(venv_python):
			return venv_python
	
	# Try common Python paths
	var candidates := PackedStringArray([
		"python3",
		"python",
		"/usr/bin/python3",
		"/usr/local/bin/python3",
		"py"  # Windows
	])
	
	for cmd in candidates:
		if _test_python(cmd):
			return cmd
	
	return ""

func _test_python(cmd: String) -> bool:
	var output := []
	var exit_code := OS.execute(cmd, PackedStringArray(["--version"]), output, true)
	return exit_code == 0

func _notification(what: int) -> void:
	# Critical: Clean up on exit
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_running():
			stop()

## Check if Python dependencies are installed
func check_dependencies() -> Dictionary:
	var result := {
		"python_found": false,
		"python_version": "",
		"mediapipe_installed": false,
		"opencv_installed": false,
		"errors": []
	}
	
	var python = _find_python()
	if python.is_empty():
		result.errors.append("Python not found in PATH")
		return result
	
	result.python_found = true
	
	# Check Python version
	var output := []
	OS.execute(python, PackedStringArray(["--version"]), output, true)
	if output.size() > 0:
		result.python_version = output[0]
	
	# Check for mediapipe
	output.clear()
	var exit = OS.execute(python, PackedStringArray(["-c", "import mediapipe; print('ok')"]), output, true)
	result.mediapipe_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
	if not result.mediapipe_installed:
		result.errors.append("MediaPipe not installed. Run: pip install -r requirements.txt")
	
	# Check for opencv
	output.clear()
	exit = OS.execute(python, PackedStringArray(["-c", "import cv2; print('ok')"]), output, true)
	result.opencv_installed = (exit == 0 and output.size() > 0 and output[0].strip_edges() == "ok")
	if not result.opencv_installed:
		result.errors.append("OpenCV not installed. Run: pip install -r requirements.txt")
	
	return result