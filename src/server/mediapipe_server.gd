class_name MediaPipeServer
extends Node
## UDP server that receives landmark data from Python MediaPipe sidecar

const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")

signal landmarks_received(landmarks: Array)
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
    
    # Drain all pending packets, keep only the newest
    var latest_packet: PackedByteArray
    
    # In Godot 4.x, we poll for packets differently
    # get_available_bytes() might not exist on PacketPeerUDP in some versions
    # Use a try-catch approach with get_packet()
    while true:
        var err = _udp.get_packet_error()
        var packet = _udp.get_packet()
        if packet.is_empty():
            break
        latest_packet = packet
    
    if latest_packet.is_empty():
        return
    
    _parse_packet(latest_packet)

func _parse_packet(packet: PackedByteArray) -> void:
    var json := JSON.new()
    var error := json.parse(packet.get_string_from_utf8())
    
    if error != OK:
        parse_error.emit("JSON parse error: " + json.get_error_message())
        return
    
    var data = json.data
    if not data is Dictionary:
        parse_error.emit("Expected JSON object, got: " + str(typeof(data)))
        return
    
    if not data.has("landmarks"):
        parse_error.emit("Missing 'landmarks' field")
        return
    
    var landmarks = data["landmarks"]
    if not landmarks is Array:
        parse_error.emit("'landmarks' should be an array")
        return
    
    landmarks_received.emit(landmarks)
