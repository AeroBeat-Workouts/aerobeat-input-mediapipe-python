class_name MediaPipeCameraView
extends TextureRect
## Camera view display for MediaPipe - shows live camera feed with optional tracking overlay
##
## Usage:
##   1. Add as child to your UI (e.g., Picture-in-Picture in corner)
##   2. Call start_stream() to begin receiving camera feed
##   3. Call stop_stream() or toggle_camera_view() to control visibility
##   4. Call update_overlay() to draw tracking dots on top of camera feed

signal stream_started()
signal stream_stopped()
signal frame_received()

## Configuration
@export var stream_url: String = "http://127.0.0.1:4243/camera"
@export var update_interval_ms: float = 33.0  # ~30 FPS for display (lower than capture)
@export var show_overlay: bool = true
@export var overlay_color: Color = Color(0, 1, 0, 0.8)  # Green tracking dots
@export var overlay_radius: float = 4.0

## Runtime state
var _http_client: HTTPClient
var _is_streaming: bool = false
var _stream_thread: Thread
var _thread_running: bool = false
var _current_frame: Image
var _frame_mutex: Mutex
var _update_timer: float = 0.0
var _landmarks: Array = []  # Current landmarks for overlay

## MJPEG parsing state
var _mjpeg_buffer: PackedByteArray
var _boundary_marker: String = "--frame-boundary"

func _ready():
	# Initialize texture
	_current_frame = Image.create(640, 480, false, Image.FORMAT_RGB8)
	var texture = ImageTexture.create_from_image(_current_frame)
	self.texture = texture
	
	# Initialize threading primitives
	_frame_mutex = Mutex.new()
	_mjpeg_buffer = PackedByteArray()
	
	# Hide by default until streaming starts
	visible = false

func _exit_tree():
	stop_stream()

func _process(delta: float):
	if not _is_streaming:
		return
	
	# Update texture at display rate (separate from stream rate)
	_update_timer += delta * 1000.0
	if _update_timer >= update_interval_ms:
		_update_timer = 0.0
		_update_texture()
	
	# Redraw overlay if enabled
	if show_overlay:
		queue_redraw()

func _draw():
	if not show_overlay or _landmarks.is_empty():
		return
	
	# Draw tracking dots overlay
	var size = get_size()
	for lm in _landmarks:
		if not lm.has("x") or not lm.has("y"):
			continue
		
		# Convert normalized coordinates to pixel coordinates
		# Flip Y axis (MediaPipe has origin at top-left, Godot at bottom-left)
		var x = lm.x * size.x
		var y = (1.0 - lm.y) * size.y
		
		# Draw circle for landmark
		draw_circle(Vector2(x, y), overlay_radius, overlay_color)
		
		# Draw landmark ID for debugging (optional)
		#if lm.has("id"):
		#	draw_string(ThemeDB.fallback_font(), Vector2(x + 6, y), str(lm.id), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, overlay_color)

## Public API

func toggle_camera_view() -> void:
	"""Toggle camera view on/off"""
	if _is_streaming:
		stop_stream()
	else:
		start_stream()

func start_stream():
	"""Start receiving MJPEG stream from Python sidecar"""
	if _is_streaming:
		return true
	
	print("[CameraView] Starting stream...")
	print("[CameraView] Stream URL: " + stream_url)
	
	# Initialize HTTP client
	_http_client = HTTPClient.new()
	_http_client.set_blocking_mode(false)
	
	# Parse host and port from URL
	var host = stream_url.split("://")[1].split("/")[0]
	var port = 4243
	if host.find(":") != -1:
		port = host.split(":")[1].to_int()
		host = host.split(":")[0]
	
	print("[CameraView] Connecting to " + host + ":" + str(port))
	
	var err = _http_client.connect_to_host(host, port)
	if err != OK:
		push_error("Failed to connect to camera stream: " + str(err))
		print("[CameraView] Connection error: " + str(err))
		return false
	
	# Wait for connection
	var timeout = 0.0
	while _http_client.get_status() == HTTPClient.STATUS_CONNECTING:
		_http_client.poll()
		timeout += get_process_delta_time()
		if timeout > 3.0:
			push_error("Connection timeout")
			print("[CameraView] Connection timeout after 3 seconds")
			return false
		await get_tree().process_frame
	
	if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		push_error("Failed to connect to stream server, status: " + str(_http_client.get_status()))
		print("[CameraView] Connection failed, status: " + str(_http_client.get_status()))
		return false
	
	print("[CameraView] Connected to stream server")
	
	# Request the stream
	_http_client.request(HTTPClient.METHOD_GET, "/camera", ["Accept: multipart/x-mixed-replace", "Connection: keep-alive", "Cache-Control: no-cache"])
	print("[CameraView] HTTP request sent")
	
	# Start streaming thread
	_is_streaming = true
	_thread_running = true
	_stream_thread = Thread.new()
	_stream_thread.start(_stream_loop)
	
	visible = true
	stream_started.emit()
	print("[CameraView] Stream started successfully")
	return true

func stop_stream() -> void:
	"""Stop receiving stream and hide camera view"""
	if not _is_streaming:
		return
	
	_thread_running = false
	_is_streaming = false
	
	# Wait for thread to finish
	if _stream_thread and _stream_thread.is_alive():
		_stream_thread.wait_to_finish()
	
	# Close HTTP connection
	if _http_client:
		_http_client.close()
		_http_client = null
	
	visible = false
	stream_stopped.emit()
	print("[CameraView] Stream stopped")

