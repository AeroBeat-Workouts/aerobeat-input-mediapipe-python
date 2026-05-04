class_name LandmarkSmoother
extends RefCounted

var _window_size: int = 4
var _samples_by_id: Dictionary = {}

func _init(window_size: int = 4) -> void:
	_window_size = maxi(window_size, 1)

func clear() -> void:
	_samples_by_id.clear()

func push_landmarks(landmarks: Array) -> Dictionary:
	for landmark: Variant in landmarks:
		if not landmark is Dictionary:
			continue
		var landmark_dict: Dictionary = landmark.duplicate(true)
		var landmark_id: int = int(landmark_dict.get("id", -1))
		if landmark_id < 0:
			continue
		var history: Array = _samples_by_id.get(landmark_id, [])
		history.append(landmark_dict)
		while history.size() > _window_size:
			history.pop_front()
		_samples_by_id[landmark_id] = history
	return get_smoothed_landmarks()

func get_smoothed_landmarks() -> Dictionary:
	var smoothed: Dictionary = {}
	for landmark_id_variant: Variant in _samples_by_id.keys():
		var history: Array = _samples_by_id.get(landmark_id_variant, [])
		if history.is_empty():
			continue
		var sum_x := 0.0
		var sum_y := 0.0
		var sum_z := 0.0
		var sum_v := 0.0
		for sample_variant: Variant in history:
			if not sample_variant is Dictionary:
				continue
			var sample: Dictionary = sample_variant
			sum_x += float(sample.get("x", 0.0))
			sum_y += float(sample.get("y", 0.0))
			sum_z += float(sample.get("z", 0.0))
			sum_v += float(sample.get("v", 0.0))
		var count: float = float(history.size())
		var latest: Dictionary = history[history.size() - 1]
		var landmark_id: int = int(landmark_id_variant)
		smoothed[landmark_id] = {
			"id": landmark_id,
			"x": sum_x / count,
			"y": sum_y / count,
			"z": sum_z / count,
			"v": sum_v / count,
			"sample_count": history.size(),
			"latest_visibility": float(latest.get("v", 0.0)),
		}
	return smoothed
