extends Control
## Draws left/right hand motion trails on top of the mirrored camera feed.

const LEFT_TRAIL_COLOR := Color(0.25, 0.95, 1.0, 0.95)
const RIGHT_TRAIL_COLOR := Color(1.0, 0.45, 0.75, 0.95)
const LEFT_POINT_COLOR := Color(0.10, 0.75, 1.0, 1.0)
const RIGHT_POINT_COLOR := Color(1.0, 0.30, 0.65, 1.0)
const TRAIL_WIDTH := 3.0
const POINT_RADIUS := 7.0

var _left_points: Array = []
var _right_points: Array = []

func update_trails(left_points: Array, right_points: Array) -> void:
	_left_points = left_points.duplicate(true)
	_right_points = right_points.duplicate(true)
	queue_redraw()

func clear_trails() -> void:
	_left_points.clear()
	_right_points.clear()
	queue_redraw()

func _draw() -> void:
	var image_bounds: Rect2 = _get_displayed_image_bounds()
	_draw_trail(_left_points, LEFT_TRAIL_COLOR, LEFT_POINT_COLOR, image_bounds, "L")
	_draw_trail(_right_points, RIGHT_TRAIL_COLOR, RIGHT_POINT_COLOR, image_bounds, "R")

func _draw_trail(points: Array, line_color: Color, point_color: Color, image_bounds: Rect2, label_text: String) -> void:
	if points.is_empty():
		return

	var screen_segments: Array[PackedVector2Array] = []
	var current_segment: PackedVector2Array = PackedVector2Array()
	var last_valid_point := Vector2.ZERO
	var has_last_valid_point := false
	for point_variant: Variant in points:
		if not point_variant is Dictionary:
			continue
		if not point_variant.has("x") or not point_variant.has("y"):
			continue
		var normalized_point := Vector2(float(point_variant.x), float(point_variant.y))
		if not _is_normalized_point_in_bounds(normalized_point):
			if current_segment.size() >= 2:
				screen_segments.append(current_segment)
			current_segment = PackedVector2Array()
			continue
		var screen_point := _normalized_to_screen(normalized_point, image_bounds)
		current_segment.append(screen_point)
		last_valid_point = screen_point
		has_last_valid_point = true

	if current_segment.size() >= 2:
		screen_segments.append(current_segment)

	for segment: PackedVector2Array in screen_segments:
		draw_polyline(segment, line_color, TRAIL_WIDTH, true)

	if not has_last_valid_point:
		return
	draw_circle(last_valid_point, POINT_RADIUS, point_color)
	draw_arc(last_valid_point, POINT_RADIUS, 0.0, TAU, 18, Color.BLACK, 1.0)
	draw_string(ThemeDB.fallback_font, last_valid_point + Vector2(10.0, -10.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, point_color)

func _is_normalized_point_in_bounds(point: Vector2) -> bool:
	return point.x >= 0.0 and point.x <= 1.0 and point.y >= 0.0 and point.y <= 1.0

func _normalized_to_screen(point: Vector2, image_bounds: Rect2) -> Vector2:
	# Trail points come from provider-normalized gameplay space, matching the landmark drawer.
	return Vector2(
		image_bounds.position.x + point.x * image_bounds.size.x,
		image_bounds.position.y + (1.0 - point.y) * image_bounds.size.y
	)

func _get_displayed_image_bounds() -> Rect2:
	var parent: TextureRect = get_parent() as TextureRect
	if parent == null:
		return get_rect()

	var texture: Texture2D = parent.texture
	if texture == null:
		return get_rect()

	var tex_size: Vector2 = texture.get_size()
	if tex_size.x == 0.0 or tex_size.y == 0.0:
		return get_rect()

	var rect: Rect2 = get_rect()
	var container_size: Vector2 = rect.size
	var tex_aspect: float = tex_size.x / tex_size.y
	var container_aspect: float = container_size.x / container_size.y
	var displayed_size: Vector2

	match parent.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			if tex_aspect > container_aspect:
				displayed_size = Vector2(container_size.x, container_size.x / tex_aspect)
			else:
				displayed_size = Vector2(container_size.y * tex_aspect, container_size.y)
		TextureRect.STRETCH_KEEP:
			displayed_size = tex_size
		_:
			displayed_size = container_size

	var offset: Vector2 = (container_size - displayed_size) / 2.0
	return Rect2(offset, displayed_size)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
