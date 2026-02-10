class_name MediaPipeCameraView
extends TextureRect
## Camera view display for MediaPipe - shows live MJPEG camera feed

signal stream_started()
signal stream_stopped()

## Configuration
@export var stream_url: String = "http://127.0.0.1:4243/camera"
@export var update_interval_ms: float = 33.0

## Runtime state
var _http_client: HTTPClient
var _is_streaming: bool = false
var _stream_thread: Thread
var _thread_running: bool = false
var _current_frame: Image
var _frame_mutex: Mutex
var _update_timer: float = 0.0

## MJPEG parsing state
var _mjpeg_buffer: PackedByteArray
var _boundary_marker: String = "--frame-boundary"

func _ready() -> void:
	_current_frame = Image.create(640, 480, false, Image.FORMAT_RGB8)
	var texture := ImageTexture.create_from_image(_current_frame)
	self.texture = texture
	
	_frame_mutex = Mutex.new()
	_mjpeg_buffer = PackedByteArray()
	
	visible = false

func _exit_tree() -> void:
	stop_stream()

func _process(delta: float) -> void:
	if not _is_streaming:
		return
	
	_update_timer += delta * 1000.0
	if _update_timer >= update_interval_ms:
		_update_timer = 0.0
		_update_texture()

func toggle_camera_view() -> void:
	if _is_streaming:
		stop_stream()
	else:
		start_stream()

func start_stream() -> bool:
	if _is_streaming:
		return true
	
	print("[CameraView] Starting stream...")
	
	_http_client = HTTPClient.new()
	_http_client.set_blocking_mode(false)
	
	var host := stream_url.split("://")[1].split("/")[0]
	var port: int = 4243
	if host.find(":") != -1:
		port = host.split(":")[1].to_int()
		host = host.split(":")[0]
	
	var err := _http_client.connect_to_host(host, port)
	if err != OK:
		push_error("Failed to connect to camera stream: " + str(err))
		return false
	
	# Wait for connection
	var timeout: float = 0.0
	while _http_client.get_status() == HTTPClient.STATUS_CONNECTING:
		_http_client.poll()
		timeout += get_process_delta_time()
		if timeout > 3.0:
			push_error("Connection timeout")
			return false
		await get_tree().process_frame
	
	if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		push_error("Failed to connect to stream server")
		return false
	
	_http_client.request(HTTPClient.METHOD_GET, "/camera", 
		["Accept: multipart/x-mixed-replace", "Connection: keep-alive", "Cache-Control: no-cache"])
	
	_is_streaming = true
	_thread_running = true
	_stream_thread = Thread.new()
	_stream_thread.start(_stream_loop)
	
	visible = true
	stream_started.emit()
	return true

func stop_stream() -> void:
	if not _is_streaming:
		return
	
	_thread_running = false
	_is_streaming = false
	
	if _stream_thread and _stream_thread.is_alive():
		_stream_thread.wait_to_finish()
	
	if _http_client:
		_http_client.close()
		_http_client = null
	
	visible = false
	stream_stopped.emit()

func is_streaming() -> bool:
	return _is_streaming

func get_stream_url() -> String:
	return stream_url

func _stream_loop() -> void:
	print("[CameraView] Stream thread started")
	var frame_count: int = 0
	var last_log_time: int = Time.get_ticks_msec()
	
	while _thread_running:
		if _http_client:
			_http_client.poll()
			
			var status := _http_client.get_status()
			
			if status == HTTPClient.STATUS_BODY:
				var chunk := _http_client.read_response_body_chunk()
				if chunk.size() > 0:
					_mjpeg_buffer.append_array(chunk)
					_parse_mjpeg_buffer()
			
			elif status == HTTPClient.STATUS_DISCONNECTED:
				print("[CameraView] Connection lost, reconnecting...")
				_http_client.connect_to_host(stream_url.split("://")[1].split("/")[0], 4243)
			
			frame_count += 1
		
		var current_time: int = Time.get_ticks_msec()
		if current_time - last_log_time > 5000:
			last_log_time = current_time
		
		OS.delay_msec(5)
	
	print("[CameraView] Stream thread ended")

func _parse_mjpeg_buffer() -> void:
	var buffer_str := _mjpeg_buffer.get_string_from_utf8()
	
	var boundary_pos := buffer_str.find(_boundary_marker)
	if boundary_pos == -1:
		return
	
	var next_boundary_pos := buffer_str.find(_boundary_marker, boundary_pos + _boundary_marker.length())
	if next_boundary_pos == -1:
		return
	
	var frame_section := buffer_str.substr(boundary_pos, next_boundary_pos - boundary_pos)
	
	var jpeg_start := frame_section.find("\r\n\r\n")
	if jpeg_start == -1:
		jpeg_start = frame_section.find("\n\n")
	
	if jpeg_start != -1:
		jpeg_start += 4
		
		var content_length_start := frame_section.find("Content-Length: ")
		var jpeg_size: int = -1
		if content_length_start != -1 and content_length_start < jpeg_start:
			var length_end := frame_section.find("\r\n", content_length_start)
			if length_end != -1:
				var length_str := frame_section.substr(content_length_start + 16, length_end - content_length_start - 16)
				jpeg_size = length_str.to_int()
		
		var jpeg_data: PackedByteArray
		if jpeg_size > 0:
			var header_bytes := frame_section.substr(0, jpeg_start).to_utf8_buffer().size()
			var start_byte := boundary_pos + header_bytes
			jpeg_data = _mjpeg_buffer.slice(start_byte, start_byte + jpeg_size)
		else:
			var jpeg_str := frame_section.substr(jpeg_start, next_boundary_pos - boundary_pos - jpeg_start)
			jpeg_data = jpeg_str.to_utf8_buffer()
		
		if jpeg_data.size() > 0:
			var image := Image.new()
			var err := image.load_jpg_from_buffer(jpeg_data)
			if err == OK:
				_frame_mutex.lock()
				_current_frame = image
				_frame_mutex.unlock()
	
	_mjpeg_buffer = _mjpeg_buffer.slice(next_boundary_pos)

func _update_texture() -> void:
	_frame_mutex.lock()
	var frame := _current_frame
	_frame_mutex.unlock()
	
	if frame and frame.get_width() > 0:
		var texture := ImageTexture.create_from_image(frame)
		self.texture = texture

static func create_picture_in_picture(parent: Node, position: Vector2 = Vector2(10, 10), 
									size: Vector2 = Vector2(320, 240)) -> MediaPipeCameraView:
	var camera_view := MediaPipeCameraView.new()
	camera_view.position = position
	camera_view.size = size
	camera_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = size
	bg.position = Vector2.ZERO
	camera_view.add_child(bg)
	bg.owner = parent
	
	parent.add_child(camera_view)
	camera_view.owner = parent
	
	return camera_view
