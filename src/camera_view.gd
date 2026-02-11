class_name MediaPipeCameraView
extends TextureRect
## Camera view display for MediaPipe - shows live MJPEG camera feed with tracking overlay

signal stream_started()
signal stream_stopped()

@export var stream_url: String = "http://127.0.0.1:4243/camera"
@export var update_interval_ms: float = 33.0
@export var show_overlay: bool = true
@export var overlay_color: Color = Color(0, 1, 0, 0.8)
@export var overlay_radius: float = 4.0
@export var flip_horizontal: bool = true:
	set(value):
		flip_horizontal = value
		_update_flip_material()

# Buffer limits for latency control
const MAX_BUFFER_SIZE := 131072  # 128KB max - larger frames will cause drops
const MAX_BUFFERED_FRAMES := 2   # Keep at most 2 frames buffered

var _tcp: StreamPeerTCP
var _is_streaming: bool = false
var _stream_thread: Thread
var _thread_running: bool = false
var _current_frame: Image
var _frame_mutex: Mutex
var _update_timer: float = 0.0
var _mjpeg_buffer: PackedByteArray
var _is_starting: bool = false  # Guard against concurrent start_stream calls

# Overlay drawing
var _overlay_landmarks: Array = []
var _overlay_mutex: Mutex
var _overlay_canvas: Control

func _ready() -> void:
	_current_frame = Image.create(640, 480, false, Image.FORMAT_RGB8)
	self.texture = ImageTexture.create_from_image(_current_frame)
	_frame_mutex = Mutex.new()
	_overlay_mutex = Mutex.new()
	_mjpeg_buffer = PackedByteArray()
	visible = false
	
	# Set up horizontal flip via material
	_update_flip_material()
	
	# Create overlay canvas for drawing landmarks
	_overlay_canvas = Control.new()
	_overlay_canvas.name = "OverlayCanvas"
	_overlay_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_canvas)
	
	# Connect to draw signal
	_overlay_canvas.draw.connect(_on_overlay_draw)

func _exit_tree() -> void:
	print("[CameraView] _exit_tree called, stopping stream...")
	# Stop the stream properly to ensure thread cleanup
	stop_stream()

func _process(delta: float) -> void:
	if not _is_streaming:
		return
	
	# Update texture every frame for lowest latency (was capped at 30 FPS)
	# This ensures we display the latest decoded frame immediately
	_update_texture()
	
	# Queue overlay redraw
	if show_overlay and _overlay_canvas:
		_overlay_canvas.queue_redraw()

func start_stream() -> bool:
	if _is_streaming:
		return true
	
	# Prevent concurrent calls
	if _is_starting:
		print("[CameraView] start_stream already in progress, skipping...")
		return false
	
	_is_starting = true
	
	# Clean up any orphaned thread from a previous failed attempt
	if _stream_thread:
		if _stream_thread.is_alive():
			_thread_running = false
			_stream_thread.wait_to_finish()
		_stream_thread = null
	
	print("[CameraView] Starting stream from: ", stream_url)
	
	# Parse URL
	var host := "127.0.0.1"
	var port := 4243
	var path := "/camera"
	
	if stream_url.begins_with("http://"):
		var rest := stream_url.substr(7)
		var path_start := rest.find("/")
		if path_start != -1:
			host = rest.substr(0, path_start)
			path = rest.substr(path_start)
		else:
			host = rest
		
		var port_sep := host.find(":")
		if port_sep != -1:
			port = host.substr(port_sep + 1).to_int()
			host = host.substr(0, port_sep)
	
	print("[CameraView] Connecting to ", host, ":", port, path)
	
	# Use raw TCP instead of HTTPClient
	_tcp = StreamPeerTCP.new()
	var err := _tcp.connect_to_host(host, port)
	print("[CameraView] connect_to_host returned: ", err)
	
	if err != OK:
		push_error("Failed to start connection: " + str(err))
		_tcp = null
		_is_starting = false
		return false
	
	# Wait for connection with timeout
	var timeout := 0.0
	var status := _tcp.get_status()
	print("[CameraView] Initial TCP status: ", status)
	
	while status == StreamPeerTCP.STATUS_CONNECTING:
		_tcp.poll()
		status = _tcp.get_status()
		timeout += get_process_delta_time()
		
		if timeout > 10.0:
			print("[CameraView] Connection timeout! Status: ", status)
			push_error("Connection timeout after 10s")
			_tcp.disconnect_from_host()
			_tcp = null
			_is_starting = false
			return false
		
		await get_tree().process_frame
	
	print("[CameraView] Final TCP status: ", status)
	
	if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		push_error("Failed to connect, status: " + str(_tcp.get_status()))
		_tcp.disconnect_from_host()
		_tcp = null
		_is_starting = false
		return false
	
	print("[CameraView] Connected, sending HTTP request...")
	
	# Send HTTP request manually
	var request := "GET " + path + " HTTP/1.1\r\n"
	request += "Host: " + host + ":" + str(port) + "\r\n"
	request += "Accept: multipart/x-mixed-replace\r\n"
	request += "Connection: keep-alive\r\n"
	request += "\r\n"
	
	_tcp.put_data(request.to_utf8_buffer())
	
	print("[CameraView] Request sent, starting stream thread...")
	
	# Start thread BEFORE setting flags to avoid race conditions
	_stream_thread = Thread.new()
	var thread_err := _stream_thread.start(_stream_loop)
	if thread_err != OK:
		push_error("Failed to start stream thread: " + str(thread_err))
		_tcp.disconnect_from_host()
		_tcp = null
		_stream_thread = null
		_is_starting = false
		return false
	
	# Only set flags after thread is confirmed started
	_is_streaming = true
	_thread_running = true
	_is_starting = false
	
	visible = true
	stream_started.emit()
	print("[CameraView] Stream started successfully")
	return true

