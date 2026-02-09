extends Node2D
## Test scene for MediaPipe Provider with AutoStart and Camera Feed
## Automatically starts Python sidecar and displays camera feed with skeleton overlay

@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var camera_display: TextureRect = $CameraDisplay
@onready var landmark_drawer: Control = $CameraDisplay/LandmarkDrawer

var provider = null
var auto_start_manager = null
var camera_view = null
var _frame_count: int = 0
var _server_ready: bool = false

func _ready():
	update_status("Initializing...", Color.WHITE)
	info_label.text = "Starting AutoStartManager..."
	
	# Create black background for landmark display
	_create_black_background()
	
	# Setup AutoStartManager
	_setup_auto_start()

func _create_black_background():
	var image = Image.create(640, 480, false, Image.FORMAT_RGB8)
	image.fill(Color(0.05, 0.05, 0.05))
	
	for x in range(640):
		image.set_pixel(x, 0, Color.DARK_GRAY)
		image.set_pixel(x, 479, Color.DARK_GRAY)
	for y in range(480):
		image.set_pixel(0, y, Color.DARK_GRAY)
		image.set_pixel(639, y, Color.DARK_GRAY)
	
	var texture = ImageTexture.create_from_image(image)
	camera_display.texture = texture
	print("[TestScene] Display background created")

func _setup_auto_start():
	# Check if AutoStartManager already exists in scene
	auto_start_manager = get_node_or_null("AutoStartManager")
	
	if auto_start_manager == null:
		# Create AutoStartManager if not found
		var AutoStartManager = load("res://src/autostart_manager.gd")
		auto_start_manager = AutoStartManager.new()
		auto_start_manager.name = "AutoStartManager"
		add_child(auto_start_manager)
		print("[TestScene] Created AutoStartManager")
	else:
		print("[TestScene] Found existing AutoStartManager")
	
	# Connect signals
	auto_start_manager.server_started.connect(_on_server_started)
	auto_start_manager.server_failed.connect(_on_server_failed)
	auto_start_manager.server_stopped.connect(_on_server_stopped)
	auto_start_manager.python_not_found.connect(_on_python_not_found)
	auto_start_manager.mediapipe_not_found.connect(_on_mediapipe_not_found)
	auto_start_manager.check_progress.connect(_on_check_progress)
	auto_start_manager.installation_progress.connect(_on_install_progress)
	auto_start_manager.installation_complete.connect(_on_install_complete)
	
	# Start server
	auto_start_manager.start_server()

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
	print("[TestScene] Server started with PID: ", pid)
	
	# Wait a moment for server to initialize
	await get_tree().create_timer(2.0).timeout
	_start_provider()
	_start_camera_feed()

func _on_server_failed(error: String) -> void:
	update_status("Server failed: " + error, Color.RED)
	info_label.text = "Error: " + error + "\n\nPlease check:\n1. Python 3 is installed\n2. Camera is connected"

func _on_server_stopped() -> void:
	update_status("Server stopped", Color.ORANGE)
	_server_ready = false

func _on_python_not_found() -> void:
	update_status("Python 3 not found!", Color.RED)
	info_label.text = "Python Not Found. Please install Python 3.8 or later."

func _on_mediapipe_not_found() -> void:
	update_status("MediaPipe not installed - Installing...", Color.YELLOW)
	info_label.text = "Installing MediaPipe...\nThis may take 2-5 minutes."

func _start_provider():
	var provider_script = load("res://test/mediapipe_provider_test.gd")
	if provider_script:
		provider = provider_script.new()
		provider.name = "MediaPipeProvider"
		add_child(provider)
		
		provider.pose_updated.connect(_on_pose_updated)
		provider.tracking_lost.connect(_on_tracking_lost)
		provider.tracking_restored.connect(_on_tracking_restored)
		
		var success = provider.start()
		if success:
			_server_ready = true
			update_status("Provider listening on port " + str(provider._server.get_bound_port()) + " - Waiting for tracking data...", Color.GREEN)
			info_label.text = """MediaPipe Provider Ready

Camera feed and tracking active.

Landmarks appear as green dots.
Make sure you're in a well-lit area."""
		else:
			update_status("Failed to start provider", Color.RED)

func _start_camera_feed():
	# Create camera view for MJPEG stream
	var MediaPipeCameraView = load("res://src/camera_view.gd")
	camera_view = MediaPipeCameraView.new()
	camera_view.name = "CameraView"
	camera_view.stream_url = "http://127.0.0.1:4243/camera"
	camera_view.position = Vector2(20, 80)
	camera_view.size = Vector2(640, 480)
	camera_view.show_overlay = true
	
	# Replace the black background with camera feed
	camera_display.replace_by(camera_view)
	camera_display = camera_view
	
	# Reconnect landmark drawer to new camera display
	if landmark_drawer:
		landmark_drawer.reparent(camera_display)
	
	# Start the stream
	camera_view.start_stream()
	print("[TestScene] Camera feed started")

func _process(_delta):
	_frame_count += 1
	
	if _frame_count % 30 == 0 and _server_ready:
		_update_debug_info()

func _on_pose_updated(landmarks: Array):
	update_status("Tracking active - " + str(landmarks.size()) + " landmarks detected", Color.GREEN)
	
	if landmark_drawer:
		landmark_drawer.update_landmarks(landmarks)
	
	# Also update camera overlay if available
	if camera_view:
		camera_view.update_overlay(landmarks)

func _on_tracking_lost():
	update_status("Tracking lost - Check camera view", Color.ORANGE)
	if landmark_drawer:
		landmark_drawer.clear_landmarks()

func _on_tracking_restored():
	update_status("Tracking restored", Color.GREEN)

func update_status(text: String, color: Color = Color.WHITE):
	if status_label:
		status_label.text = text
		status_label.modulate = color
	print("[MediaPipe Test] ", text)

func _update_debug_info():
	if not info_label or not provider or not _server_ready:
		return
	
	var info := "MediaPipe Provider Status\n"
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

func _format_pos(pos) -> String:
	if pos == null:
		return "N/A"
	if pos is Vector2:
		return "(%.2f, %.2f)" % [pos.x, pos.y]
	if pos is Vector3:
		return "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
	return str(pos)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[TestScene] Window close requested - shutting down gracefully...")
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
