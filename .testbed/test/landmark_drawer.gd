extends Control
## Draws MediaPipe pose landmarks and skeleton on top of camera feed

const LANDMARK_COLOR: Color = Color(0.0, 1.0, 0.5, 0.9)
const LANDMARK_COLOR_LOW_CONFIDENCE: Color = Color(1.0, 0.5, 0.0, 0.7)
const SKELETON_COLOR: Color = Color(0.0, 0.8, 1.0, 0.8)
const SKELETON_WIDTH: float = 2.0
const LANDMARK_RADIUS: float = 4.0

const SKELETON_CONNECTIONS: Array = [
	[0, 1], [1, 2], [2, 3], [3, 7],
	[0, 4], [4, 5], [5, 6], [6, 8],
	[9, 10],
	[11, 12], [11, 23], [12, 24], [23, 24],
	[11, 13], [13, 15], [15, 17], [15, 19], [15, 21],
	[12, 14], [14, 16], [16, 18], [16, 20], [16, 22],
	[23, 25], [25, 27], [27, 29], [27, 31],
	[24, 26], [26, 28], [28, 30], [28, 32],
]

var _landmarks: Array = []
var _min_visibility: float = 0.5

func _ready() -> void:
	queue_redraw()

func update_landmarks(landmarks: Array, min_visibility: float = 0.5) -> void:
	_min_visibility = min_visibility
	_landmarks.clear()
	
	for lm: Dictionary in landmarks:
		if lm.has("v") and lm.v >= _min_visibility:
			_landmarks.append({
				"id": lm.id,
				"x": lm.x,
				"y": lm.y,
				"z": lm.z if lm.has("z") else 0.0,
				"v": lm.v
			})
	
	queue_redraw()

func clear_landmarks() -> void:
	_landmarks.clear()
	queue_redraw()

func _draw() -> void:
	if _landmarks.is_empty():
		return
	
	# Get the actual displayed image bounds (accounts for letterboxing)
	var image_bounds: Rect2 = _get_displayed_image_bounds()
	var width: float = image_bounds.size.x
	var height: float = image_bounds.size.y
	var offset: Vector2 = image_bounds.position
	
	_draw_skeleton(width, height, offset)
	_draw_landmarks(width, height, offset)

func _draw_skeleton(width: float, height: float, offset: Vector2 = Vector2.ZERO) -> void:
	var landmark_dict: Dictionary = {}
	for landmark: Dictionary in _landmarks:
		landmark_dict[landmark.id] = landmark
	
	for connection: Array in SKELETON_CONNECTIONS:
		var id1: int = connection[0]
		var id2: int = connection[1]
		
		if landmark_dict.has(id1) and landmark_dict.has(id2):
			var lm1: Dictionary = landmark_dict[id1]
			var lm2: Dictionary = landmark_dict[id2]
			
			var pos1: Vector2 = _landmark_to_screen(lm1, width, height, offset)
			var pos2: Vector2 = _landmark_to_screen(lm2, width, height, offset)
			
			draw_line(pos1, pos2, SKELETON_COLOR, SKELETON_WIDTH)

func _draw_landmarks(width: float, height: float, offset: Vector2 = Vector2.ZERO) -> void:
	for lm: Dictionary in _landmarks:
		var pos: Vector2 = _landmark_to_screen(lm, width, height, offset)
		var color: Color = LANDMARK_COLOR if lm.v > 0.8 else LANDMARK_COLOR_LOW_CONFIDENCE
		
		draw_circle(pos, LANDMARK_RADIUS, color)
		draw_arc(pos, LANDMARK_RADIUS, 0.0, TAU, 16, Color.BLACK, 1.0)

func _landmark_to_screen(lm: Dictionary, width: float, height: float, offset: Vector2 = Vector2.ZERO) -> Vector2:
	# Apply horizontal flip to match mirrored camera feed
	# MediaPipe: (0,0) = top-left, (1,1) = bottom-right
	var x: float = offset.x + (1.0 - lm.x) * width
	var y: float = offset.y + lm.y * height
	return Vector2(x, y)

func _get_displayed_image_bounds() -> Rect2:
	"""Calculate the actual bounds of the displayed image within the parent TextureRect.
	
	When the image is letterboxed (STRETCH_KEEP_ASPECT_CENTERED), this returns
	the actual image area, not the full control size.
	"""
	var parent: TextureRect = get_parent() as TextureRect
	if parent == null:
		return get_rect()
	
	var texture: Texture2D = parent.texture
	if texture == null:
		return get_rect()
	
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x == 0 or tex_size.y == 0:
		return get_rect()
	
	var rect: Rect2 = get_rect()
	var container_size: Vector2 = rect.size
	
	# Calculate aspect ratios
	var tex_aspect: float = tex_size.x / tex_size.y
	var container_aspect: float = container_size.x / container_size.y
	
	var displayed_size: Vector2
	
	# Based on stretch mode, calculate actual displayed image size
	match parent.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			if tex_aspect > container_aspect:
				# Image is wider - fit to width
				displayed_size = Vector2(container_size.x, container_size.x / tex_aspect)
			else:
				# Image is taller - fit to height
				displayed_size = Vector2(container_size.y * tex_aspect, container_size.y)
		TextureRect.STRETCH_KEEP:
			displayed_size = tex_size
		_:
			# STRETCH_SCALE or others - fill container
			displayed_size = container_size
	
	# Center the image
	var offset: Vector2 = (container_size - displayed_size) / 2.0
	
	return Rect2(offset, displayed_size)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
