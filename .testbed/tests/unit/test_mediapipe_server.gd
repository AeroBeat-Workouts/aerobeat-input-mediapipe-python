extends RefCounted
## Unit tests for MediaPipeServer
## Compatible with GUT if available, otherwise runs basic checks

const MediaPipeServer = preload("res://src/server/mediapipe_server.gd")
const MediaPipeConfig = preload("res://src/config/mediapipe_config.gd")

var server = null
var config = null

func _init():
	# Run tests if GUT is not available
	if not _is_gut_available():
		print("[MediaPipeServerTest] Running standalone tests...")
		_run_standalone_tests()

func _is_gut_available() -> bool:
	return ClassDB.class_exists("GutTest") or FileAccess.file_exists("res://addons/gut/plugin.cfg")

func _run_standalone_tests():
	print("Testing MediaPipeServer...")
	
	config = MediaPipeConfig.new()
	config.udp_port = 9999
	
	server = MediaPipeServer.new()
	server.config = config
	
	# Test 1: Create server
	if server:
		print("✓ Server created successfully")
	else:
		print("✗ Failed to create server")
		return
	
	# Test 2: Parse valid JSON
	var landmarks_received = []
	server.landmarks_received.connect(func(l): landmarks_received = l)
	
	var test_data = JSON.stringify({"landmarks": [{"id": 0, "x": 0.5, "y": 0.5, "v": 0.99}]})
	server._parse_packet(test_data.to_utf8_buffer())
	
	if landmarks_received.size() == 1:
		print("✓ Parses valid JSON correctly")
	else:
		print("✗ Failed to parse valid JSON")
	
	# Test 3: Handle parse error
	var error_received = ""
	server.parse_error.connect(func(e): error_received = e)
	server._parse_packet("invalid json".to_utf8_buffer())
	
	if error_received != "":
		print("✓ Handles parse errors gracefully")
	else:
		print("✗ Did not emit parse error")
	
	print("[MediaPipeServerTest] Standalone tests complete.")

# GUT-compatible test methods
func before_each():
	if not _is_gut_available():
		return
	config = MediaPipeConfig.new()
	config.udp_port = 9999
	server = MediaPipeServer.new()
	server.config = config

func after_each():
	if not _is_gut_available():
		return
	if server.is_running():
		server.stop()
	server.queue_free()

func test_start_binds_to_port():
	if not _is_gut_available():
		return
	var success = server.start()
	assert_true(success, "Server should start")
	assert_true(server.is_running())
	assert_gt(server.get_bound_port(), 0)

func test_stop_releases_port():
	if not _is_gut_available():
		return
	server.start()
	server.stop()
	assert_false(server.is_running())

func test_emits_server_started_signal():
	if not _is_gut_available():
		return
	var port_received = -1
	server.server_started.connect(func(p): port_received = p)
	server.start()
	assert_gt(port_received, 0)

func test_parse_valid_json():
	if not _is_gut_available():
		return
	var landmarks_received = []
	server.landmarks_received.connect(func(l): landmarks_received = l)
	server.start()
	
	var test_data = JSON.stringify({"landmarks": [{"id": 0, "x": 0.5, "y": 0.5, "v": 0.99}]})
	server._parse_packet(test_data.to_utf8_buffer())
	
	assert_eq(landmarks_received.size(), 1)

func test_handles_parse_error():
	if not _is_gut_available():
		return
	var error_received = ""
	server.parse_error.connect(func(e): error_received = e)
	server.start()
	
	server._parse_packet("invalid json".to_utf8_buffer())
	
	assert_ne(error_received, "")
