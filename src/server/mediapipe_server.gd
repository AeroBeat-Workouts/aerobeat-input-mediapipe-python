class_name MediaPipeServer
extends Node
## UDP server that receives landmark data from Python MediaPipe sidecar

const ConfigClass = preload("res://src/config/mediapipe_config.gd")

signal landmarks_received(landmarks: Array)
signal multi_pose_received(poses: Array)
signal server_started(port: int)
signal server_stopped()
signal parse_error(error: String)

@export var config: ConfigClass

var _udp: PacketPeerUDP = PacketPeerUDP.new()
var _is_running: bool = false
var _poll_count: int = 0

func start() -> bool:
	var port: int = config.udp_port if config else 4242
	
	print("[MediaPipeServer] Starting UDP server on port ", port)
	
	var bind_result: int = _udp.bind(port, "127.0.0.1")
	if bind_result != OK:
		push_warning("MediaPipeServer: Failed to bind to port %d, trying auto-select" % port)
		bind_result = _udp.bind(0, "127.0.0.1")
		if bind_result != OK:
			push_error("MediaPipeServer: Failed to bind UDP socket")
			return false
		port = _udp.get_local_port()
		if config:
			config.udp_port = port
	
	print("[MediaPipeServer] UDP socket bound to 127.0.0.1:", port)
	_is_running = true
	server_started.emit(port)
	return true

func stop() -> void:
	_is_running = false
	_udp.close()
	server_stopped.emit()

func is_running() -> bool:
	return _is_running

func get_bound_port() -> int:
	return _udp.get_local_port() if _is_running else -1

func _process(_delta: float) -> void:
	if not _is_running:
		return
	
	_poll_count += 1
	
	var latest_packet: PackedByteArray
	var packet_count: int = 0
	
	while packet_count < 10:
		var packet: PackedByteArray = _udp.get_packet()
		if packet.is_empty():
			break
		latest_packet = packet
		packet_count += 1
	
	if latest_packet.is_empty():
		return
	
	_parse_packet(latest_packet)

func _parse_packet(packet: PackedByteArray) -> void:
	if packet.is_empty():
		return
	
	var marker: int = packet[0]
	var data_bytes: PackedByteArray = packet.slice(1)
	
	if marker == 0x00:
		_parse_json_packet(data_bytes)
	elif marker == 0x01:
		_parse_binary_packet(data_bytes)
	else:
		parse_error.emit("Unknown protocol marker: %d" % marker)

func _parse_json_packet(data_bytes: PackedByteArray) -> void:
	var json: JSON = JSON.new()
	var error: int = json.parse(data_bytes.get_string_from_utf8())
	
	if error != OK:
		parse_error.emit("JSON parse error: " + json.get_error_message())
		return
	
	var data: Variant = json.data
	if not data is Dictionary:
		parse_error.emit("Expected JSON object")
		return
	
	var data_dict: Dictionary = data
	
	if data_dict.has("poses"):
		var poses: Variant = data_dict["poses"]
		if poses is Array:
			multi_pose_received.emit(poses)
			
			var poses_array: Array = poses
			if poses_array.size() > 0:
				var first_pose: Variant = poses_array[0]
				if first_pose is Dictionary:
					var first_pose_dict: Dictionary = first_pose
					if first_pose_dict.has("landmarks"):
						var pose_landmarks: Variant = first_pose_dict["landmarks"]
						if pose_landmarks is Array:
							landmarks_received.emit(pose_landmarks)
			return
	
	if not data_dict.has("landmarks"):
		parse_error.emit("Missing 'landmarks' field")
		return
	
	var landmarks_array: Variant = data_dict["landmarks"]
	if not landmarks_array is Array:
		parse_error.emit("'landmarks' should be an array")
		return
	
	landmarks_received.emit(landmarks_array)

func _parse_binary_packet(_data_bytes: PackedByteArray) -> void:
	parse_error.emit("Binary protocol not yet supported")
