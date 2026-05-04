extends "res://addons/aerobeat-input-core/src/interfaces/boxing_input.gd"
## Assembly-facing AeroInputProvider adapter for this addon.
##
## This addon entrypoint is for consuming projects that mount this repo under
## the live assembly addon alias `res://addons/aerobeat-input-mediapipe/`
## alongside `aerobeat-input-core`.
## The standalone repo testbed continues to exercise `src/providers/mediapipe_provider.gd`
## directly so this repo can still be worked on without hiding assembly wiring here.
##
## Current truthful scope:
## - boxing gameplay intent events plus first-pass Flow motion-family signals from conservative 2D-camera detectors
## - lifecycle + polling access for head/hands/feet positions
## - tracking state + confidence queries
## - shared detector substrate metrics for normalization and body-state estimation
## - estimated per-limb velocities from 2D landmark deltas
## - no haptics or 6DOF transform output yet

const PROVIDER_ID := "mediapipe_python"

signal swing_left(placement: StringName, direction: StringName)
signal swing_right(placement: StringName, direction: StringName)
signal trail_left(placement: StringName, direction: StringName)
signal trail_right(placement: StringName, direction: StringName)

var _provider = null
var _config = null
var _tracking_mode: TrackingMode = TrackingMode.MODE_2D
var _body_track_flags: int = BodyTrackFlags.ALL

func _ready() -> void:
	_ensure_provider()

func start(settings_json: String = "") -> bool:
	_ensure_provider()
	_apply_settings(settings_json)
	var success: bool = _provider.start()
	if success:
		started.emit()
	else:
		failed.emit("MediaPipe provider failed to start")
	return success

func stop() -> void:
	if _provider == null:
		return
	_provider.stop()
	stopped.emit()

func is_tracking() -> bool:
	return _provider != null and _provider.is_tracking()

func get_provider_id() -> String:
	return PROVIDER_ID

func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION, Capability.LOWER_BODY, Capability.VELOCITY:
			return true
		_:
			return false

func trigger_haptic(_side: int, _intensity: float, _duration_ms: int) -> void:
	# No haptics in the Python/camera implementation.
	pass

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_head_position(_to_provider_mode(mode)))

func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_left_hand_position(_to_provider_mode(mode)))

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_right_hand_position(_to_provider_mode(mode)))

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_left_foot_position(_to_provider_mode(mode)))

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	return _to_vector3(_provider.get_right_foot_position(_to_provider_mode(mode)))

func get_head_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"head") if _provider != null else Vector3.ZERO

func get_left_hand_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"left_hand") if _provider != null else Vector3.ZERO

func get_right_hand_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"right_hand") if _provider != null else Vector3.ZERO

func get_left_foot_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"left_foot") if _provider != null else Vector3.ZERO

func get_right_foot_velocity() -> Vector3:
	return _provider.get_landmark_velocity_for_body_part(&"right_foot") if _provider != null else Vector3.ZERO

func get_head_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_left_hand_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_right_hand_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_left_foot_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_right_foot_rotation() -> Quaternion:
	return Quaternion.IDENTITY

func get_tracking_confidence(body_part: StringName) -> float:
	if _provider == null:
		return 0.0
	return _provider.get_detector_state().get("metrics", {}).get("confidences", {}).get(String(body_part), 0.0)

func set_tracking_mode(mode: TrackingMode) -> void:
	_tracking_mode = mode
	if _provider != null:
		_provider.set_tracking_mode(_to_provider_mode(mode))

func set_body_track_flags(flags: int) -> void:
	_body_track_flags = flags

func _ensure_provider() -> void:
	if _provider != null:
		return
	var provider_script: GDScript = _load_local_script("providers/mediapipe_provider.gd")
	_provider = provider_script.new()
	_provider.name = "MediaPipeProvider"
	add_child(_provider)
	_provider.tracking_lost.connect(func() -> void:
		failed.emit("Tracking lost")
	)
	_connect_provider_signals()
	if _provider.config == null:
		_provider.config = _new_local_config()
	_config = _provider.config

