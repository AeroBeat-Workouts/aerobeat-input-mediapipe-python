extends SceneTree

const DEFAULT_CAPTURE_DELAY_MS := 5000
const DEFAULT_VIEWPORT_SIZE := Vector2i(1280, 720)

var _scene_path := ""
var _fixture_path := ""
var _output_dir := ""
var _capture_delay_ms := DEFAULT_CAPTURE_DELAY_MS
var _scene_root: Control = null
var _started_at_ms := 0
var _captured := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: <scene_path> <fixture_path> <output_dir> [capture_delay_ms]")
		quit(2)
		return

	_scene_path = args[0]
	_fixture_path = args[1]
	_output_dir = args[2]
	if args.size() >= 4 and String(args[3]).is_valid_int():
		_capture_delay_ms = max(int(args[3]), 1000)

	DirAccess.make_dir_recursive_absolute(_output_dir)
	root.size = DEFAULT_VIEWPORT_SIZE
	_started_at_ms = Time.get_ticks_msec()

	var packed: PackedScene = load(_scene_path)
	if packed == null:
		push_error("failed to load scene: %s" % _scene_path)
		quit(3)
		return

	var node := packed.instantiate()
	if not node is Control:
		push_error("scene root is not a Control: %s" % _scene_path)
		quit(4)
		return

	_scene_root = node
	_force_fixture_runtime_settings(_scene_root)
	root.add_child(_scene_root)
	call_deferred("_run_capture_sequence")

func _force_fixture_runtime_settings(node: Node) -> void:
	for property_variant: Variant in node.get_property_list():
		var property_info: Dictionary = property_variant if property_variant is Dictionary else {}
		var property_name := String(property_info.get("name", ""))
		if property_name == "startup_mode":
			node.set("startup_mode", 0)
		elif property_name == "prerecorded_video_source":
			var video_source := OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE")
			if not video_source.is_empty():
				node.set("prerecorded_video_source", video_source)

func _run_capture_sequence() -> void:
	if _captured or _scene_root == null:
		quit(5)
		return
	await create_timer(float(_capture_delay_ms) / 1000.0).timeout
	if _captured or _scene_root == null:
		quit(5)
		return
	var elapsed_ms := Time.get_ticks_msec() - _started_at_ms
	_captured = true
	await process_frame
	await process_frame
	await _capture_outputs(elapsed_ms)
	quit(0)

func _capture_outputs(elapsed_ms: int) -> void:
	var screenshot_path := _output_dir.path_join("proving.png")
	var report_json_path := _output_dir.path_join("report.json")
	var report_md_path := _output_dir.path_join("report.md")

	var root_texture := root.get_texture()
	if root_texture != null:
		var image := root_texture.get_image()
		if image != null:
			var save_err := image.save_png(screenshot_path)
			if save_err != OK:
				push_warning("failed to save screenshot to %s (err=%d)" % [screenshot_path, save_err])
		else:
			push_warning("failed to capture screenshot image for %s" % screenshot_path)
	else:
		push_warning("failed to capture screenshot texture for %s" % screenshot_path)

	var harness_report := _collect_harness_report(elapsed_ms, screenshot_path)
	_write_text_file(report_json_path, JSON.stringify(harness_report, "\t"))
	_write_text_file(report_md_path, _build_markdown_report(harness_report))
	print("[FixtureCapture] screenshot=%s report_json=%s report_md=%s" % [screenshot_path, report_json_path, report_md_path])

