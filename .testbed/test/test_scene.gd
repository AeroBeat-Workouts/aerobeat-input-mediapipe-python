extends Node2D
## Test scene for MediaPipe Provider with AutoStart and Camera Feed
## Automatically starts Python sidecar and displays camera feed with skeleton overlay

@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var camera_display: TextureRect = $CameraDisplay
@onready var landmark_drawer: Control = $CameraDisplay/LandmarkDrawer

var provider: Node = null
var auto_start_manager: Node = null
var camera_view: Node = null
var _frame_count: int = 0
var _server_ready: bool = false

func _ready() -> void:
	update_status("Initializing...", Color.WHITE)
	info_label.text = "Starting AutoStartManager..."
	
	# Setup AutoStartManager
	_setup_auto_start()

func _setup_auto_start() -> void:
	# Get AutoStartManager from scene (should already exist as child node)
	auto_start_manager = get_node_or_null("AutoStartManager")
	
	if auto_start_manager == null:
		push_error("[TestScene] AutoStartManager node not found in scene!")
		return
	
	# Connect signals
	auto_start_manager.server_started.connect(_on_server_started)
	auto_start_manager.server_failed.connect(_on_server_failed)
	auto_start_manager.server_stopped.connect(_on_server_stopped)
	auto_start_manager.python_not_found.connect(_on_python_not_found)
	auto_start_manager.mediapipe_not_found.connect(_on_mediapipe_not_found)
	auto_start_manager.check_progress.connect(_on_check_progress)
	auto_start_manager.installation_progress.connect(_on_install_progress)
	auto_start_manager.installation_complete.connect(_on_install_complete)
	
	# Start server (async)
	await auto_start_manager.start_server()

func _on_check_progress(percentage: int, message: String) -> void:
	update_status(str(percentage) + "% - " + message, Color.YELLOW)

func _on_install_progress(percentage: int, message: String) -> void:
	update_status("Installing: " + str(percentage) + "% - " + message, Color.ORANGE)
	info_label.text = "Setting up Python environment...\nThis may take a few minutes on first run."

func _on_install_complete(success: bool) -> void:
	if success:
		update_status("Installation complete! Starting server...", Color.GREEN)
	else:
		update_status("Installation failed!", Color.RED)
		info_label.text = "Failed to install dependencies.\nCheck the console for errors."

func _on_server_started(pid: int) -> void:
	update_status("Python server started (PID: " + str(pid) + ")", Color.GREEN)
	
	# Wait a moment for server to initialize
	await get_tree().create_timer(2.0).timeout
	_start_provider()
	await _start_camera_feed()

func _on_server_failed(error: String) -> void:
	update_status("Auto-start failed: " + error, Color.RED)
	info_label.text = """Auto-start failed!

You can start Python manually:

1. Open terminal
2. Run:
cd /home/derrick/.openclaw/workspace/addons/aerobeat-input-mediapipe
python3 python_mediapipe/main.py --camera 0 --show-window

3. Press F5 in Godot to restart this scene

Or check:
- Python 3 is installed
- Camera is connected
- No firewall blocking ports 4242/4243"""

func _on_server_stopped() -> void:
	update_status("Server stopped", Color.ORANGE)
	_server_ready = false

func _on_python_not_found() -> void:
	update_status("Python 3 not found!", Color.RED)
	info_label.text = "Python Not Found. Please install Python 3.8 or later."

func _on_mediapipe_not_found() -> void:
	update_status("MediaPipe not installed - Installing...", Color.YELLOW)
	info_label.text = "Installing MediaPipe...\nThis may take 2-5 minutes."