func stop_stream() -> void:
	print("[CameraView] Stopping stream...")
	
	# Always signal thread to stop and reset all flags
	_thread_running = false
	_is_streaming = false
	_is_starting = false
	
	# Always wait for thread if it exists - don't check flags
	if _stream_thread:
		print("[CameraView] Waiting for stream thread to finish...")
		if _stream_thread.is_alive():
			_stream_thread.wait_to_finish()
		_stream_thread = null
	
	if _tcp:
		_tcp.disconnect_from_host()
		_tcp = null
	
	visible = false
	stream_stopped.emit()
	print("[CameraView] Stream stopped")

func is_streaming() -> bool:
	return _is_streaming

func _update_flip_material() -> void:
	"""Update the material to apply horizontal flip if enabled."""
	if flip_horizontal:
		# Create a simple shader to flip the texture horizontally
		var shader := Shader.new()
		shader.code = """
		shader_type canvas_item;
		void fragment() {
			vec2 uv = UV;
			uv.x = 1.0 - uv.x;
			COLOR = texture(TEXTURE, uv);
		}
		"""
		var mat := ShaderMaterial.new()
		mat.shader = shader
		self.material = mat
	else:
		self.material = null

func update_overlay(landmarks: Array) -> void:
	"""Update the landmark positions for overlay drawing.
	
	Landmarks should be in normalized coordinates (0.0-1.0) as received from MediaPipe.
	"""
	if not show_overlay:
		return
		
	_overlay_mutex.lock()
	_overlay_landmarks = landmarks.duplicate()
	_overlay_mutex.unlock()

func _on_overlay_draw() -> void:
	"""Draw landmarks on the overlay canvas, properly scaled to the camera view."""
	if not show_overlay or _overlay_landmarks.is_empty():
		return
	
	# Get the actual displayed image size within the TextureRect
	var img_size := _get_displayed_image_size()
	var img_offset := _get_displayed_image_offset(img_size)
	
	_overlay_mutex.lock()
	var landmarks_copy := _overlay_landmarks.duplicate()
	_overlay_mutex.unlock()
	
	for landmark: Dictionary in landmarks_copy:
		if not landmark is Dictionary:
			continue
		
		# Get normalized coordinates (MediaPipe gives 0.0-1.0)
		var nx: float = landmark.get("x", 0.0)
		var ny: float = landmark.get("y", 0.0)
		var visibility: float = landmark.get("v", 1.0)
		
		# Skip low visibility landmarks
		if visibility < 0.5:
			continue
		
		# Apply horizontal flip to match video if enabled
		if flip_horizontal:
			nx = 1.0 - nx
		
		# Convert normalized (0.0-1.0) to pixel coordinates within the displayed image
		var px := img_offset.x + nx * img_size.x
		var py := img_offset.y + ny * img_size.y
		
		# Draw the landmark dot
		_overlay_canvas.draw_circle(Vector2(px, py), overlay_radius, overlay_color)

