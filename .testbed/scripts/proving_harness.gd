extends Control
## Shared proving harness for live Boxing / Flow detector tuning.

const MediaPipeProviderScript = preload("res://addons/aerobeat-input-mediapipe-python/src/providers/mediapipe_provider.gd")
const MediaPipeCameraViewScript = preload("res://addons/aerobeat-input-mediapipe-python/src/camera_view.gd")
const MediaPipeConfigScript = preload("res://addons/aerobeat-input-mediapipe-python/src/config/mediapipe_config.gd")

const LEFT_WRIST_ID := 15
const RIGHT_WRIST_ID := 16
const LEFT_PINKY_ID := 17
const RIGHT_PINKY_ID := 18
const LEFT_INDEX_ID := 19
const RIGHT_INDEX_ID := 20
const LEFT_THUMB_ID := 21
const RIGHT_THUMB_ID := 22
const MAX_EVENT_LINES := 22
const MAX_TRAIL_POINTS := 36
const MAX_TRAIL_AGE_MS := 1800
const MAX_TRAIL_FRAME_JUMP := 0.28
const TRAIL_VISIBILITY_THRESHOLD_FLOOR := 0.18
const TRAIL_NEAR_BOUNDS_MARGIN := 0.08

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

const BOXING_ATTACK_EVENTS := [
	"punch_left",
	"punch_right",
	"hook_left",
	"hook_right",
	"uppercut_left",
	"uppercut_right",
]

const BOXING_KNEE_EVENTS := [
	"knee_left",
	"knee_right",
]

const BOXING_STATE_ROWS := [
	{"label": "guard", "state": "guard", "start": "guard_start", "end": "guard_end"},
	{"label": "squat", "state": "squat", "start": "squat_start", "end": "squat_end"},
	{"label": "lean_left", "state": "lean_left", "start": "lean_left_start", "end": "lean_left_end"},
	{"label": "lean_right", "state": "lean_right", "start": "lean_right_start", "end": "lean_right_end"},
	{"label": "sidestep_left", "state": "sidestep_left", "start": "sidestep_left_start", "end": "sidestep_left_end"},
	{"label": "sidestep_right", "state": "sidestep_right", "start": "sidestep_right_start", "end": "sidestep_right_end"},
]

enum HarnessMode {
	BOXING,
	FLOW,
}

enum StartupMode {
	TRACKING,
	PREVIEW_ONLY_DEBUG,
	GODOT_ONLY_DEBUG,
}

@export var harness_mode: HarnessMode = HarnessMode.BOXING
@export var startup_mode: StartupMode = StartupMode.TRACKING
@export_file("*.mp4", "*.mov", "*.avi", "*.mkv", "*.webm") var prerecorded_video_source := ""
@export var scene_title := "Detector Proving Harness"
@export_multiline var scene_notes := ""
@export var overlay_visibility_threshold := 0.35
@export var show_landmarks := true
@export var show_trails := true
@export var trail_debug_logging := true

@onready var status_label: Label = $Margin/VSplit/Header/StatusLabel
@onready var live_status_label: RichTextLabel = $Margin/VSplit/Header/LiveStatusLabel
@onready var title_label: Label = $Margin/VSplit/Header/TitleLabel
@onready var notes_label: Label = $Margin/VSplit/Header/NotesLabel
@onready var camera_display: TextureRect = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay
@onready var landmark_drawer: Control = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay/LandmarkDrawer
@onready var trail_drawer: Control = $Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay/TrailDrawer
@onready var quick_stats_label: RichTextLabel = $Margin/VSplit/Content/LeftColumn/QuickStatsPanel/QuickStats
@onready var summary_label: RichTextLabel = $Margin/VSplit/Content/RightPanelScroll/RightColumn/SummaryPanel/Summary
@onready var signal_status_label: RichTextLabel = $Margin/VSplit/Content/RightPanelScroll/RightColumn/SignalPanel/SignalStatus
@onready var metrics_label: RichTextLabel = $Margin/VSplit/Content/RightPanelScroll/RightColumn/MetricsPanel/Metrics
@onready var events_label: RichTextLabel = $Margin/VSplit/Content/RightPanelScroll/RightColumn/EventsPanel/Events

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
var _left_trail_debug := {}
var _right_trail_debug := {}
var _last_flow_events := {}
var _event_counts: Dictionary = {}
var _last_event_payloads: Dictionary = {}
var _last_event_timestamps_ms: Dictionary = {}
var _last_console_snapshot := ""

func _enter_tree() -> void:
	if startup_mode != StartupMode.GODOT_ONLY_DEBUG:
		return
	var auto_start_node := get_node_or_null("AutoStartManager")
	if auto_start_node != null:
		remove_child(auto_start_node)
		auto_start_node.queue_free()

func _ready() -> void:
	title_label.text = scene_title
	notes_label.text = scene_notes
	for label_variant: Variant in [live_status_label, quick_stats_label, summary_label, signal_status_label, metrics_label, events_label]:
		if label_variant is RichTextLabel:
			label_variant.bbcode_enabled = false
	if live_status_label:
		live_status_label.scroll_active = false
	_left_trail_debug = _make_trail_debug_state("left")
	_right_trail_debug = _make_trail_debug_state("right")
	_reset_last_flow_events()
	_reset_event_tracking()
	_update_status("Initializing...", Color.WHITE)
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		_server_ready = true
		_update_status("Godot-only debug mode active", Color.GREEN)
	else:
		_setup_auto_start()
	_refresh_debug_panels()

