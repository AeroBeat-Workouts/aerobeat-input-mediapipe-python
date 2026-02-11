class_name MediaPipeProcess
extends Node
## Manages the Python MediaPipe sidecar process
## Uses process groups (setsid) for reliable termination even when OpenCV blocks

signal process_started()
signal process_stopped(exit_code: int)
signal process_error(error: String)
signal process_output(line: String)

@export var python_script_path: String = "python_mediapipe/main.py"
@export var termination_timeout_ms: int = 2000  # Time to wait for graceful shutdown
@export var heartbeat_interval_ms: int = 500  # Send heartbeat every 500ms

var _pid: int = -1
var _pgid: int = -1  # Process group ID for killing entire group
var _python_path: String = ""
var _config: MediaPipeConfig
var _stdout_thread: Thread
var _stderr_thread: Thread
var _is_shutting_down := false
var _termination_timer: Timer = null

# Heartbeat
var _heartbeat_timer: Timer = null
var _heartbeat_udp: PacketPeerUDP = null

func start(config: MediaPipeConfig) -> bool:
	if is_running():
		process_error.emit("Process already running")
		return false
	
	_config = config
	_is_shutting_down = false
	
	# Find Python executable
	_python_path = _find_python()
	if _python_path.is_empty():
		process_error.emit("Python not found. Install Python 3.8+ and ensure it's in PATH")
		return false
	
	# Verify Python script exists
	if not FileAccess.file_exists(python_script_path):
		process_error.emit("Python script not found: " + python_script_path)
		return false
	
	# Use setsid to create a new process group - this is critical for clean termination
	# when OpenCV VideoCapture is blocking in uninterruptible sleep
	var args := PackedStringArray([
		"-c",  # bash command mode
		_build_shell_command()
	])
	
	# Start bash which will start Python in a new session
	_pid = OS.create_process("/bin/bash", args)
	if _pid == -1:
		# Fallback: try direct process creation (may not clean up properly)
		push_warning("Failed to start with process group isolation, trying direct execution...")
		return _start_direct(config)
	
	# Wait a moment for the PID file to be written, then read the actual Python PGID
	await get_tree().create_timer(0.2).timeout
	_pgid = _read_process_group_id()
	
	print("[MediaPipeProcess] Started Python sidecar - Shell PID: ", _pid, ", Python PGID: ", _pgid)
	
	# Setup heartbeat (port + 2 to avoid conflict with stream port at +1)
	_setup_heartbeat(config.udp_port + 2)
	
	process_started.emit()
	return true

func _build_shell_command() -> String:
	## Build a shell command that:
	## 1. Starts Python with setsid (new session = new process group)
	## 2. Writes the PGID to a temp file for later cleanup
	## 3. Handles proper signal forwarding
	var pid_file = "/tmp/aerobeat_mediapipe_" + str(OS.get_unique_id()) + ".pid"
	var cmd = ""
	
	# Export config as environment variables (more reliable than long args)
	cmd += "export AEROBeat_CAMERA_ID=%d; " % _config.camera_id
	cmd += "export AEROBeat_PORT=%d; " % _config.udp_port
	cmd += "export AEROBeat_HOST=\"127.0.0.1\"; "
	cmd += "export AEROBeat_DETECTION_CONF=%.2f; " % _config.detection_confidence
	cmd += "export AEROBeat_TRACKING_CONF=%.2f; " % _config.tracking_confidence
	cmd += "export AEROBeat_MODEL_COMPLEXITY=%d; " % _config.model_complexity
	
	# Start Python with setsid (creates new process group)
	# Use nohup to prevent SIGHUP when parent dies
	# Use exec to replace shell process
	cmd += "setsid nohup %s %s" % [_python_path, python_script_path]
	
	# Add arguments (shortened)
	cmd += " --camera $AEROBeat_CAMERA_ID"
	cmd += " --port $AEROBeat_PORT"
	cmd += " --host $AEROBeat_HOST"
	cmd += " --detection-confidence $AEROBeat_DETECTION_CONF"
	cmd += " --tracking-confidence $AEROBeat_TRACKING_CONF"
	cmd += " --model-complexity $AEROBeat_MODEL_COMPLEXITY"
	
	# Background the process and capture its PGID
	cmd += " > /dev/null 2>&1 &"
	cmd += " PGID=$!; "
	cmd += " echo $PGID > %s; " % pid_file
	cmd += " wait $PGID; "  # Wait for process to complete
	cmd += " rm -f %s" % pid_file  # Clean up PID file
	
	return cmd

func _read_process_group_id() -> int:
	## Read the process group ID from the temp file
	var pid_file = "/tmp/aerobeat_mediapipe_" + str(OS.get_unique_id()) + ".pid"
	var file: FileAccess = FileAccess.open(pid_file, FileAccess.READ)
	if file:
		var content: String = file.get_as_text().strip_edges()
		file.close()
		if content.is_valid_int():
			return content.to_int()
	return -1

