extends Control
## Shared proving harness for live Boxing / Flow detector tuning.

const MediaPipeProvider = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeCameraView = preload("res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd")
const MediaPipeConfig = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

const LEFT_WRIST_ID := 15
const RIGHT_WRIST_ID := 16
const MAX_EVENT_LINES := 22
const MAX_TRAIL_POINTS := 36
const MAX_TRAIL_AGE_MS := 1800

const BOXING_EVENT_ORDER := [
	"punch_left",
	"punch_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
	"guard_start",
	"guard_end",
	"squat_start",
	"squat_end",
	"lean_left_start",
	"lean_left_end",
	"lean_right_start",
	"lean_right_end",
	"sidestep_left_start",
	"sidestep_left_end",
	"sidestep_right_start",
	"sidestep_right_end",
	"knee_left",
	"knee_right",
	"leg_lift_left_start",
	"leg_lift_left_end",
	"leg_lift_right_start",
	"leg_lift_right_end",
]

const FLOW_EVENT_ORDER := [
	"swing_left",
	"swing_right",
	"trail_left",
	"trail_right",
]

enum HarnessMode {
	BOXING,
	FLOW,
}

@export var harness_mode: HarnessMode = HarnessMode.BOXING
@export var scene_title := "Detector Proving Harness"
@export_multiline var scene_notes := ""
@export var overlay_visibility_threshold := 0.35
@export var show_landmarks := true
@export var show_trails := true

@onready var status_label: Label = $Margin/VSplit/Header/StatusLabel
@onready var title_label: Label = $Margin/VSplit/Header/TitleLabel
@onready var notes_label: Label = $Margin/VSplit/Header/NotesLabel
@onready var camera_display: TextureRect = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay
@onready var landmark_drawer: Control = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay/LandmarkDrawer
@onready var trail_drawer: Control = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay/TrailDrawer
@onready var quick_stats_label: RichTextLabel = $Margin/VSplit/Content/LeftColumn/QuickStatsPanel/QuickStats
@onready var summary_label: RichTextLabel = $Margin/VSplit/Content/RightColumn/SummaryPanel/Summary
@onready var metrics_label: RichTextLabel = $Margin/VSplit/Content/RightColumn/MetricsPanel/Metrics
@onready var events_label: RichTextLabel = $Margin/VSplit/Content/RightColumn/EventsPanel/Events

var provider: MediaPipeProvider = null
var auto_start_manager: Node = null
var camera_view: MediaPipeCameraView = null
var _frame_count := 0
var _server_ready := false
var _latest_landmarks: Array = []
var _latest_state: Dictionary = {}
var _event_lines: Array[String] = []
var _left_trail: Array = []
var _right_trail: Array = []
var _last_flow_events := {}

func _ready() -> void:
	title_label.text = scene_title
	notes_label.text = scene_notes
	if quick_stats_label:
		quick_stats_label.bbcode_enabled = false
	if summary_label:
		summary_label.bbcode_enabled = false
	if metrics_label:
		metrics_label.bbcode_enabled = false
	if events_label:
		events_label.bbcode_enabled = false
	_reset_last_flow_events()
	_update_status("Initializing...", Color.WHITE)
	_setup_auto_start()
	_refresh_debug_panels()

func _setup_auto_start() -> void:
	auto_start_manager = get_node_or_null("AutoStartManager")
	if auto_start_manager == null:
		push_error("[ProvingHarness] AutoStartManager node not found in scene")
		_update_status("AutoStartManager missing", Color.RED)
		return

	auto_start_manager.server_started.connect(_on_server_started)
	auto_start_manager.server_failed.connect(_on_server_failed)
	auto_start_manager.server_stopped.connect(_on_server_stopped)
	auto_start_manager.python_not_found.connect(_on_python_not_found)
	auto_start_manager.mediapipe_not_found.connect(_on_mediapipe_not_found)
	auto_start_manager.check_progress.connect(_on_check_progress)
	auto_start_manager.installation_progress.connect(_on_install_progress)
	auto_start_manager.installation_complete.connect(_on_install_complete)

	if not auto_start_manager.auto_start:
		await auto_start_manager.start_server()

func _process(_delta: float) -> void:
	_frame_count += 1

	if _frame_count % 60 == 0 and auto_start_manager and auto_start_manager.server_pid > 0:
		if not auto_start_manager.is_server_running():
			_update_status("Python server died", Color.RED)
			_server_ready = false

	if _frame_count % 10 == 0:
		if provider != null:
			_latest_state = provider.get_detector_state()
		_refresh_debug_panels()

