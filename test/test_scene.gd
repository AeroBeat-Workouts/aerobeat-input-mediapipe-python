extends Node2D
## Test scene for MediaPipe Provider with AutoStart Manager
## Displays connection status, landmark overlay, and debug information

@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var camera_display: TextureRect = $CameraDisplay
@onready var landmark_drawer: Control = $CameraDisplay/LandmarkDrawer

var provider = null
var _frame_count: int = 0
var _server_ready: bool = false
var _installing: bool = false

func _ready():
	update_status("Initializing...", Color.WHITE)
	info_label.text = "Starting MediaPipe provider..."
	
	# Create black background for landmark display
	_create_black_background()
	
	# Start provider directly (manual mode - no AutoStartManager)
	_start_provider()

func _create_black_background():
	"""Create a black background texture for landmark display."""
	var image = Image.create(640, 480, false, Image.FORMAT_RGB8)
	image.fill(Color(0.05, 0.05, 0.05))  # Near-black background
	
	# Add border
	for x in range(640):
		image.set_pixel(x, 0, Color.DARK_GRAY)
		image.set_pixel(x, 479, Color.DARK_GRAY)
	for y in range(480):
		image.set_pixel(0, y, Color.DARK_GRAY)
		image.set_pixel(639, y, Color.DARK_GRAY)
	
	var texture = ImageTexture.create_from_image(image)
	camera_display.texture = texture
	print("[TestScene] Display background created")

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

Tracking landmarks on black background.

The Python server is processing your camera feed.
Landmarks will appear as green dots when detected.

Make sure:
1. Your camera is connected
2. You're in a well-lit area
3. Nothing is blocking the camera"""
		else:
			update_status("Failed to start provider", Color.RED)
	else:
		update_status("Failed to load MediaPipeProvider script", Color.RED)

func _process(_delta: float):
	_frame_count += 1
	
	# Update debug info every 30 frames
	if _frame_count % 30 == 0 and _server_ready:
		_update_debug_info()

func _on_pose_updated(landmarks: Array):
	update_status("Tracking active - " + str(landmarks.size()) + " landmarks detected", Color.GREEN)
	
	# Update landmark drawer
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
	
	var info := "MediaPipe Provider Status\n"
	info += "==========================\n\n"
	
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
		
		info += "\nDetected Positions:\n"
		
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
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Graceful shutdown on window close request
		print("[TestScene] Window close requested - shutting down gracefully...")
		if provider:
			provider.stop()
		# Let AutoStartManager stop the server via its _exit_tree
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE:
		if provider:
			provider.stop()
		# AutoStartManager will auto-stop server on _exit_tree
