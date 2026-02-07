extends Node2D
## Test scene for MediaPipe Provider with AutoStart Manager
## Displays connection status, camera feed, and landmarks overlay

@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var camera_display: TextureRect = $CameraDisplay
@onready var landmark_drawer: Control = $CameraDisplay/LandmarkDrawer

var provider = null
var _frame_count: int = 0
var _server_ready: bool = false
var _installing: bool = false
var _camera_feed: CameraFeed = null
var _camera_texture: ImageTexture = null

func _ready():
	update_status("Initializing...", Color.WHITE)
	info_label.text = "Waiting for AutoStartManager..."
	
	# Initialize camera display
	_initialize_camera()
	
	# Connect Run Tests button
	var run_tests_button = get_node_or_null("RunTestsButton")
	if run_tests_button:
		run_tests_button.pressed.connect(_on_run_tests_pressed)
	
	# Connect to autostart manager signals if available
	var auto_start = get_node_or_null("AutoStartManager")
	if auto_start:
		auto_start.server_started.connect(_on_server_started)
		auto_start.server_failed.connect(_on_server_failed)
		auto_start.server_stopped.connect(_on_server_stopped)
		auto_start.python_not_found.connect(_on_python_not_found)
		auto_start.mediapipe_not_found.connect(_on_mediapipe_not_found)
		auto_start.check_progress.connect(_on_check_progress)
		auto_start.installation_progress.connect(_on_install_progress)
		auto_start.installation_complete.connect(_on_install_complete)
		
		# Check current status
		if auto_start.is_server_running():
			_on_server_started(auto_start.get_server_pid())
		elif auto_start.is_installing:
			_installing = true
			update_status("Installation in progress...", Color.YELLOW)
		else:
			update_status("Waiting for dependencies...", Color.YELLOW)
			# Poll for server start (in case signal was missed)
			_start_polling_for_server(auto_start)
	else:
		update_status("AutoStartManager not found - starting manually", Color.ORANGE)
		_start_provider()

func _initialize_camera():
	"""Initialize Godot CameraServer for local camera display."""
	# Enable feed monitoring
	CameraServer.set_monitoring_feeds(true)
	
	# Check for existing feeds
	var feed_count = CameraServer.get_feed_count()
	if feed_count > 0:
		_camera_feed = CameraServer.get_feed(0)
		_activate_camera_feed()
	else:
		# No camera available, show placeholder texture
		_create_placeholder_texture()
		print("[TestScene] No camera feed available - showing placeholder")

func _create_placeholder_texture():
	"""Create a placeholder texture when no camera is available."""
	var image = Image.create(640, 480, false, Image.FORMAT_RGB8)
	image.fill(Color(0.1, 0.1, 0.15))  # Dark blue-gray background
	
	# Add some placeholder indication (gray rectangle in center)
	for y in range(200, 280):
		for x in range(120, 520):
			image.set_pixel(x, y, Color(0.2, 0.2, 0.25))
	
	_camera_texture = ImageTexture.create_from_image(image)
	camera_display.texture = _camera_texture

func _activate_camera_feed():
	if _camera_feed:
		_camera_feed.set_active(true)
		# Create texture from camera feed
		_camera_texture = _camera_feed.get_texture()
		camera_display.texture = _camera_texture
		print("[TestScene] Camera feed activated")

func _on_check_progress(percentage: int, message: String) -> void:
	update_status(str(percentage) + "% - " + message, Color.YELLOW)

func _on_install_progress(percentage: int, message: String) -> void:
	_installing = true
	update_status("Installing: " + str(percentage) + "% - " + message, Color.ORANGE)
	info_label.text = "Setting up Python environment...\nThis may take a few minutes on first run."

func _on_install_complete(success: bool) -> void:
	_installing = false
	if success:
		update_status("Installation complete! Starting server...", Color.GREEN)
	else:
		update_status("Installation failed!", Color.RED)
		info_label.text = "Failed to install dependencies.\nCheck the console for errors."

func _on_server_started(pid: int) -> void:
	update_status("Python server started (PID: " + str(pid) + ")", Color.GREEN)
	print("[TestScene] Server started with PID: ", pid)
	
	# Give the server a moment to initialize before connecting
	await get_tree().create_timer(1.0).timeout
	_start_provider()

func _on_server_failed(error: String) -> void:
	update_status("Server failed: " + error, Color.RED)
	push_error("AutoStart failed: " + error)
	info_label.text = "Error: " + error + "\n\nPlease check:\n1. Python 3 is installed\n2. Camera is connected\n3. No other app is using port 4242"

func _on_server_stopped() -> void:
	update_status("Server stopped", Color.ORANGE)
	_server_ready = false

