extends Node2D
## Test scene for MediaPipe Provider (manual mode)
## Start Python sidecar separately before running this scene
##
## Usage:
##   1. In terminal: python3 python_mediapipe/main.py --camera 0 --show-window
##   2. In Godot: Run this scene
##   3. Green dots should appear when body is detected

@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var camera_display: TextureRect = $CameraDisplay
@onready var landmark_drawer: Control = $CameraDisplay/LandmarkDrawer

var provider = null
var _frame_count: int = 0
var _server_ready: bool = false

func _ready():
	update_status("Initializing...", Color.WHITE)
	info_label.text = "Starting MediaPipe provider...\n\nMake sure Python sidecar is running:\npython3 python_mediapipe/main.py --camera 0 --show-window"
	
	# Create black background for landmark display
	_create_black_background()
	
	# Start provider directly
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

func _start_provider():
	# Load the test version of MediaPipeProvider
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

Waiting for Python sidecar data...

Make sure sidecar is running:
python3 python_mediapipe/main.py --camera 0 --show-window

Landmarks will appear as green dots when detected."""
		else:
			update_status("Failed to start provider", Color.RED)
	else:
		update_status("Failed to load MediaPipeProvider script", Color.RED)

func _process(_delta):
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
		print("[TestScene] Window close requested - shutting down gracefully...")
		if provider:
			provider.stop()
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE:
		if provider:
			provider.stop()