func _connect_provider_signals() -> void:
	if _provider == null:
		return
	if not _provider.punch_left.is_connected(_on_provider_punch_left):
		_provider.punch_left.connect(_on_provider_punch_left)
	if not _provider.punch_right.is_connected(_on_provider_punch_right):
		_provider.punch_right.connect(_on_provider_punch_right)
	if not _provider.uppercut_left.is_connected(_on_provider_uppercut_left):
		_provider.uppercut_left.connect(_on_provider_uppercut_left)
	if not _provider.uppercut_right.is_connected(_on_provider_uppercut_right):
		_provider.uppercut_right.connect(_on_provider_uppercut_right)
	if not _provider.hook_left.is_connected(_on_provider_hook_left):
		_provider.hook_left.connect(_on_provider_hook_left)
	if not _provider.hook_right.is_connected(_on_provider_hook_right):
		_provider.hook_right.connect(_on_provider_hook_right)
	if _provider.has_signal("swing_left") and not _provider.swing_left.is_connected(_on_provider_swing_left):
		_provider.swing_left.connect(_on_provider_swing_left)
	if _provider.has_signal("swing_right") and not _provider.swing_right.is_connected(_on_provider_swing_right):
		_provider.swing_right.connect(_on_provider_swing_right)
	if _provider.has_signal("trail_left") and not _provider.trail_left.is_connected(_on_provider_trail_left):
		_provider.trail_left.connect(_on_provider_trail_left)
	if _provider.has_signal("trail_right") and not _provider.trail_right.is_connected(_on_provider_trail_right):
		_provider.trail_right.connect(_on_provider_trail_right)
	if not _provider.guard_start.is_connected(_on_provider_guard_start):
		_provider.guard_start.connect(_on_provider_guard_start)
	if not _provider.guard_end.is_connected(_on_provider_guard_end):
		_provider.guard_end.connect(_on_provider_guard_end)
	if not _provider.squat_start.is_connected(_on_provider_squat_start):
		_provider.squat_start.connect(_on_provider_squat_start)
	if not _provider.squat_end.is_connected(_on_provider_squat_end):
		_provider.squat_end.connect(_on_provider_squat_end)
	if not _provider.lean_left_start.is_connected(_on_provider_lean_left_start):
		_provider.lean_left_start.connect(_on_provider_lean_left_start)
	if not _provider.lean_left_end.is_connected(_on_provider_lean_left_end):
		_provider.lean_left_end.connect(_on_provider_lean_left_end)
	if not _provider.lean_right_start.is_connected(_on_provider_lean_right_start):
		_provider.lean_right_start.connect(_on_provider_lean_right_start)
	if not _provider.lean_right_end.is_connected(_on_provider_lean_right_end):
		_provider.lean_right_end.connect(_on_provider_lean_right_end)
	if not _provider.sidestep_left_start.is_connected(_on_provider_sidestep_left_start):
		_provider.sidestep_left_start.connect(_on_provider_sidestep_left_start)
	if not _provider.sidestep_left_end.is_connected(_on_provider_sidestep_left_end):
		_provider.sidestep_left_end.connect(_on_provider_sidestep_left_end)
	if not _provider.sidestep_right_start.is_connected(_on_provider_sidestep_right_start):
		_provider.sidestep_right_start.connect(_on_provider_sidestep_right_start)
	if not _provider.sidestep_right_end.is_connected(_on_provider_sidestep_right_end):
		_provider.sidestep_right_end.connect(_on_provider_sidestep_right_end)
	if not _provider.knee_left.is_connected(_on_provider_knee_left):
		_provider.knee_left.connect(_on_provider_knee_left)
	if not _provider.knee_right.is_connected(_on_provider_knee_right):
		_provider.knee_right.connect(_on_provider_knee_right)
	if not _provider.leg_lift_left_start.is_connected(_on_provider_leg_lift_left_start):
		_provider.leg_lift_left_start.connect(_on_provider_leg_lift_left_start)
	if not _provider.leg_lift_left_end.is_connected(_on_provider_leg_lift_left_end):
		_provider.leg_lift_left_end.connect(_on_provider_leg_lift_left_end)
	if not _provider.leg_lift_right_start.is_connected(_on_provider_leg_lift_right_start):
		_provider.leg_lift_right_start.connect(_on_provider_leg_lift_right_start)
	if not _provider.leg_lift_right_end.is_connected(_on_provider_leg_lift_right_end):
		_provider.leg_lift_right_end.connect(_on_provider_leg_lift_right_end)