func _start_polling_for_server(auto_start) -> void:
	"""Poll for server start in case we missed the signal."""
	var attempts = 0
	while attempts < 30:  # Try for 3 seconds
		await get_tree().create_timer(0.1).timeout
		if auto_start.is_server_running():
			_on_server_started(auto_start.get_server_pid())
			return
		attempts += 1
	print("[TestScene] Server polling timed out")

func _on_run_tests_pressed():
	print("\n[TestScene] Running tests...")
	var test_runner = load("res://test/test_runner.gd").new()
	var success = test_runner.run_all_tests()
	if success:
		update_status("All tests passed!", Color.GREEN)
	else:
		update_status("Some tests failed - check console", Color.ORANGE)

func _on_python_not_found() -> void:
	update_status("Python 3 not found!", Color.RED)
	info_label.text = """Python Not Found

Please install Python 3.8 or later:
- Ubuntu/Debian: sudo apt install python3 python3-venv
- macOS: brew install python3
- Windows: Download from python.org

Then restart Godot."""

func _on_mediapipe_not_found() -> void:
	update_status("MediaPipe not installed - Installing...", Color.YELLOW)
	info_label.text = """Installing MediaPipe...

This may take 2-5 minutes on first run.
You'll see progress updates in the status."""

func _start_provider() -> void:
	# Load the test version of MediaPipeProvider (standalone, no AeroInputProvider dependency)
	var provider_script = load("res://test/mediapipe_provider_test.gd")
	if provider_script:
		provider = provider_script.new()
		provider.name = "MediaPipeProvider"
		add_child(provider)
		
		# Connect to provider signals
		provider.pose_updated.connect(_on_pose_updated)
		provider.tracking_lost.connect(_on_tracking_lost)
		provider.tracking_restored.connect(_on_tracking_restored)
		
		# Start the provider
		var success = provider.start()
		if success:
			_server_ready = true
			update_status("Provider listening on port " + str(provider._server.get_bound_port()) + " - Waiting for tracking data...", Color.GREEN)
			info_label.text = """MediaPipe Provider Ready

Waiting for tracking data from camera...

Make sure:
1. Your camera is connected
2. You're in a well-lit area
3. Nothing is blocking the camera

The provider will auto-detect when tracking begins."""
		else:
			update_status("Failed to start provider", Color.RED)
	else:
		update_status("Failed to load MediaPipeProvider script", Color.RED)

func _process(delta: float):
	_frame_count += 1
	
	# Update camera texture if available
	if _camera_texture and _camera_feed:
		var new_texture = _camera_feed.get_texture()
		if new_texture:
			camera_display.texture = new_texture
	
	# Update debug info every 30 frames
	if _frame_count % 30 == 0 and _server_ready:
		_update_debug_info()

func _on_pose_updated(landmarks: Array):
	# Only update status every 60 frames to reduce spam
	if _frame_count % 60 == 0:
		update_status("Tracking active - " + str(landmarks.size()) + " landmarks", Color.GREEN)
	
	# Update landmark drawer with new data
	if landmark_drawer:
		landmark_drawer.update_landmarks(landmarks)

func _on_tracking_lost():
	update_status("Tracking lost - Check camera view", Color.ORANGE)
	# Clear landmarks when tracking is lost
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
	
	var info := "MediaPipe Provider Test\n"
	info += "========================\n\n"
	
	# Camera status
	if _camera_feed and _camera_feed.is_active():
		info += "Camera: Active (Feed " + str(_camera_feed.get_id()) + ")\n"
	else:
		info += "Camera: " + ("Inactive" if not _camera_feed else "Standby") + "\n"
	
	# AutoStart Manager status
	var auto_start = get_node_or_null("AutoStartManager")
	if auto_start:
		info += "Server PID: " + str(auto_start.get_server_pid()) + "\n"
		info += "Server Running: " + str(auto_start.is_server_running()) + "\n"
	else:
		info += "AutoStart: Disabled\n"
	
	# Provider status
	if provider:
		info += "Provider Port: %d\n" % provider._server.get_bound_port()
		info += "Is Tracking: %s\n" % str(provider.is_tracking())
		
		info += "\nPositions:\n"
		
		var left_hand = provider.get_left_hand_position()
		var right_hand = provider.get_right_hand_position()
		var head = provider.get_head_position()
		
		info += "  Left Hand: %s\n" % (_format_pos(left_hand))
		info += "  Right Hand: %s\n" % (_format_pos(right_hand))
		info += "  Head: %s\n" % (_format_pos(head))
	else:
		info += "Provider: Not started\n"
	
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
	if what == NOTIFICATION_EXIT_TREE:
		if provider:
			provider.stop()
		# Deactivate camera feed
		if _camera_feed:
			_camera_feed.set_active(false)
		# AutoStartManager will auto-stop server on _exit_tree
