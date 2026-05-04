class_name PoseMetrics
extends RefCounted

static func get_landmark(landmarks_by_id: Dictionary, landmark_id: int) -> Dictionary:
	var landmark: Variant = landmarks_by_id.get(landmark_id, null)
	if landmark is Dictionary:
		return landmark
	return {}

static func has_landmark(landmarks_by_id: Dictionary, landmark_id: int) -> bool:
	return not get_landmark(landmarks_by_id, landmark_id).is_empty()

static func to_vector2(landmark: Dictionary) -> Vector2:
	return Vector2(float(landmark.get("x", 0.0)), float(landmark.get("y", 0.0)))

static func to_vector3(landmark: Dictionary) -> Vector3:
	return Vector3(
		float(landmark.get("x", 0.0)),
		float(landmark.get("y", 0.0)),
		float(landmark.get("z", 0.0))
	)

static func visibility(landmark: Dictionary) -> float:
	return float(landmark.get("latest_visibility", landmark.get("v", 0.0)))

static func average_visibility(landmarks_by_id: Dictionary, landmark_ids: Array) -> float:
	var total := 0.0
	var count := 0
	for landmark_id: Variant in landmark_ids:
		var landmark := get_landmark(landmarks_by_id, int(landmark_id))
		if landmark.is_empty():
			continue
		total += visibility(landmark)
		count += 1
	if count == 0:
		return 0.0
	return total / float(count)

static func count_visible(landmarks_by_id: Dictionary, landmark_ids: Array, min_visibility: float) -> int:
	var count := 0
	for landmark_id: Variant in landmark_ids:
		var landmark := get_landmark(landmarks_by_id, int(landmark_id))
		if landmark.is_empty():
			continue
		if visibility(landmark) >= min_visibility:
			count += 1
	return count

static func midpoint(a: Dictionary, b: Dictionary) -> Dictionary:
	if a.is_empty() or b.is_empty():
		return {}
	return {
		"x": (float(a.get("x", 0.0)) + float(b.get("x", 0.0))) * 0.5,
		"y": (float(a.get("y", 0.0)) + float(b.get("y", 0.0))) * 0.5,
		"z": (float(a.get("z", 0.0)) + float(b.get("z", 0.0))) * 0.5,
		"v": (float(a.get("v", 0.0)) + float(b.get("v", 0.0))) * 0.5,
	}

static func distance_2d(a: Dictionary, b: Dictionary) -> float:
	if a.is_empty() or b.is_empty():
		return 0.0
	return to_vector2(a).distance_to(to_vector2(b))

static func direction_2d(from_point: Dictionary, to_point: Dictionary) -> Vector2:
	if from_point.is_empty() or to_point.is_empty():
		return Vector2.ZERO
	var delta := to_vector2(to_point) - to_vector2(from_point)
	if delta.length() <= 0.000001:
		return Vector2.ZERO
	return delta.normalized()

static func angle_degrees(a: Dictionary, b: Dictionary, c: Dictionary) -> float:
	if a.is_empty() or b.is_empty() or c.is_empty():
		return 0.0
	var ba := to_vector2(a) - to_vector2(b)
	var bc := to_vector2(c) - to_vector2(b)
	if ba.length() <= 0.000001 or bc.length() <= 0.000001:
		return 0.0
	return rad_to_deg(absf(ba.angle_to(bc)))

static func normalized_ratio(value: float, baseline: float) -> float:
	if absf(baseline) <= 0.000001:
		return 0.0
	return value / baseline

static func clamp01(value: float) -> float:
	return clampf(value, 0.0, 1.0)