func _on_check_progress(percentage: int, message: String) -> void:
	_update_status("%d%% - %s" % [percentage, message], Color.YELLOW)

func _on_install_progress(percentage: int, message: String) -> void:
	_update_status("Installing: %d%% - %s" % [percentage, message], Color.ORANGE)

func _on_install_complete(success: bool) -> void:
	if success:
		_update_status("Installation complete. Starting server...", Color.GREEN)
	else:
		_update_status("Installation failed", Color.RED)

func _on_python_not_found() -> void:
	_update_status("Python 3 not found", Color.RED)

func _on_mediapipe_not_found() -> void:
	_update_status("MediaPipe runtime missing - installing", Color.YELLOW)

func _on_server_started(pid: int) -> void:
	_update_status("Python server started (PID %d)" % pid, Color.GREEN)
	await get_tree().create_timer(1.5).timeout
	await _start_camera_feed()
	_start_provider()

func _on_server_failed(error: String) -> void:
	_update_status("Auto-start failed: %s" % error, Color.RED)
	_record_event("server_failed", {"detail": error})

func _on_server_stopped() -> void:
	_server_ready = false
	_update_status("Server stopped", Color.ORANGE)

func _start_provider() -> void:
	if provider != null:
		return

	provider = MediaPipeProvider.new()
	provider.name = "MediaPipeProvider"
	provider.config = _build_runtime_config()
	add_child(provider)

	provider.pose_updated.connect(_on_pose_updated)
	provider.tracking_lost.connect(_on_tracking_lost)
	provider.tracking_restored.connect(_on_tracking_restored)
	_connect_mode_signals()

	var success := provider.start()
	if success:
		_server_ready = true
		_record_event("provider_started", {"mode": _mode_name()})
		_update_status("%s harness live" % _mode_name(), Color.GREEN)
	else:
		_update_status("Provider failed to start", Color.RED)

func _build_runtime_config() -> MediaPipeConfig:
	var config := MediaPipeConfig.new()
	config.min_visibility = overlay_visibility_threshold
	config.track_left_foot = true
	config.track_right_foot = true
	config.flip_horizontal = true
	return config

func _connect_mode_signals() -> void:
	if harness_mode == HarnessMode.BOXING:
		for signal_name: String in ["punch_left", "punch_right", "hook_left", "hook_right", "uppercut_left", "uppercut_right", "knee_left", "knee_right"]:
			_connect_power_signal(signal_name)
		for signal_name: String in ["guard_start", "guard_end", "squat_start", "squat_end", "lean_left_start", "lean_left_end", "lean_right_start", "lean_right_end", "sidestep_left_start", "sidestep_left_end", "sidestep_right_start", "sidestep_right_end", "leg_lift_left_start", "leg_lift_left_end", "leg_lift_right_start", "leg_lift_right_end"]:
			_connect_simple_signal(signal_name)
	else:
		for signal_name: String in ["swing_left", "swing_right", "trail_left", "trail_right"]:
			_connect_flow_signal(signal_name)

func _connect_simple_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func() -> void:
		_record_event(signal_name, {})
	)

func _connect_power_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func(power: float) -> void:
		_record_event(signal_name, {"power": power})
	)

func _connect_flow_signal(signal_name: String) -> void:
	if provider == null or not provider.has_signal(signal_name):
		return
	provider.connect(signal_name, func(placement: StringName, direction: StringName) -> void:
		_last_flow_events[signal_name] = {
			"placement": placement,
			"direction": direction,
			"timestamp_ms": Time.get_ticks_msec(),
		}
		_record_event(signal_name, {"placement": placement, "direction": direction})
	)

func _on_pose_updated(landmarks: Array) -> void:
	_latest_landmarks = landmarks.duplicate(true)
	_latest_state = provider.get_detector_state() if provider != null else {}

	if show_landmarks and landmark_drawer:
		landmark_drawer.update_landmarks(landmarks, overlay_visibility_threshold)
	elif landmark_drawer:
		landmark_drawer.clear_landmarks()

	_update_motion_trails(landmarks)
	_refresh_debug_panels()