func _setup_auto_start() -> void:
	auto_start_manager = get_node_or_null("AutoStartManager")
	if auto_start_manager == null:
		push_error("[ProvingHarness] AutoStartManager node not found in scene")
		_update_status("AutoStartManager missing", Color.RED)
		return

	auto_start_manager.camera_source_override = _get_scene_camera_source_override()

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

	if _frame_count % 30 == 0:
		_emit_console_snapshot_if_changed()

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

	if startup_mode == StartupMode.PREVIEW_ONLY_DEBUG:
		_server_ready = true
		_update_status("Preview-only debug mode active", Color.GREEN)
		if landmark_drawer:
			landmark_drawer.clear_landmarks()
		if trail_drawer:
			trail_drawer.clear_trails()
		return

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

	provider = MediaPipeProviderScript.new()
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
	var config := MediaPipeConfigScript.new()
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
	var left_wrist := _resolve_trail_hand_point(landmarks, LEFT_WRIST_ID, [LEFT_INDEX_ID, LEFT_PINKY_ID, LEFT_THUMB_ID])
	var right_wrist := _resolve_trail_hand_point(landmarks, RIGHT_WRIST_ID, [RIGHT_INDEX_ID, RIGHT_PINKY_ID, RIGHT_THUMB_ID])
	_append_trail_point(_left_trail, left_wrist, timestamp_ms, _left_trail_debug)
	_append_trail_point(_right_trail, right_wrist, timestamp_ms, _right_trail_debug)
	_prune_trail(_left_trail, timestamp_ms)
	_prune_trail(_right_trail, timestamp_ms)
	_update_trail_debug_state(_left_trail, _left_trail_debug, timestamp_ms)
	_update_trail_debug_state(_right_trail, _right_trail_debug, timestamp_ms)
	if show_trails and trail_drawer:
		trail_drawer.update_trails(_left_trail, _right_trail)
	elif trail_drawer:
		trail_drawer.clear_trails()

func _append_trail_point(trail: Array, landmark: Dictionary, timestamp_ms: int, debug_state: Dictionary) -> void:
	debug_state["frame_samples"] = int(debug_state.get("frame_samples", 0)) + 1
	if landmark.is_empty():
		_note_trail_debug_skip(debug_state, "missing")
		return
	var visibility := float(landmark.get("v", 0.0))
	var trail_visibility_threshold := _trail_visibility_threshold()
	if visibility < trail_visibility_threshold:
		_note_trail_debug_skip(debug_state, "low_visibility")
		debug_state["last_visibility"] = visibility
		return
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	debug_state["last_visibility"] = visibility
	debug_state["last_point"] = point
	if not _is_normalized_point_in_bounds(point):
		trail.clear()
		debug_state["out_of_bounds_clears"] = int(debug_state.get("out_of_bounds_clears", 0)) + 1
		debug_state["last_action"] = "clear_oob"
		return
	var jump_distance := _trail_jump_distance(trail, point)
	debug_state["last_jump_distance"] = jump_distance
	if jump_distance > MAX_TRAIL_FRAME_JUMP:
		_append_trail_break(trail, timestamp_ms)
		debug_state["continuity_breaks"] = int(debug_state.get("continuity_breaks", 0)) + 1
		debug_state["last_action"] = "break_reseed"
	else:
		debug_state["last_action"] = "append"
	if _trail_needs_reseed(trail):
		debug_state["reseeds"] = int(debug_state.get("reseeds", 0)) + 1
		if debug_state["last_action"] == "append":
			debug_state["last_action"] = "seed"
	trail.append(_make_trail_point(point, visibility, timestamp_ms))
	debug_state["appends"] = int(debug_state.get("appends", 0)) + 1
	while trail.size() > MAX_TRAIL_POINTS:
		trail.remove_at(0)

func _resolve_trail_hand_point(landmarks: Array, wrist_id: int, fallback_ids: Array[int]) -> Dictionary:
	var wrist := _find_landmark(landmarks, wrist_id)
	var trail_visibility_threshold := _trail_visibility_threshold()
	if _trail_landmark_is_directly_usable(wrist, trail_visibility_threshold):
		return wrist

	var candidates: Array[Dictionary] = []
	if _trail_landmark_is_candidate(wrist):
		candidates.append(wrist)
	for landmark_id: int in fallback_ids:
		var candidate := _find_landmark(landmarks, landmark_id)
		if _trail_landmark_is_candidate(candidate):
			candidates.append(candidate)
	if candidates.is_empty():
		return wrist
	return _synthesize_trail_hand_point(candidates)

func _trail_visibility_threshold() -> float:
	return minf(overlay_visibility_threshold, TRAIL_VISIBILITY_THRESHOLD_FLOOR)

func _trail_landmark_is_directly_usable(landmark: Dictionary, min_visibility: float) -> bool:
	if landmark.is_empty():
		return false
	if float(landmark.get("v", 0.0)) < min_visibility:
		return false
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	return _is_normalized_point_in_bounds(point)