func _apply_settings(settings_json: String) -> void:
	if settings_json.is_empty():
		return
	var parsed: Variant = JSON.parse_string(settings_json)
	if !(parsed is Dictionary):
		return
	var settings: Dictionary = parsed
	if _provider.config == null:
		_provider.config = _new_local_config()
	_config = _provider.config
	if settings.has("udp_port"):
		_config.udp_port = int(settings["udp_port"])
	if settings.has("min_visibility"):
		_config.min_visibility = float(settings["min_visibility"])
	if settings.has("tracking_confidence"):
		_config.tracking_confidence = float(settings["tracking_confidence"])
	if settings.has("flip_horizontal"):
		_config.flip_horizontal = bool(settings["flip_horizontal"])

func _load_local_script(relative_path: String) -> GDScript:
	var script_path := _resolve_local_path(relative_path)
	var script: Variant = load(script_path)
	if script == null:
		push_error("Failed to load MediaPipe addon script: %s" % script_path)
		return null
	return script

func _new_local_config() -> Variant:
	var config_script: GDScript = _load_local_script("config/mediapipe_config.gd")
	return config_script.new()

func _resolve_local_path(relative_path: String) -> String:
	return "%s/%s" % [get_script().resource_path.get_base_dir(), relative_path]

func _on_provider_punch_left(power: float) -> void:
	punch_left.emit(power)

func _on_provider_punch_right(power: float) -> void:
	punch_right.emit(power)

func _on_provider_uppercut_left(power: float) -> void:
	uppercut_left.emit(power)

func _on_provider_uppercut_right(power: float) -> void:
	uppercut_right.emit(power)

func _on_provider_hook_left(power: float) -> void:
	hook_left.emit(power)

func _on_provider_hook_right(power: float) -> void:
	hook_right.emit(power)

func _on_provider_swing_left(placement: StringName, direction: StringName) -> void:
	swing_left.emit(placement, direction)

func _on_provider_swing_right(placement: StringName, direction: StringName) -> void:
	swing_right.emit(placement, direction)

func _on_provider_trail_left(placement: StringName, direction: StringName) -> void:
	trail_left.emit(placement, direction)

func _on_provider_trail_right(placement: StringName, direction: StringName) -> void:
	trail_right.emit(placement, direction)

func _on_provider_guard_start() -> void:
	guard_start.emit()

func _on_provider_guard_end() -> void:
	guard_end.emit()

func _on_provider_squat_start() -> void:
	squat_start.emit()

func _on_provider_squat_end() -> void:
	squat_end.emit()

func _on_provider_lean_left_start() -> void:
	lean_left_start.emit()

func _on_provider_lean_left_end() -> void:
	lean_left_end.emit()

func _on_provider_lean_right_start() -> void:
	lean_right_start.emit()

func _on_provider_lean_right_end() -> void:
	lean_right_end.emit()

func _on_provider_sidestep_left_start() -> void:
	sidestep_left_start.emit()

func _on_provider_sidestep_left_end() -> void:
	sidestep_left_end.emit()

func _on_provider_sidestep_right_start() -> void:
	sidestep_right_start.emit()

func _on_provider_sidestep_right_end() -> void:
	sidestep_right_end.emit()

func _on_provider_knee_left(power: float) -> void:
	knee_left.emit(power)

func _on_provider_knee_right(power: float) -> void:
	knee_right.emit(power)

func _on_provider_leg_lift_left_start() -> void:
	leg_lift_left_start.emit()

func _on_provider_leg_lift_left_end() -> void:
	leg_lift_left_end.emit()

func _on_provider_leg_lift_right_start() -> void:
	leg_lift_right_start.emit()

func _on_provider_leg_lift_right_end() -> void:
	leg_lift_right_end.emit()

func _to_provider_mode(mode: TrackingMode) -> int:
	return 1 if mode == TrackingMode.MODE_3D else 0

func _to_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector2:
		return Vector3(value.x, value.y, 0.0)
	return Vector3.ZERO
