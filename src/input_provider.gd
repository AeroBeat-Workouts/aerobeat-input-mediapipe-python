extends "res://addons/aerobeat-core/src/interfaces/input_provider.gd"
## Assembly-facing AeroInputProvider adapter for this addon.
##
## This addon entrypoint is for consuming projects that mount this repo under
## `res://addons/aerobeat-input-mediapipe-python/` alongside `aerobeat-core`.
## The standalone repo testbed continues to exercise `src/providers/mediapipe_provider.gd`
## directly so this repo can still be worked on without hiding assembly wiring here.
##
## Current truthful scope:
## - lifecycle + polling access for head/hands/feet positions
## - tracking state + basic confidence queries
## - no gesture callbacks, haptics, velocity, or 6DOF transform output yet

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

func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.LOWER_BODY:
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
	return Vector3.ZERO

func get_left_hand_velocity() -> Vector3:
	return Vector3.ZERO

func get_right_hand_velocity() -> Vector3:
	return Vector3.ZERO

func get_left_foot_velocity() -> Vector3:
	return Vector3.ZERO

func get_right_foot_velocity() -> Vector3:
	return Vector3.ZERO

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
	if _provider == null or _provider.config == null:
		return 0.0
	var landmark_id := _body_part_to_landmark_id(body_part)
	if landmark_id < 0:
		return 0.0
	var landmark: Variant = _provider._landmarks.get(landmark_id, null)
	if landmark is Dictionary:
		return float(landmark.get("v", 0.0))
	return 0.0

func set_tracking_mode(mode: TrackingMode) -> void:
	_tracking_mode = mode
	if _provider != null:
		_provider.set_tracking_mode(_to_provider_mode(mode))

func set_body_track_flags(flags: int) -> void:
	_body_track_flags = flags

func _ensure_provider() -> void:
	if _provider != null:
		return
	var provider_script: GDScript = _load_local_script("src/providers/mediapipe_provider.gd")
	_provider = provider_script.new()
	_provider.name = "MediaPipeProvider"
	add_child(_provider)
	_provider.tracking_lost.connect(func() -> void:
		failed.emit("Tracking lost")
	)
	if _provider.config == null:
		_provider.config = _new_local_config()
	_config = _provider.config

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
	var config_script: GDScript = _load_local_script("src/config/mediapipe_config.gd")
	return config_script.new()

func _resolve_local_path(relative_path: String) -> String:
	return "%s/%s" % [get_script().resource_path.get_base_dir(), relative_path]

func _to_provider_mode(mode: TrackingMode) -> int:
	return 1 if mode == TrackingMode.MODE_3D else 0

func _to_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector2:
		return Vector3(value.x, value.y, 0.0)
	return Vector3.ZERO

func _body_part_to_landmark_id(body_part: StringName) -> int:
	match String(body_part):
		"head":
			return _provider.LANDMARK_NOSE
		"left_hand":
			return _provider.LANDMARK_LEFT_WRIST
		"right_hand":
			return _provider.LANDMARK_RIGHT_WRIST
		"left_foot":
			return _provider.LANDMARK_LEFT_ANKLE
		"right_foot":
			return _provider.LANDMARK_RIGHT_ANKLE
		_:
			return -1