func _trail_landmark_is_candidate(landmark: Dictionary) -> bool:
	if landmark.is_empty():
		return false
	if float(landmark.get("v", 0.0)) < _trail_visibility_threshold():
		return false
	var point := Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))
	return _is_point_within_trail_near_bounds(point)

func _synthesize_trail_hand_point(candidates: Array[Dictionary]) -> Dictionary:
	var total_weight := 0.0
	var blended_point := Vector2.ZERO
	var best_visibility := 0.0
	for candidate: Dictionary in candidates:
		var visibility := float(candidate.get("v", 0.0))
		var point := Vector2(float(candidate.get("x", 0.0)), float(candidate.get("y", 0.0)))
		var clamped_point := Vector2(clampf(point.x, 0.0, 1.0), clampf(point.y, 0.0, 1.0))
		blended_point += clamped_point * visibility
		total_weight += visibility
		best_visibility = maxf(best_visibility, visibility)
	if total_weight <= 0.000001:
		return {}
	return _make_trail_point(blended_point / total_weight, best_visibility, Time.get_ticks_msec())

func _is_point_within_trail_near_bounds(point: Vector2) -> bool:
	return point.x >= -TRAIL_NEAR_BOUNDS_MARGIN and point.x <= 1.0 + TRAIL_NEAR_BOUNDS_MARGIN and point.y >= -TRAIL_NEAR_BOUNDS_MARGIN and point.y <= 1.0 + TRAIL_NEAR_BOUNDS_MARGIN

