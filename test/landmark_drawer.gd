extends Control
## Draws MediaPipe pose landmarks and skeleton on top of camera feed

# Landmark colors
const LANDMARK_COLOR = Color(0.0, 1.0, 0.5, 0.9)  # Green-cyan
const LANDMARK_COLOR_LOW_CONFIDENCE = Color(1.0, 0.5, 0.0, 0.7)  # Orange
const SKELETON_COLOR = Color(0.0, 0.8, 1.0, 0.8)  # Cyan
const SKELETON_WIDTH = 2.0
const LANDMARK_RADIUS = 4.0

# MediaPipe Pose connections (skeleton)
# Format: [landmark1, landmark2]
const SKELETON_CONNECTIONS = [
	# Face
	[0, 1], [1, 2], [2, 3], [3, 7],  # Nose to eyes
	[0, 4], [4, 5], [5, 6], [6, 8],  # Nose to other eye
	[9, 10],  # Mouth
	
	# Torso
	[11, 12], [11, 23], [12, 24], [23, 24],  # Shoulders to hips
	
	# Left arm
	[11, 13], [13, 15], [15, 17], [15, 19], [15, 21],  # Shoulder to wrist
	
	# Right arm
	[12, 14], [14, 16], [16, 18], [16, 20], [16, 22],  # Shoulder to wrist
	
	# Left leg
	[23, 25], [25, 27], [27, 29], [27, 31],  # Hip to ankle
	
	# Right leg
	[24, 26], [26, 28], [28, 30], [28, 32],  # Hip to ankle
]

# Current landmarks to draw
var _landmarks: Array = []
var _min_visibility: float = 0.5

func _ready():
	# Ensure we can draw
	queue_redraw()

func update_landmarks(landmarks: Array, min_visibility: float = 0.5):
	_min_visibility = min_visibility
	_landmarks.clear()
	
	# Convert to local format with visibility check
	for lm in landmarks:
		if lm.has("v") and lm.v >= _min_visibility:
			_landmarks.append({
				"id": lm.id,
				"x": lm.x,
				"y": lm.y,
				"z": lm.z if lm.has("z") else 0.0,
				"v": lm.v
			})
	
	queue_redraw()

func clear_landmarks():
	_landmarks.clear()
	queue_redraw()

func _draw():
	if _landmarks.is_empty():
		return
	
	var display_rect = get_rect()
	var width = display_rect.size.x
	var height = display_rect.size.y
	
	# Draw skeleton connections first (so they appear behind landmarks)
	_draw_skeleton(width, height)
	
	# Draw landmarks
	_draw_landmarks(width, height)

func _draw_skeleton(width: float, height: float):
	# Create a dictionary for quick landmark lookup
	var landmark_dict = {}
	for lm in _landmarks:
		landmark_dict[lm.id] = lm
	
	# Draw each connection
	for connection in SKELETON_CONNECTIONS:
		var id1 = connection[0]
		var id2 = connection[1]
		
		if landmark_dict.has(id1) and landmark_dict.has(id2):
			var lm1 = landmark_dict[id1]
			var lm2 = landmark_dict[id2]
			
			var pos1 = _landmark_to_screen(lm1, width, height)
			var pos2 = _landmark_to_screen(lm2, width, height)
			
			draw_line(pos1, pos2, SKELETON_COLOR, SKELETON_WIDTH)

func _draw_landmarks(width: float, height: float):
	for lm in _landmarks:
		var pos = _landmark_to_screen(lm, width, height)
		
		# Color based on confidence
		var color = LANDMARK_COLOR if lm.v > 0.8 else LANDMARK_COLOR_LOW_CONFIDENCE
		
		# Draw filled circle for landmark
		draw_circle(pos, LANDMARK_RADIUS, color)
		
		# Draw outline
		draw_arc(pos, LANDMARK_RADIUS, 0, TAU, 16, Color.BLACK, 1.0)

func _landmark_to_screen(lm: Dictionary, width: float, height: float) -> Vector2:
	# MediaPipe coordinates are normalized [0, 1]
	# X: 0=left, 1=right
	# Y: 0=top, 1=bottom
	# Flip Y so 0 is at the top
	var x = lm.x * width
	var y = (1.0 - lm.y) * height
	return Vector2(x, y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
