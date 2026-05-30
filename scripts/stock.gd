class_name Stock
extends Control

## 当玩家点击或触摸牌库以发牌时发出此信号。
signal deal_requested

const CARD_WIDTH: int = 100    # 单张牌的宽度 / Card width in pixels
const CARD_HEIGHT: int = 140   # 单张牌的高度 / Card height in pixels
const CORNER_RADIUS: int = 8   # 牌背圆角半径 / Corner radius for card back drawing

var _remaining: int = 0        # 牌库中剩余的牌数 / Remaining cards in stock
var _count_label: Label        # 显示剩余牌数的标签 / Label showing remaining count
var _back_texture: Texture2D = null  # 牌背纹理 / Card back texture


func _ready() -> void:
	# 设置控件的最小和实际尺寸为单张牌大小
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	# 阻止鼠标事件穿透，确保能接收点击
	mouse_filter = Control.MOUSE_FILTER_STOP

	_back_texture = load("res://assets/cards/back.png")

	# 创建并配置剩余牌数标签
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.size = size
	_count_label.position = Vector2.ZERO
	_count_label.add_theme_font_size_override("font_size", 24)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_count_label)

	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			deal_requested.emit()
	# 触摸事件通过 project.godot 设置模拟为鼠标事件。


## 更新剩余牌数并控制显示/隐藏。
func set_remaining(count: int) -> void:
	_remaining = count
	if _count_label:
		_count_label.text = str(count)
	visible = count > 0
	queue_redraw()


## 当牌库中没有剩余牌时返回 true。
func is_empty() -> bool:
	return _remaining <= 0


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 绘制一小叠牌背
	var stack_count: int = mini(_remaining, 3)
	for i in range(stack_count):
		var offset: Vector2 = Vector2((stack_count - 1 - i) * 2, (stack_count - 1 - i) * 2)
		var card_rect := Rect2(
			offset,
			Vector2(size.x - (stack_count - 1) * 4, size.y - (stack_count - 1) * 4)
		)
		# 为堆叠中的每张牌绘制阴影
		if i < stack_count - 1:
			var shadow_rect := Rect2(card_rect.position + Vector2(2, 2), card_rect.size)
			_draw_rounded_rect_fill(shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.2))

		# 绘制牌背纹理
		if _back_texture != null:
			_draw_rounded_rect_fill(card_rect, CORNER_RADIUS, Color.WHITE)
			draw_texture_rect(_back_texture, card_rect, false)
		else:
			_draw_rounded_rect_fill(card_rect, CORNER_RADIUS, Color("#0c1f3d"))
			draw_rounded_rect_outline(card_rect, CORNER_RADIUS, Color("#081830"), 1.5)


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
