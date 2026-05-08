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

	var screen_points: PackedVector2Array = []
	for point_variant: Variant in points:
		if not point_variant is Dictionary:
			continue
		if not point_variant.has("x") or not point_variant.has("y"):
			continue
		screen_points.append(_normalized_to_screen(Vector2(float(point_variant.x), float(point_variant.y)), image_bounds))

	if screen_points.size() >= 2:
		draw_polyline(screen_points, line_color, TRAIL_WIDTH, true)

	var last_point: Vector2 = screen_points[screen_points.size() - 1]
	draw_circle(last_point, POINT_RADIUS, point_color)
	draw_arc(last_point, POINT_RADIUS, 0.0, TAU, 18, Color.BLACK, 1.0)
	draw_string(ThemeDB.fallback_font, last_point + Vector2(10.0, -10.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, point_color)

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
