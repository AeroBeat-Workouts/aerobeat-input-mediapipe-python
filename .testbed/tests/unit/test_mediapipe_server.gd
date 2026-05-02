extends "res://addons/gut/test.gd"

const MediaPipeServer = preload("res://addons/aerobeat-input-mediapipe-python/src/server/mediapipe_server.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

var server: MediaPipeServer = null
var config: MediaPipeConfig = null

func before_each() -> void:
	config = MediaPipeConfig.new()
	config.udp_port = 9999
	server = add_child_autoqfree(MediaPipeServer.new())
	server.config = config

func after_each() -> void:
	if server != null and is_instance_valid(server) and server.is_running():
		server.stop()

func test_start_binds_to_port() -> void:
	var success := server.start()
	assert_true(success, "Server should start")
	assert_true(server.is_running())
	assert_gt(server.get_bound_port(), 0)

func test_stop_releases_port() -> void:
	server.start()
	server.stop()
	assert_false(server.is_running())
	assert_eq(server.get_bound_port(), -1)

func test_emits_server_started_signal() -> void:
	watch_signals(server)
	server.start()
	assert_signal_emitted(server, "server_started")

func test_parse_valid_json() -> void:
	watch_signals(server)
	var test_data := JSON.stringify({"landmarks": [{"id": 0, "x": 0.5, "y": 0.5, "v": 0.99}]})
	var packet := PackedByteArray([0x00])
	packet.append_array(test_data.to_utf8_buffer())
	server._parse_packet(packet)

	assert_signal_emitted(server, "landmarks_received")

func test_handles_parse_error() -> void:
	watch_signals(server)
	var packet := PackedByteArray([0x00])
	packet.append_array("invalid json".to_utf8_buffer())
	server._parse_packet(packet)

	assert_signal_emitted(server, "parse_error")
