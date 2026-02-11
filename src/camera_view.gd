class_name MediaPipeCameraView
extends TextureRect
## Camera view display for MediaPipe - shows live MJPEG camera feed

signal stream_started()
signal stream_stopped()

@export var stream_url: String = "http://127.0.0.1:4243/camera"
@export var update_interval_ms: float = 33.0

var _tcp: StreamPeerTCP
var _is_streaming: bool = false
var _stream_thread: Thread
var _thread_running: bool = false
var _current_frame: Image
var _frame_mutex: Mutex
var _update_timer: float = 0.0
var _mjpeg_buffer: PackedByteArray

func _ready() -> void:
	_current_frame = Image.create(640, 480, false, Image.FORMAT_RGB8)
	self.texture = ImageTexture.create_from_image(_current_frame)
	_frame_mutex = Mutex.new()
	_mjpeg_buffer = PackedByteArray()
	visible = false

func _exit_tree() -> void:
	print("[CameraView] _exit_tree called, stopping stream...")
	_thread_running = false
	
	if _stream_thread:
		if _stream_thread.is_alive():
			_stream_thread.wait_to_finish()
		_stream_thread = null
	
	if _tcp:
		_tcp.disconnect_from_host()
		_tcp = null

func _process(delta: float) -> void:
	if not _is_streaming:
		return
	_update_timer += delta * 1000.0
	if _update_timer >= update_interval_ms:
		_update_timer = 0.0
		_update_texture()

func start_stream() -> bool:
	if _is_streaming:
		return true
	
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
			return false
		
		await get_tree().process_frame
	
	print("[CameraView] Final TCP status: ", status)
	
	if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		push_error("Failed to connect, status: " + str(_tcp.get_status()))
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
	
	_is_streaming = true
	_thread_running = true
	_stream_thread = Thread.new()
	var thread_err := _stream_thread.start(_stream_loop)
	if thread_err != OK:
		push_error("Failed to start stream thread: " + str(thread_err))
		_is_streaming = false
		_thread_running = false
		return false
	
	visible = true
	stream_started.emit()
	print("[CameraView] Stream started successfully")
	return true

func stop_stream() -> void:
	if not _is_streaming:
		return
	
	print("[CameraView] Stopping stream...")
	_thread_running = false
	_is_streaming = false
	
	if _stream_thread and _stream_thread.is_alive():
		_stream_thread.wait_to_finish()
	
	if _tcp:
		_tcp.disconnect_from_host()
		_tcp = null
	
	visible = false
	stream_stopped.emit()
	print("[CameraView] Stream stopped")

func is_streaming() -> bool:
	return _is_streaming

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
				
				# Parse HTTP headers first
				if not header_parsed:
					var header_end := _mjpeg_buffer.get_string_from_utf8().find("\r\n\r\n")
					if header_end != -1:
						print("[CameraView] HTTP headers received")
						_mjpeg_buffer = _mjpeg_buffer.slice(header_end + 4)
						header_parsed = true
				
				# Try to parse frames
				if header_parsed:
					while _parse_mjpeg_frame():
						frames_decoded += 1
		
		# Log stats every 5 seconds
		var now := Time.get_ticks_msec()
		if now - last_log > 5000:
			print("[CameraView] Stats: ", bytes_received, " bytes, ", frames_decoded, " frames")
			bytes_received = 0
			frames_decoded = 0
			last_log = now
		
		OS.delay_msec(5)
	
	print("[CameraView] Stream thread ended")

func _parse_mjpeg_frame() -> bool:
	# Convert buffer to string just for finding boundaries (headers are ASCII)
	var buffer_str := _mjpeg_buffer.get_string_from_utf8()
	
	# Find boundary
	var boundary := "--frame-boundary"
	var boundary_pos := buffer_str.find(boundary)
	if boundary_pos == -1:
		return false
	
	var next_boundary := buffer_str.find(boundary, boundary_pos + boundary.length())
	if next_boundary == -1:
		return false
	
	# Extract frame section as string for parsing headers
	var frame_section := buffer_str.substr(boundary_pos, next_boundary - boundary_pos)
	
	# Find Content-Length header
	var content_length_start := frame_section.find("Content-Length: ")
	var jpeg_data: PackedByteArray
	
	if content_length_start != -1:
		var length_end := frame_section.find("\r\n", content_length_start)
		if length_end != -1:
			var len_str := frame_section.substr(content_length_start + 16, length_end - content_length_start - 16)
			var jpeg_size := len_str.to_int()
			
			# Find header end in string
			var header_end := frame_section.find("\r\n\r\n")
			if header_end == -1:
				header_end = frame_section.find("\n\n")
			if header_end != -1:
				header_end += 4
				
				# Calculate byte positions
				var header_str := frame_section.substr(0, header_end)
				var header_bytes := header_str.to_utf8_buffer().size()
				var start_byte := boundary_pos + header_bytes
				
				if start_byte + jpeg_size <= _mjpeg_buffer.size():
					jpeg_data = _mjpeg_buffer.slice(start_byte, start_byte + jpeg_size)
	
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