func _get_displayed_image_size() -> Vector2:
	"""Calculate the actual size of the displayed image after aspect ratio scaling."""
	if not _current_frame:
		return size
	
	var frame_size := Vector2(_current_frame.get_width(), _current_frame.get_height())
	if frame_size.x == 0 or frame_size.y == 0:
		return size
	
	var view_size := size
	var frame_aspect := frame_size.x / frame_size.y
	var view_aspect := view_size.x / view_size.y
	
	# Determine actual displayed size based on stretch mode
	match stretch_mode:
		STRETCH_KEEP_ASPECT_CENTERED, STRETCH_KEEP_ASPECT_COVERED:
			if frame_aspect > view_aspect:
				# Image is wider - fit to width
				var img_scale := view_size.x / frame_size.x
				return Vector2(view_size.x, frame_size.y * img_scale)
			else:
				# Image is taller - fit to height
				var img_scale := view_size.y / frame_size.y
				return Vector2(frame_size.x * img_scale, view_size.y)
		STRETCH_KEEP:
			return frame_size
		_:
			# Default: fill the rect
			return view_size

func _get_displayed_image_offset(displayed_size: Vector2) -> Vector2:
	"""Calculate the offset of the displayed image within the TextureRect."""
	return (size - displayed_size) / 2.0

func _stream_loop() -> void:
	print("[CameraView] Stream thread started")
	var bytes_received := 0
	var frames_decoded := 0
	var last_log := Time.get_ticks_msec()
	var header_parsed := false
	
	while _thread_running and _tcp:
		_tcp.poll()
		
		if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("[CameraView] Connection lost")
			break
		
		# Read available data
		var available := _tcp.get_available_bytes()
		if available > 0:
			var chunk := _tcp.get_data(available)
			if chunk[0] == OK:
				bytes_received += chunk[1].size()
				_mjpeg_buffer.append_array(chunk[1])
				
				# Buffer overflow protection - drop old data if buffer grows too large
				if _mjpeg_buffer.size() > MAX_BUFFER_SIZE:
					print("[CameraView] Buffer overflow (", _mjpeg_buffer.size(), " bytes), dropping stale frames")
					# Keep only the most recent data (last 8KB which likely contains a partial frame)
					var keep_size: int = mini(8192, _mjpeg_buffer.size())
					_mjpeg_buffer = _mjpeg_buffer.slice(_mjpeg_buffer.size() - keep_size)
					header_parsed = false  # Reset header parsing
				
				# Parse HTTP headers first (search for \r\n\r\n as bytes, not UTF-8)
				if not header_parsed:
					var header_end := _find_byte_pattern(_mjpeg_buffer, PackedByteArray([0x0D, 0x0A, 0x0D, 0x0A]))  # \r\n\r\n
					if header_end != -1:
						print("[CameraView] HTTP headers received")
						_mjpeg_buffer = _mjpeg_buffer.slice(header_end + 4)
						header_parsed = true
				
				# Try to parse frames - but limit to prevent frame buildup
				if header_parsed:
					var parsed_count := 0
					while parsed_count < MAX_BUFFERED_FRAMES and _parse_mjpeg_frame():
						frames_decoded += 1
						parsed_count += 1
		
		# Log stats every 5 seconds
		var now := Time.get_ticks_msec()
		if now - last_log > 5000:
			print("[CameraView] Stats: ", bytes_received, " bytes, ", frames_decoded, " frames")
			bytes_received = 0
			frames_decoded = 0
			last_log = now
		
		OS.delay_msec(1)  # Reduced from 5ms for lower latency
	
	print("[CameraView] Stream thread ended")

func _find_byte_pattern(buffer: PackedByteArray, pattern: PackedByteArray) -> int:
	"""Find byte pattern in buffer. Returns -1 if not found."""
	if pattern.is_empty() or buffer.size() < pattern.size():
		return -1
	
	for i in range(buffer.size() - pattern.size() + 1):
		var found := true
		for j in range(pattern.size()):
			if buffer[i + j] != pattern[j]:
				found = false
				break
		if found:
			return i
	return -1

