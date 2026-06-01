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
			Drawing.rounded_rect_fill(self, shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.2))

		# 绘制牌背纹理
		if _back_texture != null:
			Drawing.rounded_rect_fill(self, card_rect, CORNER_RADIUS, Color.WHITE)
			draw_texture_rect(_back_texture, card_rect, false)
		else:
			Drawing.rounded_rect_fill(self, card_rect, CORNER_RADIUS, Color("#0c1f3d"))
			Drawing.rounded_rect_outline(self, card_rect, CORNER_RADIUS, Color("#081830"), 1.5)