func _update_motion_trails(landmarks: Array) -> void:
	var timestamp_ms := Time.get_ticks_msec()
	var left_wrist := _find_landmark(landmarks, LEFT_WRIST_ID)
	var right_wrist := _find_landmark(landmarks, RIGHT_WRIST_ID)
	_append_trail_point(_left_trail, left_wrist, timestamp_ms)
	_append_trail_point(_right_trail, right_wrist, timestamp_ms)
	_prune_trail(_left_trail, timestamp_ms)
	_prune_trail(_right_trail, timestamp_ms)
	if show_trails and trail_drawer:
		trail_drawer.update_trails(_left_trail, _right_trail)
	elif trail_drawer:
		trail_drawer.clear_trails()

func _append_trail_point(trail: Array, landmark: Dictionary, timestamp_ms: int) -> void:
	if landmark.is_empty():
		return
	var visibility := float(landmark.get("v", 0.0))
	if visibility < overlay_visibility_threshold:
		return
	trail.append({
		"x": float(landmark.get("x", 0.0)),
		"y": float(landmark.get("y", 0.0)),
		"v": visibility,
		"timestamp_ms": timestamp_ms,
	})
	while trail.size() > MAX_TRAIL_POINTS:
		trail.remove_at(0)

func _prune_trail(trail: Array, timestamp_ms: int) -> void:
	while trail.size() > 0 and timestamp_ms - int(trail[0].get("timestamp_ms", timestamp_ms)) > MAX_TRAIL_AGE_MS:
		trail.remove_at(0)

func _find_landmark(landmarks: Array, landmark_id: int) -> Dictionary:
	for landmark_variant: Variant in landmarks:
		if not landmark_variant is Dictionary:
			continue
		var landmark: Dictionary = landmark_variant
		if int(landmark.get("id", -1)) == landmark_id:
			return landmark
	return {}

func _on_tracking_lost() -> void:
	_update_status("Tracking lost", Color.ORANGE)
	_record_event("tracking_lost", {})
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()

func _on_tracking_restored() -> void:
	_update_status("Tracking restored", Color.GREEN)
	_record_event("tracking_restored", {})

func _start_camera_feed() -> void:
	camera_view = MediaPipeCameraView.new()
	camera_view.name = "CameraView"
	camera_view.stream_url = "http://127.0.0.1:4243/camera"
	camera_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	camera_view.show_overlay = false

	var previous_display := camera_display
	previous_display.replace_by(camera_view)
	camera_display = camera_view
	if landmark_drawer:
		landmark_drawer.reparent(camera_display)
	if trail_drawer:
		trail_drawer.reparent(camera_display)
	if previous_display and previous_display != camera_view:
		previous_display.queue_free()

	await get_tree().process_frame
	var stream_started := await camera_view.start_stream()
	if not stream_started:
		_record_event("camera_stream_failed", {})

func _refresh_debug_panels() -> void:
	quick_stats_label.text = _build_quick_stats_text()
	summary_label.text = _build_summary_text()
	metrics_label.text = _build_metrics_text()
	events_label.text = _build_events_text()

func _build_quick_stats_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var visible_landmarks := int((state.get("landmarks_by_id", {}) as Dictionary).size())
	var lines := [
		"Quick stats",
		"==========",
		"Mode: %s" % _mode_name(),
		"Server: %s" % ("ready" if _server_ready else "starting"),
		"Camera: %s" % ("streaming" if camera_view and camera_view.is_streaming() else "offline"),
		"Tracking: %s" % String(state.get("tracking_state", &"lost")),
		"Poses: %d" % pose_count,
		"Visible landmarks: %d" % visible_landmarks,
		"Head confidence: %s" % _fmt_float(confidences.get("head", 0.0)),
		"L hand confidence: %s" % _fmt_float(confidences.get("left_hand", 0.0)),
		"R hand confidence: %s" % _fmt_float(confidences.get("right_hand", 0.0)),
	]
	if harness_mode == HarnessMode.BOXING:
		lines.append("Height state: %s" % String(measurements.get("height_state", &"unknown")))
		lines.append("Lateral offset: %s" % _fmt_float(measurements.get("lateral_offset", 0.0)))
	else:
		lines.append("Trail L points/duration: %d / %dms" % [_left_trail.size(), _trail_duration_ms(_left_trail)])
		lines.append("Trail R points/duration: %d / %dms" % [_right_trail.size(), _trail_duration_ms(_right_trail)])
	return "\n".join(lines)

