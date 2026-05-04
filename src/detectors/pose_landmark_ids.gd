class_name PoseLandmarkIds
extends RefCounted

const NOSE := 0
const LEFT_EYE_INNER := 1
const LEFT_EYE := 2
const LEFT_EYE_OUTER := 3
const RIGHT_EYE_INNER := 4
const RIGHT_EYE := 5
const RIGHT_EYE_OUTER := 6
const LEFT_EAR := 7
const RIGHT_EAR := 8
const MOUTH_LEFT := 9
const MOUTH_RIGHT := 10
const LEFT_SHOULDER := 11
const RIGHT_SHOULDER := 12
const LEFT_ELBOW := 13
const RIGHT_ELBOW := 14
const LEFT_WRIST := 15
const RIGHT_WRIST := 16
const LEFT_PINKY := 17
const RIGHT_PINKY := 18
const LEFT_INDEX := 19
const RIGHT_INDEX := 20
const LEFT_THUMB := 21
const RIGHT_THUMB := 22
const LEFT_HIP := 23
const RIGHT_HIP := 24
const LEFT_KNEE := 25
const RIGHT_KNEE := 26
const LEFT_ANKLE := 27
const RIGHT_ANKLE := 28
const LEFT_HEEL := 29
const RIGHT_HEEL := 30
const LEFT_FOOT_INDEX := 31
const RIGHT_FOOT_INDEX := 32

const TRACKING_KEY_LANDMARKS := [
	NOSE,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	LEFT_HIP,
	RIGHT_HIP,
	LEFT_WRIST,
	RIGHT_WRIST,
]

const BASELINE_KEY_LANDMARKS := [
	NOSE,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	LEFT_HIP,
	RIGHT_HIP,
	LEFT_ANKLE,
	RIGHT_ANKLE,
]

static func semantic_to_landmark_id(body_part: StringName) -> int:
	match String(body_part):
		"head":
			return NOSE
		"left_hand":
			return LEFT_WRIST
		"right_hand":
			return RIGHT_WRIST
		"left_foot":
			return LEFT_ANKLE
		"right_foot":
			return RIGHT_ANKLE
		"left_elbow":
			return LEFT_ELBOW
		"right_elbow":
			return RIGHT_ELBOW
		"left_shoulder":
			return LEFT_SHOULDER
		"right_shoulder":
			return RIGHT_SHOULDER
		"left_hip":
			return LEFT_HIP
		"right_hip":
			return RIGHT_HIP
		_:
			return -1
