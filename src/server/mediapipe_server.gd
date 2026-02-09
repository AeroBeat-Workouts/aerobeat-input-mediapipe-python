class_name MediaPipeServer
extends Node
## UDP server that receives landmark data from Python MediaPipe sidecar
## Now supports multiple poses for local multiplayer

const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")

signal landmarks_received(landmarks: Array)
signal multi_pose_received(poses: Array)  # Array of {pose_id, landmarks}
signal server_started(port: int)
signal server_stopped()
signal parse_error(error: String)

@export var config: MediaPipeConfig

var _udp := PacketPeerUDP.new()
var _is_running := false

func start() -> bool:
    var port = config.udp_port if config else 4242
    
    # Try to bind, with fallback to next available port
    var bind_result = _udp.bind(port)
    if bind_result != OK:
        push_warning("MediaPipeServer: Failed to bind to port %d, trying auto-select" % port)
        bind_result = _udp.bind(0)  # 0 = auto-select
        if bind_result != OK:
            push_error("MediaPipeServer: Failed to bind UDP socket")
            return false
        port = _udp.get_local_port()
        if config:
            config.udp_port = port
    
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
    
    # Godot 4 UDP: just try to get packets
    var latest_packet: PackedByteArray
    var packet_count = 0
    
    while packet_count < 10:
        var packet = _udp.get_packet()
        if packet.is_empty():
            break
        latest_packet = packet
        packet_count += 1
    
    if latest_packet.is_empty():
        return
    
    # Packet received successfully - parse it
    print("[MediaPipeServer] Received packet of ", latest_packet.size(), " bytes")
    _parse_packet(latest_packet)

func _parse_packet(packet: PackedByteArray) -> void:
    # Check for protocol marker
    if packet.is_empty():
        return
    
    var marker = packet[0]
    var data_bytes = packet.slice(1)
    
    if marker == 0x00:
        # JSON protocol
        print("[MediaPipeServer] Parsing JSON packet...")
        _parse_json_packet(data_bytes)
    elif marker == 0x01:
        # Binary protocol (legacy single-pose)
        _parse_binary_packet(data_bytes)
    else:
        parse_error.emit("Unknown protocol marker: %d" % marker)

func _parse_json_packet(data_bytes: PackedByteArray) -> void:
    var json := JSON.new()
    var error := json.parse(data_bytes.get_string_from_utf8())
    
    if error != OK:
        parse_error.emit("JSON parse error: " + json.get_error_message())
        return
    
    var data = json.data
    if not data is Dictionary:
        parse_error.emit("Expected JSON object, got: " + str(typeof(data)))
        return
    
    # Debug: Show what keys we received
    print("[MediaPipeServer] JSON keys: ", data.keys())
    
    # Check for multi-pose data
    if data.has("poses"):
        var poses = data["poses"]
        print("[MediaPipeServer] Poses count: ", poses.size() if poses is Array else 0)
        if poses is Array:
            multi_pose_received.emit(poses)
            
            # Also emit primary pose for backward compatibility
            if poses.size() > 0 and poses[0] is Dictionary and poses[0].has("landmarks"):
                var landmarks = poses[0]["landmarks"]
                print("[MediaPipeServer] Primary landmarks: ", landmarks.size() if landmarks is Array else 0)
                landmarks_received.emit(landmarks)
            return
    
    # Fallback to legacy single-pose format
    if not data.has("landmarks"):
        parse_error.emit("Missing 'landmarks' field")
        return
    
    var landmarks = data["landmarks"]
    if not landmarks is Array:
        parse_error.emit("'landmarks' should be an array")
        return
    
    print("[MediaPipeServer] Legacy landmarks: ", landmarks.size())
    landmarks_received.emit(landmarks)

func _parse_binary_packet(data_bytes: PackedByteArray) -> void:
    # Binary protocol - legacy single-pose support
    # For now, just emit parse error since we primarily use JSON for multi-pose
    parse_error.emit("Binary protocol not yet supported for multi-pose")