func _start_provider() -> void:
	var provider_script: GDScript = load("res://test/mediapipe_provider_test.gd")
	if provider_script:
		provider = provider_script.new()
		provider.name = "MediaPipeProvider"
		add_child(provider)
		
		provider.pose_updated.connect(_on_pose_updated)
		provider.tracking_lost.connect(_on_tracking_lost)
		provider.tracking_restored.connect(_on_tracking_restored)
		
		var success: bool = provider.start()
		if success:
			_server_ready = true
			update_status("Provider listening on port " + str(provider._server.get_bound_port()) + " - Waiting for tracking data...", Color.GREEN)
			info_label.text = """MediaPipe Provider Ready

Camera feed and tracking active.

Landmarks appear as green dots.
Make sure you're in a well-lit area."""
		else:
			update_status("Failed to start provider", Color.RED)

func _start_camera_feed() -> void:
	# Create camera view for MJPEG stream
	var CameraViewClass: GDScript = load("res://src/camera_view.gd")
	if CameraViewClass == null:
		push_error("[TestScene] Failed to load camera_view.gd")
		return
	
	camera_view = CameraViewClass.new()
	camera_view.name = "CameraView"
	camera_view.stream_url = "http://127.0.0.1:4243/camera"
	camera_view.position = Vector2(20, 80)
	camera_view.size = Vector2(640, 480)
	
	# Replace the display with camera feed
	camera_display.replace_by(camera_view)
	camera_display = camera_view
	
	# Reconnect landmark drawer to new camera display
	if landmark_drawer:
		landmark_drawer.reparent(camera_display)
	
	# Start the stream (async)
	await camera_view.start_stream()

func _process(_delta: float) -> void:
	_frame_count += 1
	
	# Check server liveness every 60 frames (~1 second)
	if _frame_count % 60 == 0:
		if auto_start_manager and auto_start_manager.server_pid > 0:
			var is_alive: bool = auto_start_manager.is_server_running()
			if not is_alive:
				update_status("Python server died!", Color.RED)
	
	if _frame_count % 30 == 0 and _server_ready:
		_update_debug_info()

func _on_pose_updated(landmarks: Array) -> void:
	if _frame_count % 60 == 0:
		update_status("Tracking active - " + str(landmarks.size()) + " landmarks detected", Color.GREEN)
	
	if landmark_drawer:
		landmark_drawer.update_landmarks(landmarks)

func _on_tracking_lost() -> void:
	update_status("Tracking lost - Check camera view", Color.ORANGE)
	if landmark_drawer:
		landmark_drawer.clear_landmarks()

func _on_tracking_restored() -> void:
	update_status("Tracking restored", Color.GREEN)

func update_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.modulate = color
	print("[MediaPipe Test] ", text)

func _update_debug_info() -> void:
	if not info_label or not provider or not _server_ready:
		return
	
	var info: String = "MediaPipe Provider Status\n"
	info += "==========================\n\n"
	
	if auto_start_manager:
		info += "Server PID: " + str(auto_start_manager.get_server_pid()) + "\n"
		info += "Server Running: " + str(auto_start_manager.is_server_running()) + "\n"
	
	if provider:
		info += "Provider Port: %d\n" % provider._server.get_bound_port()
		info += "Is Tracking: %s\n" % str(provider.is_tracking())
		info += "Camera Feed: %s\n" % ("Active" if camera_view and camera_view.is_streaming() else "Inactive")
		
		info += "\nDetected Positions:\n"
		info += "  Left Hand: %s\n" % (_format_pos(provider.get_left_hand_position()))
		info += "  Right Hand: %s\n" % (_format_pos(provider.get_right_hand_position()))
		info += "  Head: %s\n" % (_format_pos(provider.get_head_position()))
	
	info_label.text = info

func _format_pos(pos: Variant) -> String:
	if pos == null:
		return "N/A"
	if pos is Vector2:
		return "(%.2f, %.2f)" % [pos.x, pos.y]
	if pos is Vector3:
		return "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
	return str(pos)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if provider:
			provider.stop()
		if auto_start_manager:
			auto_start_manager.stop_server()
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE:
		if provider:
			provider.stop()
		if auto_start_manager:
			auto_start_manager.stop_server()
