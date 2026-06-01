class_name Foundation
extends Control

## 完成序列（K→A）的视觉指示器，最多支持 8 个槽位。

const SLOT_WIDTH: int = 100     # 单个槽位宽度 / Width of each foundation slot
const SLOT_HEIGHT: int = 140    # 单个槽位高度 / Height of each foundation slot
const SLOT_SPACING: int = 12    # 槽位之间的间距 / Spacing between slots
const NUM_SLOTS: int = 8        # 总槽位数量（对应 8 组完整序列） / Total number of foundation slots
const CORNER_RADIUS: int = 8    # 圆角半径 / Corner radius for drawing

var _completed_count: int = 0   # 当前已完成的序列数量 / Number of completed sequences
var _completed_suits: Array[int] = []  # 每个完成序列的花色 / Suits of completed sequences
var _back_texture: Texture2D = null  # 牌背纹理，用于填充完成的槽位 / Card back texture for filled slots
var _cached_font: Font = null        # 缓存的主题字体 / Cached theme font


func _ready() -> void:
	# 根据槽位数量计算控件总宽度
	custom_minimum_size = Vector2(
		NUM_SLOTS * SLOT_WIDTH + (NUM_SLOTS - 1) * SLOT_SPACING,
		SLOT_HEIGHT
	)
	size = custom_minimum_size
	_back_texture = load("res://assets/cards/back.png")
	_cached_font = get_theme_default_font()
	queue_redraw()


## 将另一个槽位标记为由完成的序列填充。
func add_completed_sequence(suit: int = -1) -> void:
	if _completed_count < NUM_SLOTS:
		_completed_count += 1
		_completed_suits.append(suit)
		queue_redraw()


## 移除一个已完成的序列（用于撤销操作）。
func remove_completed_sequence() -> void:
	if _completed_count > 0:
		_completed_count -= 1
		if _completed_suits.size() > 0:
			_completed_suits.pop_back()
		queue_redraw()


## 返回目前已完成的序列数量。
func get_completed_count() -> int:
	return _completed_count


## 重置所有槽位为空。
func reset() -> void:
	_completed_count = 0
	_completed_suits.clear()
	queue_redraw()


func _draw() -> void:
	for i in range(NUM_SLOTS):
		var x: float = i * (SLOT_WIDTH + SLOT_SPACING)
		var rect := Rect2(Vector2(x, 0), Vector2(SLOT_WIDTH, SLOT_HEIGHT))

		# 空槽位：深色内部配金色外边框
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color(0.06, 0.18, 0.1, 0.6))
		draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(0.6, 0.5, 0.2, 0.5), 2.0)
		# 内部细金色线条
		var inner_outline := rect.grow(-4)
		draw_rounded_rect_outline(inner_outline, CORNER_RADIUS - 2, Color(0.5, 0.42, 0.15, 0.35), 1.0)

		# 如果该槽位有完成的序列，绘制填充的牌背风格指示器
		if i < _completed_count:
			var inner_rect := rect.grow(-6)
			_draw_rounded_rect_fill(inner_rect, CORNER_RADIUS - 1, Color("#0c1f3d"))
			var ii_rect := inner_rect.grow(-3)
			_draw_rounded_rect_fill(ii_rect, CORNER_RADIUS - 2, Color("#0f2850"))
			draw_rounded_rect_outline(ii_rect, CORNER_RADIUS - 2, Color("#1a3d6e"), 1.0)

			# 绘制对应花色的符号以指示完成的序列
			var font: Font = _cached_font if _cached_font != null else get_theme_default_font()
			var symbol: String = _get_suit_symbol(i)
			var text_size: Vector2 = font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
			var pos: Vector2 = rect.position + (rect.size - text_size) * 0.5 + Vector2(0, text_size.y * 0.5)
			# 轻微阴影
			draw_string(font, pos + Vector2(1, 1), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color(0, 0, 0, 0.3))
			draw_string(font, pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)


## 返回指定索引槽位对应的花色符号。
func _get_suit_symbol(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= _completed_suits.size():
		return "♠"
	match _completed_suits[slot_index]:
		0: return "♠"
		1: return "♥"
		2: return "♦"
		3: return "♣"
		_: return "♠"


## 用指定颜色填充一个圆角矩形。
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
