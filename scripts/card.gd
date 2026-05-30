class_name Card
extends Control

## Emitted when the player clicks on this card.
signal card_clicked(card)
## Emitted when the player starts dragging this card.
signal card_drag_started(card)
## Emitted when the player stops dragging this card.
signal card_drag_ended(card)

# ---------------------------------------------------------------------------
# Card appearance constants
# ---------------------------------------------------------------------------
const CARD_WIDTH: int = 100
const CARD_HEIGHT: int = 140
const CORNER_RADIUS: int = 6
const FONT_SIZE: int = 18
const SUIT_FONT_SIZE: int = 16
const PIP_FONT_SIZE: int = 14
const COURT_FONT_SIZE: int = 40
const COURT_SUIT_SIZE: int = 28
const CENTER_SUIT_SIZE: int = 52

# ---------------------------------------------------------------------------
# Card properties
# ---------------------------------------------------------------------------
## Suit index: 0 = Spades, 1 = Hearts, 2 = Diamonds, 3 = Clubs
var suit: int = 0:
	set(value):
		suit = value
		queue_redraw()

## Rank: 1 (Ace) through 13 (King)
var rank: int = 1:
	set(value):
		rank = value
		queue_redraw()

## Whether the card is face-up (true) or face-down (false)
var face_up: bool = false:
	set(value):
		face_up = value
		queue_redraw()

## Whether the card is highlighted (e.g., selected for a move)
var is_highlighted: bool = false:
	set(value):
		is_highlighted = value
		queue_redraw()

## Internal flag tracking whether the player is currently dragging this card.
var _is_dragging: bool = false

var _face_texture: Texture2D = null
var _back_texture: Texture2D = null

# ---------------------------------------------------------------------------
# Built-in overrides
# ---------------------------------------------------------------------------
func _init() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)


func _ready() -> void:
	# Ensure we receive gui input events
	mouse_filter = Control.MOUSE_FILTER_STOP
	_back_texture = load("res://assets/cards/back.png")
	queue_redraw()


func _draw() -> void:
	if face_up:
		_draw_face_up()
	else:
		_draw_face_down()

	# Highlight overlay
	if is_highlighted:
		_draw_highlight()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
## Configures the card with the given suit and rank.
func set_card_data(new_suit: int, new_rank: int) -> void:
	suit = new_suit
	rank = new_rank
	var suit_name: String
	match suit:
		0: suit_name = "spades"
		1: suit_name = "hearts"
		2: suit_name = "diamonds"
		3: suit_name = "clubs"
		_: suit_name = "spades"
	_face_texture = load("res://assets/cards/%s_%d.png" % [suit_name, rank])
	queue_redraw()


## Flips the card between face-up and face-down.
func flip() -> void:
	face_up = not face_up


## Enables or disables the highlight overlay.
func set_highlight(enabled: bool) -> void:
	is_highlighted = enabled


## Returns the rank as a display string (A, 2–10, J, Q, K).
func get_rank_string() -> String:
	match rank:
		1:  return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_:  return str(rank)


## Returns the suit symbol (♠, ♥, ♦, ♣).
func get_suit_symbol() -> String:
	match suit:
		0: return "♠"
		1: return "♥"
		2: return "♦"
		3: return "♣"
		_: return "?"


## Returns true if this is a red suit (Hearts or Diamonds).
func is_red() -> bool:
	return suit == 1 or suit == 2


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				card_clicked.emit(self)
				_is_dragging = true
				card_drag_started.emit(self)
			else:
				if _is_dragging:
					_is_dragging = false
					card_drag_ended.emit(self)
	# Touch events are emulated as mouse events via project.godot setting,
	# so we don't need explicit InputEventScreenTouch handling here.


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------
func _draw_face_up() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Card shadow
	var shadow_rect := Rect2(Vector2(2, 2), size)
	_draw_rounded_rect_fill(shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.25))

	# White rounded background (slightly larger than texture to cover edges)
	_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color.WHITE)

	# Draw the face texture scaled to card size
	if _face_texture != null:
		draw_texture_rect(_face_texture, rect, false)

	# Thin border overlay
	draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(0.25, 0.25, 0.25, 0.3), 0.5)


func _draw_face_down() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Card shadow
	var shadow_rect := Rect2(Vector2(2, 2), size)
	_draw_rounded_rect_fill(shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.25))

	# Draw the back texture scaled to card size
	if _back_texture != null:
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color.WHITE)
		draw_texture_rect(_back_texture, rect, false)
	else:
		# Fallback: dark blue pattern
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color("#0c1f3d"))


func _draw_highlight() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	# Semi-transparent golden glow overlay
	_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color(1.0, 0.85, 0.2, 0.18))
	draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(1.0, 0.9, 0.4, 0.6), 2.5)
	# Inner thin bright line
	draw_rounded_rect_outline(rect.grow(-3), CORNER_RADIUS - 1, Color(1.0, 0.95, 0.6, 0.4), 1.0)


## Fills a rounded rectangle with the given color.
func _draw_rounded_rect_fill(rect: Rect2, radius: float, color: Color) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	# Central rectangle
	var inner := Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(r * 2, 0))
	draw_rect(inner, color)
	var inner_v := Rect2(rect.position + Vector2(0, r), rect.size - Vector2(0, r * 2))
	draw_rect(inner_v, color)
	# Four corner circles
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


## Draws a rounded rectangle outline using multiple draw_arc / draw_line calls.
func draw_rounded_rect_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var tl := rect.position + Vector2(r, r)
	var tr := rect.position + Vector2(rect.size.x - r, r)
	var br := rect.position + rect.size - Vector2(r, r)
	var bl := rect.position + Vector2(r, rect.size.y - r)

	# Four straight edges
	draw_line(tl + Vector2(-r, 0), tr + Vector2(r, 0), color, width)
	draw_line(tr + Vector2(0, -r), br + Vector2(0, r), color, width)
	draw_line(br + Vector2(r, 0), bl + Vector2(-r, 0), color, width)
	draw_line(bl + Vector2(0, r), tl + Vector2(0, -r), color, width)

	# Four corner arcs
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