func _collect_harness_report(elapsed_ms: int, screenshot_path: String) -> Dictionary:
	var report := {
		"fixture_path": ProjectSettings.globalize_path(_fixture_path),
		"video_path": OS.get_environment("AEROBEAT_MEDIAPIPE_CAMERA_SOURCE"),
		"scene_path": _scene_path,
		"captured_at": Time.get_datetime_string_from_system(true, true),
		"elapsed_ms": elapsed_ms,
		"screenshot_path": screenshot_path,
		"viewport_size": {"width": root.size.x, "height": root.size.y},
		"status": {},
		"surfaces": {},
		"fixture_capture": {},
	}

	var status_label := _scene_root.get_node_or_null("Margin/VSplit/Header/StatusLabel") as Label
	var live_status_label := _scene_root.get_node_or_null("Margin/VSplit/Header/LiveStatusLabel") as RichTextLabel
	var title_label := _scene_root.find_child("TitleLabel", true, false) as Label
	var notes_label := _scene_root.get_node_or_null("Margin/VSplit/Header/NotesLabel") as Label
	var quick_stats_label := _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/QuickStatsPanel/QuickStats") as RichTextLabel
	var summary_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/SummaryPanel/Summary") as RichTextLabel
	var signal_status_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/SignalPanel/SignalStatus") as RichTextLabel
	var metrics_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/MetricsPanel/Metrics") as RichTextLabel
	var events_label := _scene_root.get_node_or_null("Margin/VSplit/Content/RightPanelScroll/RightColumn/EventsPanel/Events") as RichTextLabel
	var camera_display := _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraView") as TextureRect
	if camera_display == null:
		camera_display = _scene_root.get_node_or_null("Margin/VSplit/Content/LeftColumn/CameraPanel/CameraDisplay") as TextureRect
	var auto_start := _scene_root.get_node_or_null("AutoStartManager")
	var provider: Variant = _scene_root.get("provider") if _scene_root != null else null

	report["status"] = {
		"title": title_label.text if title_label else "",
		"status_label": status_label.text if status_label else "",
		"live_status": live_status_label.text if live_status_label else "",
		"notes": notes_label.text if notes_label else "",
		"camera_streaming": camera_display.visible if camera_display else false,
		"camera_has_texture": camera_display.texture != null if camera_display else false,
		"server_pid": int(auto_start.get("server_pid")) if auto_start != null else -1,
		"provider_present": provider != null,
	}

	report["surfaces"] = {
		"quick_stats": _node_text(quick_stats_label),
		"summary": _node_text(summary_label),
		"signal_status": _node_text(signal_status_label),
		"metrics": _node_text(metrics_label),
		"events": _node_text(events_label),
	}
	if _scene_root != null and _scene_root.has_method("get_fixture_capture_report"):
		report["fixture_capture"] = _scene_root.call("get_fixture_capture_report")
	return report

func _node_text(node: Node) -> String:
	if node == null:
		return ""
	if node is RichTextLabel:
		return (node as RichTextLabel).text
	if node is Label:
		return (node as Label).text
	return ""

func _write_text_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("failed to open output file: %s" % path)
		return
	file.store_string(content)
	file.close()

func _build_markdown_report(report: Dictionary) -> String:
	var status: Dictionary = report.get("status", {})
	var surfaces: Dictionary = report.get("surfaces", {})
	var lines := PackedStringArray([
		"# Proving Fixture Capture",
		"",
		"- Fixture: `%s`" % String(report.get("fixture_path", "")),
		"- Video: `%s`" % String(report.get("video_path", "")),
		"- Scene: `%s`" % String(report.get("scene_path", "")),
		"- Captured: `%s`" % String(report.get("captured_at", "")),
		"- Elapsed: `%dms`" % int(report.get("elapsed_ms", 0)),
		"- Screenshot: `%s`" % String(report.get("screenshot_path", "")),
		"",
		"## Status",
		"",
		"- Title: %s" % String(status.get("title", "")),
		"- Status label: %s" % String(status.get("status_label", "")),
		"- Live status: %s" % String(status.get("live_status", "")),
		"- Camera streaming: %s" % str(bool(status.get("camera_streaming", false))),
		"- Camera has texture: %s" % str(bool(status.get("camera_has_texture", false))),
		"- Server PID: %d" % int(status.get("server_pid", -1)),
		"- Provider present: %s" % str(bool(status.get("provider_present", false))),
		"",
	])

	for section_name in ["quick_stats", "summary", "signal_status", "metrics", "events"]:
		lines.append("## %s" % String(section_name).replace("_", " ").capitalize())
		lines.append("")
		lines.append("```text")
		lines.append(String(surfaces.get(section_name, "")))
		lines.append("```")
		lines.append("")

	return "\n".join(lines)
