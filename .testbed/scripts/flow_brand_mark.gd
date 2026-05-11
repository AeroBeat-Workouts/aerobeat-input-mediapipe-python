extends Control

const WHITE := Color(1.0, 1.0, 1.0, 0.94)
const ACCENT := Color8(0xB9, 0xFF, 0x5F, 0xFF)

func _ready() -> void:
	custom_minimum_size = Vector2(34, 34)
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	var size_min := minf(rect.size.x, rect.size.y)
	var stroke := clampf(size_min * 0.115, 2.5, 4.5)
	var inset := size_min * 0.18
	var p1 := Vector2(inset, inset)
	var p2 := Vector2(rect.size.x - inset, rect.size.y - inset)
	var p3 := Vector2(rect.size.x - inset * 1.05, inset)
	var p4 := Vector2(inset * 0.95, rect.size.y - inset)
	draw_line(p1, p2, WHITE, stroke, true)
	draw_line(p3, p4, WHITE, stroke, true)
	draw_line(Vector2(inset * 0.52, rect.size.y - inset * 1.02), Vector2(rect.size.x * 0.36, rect.size.y * 0.63), ACCENT, stroke * 0.6, true)
