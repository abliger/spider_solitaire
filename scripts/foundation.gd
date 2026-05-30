class_name Foundation
extends Control

## Visual indicator for completed K->A sequences (up to 8 slots).

const SLOT_WIDTH: int = 100
const SLOT_HEIGHT: int = 140
const SLOT_SPACING: int = 12
const NUM_SLOTS: int = 8
const CORNER_RADIUS: int = 8

var _completed_count: int = 0
var _back_texture: Texture2D = null


func _ready() -> void:
	custom_minimum_size = Vector2(
		NUM_SLOTS * SLOT_WIDTH + (NUM_SLOTS - 1) * SLOT_SPACING,
		SLOT_HEIGHT
	)
	size = custom_minimum_size
	_back_texture = load("res://assets/cards/back.png")
	queue_redraw()


## Marks another slot as filled by a completed sequence.
func add_completed_sequence() -> void:
	if _completed_count < NUM_SLOTS:
		_completed_count += 1
		queue_redraw()


## Removes one completed sequence (used for undo).
func remove_completed_sequence() -> void:
	if _completed_count > 0:
		_completed_count -= 1
		queue_redraw()


## Returns how many sequences have been completed so far.
func get_completed_count() -> int:
	return _completed_count


## Resets all slots to empty.
func reset() -> void:
	_completed_count = 0
	queue_redraw()


func _draw() -> void:
	for i in range(NUM_SLOTS):
		var x: float = i * (SLOT_WIDTH + SLOT_SPACING)
		var rect := Rect2(Vector2(x, 0), Vector2(SLOT_WIDTH, SLOT_HEIGHT))

		# Empty slot: dark inner with golden outline
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color(0.06, 0.18, 0.1, 0.6))
		draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(0.6, 0.5, 0.2, 0.5), 2.0)
		# Inner thin gold line
		var inner_outline := rect.grow(-4)
		draw_rounded_rect_outline(inner_outline, CORNER_RADIUS - 2, Color(0.5, 0.42, 0.15, 0.35), 1.0)

		# If this slot has a completed sequence, draw a filled card-back style indicator
		if i < _completed_count:
			var inner_rect := rect.grow(-6)
			_draw_rounded_rect_fill(inner_rect, CORNER_RADIUS - 1, Color("#0c1f3d"))
			var ii_rect := inner_rect.grow(-3)
			_draw_rounded_rect_fill(ii_rect, CORNER_RADIUS - 2, Color("#0f2850"))
			draw_rounded_rect_outline(ii_rect, CORNER_RADIUS - 2, Color("#1a3d6e"), 1.0)

			# Draw a spade symbol to indicate a completed sequence
			var font: Font = get_theme_default_font()
			var symbol: String = "♠"
			var text_size: Vector2 = font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
			var pos: Vector2 = rect.position + (rect.size - text_size) * 0.5 + Vector2(0, text_size.y * 0.5)
			# Slight shadow
			draw_string(font, pos + Vector2(1, 1), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color(0, 0, 0, 0.3))
			draw_string(font, pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)


## Fills a rounded rectangle with the given color.
func _draw_rounded_rect_fill(rect: Rect2, radius: float, color: Color) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var inner := Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(r * 2, 0))
	draw_rect(inner, color)
	var inner_v := Rect2(rect.position + Vector2(0, r), rect.size - Vector2(0, r * 2))
	draw_rect(inner_v, color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


func draw_rounded_rect_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var tl := rect.position + Vector2(r, r)
	var tr := rect.position + Vector2(rect.size.x - r, r)
	var br := rect.position + rect.size - Vector2(r, r)
	var bl := rect.position + Vector2(r, rect.size.y - r)

	draw_line(tl + Vector2(-r, 0), tr + Vector2(r, 0), color, width)
	draw_line(tr + Vector2(0, -r), br + Vector2(0, r), color, width)
	draw_line(br + Vector2(r, 0), bl + Vector2(-r, 0), color, width)
	draw_line(bl + Vector2(0, r), tl + Vector2(0, -r), color, width)

	var points := 8
	_draw_arc(tl, r, PI, PI * 1.5, points, color, width)
	_draw_arc(tr, r, PI * 1.5, TAU, points, color, width)
	_draw_arc(br, r, 0, PI * 0.5, points, color, width)
	_draw_arc(bl, r, PI * 0.5, PI, points, color, width)


func _draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, points: int, color: Color, width: float) -> void:
	var angle_step := (end_angle - start_angle) / points
	for i in range(points):
		var a1 := start_angle + angle_step * i
		var a2 := start_angle + angle_step * (i + 1)
		var p1 := center + Vector2(cos(a1), sin(a1)) * radius
		var p2 := center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width)