func _setup_heartbeat(heartbeat_port: int) -> void:
	## Setup UDP socket for sending heartbeats to Python
	if _heartbeat_udp == null:
		_heartbeat_udp = PacketPeerUDP.new()
		_heartbeat_udp.set_dest_address("127.0.0.1", heartbeat_port)
		print("[MediaPipeProcess] Heartbeat target: 127.0.0.1:%d" % heartbeat_port)
	
	# Create heartbeat timer
	if _heartbeat_timer == null:
		_heartbeat_timer = Timer.new()
		_heartbeat_timer.wait_time = heartbeat_interval_ms / 1000.0
		_heartbeat_timer.autostart = true
		_heartbeat_timer.timeout.connect(_send_heartbeat)
		add_child(_heartbeat_timer)
	else:
		_heartbeat_timer.start()

func _send_heartbeat() -> void:
	## Send heartbeat to Python process to keep it alive
	if _heartbeat_udp and is_running():
		var packet := PackedByteArray()
		packet.append(0x01)  # Heartbeat marker
		_heartbeat_udp.put_packet(packet)

func _stop_heartbeat() -> void:
	## Stop the heartbeat timer
	if _heartbeat_timer:
		_heartbeat_timer.stop()

func _start_direct(config: MediaPipeConfig) -> bool:
	## Fallback: start Python directly without process group isolation
	## Note: This may leave zombie processes if OpenCV blocks
	var args := PackedStringArray([
		python_script_path,
		"--camera", str(config.camera_id),
		"--port", str(config.udp_port),
		"--host", "127.0.0.1",
		"--detection-confidence", str(config.detection_confidence),
		"--tracking-confidence", str(config.tracking_confidence),
		"--model-complexity", str(config.model_complexity)
	])
	
	_pid = OS.create_process(_python_path, args)
	_pgid = _pid  # PGID = PID for direct processes
	
	if _pid == -1:
		process_error.emit("Failed to start Python process. Check Python installation.")
		return false
	
	process_started.emit()
	return true

func stop() -> void:
	if _is_shutting_down:
		return
	
	# Check if actually running
	if _pid == -1 and _pgid == -1:
		return
	
	_is_shutting_down = true
	print("[MediaPipeProcess] Stopping Python sidecar (PID: %d, PGID: %d)..." % [_pid, _pgid])
	
	# Stop heartbeat first (important: stop sending heartbeats so Python knows to exit)
	_stop_heartbeat()
	
	# Small delay to let Python detect missing heartbeat
	OS.delay_msec(100)
	
	# Use shell command to kill the entire process group
	# Strategy: SIGTERM first, wait, then SIGKILL if needed
	await _terminate_process_group()
	
	_pid = -1
	_pgid = -1
	_is_shutting_down = false
	process_stopped.emit(0)

func _terminate_process_group() -> void:
	## Terminate the entire process group with escalating force
	var pgid_to_kill: int = _pgid if _pgid > 0 else _pid
	if pgid_to_kill <= 0:
		return
	
	# Step 1: Send SIGTERM to entire process group
	var output: Array = []
	var exit_code: int
	
	# Try SIGTERM on the process group first
	exit_code = OS.execute("/bin/kill", PackedStringArray(["-TERM", "-" + str(pgid_to_kill)]), output, true)
	print("[MediaPipeProcess] Sent SIGTERM to process group %d (exit: %d)" % [pgid_to_kill, exit_code])
	
	# Step 2: Wait for graceful shutdown
	var elapsed := 0
	var check_interval := 100  # ms
	var max_wait := termination_timeout_ms
	
	while elapsed < max_wait:
		await get_tree().create_timer(check_interval / 1000.0).timeout
		elapsed += check_interval
		
		# Check if process group is still alive
		if not _is_process_group_alive(pgid_to_kill):
			print("[MediaPipeProcess] Process group %d terminated gracefully" % pgid_to_kill)
			return
	
	# Step 3: Force kill with SIGKILL
	push_warning("[MediaPipeProcess] Graceful shutdown timeout, forcing SIGKILL...")
	output.clear()
	exit_code = OS.execute("/bin/kill", PackedStringArray(["-KILL", "-" + str(pgid_to_kill)]), output, true)
	print("[MediaPipeProcess] Sent SIGKILL to process group %d (exit: %d)" % [pgid_to_kill, exit_code])
	
	# Step 4: Brief wait then check again
	await get_tree().create_timer(0.5).timeout
	
	if _is_process_group_alive(pgid_to_kill):
		push_error("[MediaPipeProcess] CRITICAL: Failed to kill process group %d even with SIGKILL!" % pgid_to_kill)
		push_error("[MediaPipeProcess] Manual cleanup required: sudo kill -9 -%d" % pgid_to_kill)
	else:
		print("[MediaPipeProcess] Process group %d killed successfully" % pgid_to_kill)
	
	# Clean up PID file if it exists
	var pid_file: String = "/tmp/aerobeat_mediapipe_" + str(OS.get_unique_id()) + ".pid"
	if FileAccess.file_exists(pid_file):
		DirAccess.remove_absolute(pid_file)

