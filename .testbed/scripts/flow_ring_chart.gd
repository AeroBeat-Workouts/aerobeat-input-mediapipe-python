extends Control
class_name FlowRingChart

@export var chart_title := "Placement"
@export_range(1, 13, 1) var ring_count := 12
@export var has_center_slot := false
@export var active_index := -1:
	set(value):
		if active_index == value:
			return
		active_index = value
		queue_redraw()

@export var line_color := Color(1.0, 1.0, 1.0, 0.75)
@export var inactive_fill_color := Color(1.0, 1.0, 1.0, 0.12)
@export var active_fill_color := Color(0.47, 0.82, 1.0, 0.95)
@export var label_color := Color(1.0, 1.0, 1.0, 1.0)
@export var title_color := Color(1.0, 1.0, 1.0, 1.0)

const TITLE_HEIGHT := 30.0
const TITLE_FONT_SIZE := 16
const SLOT_FONT_SIZE := 18
const SLOT_STROKE_WIDTH := 2.0
const RING_STROKE_WIDTH := 1.5

func _ready() -> void:
	custom_minimum_size = Vector2(260, 260)
	queue_redraw()

func set_chart_state(next_title: String, next_ring_count: int, next_has_center_slot: bool, next_active_index: int) -> void:
	chart_title = next_title
	ring_count = max(next_ring_count, 1)
	has_center_slot = next_has_center_slot
	active_index = next_active_index
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	var title_font := ThemeDB.fallback_font
	if title_font == null:
		return
	var slot_font := title_font
	var title_size := title_font.get_string_size(chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE)
	var title_position := Vector2((rect.size.x - title_size.x) * 0.5, TITLE_HEIGHT * 0.8)
	draw_string(title_font, title_position, chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE, title_color)

	var chart_rect := Rect2(Vector2(8.0, TITLE_HEIGHT + 6.0), Vector2(maxf(rect.size.x - 16.0, 80.0), maxf(rect.size.y - TITLE_HEIGHT - 14.0, 80.0)))
	var center := chart_rect.position + chart_rect.size * 0.5
	var radius := minf(chart_rect.size.x, chart_rect.size.y) * 0.37
	var slot_radius := clampf(radius * 0.16, 14.0, 23.0)

	draw_arc(center, radius, 0.0, TAU, 96, line_color, RING_STROKE_WIDTH, true)
	for index: int in range(ring_count):
		var slot_center := _slot_center(center, radius, index)
		_draw_slot(slot_center, slot_radius, index, false, slot_font)
	if has_center_slot:
		_draw_slot(center, slot_radius, ring_count, true, slot_font)

func _slot_center(center: Vector2, radius: float, index: int) -> Vector2:
	var angle := -PI / 2.0 + PI / 6.0 + float(index) * (TAU / float(ring_count))
	return center + Vector2(cos(angle), sin(angle)) * radius

func _draw_slot(slot_center: Vector2, slot_radius: float, index: int, is_center: bool, font: Font) -> void:
	var is_active := active_index == index
	var fill_color := active_fill_color if is_active else inactive_fill_color
	draw_circle(slot_center, slot_radius, fill_color)
	draw_arc(slot_center, slot_radius, 0.0, TAU, 48, line_color, SLOT_STROKE_WIDTH, true)
	var label := str(index + 1)
	var font_size := SLOT_FONT_SIZE if not is_center else SLOT_FONT_SIZE + 1
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := slot_center + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