func _build_summary_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var baseline: Dictionary = state.get("baseline", {})
	var lines := [
		"Overview",
		"========",
		"Harness: %s" % scene_title,
		"Tracking state: %s" % String(state.get("tracking_state", &"lost")),
		"Baseline calibrated: %s" % str(bool(baseline.get("is_calibrated", false))),
		"Baseline frames: %d" % int(baseline.get("sample_frames", 0)),
		"Shoulder width: %s" % _fmt_float(measurements.get("shoulder_width", 0.0)),
		"Torso height: %s" % _fmt_float(measurements.get("torso_height", 0.0)),
	]
	if harness_mode == HarnessMode.BOXING:
		lines.append("")
		lines.append("Body states")
		lines.append("-----------")
		lines.append("guard=%s squat=%s" % [str(bool(gesture_states.get("guard", false))), str(bool(gesture_states.get("squat", false)))])
		lines.append("lean_left=%s lean_right=%s" % [str(bool(gesture_states.get("lean_left", false))), str(bool(gesture_states.get("lean_right", false)))])
		lines.append("sidestep_left=%s sidestep_right=%s" % [str(bool(gesture_states.get("sidestep_left", false))), str(bool(gesture_states.get("sidestep_right", false)))])
		lines.append("leg_lift_left=%s leg_lift_right=%s" % [str(bool(gesture_states.get("leg_lift_left", false))), str(bool(gesture_states.get("leg_lift_right", false)))])
		lines.append("height=%s ratio=%s squat_depth=%s" % [String(measurements.get("height_state", &"unknown")), _fmt_float(measurements.get("height_ratio", 0.0)), _fmt_float(measurements.get("squat_depth", 0.0))])
		lines.append("head/hip lateral=%s / %s" % [_fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
	else:
		lines.append("")
		lines.append("Flow event summary")
		lines.append("------------------")
		for key: String in ["swing_left", "swing_right", "trail_left", "trail_right"]:
			lines.append("%s: %s" % [key, _describe_last_flow_event(key)])
		lines.append("trail_left_active=%s trail_right_active=%s" % [str(bool(gesture_states.get("trail_left", false))), str(bool(gesture_states.get("trail_right", false)))])
		lines.append("Local continuity: L=%d pts (%dms), R=%d pts (%dms)" % [_left_trail.size(), _trail_duration_ms(_left_trail), _right_trail.size(), _trail_duration_ms(_right_trail)])
	return "\n".join(lines)

func _build_metrics_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var velocities: Dictionary = metrics.get("velocities", {})
	var directions: Dictionary = metrics.get("directions", {})
	var lines := [
		"Detector metrics",
		"================",
		"Confidences: head=%s torso=%s" % [_fmt_float(confidences.get("head", 0.0)), _fmt_float(confidences.get("torso", 0.0))],
		"             left_hand=%s right_hand=%s" % [_fmt_float(confidences.get("left_hand", 0.0)), _fmt_float(confidences.get("right_hand", 0.0))],
		"             left_foot=%s right_foot=%s" % [_fmt_float(confidences.get("left_foot", 0.0)), _fmt_float(confidences.get("right_foot", 0.0))],
		"Velocities:  L hand=%s" % _fmt_vec3(velocities.get("left_hand", Vector3.ZERO)),
		"             R hand=%s" % _fmt_vec3(velocities.get("right_hand", Vector3.ZERO)),
		"             L foot=%s" % _fmt_vec3(velocities.get("left_foot", Vector3.ZERO)),
		"             R foot=%s" % _fmt_vec3(velocities.get("right_foot", Vector3.ZERO)),
		"Directions:  L hand=%s R hand=%s" % [_fmt_vec2(directions.get("left_hand", Vector2.ZERO)), _fmt_vec2(directions.get("right_hand", Vector2.ZERO))],
	]
	if harness_mode == HarnessMode.BOXING:
		lines.append("")
		lines.append("Boxing threshold readouts")
		lines.append("------------------------")
		lines.append("L arm ext=%s elbow=%s°" % [_fmt_float(measurements.get("left_arm_extension", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg", 0.0))])
		lines.append("R arm ext=%s elbow=%s°" % [_fmt_float(measurements.get("right_arm_extension", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg", 0.0))])
		lines.append("height_ratio=%s head_drop=%s" % [_fmt_float(measurements.get("height_ratio", 0.0)), _fmt_float(measurements.get("head_drop_ratio", 0.0))])
		lines.append("lateral body/head/hip=%s / %s / %s" % [_fmt_float(measurements.get("lateral_offset", 0.0)), _fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
		lines.append("L knee/foot rise=%s / %s" % [_fmt_float(measurements.get("left_knee_rise", 0.0)), _fmt_float(measurements.get("left_foot_rise", 0.0))])
		lines.append("R knee/foot rise=%s / %s" % [_fmt_float(measurements.get("right_knee_rise", 0.0)), _fmt_float(measurements.get("right_foot_rise", 0.0))])
		lines.append("L leg angle=%s°  R leg angle=%s°" % [_fmt_float(measurements.get("left_leg_angle_from_core_deg", 0.0)), _fmt_float(measurements.get("right_leg_angle_from_core_deg", 0.0))])
	else:
		lines.append("")
		lines.append("Flow / continuity readouts")
		lines.append("-------------------------")
		lines.append("Last swing_left: %s" % _describe_last_flow_event("swing_left"))
		lines.append("Last swing_right: %s" % _describe_last_flow_event("swing_right"))
		lines.append("Last trail_left: %s" % _describe_last_flow_event("trail_left"))
		lines.append("Last trail_right: %s" % _describe_last_flow_event("trail_right"))
		lines.append("L trail points=%d duration=%dms" % [_left_trail.size(), _trail_duration_ms(_left_trail)])
		lines.append("R trail points=%d duration=%dms" % [_right_trail.size(), _trail_duration_ms(_right_trail)])
		lines.append("Placement feed is detector-emitted. Continuity timing above is local harness visualization.")
	return "\n".join(lines)

func _build_events_text() -> String:
	var lines := ["Live events", "==========="]
	if _event_lines.is_empty():
		lines.append("(waiting for detector activity)")
	else:
		lines.append_array(_event_lines)
	return "\n".join(lines)

func _record_event(event_name: String, payload: Dictionary) -> void:
	var timestamp := Time.get_time_string_from_system()
	var line := "%s  %s%s" % [timestamp, event_name, _format_event_payload(payload)]
	_event_lines.push_front(line)
	while _event_lines.size() > MAX_EVENT_LINES:
		_event_lines.pop_back()
	_refresh_debug_panels()

func _format_event_payload(payload: Dictionary) -> String:
	if payload.is_empty():
		return ""
	var parts: Array[String] = []
	for key_variant: Variant in payload.keys():
		var key := String(key_variant)
		var value: Variant = payload[key_variant]
		if value is float:
			parts.append("%s=%.3f" % [key, value])
		else:
			parts.append("%s=%s" % [key, str(value)])
	return "  [" + ", ".join(parts) + "]"

func _describe_last_flow_event(event_name: String) -> String:
	var event_data: Dictionary = _last_flow_events.get(event_name, {})
	if event_data.is_empty():
		return "none"
	var age_ms := Time.get_ticks_msec() - int(event_data.get("timestamp_ms", 0))
	return "%s / %s (%dms ago)" % [String(event_data.get("placement", &"center")), String(event_data.get("direction", StringName())), age_ms]

func _trail_duration_ms(trail: Array) -> int:
	if trail.size() < 2:
		return 0
	return max(int(trail[trail.size() - 1].get("timestamp_ms", 0)) - int(trail[0].get("timestamp_ms", 0)), 0)

func _reset_last_flow_events() -> void:
	_last_flow_events = {
		"swing_left": {},
		"swing_right": {},
		"trail_left": {},
		"trail_right": {},
	}

func _mode_name() -> String:
	return "Boxing" if harness_mode == HarnessMode.BOXING else "Flow"

func _fmt_float(value: Variant) -> String:
	return "%.3f" % float(value if value != null else 0.0)

func _fmt_vec2(value: Variant) -> String:
	if value is Vector2:
		return "(%.3f, %.3f)" % [value.x, value.y]
	return "(0.000, 0.000)"

func _fmt_vec3(value: Variant) -> String:
	if value is Vector3:
		return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]
	return "(0.000, 0.000, 0.000)"

func _update_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.modulate = color

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_stop_everything()
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		_stop_everything()

func _stop_everything() -> void:
	if camera_view and camera_view.is_streaming():
		camera_view.stop_stream()
	if camera_view and is_instance_valid(camera_view):
		camera_view.queue_free()
	camera_view = null

	if provider:
		provider.stop()
		if is_instance_valid(provider):
			provider.queue_free()
		provider = null

	auto_start_manager = null
	_server_ready = false