func _parse_mjpeg_frame() -> bool:
	# Search for boundary as raw bytes, not UTF-8
	var boundary_bytes := PackedByteArray([0x2D, 0x2D, 0x66, 0x72, 0x61, 0x6D, 0x65, 0x2D, 0x62, 0x6F, 0x75, 0x6E, 0x64, 0x61, 0x72, 0x79])  # "--frame-boundary"
	var boundary_pos := _find_byte_pattern(_mjpeg_buffer, boundary_bytes)
	if boundary_pos == -1:
		return false
	
	# Find next boundary to isolate this frame
	var next_boundary := _find_byte_pattern(_mjpeg_buffer.slice(boundary_pos + boundary_bytes.size()), boundary_bytes)
	if next_boundary == -1:
		return false
	next_boundary += boundary_pos + boundary_bytes.size()  # Adjust offset back to absolute
	
	# Extract just this frame's data for header parsing
	var frame_data := _mjpeg_buffer.slice(boundary_pos, next_boundary)
	
	# Find Content-Length header by searching for "Content-Length: " as bytes
	var content_length_header := PackedByteArray([0x43, 0x6F, 0x6E, 0x74, 0x65, 0x6E, 0x74, 0x2D, 0x4C, 0x65, 0x6E, 0x67, 0x74, 0x68, 0x3A, 0x20])  # "Content-Length: "
	var content_length_start := _find_byte_pattern(frame_data, content_length_header)
	var jpeg_data: PackedByteArray
	
	if content_length_start != -1:
		# Find end of line (\r\n) after Content-Length
		var line_end := _find_byte_pattern(frame_data.slice(content_length_start + content_length_header.size()), PackedByteArray([0x0D, 0x0A]))
		if line_end != -1:
			# Extract just the number as bytes, then parse it
			var num_start := content_length_start + content_length_header.size()
			var num_data := frame_data.slice(num_start, num_start + line_end)
			var len_str := num_data.get_string_from_ascii()  # ASCII is safe for numbers
			var jpeg_size := len_str.to_int()
			
			# Find header end (\r\n\r\n) in frame data
			var header_end := _find_byte_pattern(frame_data, PackedByteArray([0x0D, 0x0A, 0x0D, 0x0A]))
			if header_end == -1:
				header_end = _find_byte_pattern(frame_data, PackedByteArray([0x0A, 0x0A]))  # Fall back to \n\n
			if header_end != -1:
				var header_size := header_end + 4  # Account for \r\n\r\n
				# Calculate actual byte position in original buffer
				var jpeg_start := boundary_pos + header_size
				
				if jpeg_start + jpeg_size <= _mjpeg_buffer.size():
					jpeg_data = _mjpeg_buffer.slice(jpeg_start, jpeg_start + jpeg_size)
	
	if jpeg_data.is_empty():
		# Fallback: find JPEG start marker (FF D8) in raw bytes
		for i in range(boundary_pos, min(next_boundary, _mjpeg_buffer.size() - 1)):
			if _mjpeg_buffer[i] == 0xFF and _mjpeg_buffer[i + 1] == 0xD8:
				# Found JPEG start, extract until end marker (FF D9) or next boundary
				var jpeg_start := i
				var jpeg_end := next_boundary
				
				# Look for JPEG end marker
				for j in range(jpeg_start + 2, min(next_boundary, _mjpeg_buffer.size() - 1)):
					if _mjpeg_buffer[j] == 0xFF and _mjpeg_buffer[j + 1] == 0xD9:
						jpeg_end = j + 2
						break
				
				if jpeg_end > jpeg_start:
					jpeg_data = _mjpeg_buffer.slice(jpeg_start, jpeg_end)
					break
	
	if jpeg_data.size() > 0:
		var img := Image.new()
		var err := img.load_jpg_from_buffer(jpeg_data)
		if err == OK:
			_frame_mutex.lock()
			_current_frame = img
			_frame_mutex.unlock()
			_mjpeg_buffer = _mjpeg_buffer.slice(next_boundary)
			return true
		else:
			print("[CameraView] JPEG decode error: ", err, " (size: ", jpeg_data.size(), ")")
	
	_mjpeg_buffer = _mjpeg_buffer.slice(next_boundary)
	return false

func _update_texture() -> void:
	_frame_mutex.lock()
	var frame := _current_frame
	_frame_mutex.unlock()
	if frame and frame.get_width() > 0:
		self.texture = ImageTexture.create_from_image(frame)
