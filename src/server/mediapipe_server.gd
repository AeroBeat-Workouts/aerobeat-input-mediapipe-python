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
		print("[MediaPipeServer] Port %d in use, auto-selecting alternative..." % port)
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

func _parse_binary_packet(data_bytes: PackedByteArray) -> void:
	if data_bytes.size() < 54:  # Minimum header size
		parse_error.emit("Binary packet too small: " + str(data_bytes.size()))
		return
	
	var offset := 0
	
	# Read header
	var version := data_bytes[offset]
	offset += 1
	
	if version != 1:
		parse_error.emit("Unknown binary protocol version: " + str(version))
		return
	
	# Skip timestamp and timing data (we don't need it for landmarks)
	offset += 8 * 6  # 6 doubles
	
	# Skip frame count, fps, skip frames
	offset += 4 * 3  # 3 ints/floats
	
	# Read number of poses
	var num_poses := data_bytes[offset]
	offset += 1
	
	if num_poses == 0:
		return
	
	var all_poses: Array = []
	
	for pose_idx in range(num_poses):
		if offset >= data_bytes.size():
			break
		
		var pose_id := data_bytes[offset]
		offset += 1
		
		if offset >= data_bytes.size():
			break
		
		var num_landmarks := data_bytes[offset]
		offset += 1
		
		var landmarks: Array = []
		
		for lm_idx in range(num_landmarks):
			if offset + 17 > data_bytes.size():  # Each landmark is 17 bytes
				break
			
			var lm_id := data_bytes[offset]
			offset += 1
			
			# Read floats (4 bytes each, little-endian)
			var x := data_bytes.decode_float(offset)
			offset += 4
			var y := data_bytes.decode_float(offset)
			offset += 4
			var z := data_bytes.decode_float(offset)
			offset += 4
			var v := data_bytes.decode_float(offset)
			offset += 4
			
			landmarks.append({
				"id": lm_id,
				"x": x,
				"y": y,
				"z": z,
				"v": v
			})
		
		all_poses.append({
			"pose_id": pose_id,
			"landmarks": landmarks
		})
	
	# Emit multi-pose data
	if all_poses.size() > 0:
		multi_pose_received.emit(all_poses)
		
		# Also emit legacy landmarks from first pose
		var first_pose: Variant = all_poses[0]
		if first_pose is Dictionary:
			var first_pose_dict: Dictionary = first_pose
			var landmarks: Variant = first_pose_dict.get("landmarks", [])
			if landmarks is Array:
				landmarks_received.emit(landmarks)