func update_overlay(landmarks: Array) -> void:
	"""Update tracking overlay with new landmarks"""
	_landmarks = landmarks

func is_streaming() -> bool:
	"""Check if currently receiving stream"""
	return _is_streaming

func get_stream_url() -> String:
	"""Get the current stream URL"""
	return stream_url

## Internal methods

func _stream_loop():
	"""Background thread for receiving MJPEG stream"""
	print("[CameraView] Stream thread started")
	var frame_count = 0
	var last_log_time = Time.get_ticks_msec()
	
	while _thread_running:
		if _http_client:
			_http_client.poll()
			
			var status = _http_client.get_status()
			
			if status == HTTPClient.STATUS_BODY:
				# Read available data
				var chunk = _http_client.read_response_body_chunk()
				if chunk.size() > 0:
					_mjpeg_buffer.append_array(chunk)
					_parse_mjpeg_buffer()
			
			elif status == HTTPClient.STATUS_CONNECTED:
				# Request still being processed
				pass
			
			elif status == HTTPClient.STATUS_DISCONNECTED:
				# Connection lost, try to reconnect
				print("[CameraView] Connection lost, reconnecting...")
				_http_client.connect_to_host(stream_url.split("://")[1].split("/")[0], 4243)
		
		# Log frame reception every 5 seconds
		var current_time = Time.get_ticks_msec()
		if current_time - last_log_time > 5000:
			print("[CameraView] Stream thread alive, buffer size: " + str(_mjpeg_buffer.size()))
			last_log_time = current_time
		
		# Small delay to prevent busy-waiting
		OS.delay_msec(5)
	
	print("[CameraView] Stream thread ended")

func _parse_mjpeg_buffer():
	"""Parse MJPEG buffer and extract JPEG frames"""
	var buffer_str = _mjpeg_buffer.get_string_from_utf8()
	
	# Look for boundary marker
	var boundary_pos = buffer_str.find(_boundary_marker)
	if boundary_pos == -1:
		return
	
	# Find next boundary (end of this frame)
	var next_boundary_pos = buffer_str.find(_boundary_marker, boundary_pos + _boundary_marker.length())
	if next_boundary_pos == -1:
		return  # Wait for more data
	
	# Extract frame data between boundaries
	var frame_section = buffer_str.substr(boundary_pos, next_boundary_pos - boundary_pos)
	
	# Look for JPEG data (starts after double CRLF)
	var jpeg_start = frame_section.find("\r\n\r\n")
	if jpeg_start == -1:
		jpeg_start = frame_section.find("\n\n")
	
	if jpeg_start != -1:
		jpeg_start += 4  # Skip the CRLFCRLF
		
		# Find Content-Length if present
		var content_length_start = frame_section.find("Content-Length: ")
		var jpeg_size = -1
		if content_length_start != -1 and content_length_start < jpeg_start:
			var length_end = frame_section.find("\r\n", content_length_start)
			if length_end != -1:
				var length_str = frame_section.substr(content_length_start + 16, length_end - content_length_start - 16)
				jpeg_size = length_str.to_int()
		
		# Extract JPEG data
		var jpeg_data: PackedByteArray
		if jpeg_size > 0:
			# Calculate byte positions in original buffer
			var header_bytes = frame_section.substr(0, jpeg_start).to_utf8_buffer().size()
			var start_byte = boundary_pos + header_bytes
			jpeg_data = _mjpeg_buffer.slice(start_byte, start_byte + jpeg_size)
		else:
			# No Content-Length, try to extract from string position
			var jpeg_str = frame_section.substr(jpeg_start, next_boundary_pos - boundary_pos - jpeg_start)
			jpeg_data = jpeg_str.to_utf8_buffer()
		
		# Decode JPEG
		if jpeg_data.size() > 0:
			var image = Image.new()
			var err = image.load_jpg_from_buffer(jpeg_data)
			if err == OK:
				_frame_mutex.lock()
				_current_frame = image
				_frame_mutex.unlock()
				frame_received.emit()
				print("[CameraView] Frame decoded, size: " + str(image.get_width()) + "x" + str(image.get_height()))
			else:
				print("[CameraView] JPEG decode error: " + str(err))
	
	# Remove processed data from buffer
	_mjpeg_buffer = _mjpeg_buffer.slice(next_boundary_pos)

func _update_texture():
	"""Update displayed texture with latest frame"""
	_frame_mutex.lock()
	var frame = _current_frame
	_frame_mutex.unlock()
	
	if frame and frame.get_width() > 0:
		var texture = ImageTexture.create_from_image(frame)
		self.texture = texture

## Static helper for creating PiP-style camera view

static func create_picture_in_picture(parent: Node, position: Vector2 = Vector2(10, 10), 
									size: Vector2 = Vector2(320, 240)) -> MediaPipeCameraView:
	"""
	Create a Picture-in-Picture style camera view.
	
	Usage:
		var camera_view = MediaPipeCameraView.create_picture_in_picture(self)
		camera_view.start_stream()
	"""
	var camera_view = MediaPipeCameraView.new()
	camera_view.position = position
	camera_view.size = size
	camera_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Add semi-transparent background for visibility
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = size
	bg.position = Vector2.ZERO
	camera_view.add_child(bg)
	bg.owner = parent
	
	parent.add_child(camera_view)
	camera_view.owner = parent
	
	return camera_view
