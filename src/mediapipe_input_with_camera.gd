class_name MediaPipeInputWithCamera
extends Node
## Convenience wrapper that combines MediaPipeProvider with CameraView
##
## This node provides a one-stop solution for:
## - Body tracking via MediaPipe
## - Live camera feed display (toggleable)
## - Synchronized tracking overlay on camera
##
## Usage:
##   1. Add MediaPipeInputWithCamera to your scene
##   2. Configure the stream URL (default: http://127.0.0.1:4243/camera)
##   3. Call start() to begin tracking and streaming
##   4. Toggle camera view with toggle_camera() or set show_camera = true/false
##
## Example:
##   @onready var input = $MediaPipeInputWithCamera
##   
##   func _ready():
##       input.start()
##       input.toggle_camera()  # Show camera view
##   
##   func _process(delta):
##       var left_hand = input.get_left_hand_position()
##       if left_hand:
##           $Player.position = left_hand * screen_size

signal tracking_started()
signal tracking_stopped()
signal camera_view_toggled(enabled: bool)

## Configuration
@export var auto_start: bool = true
@export var show_camera: bool = false:
	set(value):
		if show_camera != value:
			show_camera = value
			_update_camera_visibility()
@export var camera_position: Vector2 = Vector2(10, 10)
@export var camera_size: Vector2 = Vector2(320, 240)
@export var stream_url: String = "http://127.0.0.1:4243/camera"
@export var udp_port: int = 4242
@export var show_tracking_overlay: bool = true
@export var overlay_color: Color = Color(0, 1, 0, 0.8)
@export var camera_toggle_key: Key = KEY_TAB

## References (created dynamically)
var _provider: MediaPipeProvider
var _camera_view: MediaPipeCameraView
var _is_running: bool = false

func _ready():
	# Create MediaPipe provider
	_create_provider()
	
	# Create camera view (hidden by default)
	_create_camera_view()
	
	# Auto-start if configured
	if auto_start:
		start()
	
	# Apply initial visibility
	_update_camera_visibility()

func _input(event):
	# Toggle camera view on key press
	if event is InputEventKey and event.pressed and event.keycode == camera_toggle_key:
		toggle_camera()

func _exit_tree():
	stop()

## Public API

func start() -> bool:
	"""Start tracking and streaming"""
	if _is_running:
		return true
	
	if not _provider:
		_create_provider()
	
	var success = _provider.start()
	if success:
		_is_running = true
		tracking_started.emit()
		print("[MediaPipeInputWithCamera] Tracking started")
	else:
		push_error("Failed to start MediaPipe tracking")
	
	return success

func stop():
	"""Stop tracking and streaming"""
	if not _is_running:
		return
	
	if _camera_view:
		_camera_view.stop_stream()
	
	if _provider:
		_provider.stop()
	
	_is_running = false
	tracking_stopped.emit()
	print("[MediaPipeInputWithCamera] Tracking stopped")

func toggle_camera() -> void:
	"""Toggle camera view on/off"""
	show_camera = !show_camera
	camera_view_toggled.emit(show_camera)

func is_tracking() -> bool:
	"""Check if currently tracking"""
	return _is_running and _provider and _provider.is_tracking()

func is_camera_visible() -> bool:
	"""Check if camera view is currently visible"""
	return _camera_view and _camera_view.visible and _camera_view.is_streaming()

## Position Getters (delegate to provider)

func get_left_hand_position(mode: int = 0) -> Variant:
	return _provider.get_left_hand_position(mode) if _provider else null

func get_right_hand_position(mode: int = 0) -> Variant:
	return _provider.get_right_hand_position(mode) if _provider else null

func get_head_position(mode: int = 0) -> Variant:
	return _provider.get_head_position(mode) if _provider else null

func get_left_foot_position(mode: int = 0) -> Variant:
	return _provider.get_left_foot_position(mode) if _provider else null

func get_right_foot_position(mode: int = 0) -> Variant:
	return _provider.get_right_foot_position(mode) if _provider else null

func get_landmark_position(landmark_id: int, mode: int = 0) -> Variant:
	return _provider._get_landmark_position(landmark_id, mode) if _provider else null

## Internal Methods

func _create_provider():
	"""Create and configure MediaPipe provider"""
	if _provider:
		return
	
	# Load required scripts
	var MediaPipeProvider = load("res://src/providers/mediapipe_provider.gd")
	var MediaPipeConfig = load("res://src/config/mediapipe_config.gd")
	var MediaPipeServer = load("res://src/server/mediapipe_server.gd")
	
	_provider = MediaPipeProvider.new()
	_provider.name = "MediaPipeProvider"
	
	# Configure
	var config = MediaPipeConfig.new()
	config.udp_port = udp_port
	_provider.config = config
	
	# Connect signals
	_provider.pose_updated.connect(_on_pose_updated)
	
	add_child(_provider)
	_provider.owner = owner

func _create_camera_view():
	"""Create and configure camera view"""
	if _camera_view:
		return
	
	var MediaPipeCameraView = load("res://src/camera_view.gd")
	
	_camera_view = MediaPipeCameraView.new()
	_camera_view.name = "MediaPipeCameraView"
	_camera_view.stream_url = stream_url
	_camera_view.position = camera_position
	_camera_view.size = camera_size
	_camera_view.show_overlay = show_tracking_overlay
	_camera_view.overlay_color = overlay_color
	_camera_view.visible = false  # Hidden by default
	
	# Set up proper sizing
	_camera_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	add_child(_camera_view)
	_camera_view.owner = owner

func _update_camera_visibility():
	"""Update camera view based on show_camera property"""
	if not _camera_view:
		return
	
	if show_camera:
		if not _camera_view.is_streaming():
			_camera_view.start_stream()
		_camera_view.visible = true
	else:
		_camera_view.stop_stream()
		_camera_view.visible = false

func _on_pose_updated(landmarks: Array):
	"""Handle pose update - sync to camera overlay"""
	# Update tracking overlay on camera view
	if _camera_view and _camera_view.is_streaming():
		_camera_view.update_overlay(landmarks)
