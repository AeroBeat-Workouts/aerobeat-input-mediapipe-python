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
	
	# Check if process group is alive using negative PGID
	# kill -0 returns 0 if process exists, non-zero if it doesn't
	var output: Array = []
	var exit_code: int = OS.execute("/bin/kill", ["-0", "-" + str(server_pid)], output, false)
	return exit_code == 0

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
## Uses setsid to create isolated process group for reliable termination
func _start_detached_server() -> int:
	# First kill any existing servers
	await _kill_existing_servers()
	
	var python: String = "/usr/bin/python3"
	# Use project-relative paths instead of hardcoded absolute paths
	var script: String = ProjectSettings.globalize_path("res://python_mediapipe/main.py")
	var venv_packages: String = ProjectSettings.globalize_path("res://venv/lib/python3.12/site-packages")
	var project_dir: String = ProjectSettings.globalize_path("res://")
	
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
	bash_cmd += "PYTHONPATH=" + venv_packages + " "
	
	# Use setsid to create new session/process group
	# This is KEY for reliable termination even when OpenCV blocks
	bash_cmd += "setsid nohup " + python + " -u " + script + " "
	bash_cmd += "--camera 0 --port 4242 --model-complexity 1 --preprocess-size 480 --stream-camera --stream-port 4243 --no-filter"
	bash_cmd += " > /tmp/aerobeat_server.log 2>&1 &"
	
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
	
	# Wait for server to fully start
	print("[AutoStartManager] Waiting 2.5s for server to start...")
	if get_tree() == null:
		print("[AutoStartManager] ERROR: get_tree() is null before 2.5s wait!")
		return -1
	await get_tree().create_timer(2.5).timeout
	print("[AutoStartManager] 2.5s wait complete")
	
	# Verify server is actually running
	print("[AutoStartManager] Checking if PGID %d is alive..." % pgid)
	var is_alive := _is_process_alive(pgid)
	print("[AutoStartManager] _is_process_alive returned: %s" % str(is_alive))
	
	if is_alive:
		print("[AutoStartManager] PGID %d is alive, returning success" % pgid)
		return pgid
	
	print("[AutoStartManager] PGID %d is NOT alive, returning failure" % pgid)
	return -1

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
		print("[AutoStartManager] Heartbeat: UDP socket is null")
		return
	
	var running := is_server_running()
	if not running:
		print("[AutoStartManager] Heartbeat: Server not running (PID: %d)" % server_pid)
		return
	
	var packet := PackedByteArray()
	packet.append(0x01)  # Heartbeat marker
	var err := _heartbeat_udp.put_packet(packet)
	if err != OK:
		print("[AutoStartManager] Heartbeat: Failed to send packet, error: %d" % err)

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
	var detached_pid: int = await _start_detached_server()
	print("[AutoStartManager] _start_detached_server() returned PID: %d" % detached_pid)
	
	if detached_pid > 0:
		server_pid = detached_pid
		_is_running = true
		
		# Setup heartbeat on port + 2 (avoid conflict with stream port at +1)
		_setup_heartbeat(server_port + 2)
		
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
			_stop_heartbeat()
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