func _trail_jump_distance(trail: Array, point: Vector2) -> float:
	if trail.is_empty():
		return 0.0
	for index: int in range(trail.size() - 1, -1, -1):
		var point_variant: Variant = trail[index]
		if not point_variant is Dictionary:
			continue
		var trail_point: Dictionary = point_variant
		if not trail_point.has("x") or not trail_point.has("y"):
			continue
		var previous := Vector2(float(trail_point.get("x", 0.0)), float(trail_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(previous):
			continue
		return previous.distance_to(point)
	return 0.0

func _append_trail_break(trail: Array, timestamp_ms: int) -> void:
	if trail.is_empty():
		return
	var last_point_variant: Variant = trail[trail.size() - 1]
	if last_point_variant is Dictionary:
		var last_point: Dictionary = last_point_variant
		var last_break_point := Vector2(float(last_point.get("x", 0.0)), float(last_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(last_break_point):
			return
	trail.append({
		"x": -1.0,
		"y": -1.0,
		"v": 0.0,
		"timestamp_ms": timestamp_ms,
	})

func _trail_needs_reseed(trail: Array) -> bool:
	if trail.is_empty():
		return true
	var last_point_variant: Variant = trail[trail.size() - 1]
	if not last_point_variant is Dictionary:
		return false
	var last_point: Dictionary = last_point_variant
	if not last_point.has("x") or not last_point.has("y"):
		return false
	return not _is_normalized_point_in_bounds(Vector2(float(last_point.get("x", 0.0)), float(last_point.get("y", 0.0))))

func _make_trail_debug_state(side: String) -> Dictionary:
	return {
		"side": side,
		"frame_samples": 0,
		"appends": 0,
		"reseeds": 0,
		"continuity_breaks": 0,
		"out_of_bounds_clears": 0,
		"missing_skips": 0,
		"low_visibility_skips": 0,
		"last_action": "idle",
		"last_jump_distance": 0.0,
		"last_visibility": 0.0,
		"last_live_points": 0,
		"last_break_markers": 0,
		"last_drawable_segments": 0,
		"last_segment_points": 0,
		"last_duration_ms": 0,
	}

func _note_trail_debug_skip(debug_state: Dictionary, reason: String) -> void:
	match reason:
		"missing":
			debug_state["missing_skips"] = int(debug_state.get("missing_skips", 0)) + 1
		"low_visibility":
			debug_state["low_visibility_skips"] = int(debug_state.get("low_visibility_skips", 0)) + 1
	debug_state["last_action"] = reason
	debug_state["last_jump_distance"] = 0.0

func _update_trail_debug_state(trail: Array, debug_state: Dictionary, timestamp_ms: int) -> void:
	var live_points := 0
	var break_markers := 0
	var drawable_segments := 0
	var current_segment_points := 0
	for point_variant: Variant in trail:
		if not point_variant is Dictionary:
			continue
		var trail_point: Dictionary = point_variant
		if not trail_point.has("x") or not trail_point.has("y"):
			continue
		var point := Vector2(float(trail_point.get("x", 0.0)), float(trail_point.get("y", 0.0)))
		if not _is_normalized_point_in_bounds(point):
			break_markers += 1
			if current_segment_points >= 2:
				drawable_segments += 1
			current_segment_points = 0
			continue
		live_points += 1
		current_segment_points += 1
	if current_segment_points >= 2:
		drawable_segments += 1
	debug_state["last_live_points"] = live_points
	debug_state["last_break_markers"] = break_markers
	debug_state["last_drawable_segments"] = drawable_segments
	debug_state["last_segment_points"] = current_segment_points
	debug_state["last_duration_ms"] = _trail_duration_ms(trail)
	debug_state["last_age_ms"] = timestamp_ms

func _format_trail_debug_line(debug_state: Dictionary) -> String:
	return "%s trail | pts=%d segs=%d tail=%d breaks=%d reseeds=%d clears=%d miss=%d low=%d jump=%s action=%s dur=%dms" % [
		String(debug_state.get("side", "?")),
		int(debug_state.get("last_live_points", 0)),
		int(debug_state.get("last_drawable_segments", 0)),
		int(debug_state.get("last_segment_points", 0)),
		int(debug_state.get("continuity_breaks", 0)),
		int(debug_state.get("reseeds", 0)),
		int(debug_state.get("out_of_bounds_clears", 0)),
		int(debug_state.get("missing_skips", 0)),
		int(debug_state.get("low_visibility_skips", 0)),
		_fmt_float(debug_state.get("last_jump_distance", 0.0)),
		String(debug_state.get("last_action", "idle")),
		int(debug_state.get("last_duration_ms", 0)),
	]

func _make_trail_point(point: Vector2, visibility: float, timestamp_ms: int) -> Dictionary:
	return {
		"x": point.x,
		"y": point.y,
		"v": visibility,
		"timestamp_ms": timestamp_ms,
	}

func _is_normalized_point_in_bounds(point: Vector2) -> bool:
	return point.x >= 0.0 and point.x <= 1.0 and point.y >= 0.0 and point.y <= 1.0

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
	_left_trail.clear()
	_right_trail.clear()
	if landmark_drawer:
		landmark_drawer.clear_landmarks()
	if trail_drawer:
		trail_drawer.clear_trails()

func _on_tracking_restored() -> void:
	_update_status("Tracking restored", Color.GREEN)
	_record_event("tracking_restored", {})

func _start_camera_feed() -> void:
	camera_view = MediaPipeCameraViewScript.new()
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
	live_status_label.text = _build_live_status_text()
	quick_stats_label.text = _build_quick_stats_text()
	summary_label.text = _build_summary_text()
	signal_status_label.text = _build_signal_text()
	metrics_label.text = _build_metrics_text()
	events_label.text = _build_events_text()

func _build_live_status_text() -> String:
	var state: Dictionary = _latest_state
	var tracking_state := _tracking_status_text(state)
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var last_event_name := _latest_event_name()
	var last_event_age := _last_seen_text(last_event_name) if last_event_name != "" else "never"
	return "Live | mode=%s srv=%s cam=%s src=%s track=%s poses=%d last=%s %s" % [
		_get_startup_mode_label(),
		_server_status_text(),
		_camera_status_text("on", "off"),
		_camera_source_compact_text(),
		tracking_state,
		pose_count,
		(last_event_name if last_event_name != "" else "none"),
		last_event_age,
	]

func _build_quick_stats_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var confidences: Dictionary = metrics.get("confidences", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	var pose_count := int(provider.get_num_poses()) if provider != null else 0
	var visible_landmarks := int((state.get("landmarks_by_id", {}) as Dictionary).size())
	var lines := [
		"Quick stats",
		"==========",
		"Mode: %s" % _mode_name(),
		"Startup: %s" % _get_startup_mode_label(),
		"Server: %s" % _server_status_text(),
		"Camera: %s" % _camera_status_text("streaming", "offline"),
		"Source: %s" % _camera_source_summary_text(),
		"Tracking: %s" % _tracking_status_text(state),
		"Poses: %d" % pose_count,
		"Visible landmarks: %d" % visible_landmarks,
		"Head confidence: %s" % _fmt_float(confidences.get("head", 0.0)),
		"L hand confidence: %s" % _fmt_float(confidences.get("left_hand", 0.0)),
		"R hand confidence: %s" % _fmt_float(confidences.get("right_hand", 0.0)),
	]
	if harness_mode == HarnessMode.BOXING:
		var armed_count := 0
		for event_name: String in BOXING_ATTACK_EVENTS + BOXING_KNEE_EVENTS:
			if bool(ready_map.get(event_name, true)):
				armed_count += 1
		lines.append("Height state: %s" % String(measurements.get("height_state", &"unknown")))
		lines.append("Guard active: %s" % str(bool(gesture_states.get("guard", false))))
		lines.append("Attack gates armed: %d / %d" % [armed_count, BOXING_ATTACK_EVENTS.size() + BOXING_KNEE_EVENTS.size()])
		if trail_debug_logging:
			lines.append(_format_trail_debug_line(_left_trail_debug))
			lines.append(_format_trail_debug_line(_right_trail_debug))
	else:
		var swing_ready := int(bool(ready_map.get("swing_left", true))) + int(bool(ready_map.get("swing_right", true)))
		var active_trails := int(bool(gesture_states.get("trail_left", false))) + int(bool(gesture_states.get("trail_right", false)))
		lines.append("Swing gates armed: %d / 2" % swing_ready)
		lines.append("Active trails: %d / 2" % active_trails)
		lines.append("Flow candidate L: %s / %s" % [_fmt_flow_candidate(left_flow), _fmt_flow_direction_candidate(left_flow)])
		lines.append("Flow candidate R: %s / %s" % [_fmt_flow_candidate(right_flow), _fmt_flow_direction_candidate(right_flow)])
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
		"Startup: %s" % _get_startup_mode_label(),
		"Video source: %s" % _camera_source_summary_text(),
		"Tracking state: %s" % _tracking_status_text(state),
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
		if trail_debug_logging:
			lines.append("")
			lines.append("Trail continuity")
			lines.append("----------------")
			lines.append(_format_trail_debug_line(_left_trail_debug))
			lines.append(_format_trail_debug_line(_right_trail_debug))
	else:
		var gesture_debug: Dictionary = state.get("gesture_debug", {})
		var ready_map: Dictionary = gesture_debug.get("ready", {})
		var flow_debug: Dictionary = gesture_debug.get("flow", {})
		var left_flow: Dictionary = flow_debug.get("left", {})
		var right_flow: Dictionary = flow_debug.get("right", {})
		lines.append("")
		lines.append("Flow event summary")
		lines.append("------------------")
		for key: String in ["swing_left", "swing_right", "trail_left", "trail_right"]:
			lines.append("%s: %s" % [key, _describe_last_flow_event(key)])
		lines.append("swing_ready L/R=%s / %s" % [str(bool(ready_map.get("swing_left", true))), str(bool(ready_map.get("swing_right", true)))])
		lines.append("trail_active L/R=%s / %s" % [str(bool(gesture_states.get("trail_left", false))), str(bool(gesture_states.get("trail_right", false)))])
		lines.append("placement vs direction L=%s / %s" % [_fmt_flow_candidate(left_flow), _fmt_flow_direction_candidate(left_flow)])
		lines.append("placement vs direction R=%s / %s" % [_fmt_flow_candidate(right_flow), _fmt_flow_direction_candidate(right_flow)])
		lines.append("Mirrored-hand sanity")
		lines.append("-------------------")
		lines.append(_format_flow_sanity_line("left", left_flow))
		lines.append(_format_flow_sanity_line("right", right_flow))
		lines.append("Local continuity: L=%d pts (%dms), R=%d pts (%dms)" % [_left_trail.size(), _trail_duration_ms(_left_trail), _right_trail.size(), _trail_duration_ms(_right_trail)])
	return "\n".join(lines)

func _build_signal_text() -> String:
	if harness_mode == HarnessMode.BOXING:
		return _build_boxing_signal_text()
	return _build_flow_signal_text()

func _build_boxing_signal_text() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var guard_active := bool(gesture_states.get("guard", false))
	var lines := [
		"Boxing signal board",
		"===================",
		"Persistent status/counters for the supported Boxing surface.",
		"guard suppression: %s" % ("ON" if guard_active else "OFF"),
		"",
		"Punch / hook / uppercut families",
		"-----------------------------",
	]
	for event_name: String in BOXING_ATTACK_EVENTS:
		lines.append(_format_attack_signal_row(event_name, ready_map, guard_active))
	lines.append("")
	lines.append("Guard + body-state transitions")
	lines.append("-----------------------------")
	for row_variant: Variant in BOXING_STATE_ROWS:
		var row: Dictionary = row_variant
		lines.append(_format_state_signal_row(String(row.get("label", "")), String(row.get("state", "")), String(row.get("start", "")), String(row.get("end", "")), gesture_states))
	lines.append("")
	lines.append("Knees / leg lifts")
	lines.append("-----------------")
	for event_name: String in BOXING_KNEE_EVENTS:
		lines.append(_format_attack_signal_row(event_name, ready_map, false))
	lines.append(_format_state_signal_row("leg_lift_left", "leg_lift_left", "leg_lift_left_start", "leg_lift_left_end", gesture_states))
	lines.append(_format_state_signal_row("leg_lift_right", "leg_lift_right", "leg_lift_right_start", "leg_lift_right_end", gesture_states))
	lines.append("")
	lines.append("Current detector inputs")
	lines.append("----------------------")
	lines.append("L extension=%s  elbow=%s°" % [_fmt_float(measurements.get("left_arm_extension", 0.0)), _fmt_float(measurements.get("left_elbow_bend_deg", 0.0))])
	lines.append("R extension=%s  elbow=%s°" % [_fmt_float(measurements.get("right_arm_extension", 0.0)), _fmt_float(measurements.get("right_elbow_bend_deg", 0.0))])
	lines.append("squat depth=%s  head drop=%s" % [_fmt_float(measurements.get("squat_depth", 0.0)), _fmt_float(measurements.get("head_drop_ratio", 0.0))])
	lines.append("lateral body/head/hip=%s / %s / %s" % [_fmt_float(measurements.get("lateral_offset", 0.0)), _fmt_float(measurements.get("head_lateral_offset", 0.0)), _fmt_float(measurements.get("hip_lateral_offset", 0.0))])
	lines.append("L knee/foot rise=%s / %s" % [_fmt_float(measurements.get("left_knee_rise", 0.0)), _fmt_float(measurements.get("left_foot_rise", 0.0))])
	lines.append("R knee/foot rise=%s / %s" % [_fmt_float(measurements.get("right_knee_rise", 0.0)), _fmt_float(measurements.get("right_foot_rise", 0.0))])
	return "\n".join(lines)

func _build_flow_signal_text() -> String:
	var state: Dictionary = _latest_state
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var gesture_debug: Dictionary = state.get("gesture_debug", {})
	var ready_map: Dictionary = gesture_debug.get("ready", {})
	var flow_debug: Dictionary = gesture_debug.get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	var lines := [
		"Flow signal board",
		"=================",
		"Persistent status/counters for swings, trails, readiness, and candidate truth.",
		"",
		"Left hand surface",
		"-----------------",
		_format_flow_event_row("swing_left", left_flow, ready_map, false),
		_format_flow_event_row("trail_left", left_flow, ready_map, bool(gesture_states.get("trail_left", false))),
		_format_flow_candidate_row("left", left_flow),
		"",
		"Right hand surface",
		"------------------",
		_format_flow_event_row("swing_right", right_flow, ready_map, false),
		_format_flow_event_row("trail_right", right_flow, ready_map, bool(gesture_states.get("trail_right", false))),
		_format_flow_candidate_row("right", right_flow),
	]
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
		var gesture_debug: Dictionary = state.get("gesture_debug", {})
		var flow_debug: Dictionary = gesture_debug.get("flow", {})
		var left_flow: Dictionary = flow_debug.get("left", {})
		var right_flow: Dictionary = flow_debug.get("right", {})
		lines.append("")
		lines.append("Flow / continuity readouts")
		lines.append("-------------------------")
		lines.append("Left hand")
		lines.append(_format_flow_analysis_line("swing window", left_flow.get("swing_analysis", {})))
		lines.append(_format_flow_analysis_line("trail window", left_flow.get("trail_analysis", {})))
		lines.append("latest pos=%s conf=%s avg_x=%s offset=%s" % [_fmt_vec2(left_flow.get("latest_position", Vector2.ZERO)), _fmt_float(left_flow.get("latest_confidence", 0.0)), _fmt_float(left_flow.get("avg_x", 0.0)), _fmt_float(left_flow.get("center_offset_ratio", 0.0))])
		lines.append("vel=%s dir=%s" % [_fmt_vec3(velocities.get("left_hand", Vector3.ZERO)), _fmt_vec2(directions.get("left_hand", Vector2.ZERO))])
		lines.append("")
		lines.append("Right hand")
		lines.append(_format_flow_analysis_line("swing window", right_flow.get("swing_analysis", {})))
		lines.append(_format_flow_analysis_line("trail window", right_flow.get("trail_analysis", {})))
		lines.append("latest pos=%s conf=%s avg_x=%s offset=%s" % [_fmt_vec2(right_flow.get("latest_position", Vector2.ZERO)), _fmt_float(right_flow.get("latest_confidence", 0.0)), _fmt_float(right_flow.get("avg_x", 0.0)), _fmt_float(right_flow.get("center_offset_ratio", 0.0))])
		lines.append("vel=%s dir=%s" % [_fmt_vec3(velocities.get("right_hand", Vector3.ZERO)), _fmt_vec2(directions.get("right_hand", Vector2.ZERO))])
		lines.append("")
		lines.append("Placement is detector-emitted; local trail durations remain on-screen for continuity sanity only.")
	return "\n".join(lines)

func _format_flow_event_row(event_name: String, hand_debug: Dictionary, ready_map: Dictionary, active: bool) -> String:
	var event_kind := "swing" if event_name.begins_with("swing_") else "trail"
	var analysis: Dictionary = hand_debug.get("swing_analysis", {}) if event_kind == "swing" else hand_debug.get("trail_analysis", {})
	var meta: Dictionary = hand_debug.get("swing_meta", {}) if event_kind == "swing" else hand_debug.get("trail_meta", {})
	var status := "ACTIVE" if event_kind == "trail" and active else ("READY" if bool(ready_map.get(event_name, true)) else "RESET")
	if event_kind == "trail" and not active:
		status = "IDLE"
	return "%s  status=%s  count=%d  last=%s  emitted=%s/%s  cand=%s/%s  dur=%dms  arc=%s  net=%s  cons=%s  lane=%s  conf=%s" % [
		event_name,
		status,
		_event_count(event_name),
		_last_seen_text(event_name),
		String(meta.get("placement", &"-")),
		String(meta.get("direction", &"-")),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
		int(analysis.get("duration_ms", 0)),
		_fmt_float(analysis.get("arc_length", 0.0)),
		_fmt_float(analysis.get("net_distance", 0.0)),
		_fmt_float(analysis.get("directional_consistency", 0.0)),
		_fmt_float(analysis.get("lane_spread", 0.0)),
		_fmt_float(analysis.get("avg_confidence", 0.0)),
	]

func _format_flow_candidate_row(side: String, hand_debug: Dictionary) -> String:
	return "%s hand  history=%d pts / %dms  latest=%s  avg_x=%s  center_offset=%s  placement=%s  direction=%s" % [
		side,
		int(hand_debug.get("history_points", 0)),
		int(hand_debug.get("history_duration_ms", 0)),
		_fmt_vec2(hand_debug.get("latest_position", Vector2.ZERO)),
		_fmt_float(hand_debug.get("avg_x", 0.0)),
		_fmt_float(hand_debug.get("center_offset_ratio", 0.0)),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
	]

func _format_flow_analysis_line(label: String, analysis_variant: Variant) -> String:
	var analysis: Dictionary = analysis_variant if analysis_variant is Dictionary else {}
	if analysis.is_empty():
		return "%s: no candidate yet" % label
	return "%s: samples=%d dur=%dms arc=%s net=%s cons=%s lane=%s conf=%s placement=%s direction=%s" % [
		label,
		int(analysis.get("sample_count", 0)),
		int(analysis.get("duration_ms", 0)),
		_fmt_float(analysis.get("arc_length", 0.0)),
		_fmt_float(analysis.get("net_distance", 0.0)),
		_fmt_float(analysis.get("directional_consistency", 0.0)),
		_fmt_float(analysis.get("lane_spread", 0.0)),
		_fmt_float(analysis.get("avg_confidence", 0.0)),
		String(analysis.get("placement", &"-")),
		String(analysis.get("direction", &"-")),
	]

func _format_flow_sanity_line(side: String, hand_debug: Dictionary) -> String:
	return "%s hand: latest=%s avg_x=%s offset=%s placement=%s direction=%s" % [
		side,
		_fmt_vec2(hand_debug.get("latest_position", Vector2.ZERO)),
		_fmt_float(hand_debug.get("avg_x", 0.0)),
		_fmt_float(hand_debug.get("center_offset_ratio", 0.0)),
		_fmt_flow_candidate(hand_debug),
		_fmt_flow_direction_candidate(hand_debug),
	]

func _fmt_flow_candidate(hand_debug: Dictionary) -> String:
	var candidate := String(hand_debug.get("placement_candidate", StringName()))
	return candidate if candidate != "" else "-"

func _fmt_flow_direction_candidate(hand_debug: Dictionary) -> String:
	var candidate := String(hand_debug.get("direction_candidate", StringName()))
	return candidate if candidate != "" else "-"

func _build_events_text() -> String:
	var lines := ["Live events", "==========="]
	if _event_lines.is_empty():
		lines.append("(waiting for detector activity)")
	else:
		lines.append_array(_event_lines)
	return "\n".join(lines)

func _record_event(event_name: String, payload: Dictionary) -> void:
	var timestamp := Time.get_time_string_from_system()
	var timestamp_ms := Time.get_ticks_msec()
	_event_counts[event_name] = int(_event_counts.get(event_name, 0)) + 1
	_last_event_payloads[event_name] = payload.duplicate(true)
	_last_event_timestamps_ms[event_name] = timestamp_ms
	var line := "%s  %s%s" % [timestamp, event_name, _format_event_payload(payload)]
	_event_lines.push_front(line)
	while _event_lines.size() > MAX_EVENT_LINES:
		_event_lines.pop_back()
	print("[ProvingHarness][%s] %s%s" % [_mode_name(), event_name, _format_event_payload(payload)])
	_refresh_debug_panels()
	_emit_console_snapshot_if_changed(true)

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

func _reset_event_tracking() -> void:
	_event_lines = []
	_event_counts = {}
	_last_event_payloads = {}
	_last_event_timestamps_ms = {}
	for event_name: String in BOXING_EVENT_ORDER + FLOW_EVENT_ORDER + ["provider_started", "tracking_lost", "tracking_restored", "camera_stream_failed", "server_failed"]:
		_event_counts[event_name] = 0

func _format_attack_signal_row(event_name: String, ready_map: Dictionary, guard_suppressed: bool) -> String:
	var status := "READY" if bool(ready_map.get(event_name, true)) else "RESET"
	if guard_suppressed and BOXING_ATTACK_EVENTS.has(event_name):
		status = "SUPPRESSED"
	var power_text := ""
	var payload: Dictionary = _last_event_payloads.get(event_name, {})
	if payload.has("power"):
		power_text = " power=%s" % _fmt_float(payload.get("power", 0.0))
	return "%s  status=%s  count=%d  last=%s%s" % [event_name, status, _event_count(event_name), _last_seen_text(event_name), power_text]

func _format_state_signal_row(label: String, state_name: String, start_event: String, end_event: String, gesture_states: Dictionary) -> String:
	var active := bool(gesture_states.get(state_name, false))
	return "%s  active=%s  start/end=%d/%d  last=%s" % [label, str(active), _event_count(start_event), _event_count(end_event), _last_transition_text(start_event, end_event)]

func _event_count(event_name: String) -> int:
	return int(_event_counts.get(event_name, 0))

func _last_seen_text(event_name: String) -> String:
	var timestamp_ms := int(_last_event_timestamps_ms.get(event_name, 0))
	if timestamp_ms <= 0:
		return "never"
	return _fmt_age_ms(Time.get_ticks_msec() - timestamp_ms)

func _last_transition_text(start_event: String, end_event: String) -> String:
	var start_ts := int(_last_event_timestamps_ms.get(start_event, 0))
	var end_ts := int(_last_event_timestamps_ms.get(end_event, 0))
	if start_ts <= 0 and end_ts <= 0:
		return "never"
	if start_ts >= end_ts:
		return "%s %s ago" % [start_event, _fmt_age_ms(Time.get_ticks_msec() - start_ts)]
	return "%s %s ago" % [end_event, _fmt_age_ms(Time.get_ticks_msec() - end_ts)]

func _fmt_age_ms(age_ms: int) -> String:
	if age_ms < 1000:
		return "%dms" % age_ms
	return "%.1fs" % (float(age_ms) / 1000.0)

func _latest_event_name() -> String:
	var latest_name := ""
	var latest_timestamp := -1
	for event_name_variant: Variant in _last_event_timestamps_ms.keys():
		var event_name := String(event_name_variant)
		var timestamp_ms := int(_last_event_timestamps_ms.get(event_name_variant, 0))
		if timestamp_ms > latest_timestamp:
			latest_timestamp = timestamp_ms
			latest_name = event_name
	return latest_name

func _build_console_snapshot() -> String:
	var state: Dictionary = _latest_state
	var metrics: Dictionary = state.get("metrics", {})
	var measurements: Dictionary = metrics.get("measurements", {})
	var gesture_states: Dictionary = state.get("gesture_states", {})
	var base := "[ProvingHarness][%s] mode=%s status=%s server=%s camera=%s source=%s poses=%d" % [
		_mode_name(),
		_get_startup_mode_label(),
		_tracking_status_text(state),
		_server_status_text(),
		_camera_status_text("streaming", "offline"),
		_camera_source_compact_text(),
		(int(provider.get_num_poses()) if provider != null else 0),
	]
	if harness_mode == HarnessMode.BOXING:
		if trail_debug_logging:
			return "%s guard=%s squat=%s height=%s latest=%s | %s | %s" % [
				base,
				str(bool(gesture_states.get("guard", false))),
				str(bool(gesture_states.get("squat", false))),
				String(measurements.get("height_state", &"unknown")),
				(_latest_event_name() if _latest_event_name() != "" else "none"),
				_format_trail_debug_line(_left_trail_debug),
				_format_trail_debug_line(_right_trail_debug),
			]
		return "%s guard=%s squat=%s height=%s latest=%s" % [
			base,
			str(bool(gesture_states.get("guard", false))),
			str(bool(gesture_states.get("squat", false))),
			String(measurements.get("height_state", &"unknown")),
			(_latest_event_name() if _latest_event_name() != "" else "none"),
		]
	var flow_debug: Dictionary = (state.get("gesture_debug", {}) as Dictionary).get("flow", {})
	var left_flow: Dictionary = flow_debug.get("left", {})
	var right_flow: Dictionary = flow_debug.get("right", {})
	return "%s trail_left=%s trail_right=%s cand_left=%s/%s cand_right=%s/%s latest=%s" % [
		base,
		str(bool(gesture_states.get("trail_left", false))),
		str(bool(gesture_states.get("trail_right", false))),
		_fmt_flow_candidate(left_flow),
		_fmt_flow_direction_candidate(left_flow),
		_fmt_flow_candidate(right_flow),
		_fmt_flow_direction_candidate(right_flow),
		(_latest_event_name() if _latest_event_name() != "" else "none"),
	]

func _emit_console_snapshot_if_changed(force: bool = false) -> void:
	var snapshot := _build_console_snapshot()
	if not force and snapshot == _last_console_snapshot:
		return
	_last_console_snapshot = snapshot
	print(snapshot)

func _get_scene_camera_source_override() -> String:
	return prerecorded_video_source.strip_edges()

func _get_effective_camera_source() -> String:
	if auto_start_manager != null and auto_start_manager.has_method("get_active_camera_source"):
		return String(auto_start_manager.get_active_camera_source())
	var explicit_override := _get_scene_camera_source_override()
	if not explicit_override.is_empty():
		return ProjectSettings.globalize_path(explicit_override) if not explicit_override.is_valid_int() else explicit_override
	var env_override := OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE").strip_edges()
	if not env_override.is_empty():
		return ProjectSettings.globalize_path(env_override) if not env_override.is_valid_int() else env_override
	return "0"

func _camera_source_summary_text() -> String:
	var source := _get_effective_camera_source()
	if source == "0":
		return "live camera (default)"
	var scene_override := _get_scene_camera_source_override()
	if not scene_override.is_empty():
		return "scene override: %s" % scene_override
	var env_override := OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE").strip_edges()
	if not env_override.is_empty():
		return "environment override: %s" % env_override
	return source

func _camera_source_compact_text() -> String:
	var source := _get_effective_camera_source()
	if source == "0":
		return "live"
	return source.get_file() if source.get_file() != "" else source

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

func _get_startup_mode_label() -> String:
	match startup_mode:
		StartupMode.PREVIEW_ONLY_DEBUG:
			return "Preview-only debug"
		StartupMode.GODOT_ONLY_DEBUG:
			return "Godot-only debug"
		_:
			return "Tracking"

func _server_status_text() -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	return "ready" if _server_ready else "starting"

func _camera_status_text(active_label: String, inactive_label: String) -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	return active_label if camera_view and camera_view.is_streaming() else inactive_label

func _tracking_status_text(state: Dictionary) -> String:
	if startup_mode == StartupMode.GODOT_ONLY_DEBUG:
		return "disabled"
	if startup_mode == StartupMode.PREVIEW_ONLY_DEBUG and provider == null:
		return "preview_only"
	return String(state.get("tracking_state", &"lost"))

func _update_status(text: String, color: Color) -> void:
	var source_suffix := " | src=%s" % _camera_source_compact_text()
	status_label.text = text + source_suffix
	status_label.modulate = color
	print("[ProvingHarness][%s] %s%s" % [_mode_name(), text, source_suffix])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[ProvingHarness][%s] Window close request" % _mode_name())
		_stop_everything()
		get_tree().quit()
	elif what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		print("[ProvingHarness][%s] Scene teardown notification=%d" % [_mode_name(), what])
		_stop_everything()

func _stop_everything() -> void:
	print("[ProvingHarness][%s] Stopping harness resources" % _mode_name())
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