func _is_process_group_alive(pgid: int) -> bool:
	## Check if any process in the group is still alive
	if pgid <= 0:
		return false
	
	var output: Array = []
	var exit_code: int = OS.execute("/bin/kill", PackedStringArray(["-0", "-" + str(pgid)]), output, true)
	# kill -0 returns 0 if process exists, non-zero if it doesn't
	return exit_code == 0

func is_running() -> bool:
	# Check both the shell PID and the Python process group
	if _pid != -1 and OS.is_process_running(_pid):
		return true
	if _pgid > 0 and _is_process_group_alive(_pgid):
		return true
	return false

func get_pid() -> int:
	return _pid

func get_process_group_id() -> int:
	return _pgid

func _find_python() -> String:
	# Check for virtual environment first
	if OS.has_environment("VIRTUAL_ENV"):
		var venv_python: String = OS.get_environment("VIRTUAL_ENV") + "/bin/python"
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
	
	for cmd: String in candidates:
		if _test_python(cmd):
			return cmd
	
	return ""

func _test_python(cmd: String) -> bool:
	var output: Array = []
	var exit_code: int = OS.execute(cmd, PackedStringArray(["--version"]), output, true)
	return exit_code == 0

func _notification(what: int) -> void:
	# Critical: Clean up on exit - handle multiple scenarios
	match what:
		NOTIFICATION_PREDELETE:
			# Called when node is about to be deleted (earliest cleanup point)
			print("[MediaPipeProcess] PREDELETE notification - force killing process group")
			_force_kill_immediate()
		NOTIFICATION_EXIT_TREE:
			# Called when node leaves the scene tree
			print("[MediaPipeProcess] EXIT_TREE notification - stopping process")
			if is_running() or _pgid > 0:
				# Use call_deferred to handle async stop from sync notification
				_stop_sync()
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Called when window/application is closing
			print("[MediaPipeProcess] WM_CLOSE_REQUEST notification - stopping process")
			if is_running() or _pgid > 0:
				_stop_sync()

func _stop_sync() -> void:
	## Synchronous stop for use in notifications
	# Stop heartbeat first (so Python self-terminates)
	_stop_heartbeat()
	
	# Give Python a moment to detect missing heartbeat
	OS.delay_msec(200)
	
	# Try graceful termination first
	var pgid_to_kill: int = _pgid if _pgid > 0 else _pid
	if pgid_to_kill > 0:
		var output: Array = []
		OS.execute("/bin/kill", PackedStringArray(["-TERM", "-" + str(pgid_to_kill)]), output, true)
		
		# Wait briefly for graceful shutdown
		OS.delay_msec(500)
		
		# Force kill if still alive
		if _is_process_group_alive(pgid_to_kill):
			OS.execute("/bin/kill", PackedStringArray(["-KILL", "-" + str(pgid_to_kill)]), output, true)
			OS.delay_msec(100)
	
	# Clean up PID file
	var pid_file: String = "/tmp/aerobeat_mediapipe_" + str(OS.get_unique_id()) + ".pid"
	if FileAccess.file_exists(pid_file):
		DirAccess.remove_absolute(pid_file)
	
	# Close UDP
	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null

func _force_kill_immediate() -> void:
	## Force kill immediately without async/await (for use in _notification)
	## This is a synchronous last-resort cleanup
	_stop_heartbeat()
	
	var pgid_to_kill: int = _pgid if _pgid > 0 else _pid
	if pgid_to_kill <= 0:
		return
	
	var output: Array = []
	# Send SIGKILL immediately - no waiting
	OS.execute("/bin/kill", PackedStringArray(["-KILL", "-" + str(pgid_to_kill)]), output, true)
	
	# Clean up PID file
	var pid_file: String = "/tmp/aerobeat_mediapipe_" + str(OS.get_unique_id()) + ".pid"
	if FileAccess.file_exists(pid_file):
		DirAccess.remove_absolute(pid_file)
	
	# Close UDP
	if _heartbeat_udp:
		_heartbeat_udp.close()
		_heartbeat_udp = null

## Check if Python dependencies are installed
func check_dependencies() -> Dictionary:
	var result := {
		"python_found": false,
		"python_version": "",
		"mediapipe_installed": false,
		"opencv_installed": false,
		"errors": []
	}
	
	var python: String = _find_python()
	if python.is_empty():
		result.errors.append("Python not found in PATH")
		return result
	
	result.python_found = true
	
	# Check Python version
	var output: Array = []
	OS.execute(python, PackedStringArray(["--version"]), output, true)
	if output.size() > 0:
		result.python_version = output[0]
	
	# Check for mediapipe
	output.clear()
	var exit: int = OS.execute(python, PackedStringArray(["-c", "import mediapipe; print('ok')"]), output, true)
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
