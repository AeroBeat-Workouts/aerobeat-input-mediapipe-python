## strategy_mediapipe.gd
##
## Listens for and processes full-body pose data from the MediaPipe Python driver.
## This script opens a UDP socket, parses incoming JSON payloads, and emits the
## landmark data for other nodes to consume.

class_name StrategyMediaPipe
# Note: This assumes a base "Strategy" class may exist in your project.
# If not, extending Node is perfectly fine.
extends Node

## Emitted when a new, valid set of pose landmarks is received.
## The payload is an Array of Dictionaries, one for each landmark.
signal pose_updated(landmarks: Array)

# This port MUST match the UDP_PORT in the Python script.
const PORT = 4242

var udp_listener: PacketPeerUDP
var last_landmarks: Array = []


## Called when the node enters the scene tree.
## Initializes the UDP listener.
func _enter_tree() -> void:
	udp_listener = PacketPeerUDP.new()
	var err: Error = udp_listener.listen(PORT)
	
	if err != OK:
		printerr("StrategyMediaPipe: Error listening on port %d. Is it in use?" % PORT)
		udp_listener = null # Invalidate the listener to prevent errors in _process
		return
	
	print("StrategyMediaPipe: Listening for UDP packets on port %d" % PORT)


## Called when the node is removed from the scene tree.
## Ensures the UDP socket is closed to free up the port.
func _exit_tree() -> void:
	if udp_listener:
		udp_listener.close()
	print("StrategyMediaPipe: UDP listener stopped.")


## Called every frame.
func _process(_delta: float) -> void:
	if not udp_listener:
		return

	# Process all available packets to get the most recent data
	while udp_listener.get_available_packet_count() > 0:
		var packet_bytes: PackedByteArray = udp_listener.get_packet()
		var packet_str: String = packet_bytes.get_string_from_utf8()
		
		var json := JSON.new()
		if json.parse(packet_str) != OK:
			printerr("StrategyMediaPipe: Error parsing JSON: ", json.get_error_message())
			continue
		
		var data: Dictionary = json.get_data()
		if data.has("landmarks"):
			last_landmarks = data["landmarks"]
			pose_updated.emit(last_landmarks)
		else:
			printerr("StrategyMediaPipe: Received invalid payload (missing 'landmarks' key).")