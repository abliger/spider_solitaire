class_name Card
extends Control

## 当玩家点击此纸牌时发出此信号。
signal card_clicked(card)
## 当玩家开始拖拽此纸牌时发出此信号。
signal card_drag_started(card)
## 当玩家停止拖拽此纸牌时发出此信号。
signal card_drag_ended(card)

# ---------------------------------------------------------------------------
# 纸牌外观常量
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
# 纸牌属性
# ---------------------------------------------------------------------------
## 花色索引：0 = 黑桃，1 = 红桃，2 = 方块，3 = 梅花
var suit: int = 0:
	set(value):
		suit = value
		queue_redraw()

## 点数：1（A）到 13（K）
var rank: int = 1:
	set(value):
		rank = value
		queue_redraw()

## 纸牌是否为正面朝上（true）或背面朝上（false）
var face_up: bool = false:
	set(value):
		face_up = value
		queue_redraw()

## 纸牌是否被高亮（例如，被选为移动目标）
var is_highlighted: bool = false:
	set(value):
		is_highlighted = value
		queue_redraw()

## 内部标志，追踪玩家是否正在拖拽此纸牌。
var _is_dragging: bool = false

var _face_texture: Texture2D = null
var _back_texture: Texture2D = null

# ---------------------------------------------------------------------------
# 内置函数重写
# ---------------------------------------------------------------------------
func _init() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)


func _ready() -> void:
	# 确保我们接收 GUI 输入事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	_back_texture = load("res://assets/cards/back.png")
	queue_redraw()


func _draw() -> void:
	# 提示高亮发光层（绘制在纸牌下方）
	if is_highlighted:
		_draw_highlight_glow()

	if face_up:
		_draw_face_up()
	else:
		_draw_face_down()

	# 高亮覆盖层（绘制在纸牌上方）
	if is_highlighted:
		_draw_highlight()


# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------
## 使用给定的花色和点数配置纸牌。
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


## 翻转纸牌（正反面切换）。
func flip() -> void:
	face_up = not face_up


## 启用或禁用高亮覆盖层。
func set_highlight(enabled: bool) -> void:
	is_highlighted = enabled


## 返回点数的显示字符串（A, 2–10, J, Q, K）。
func get_rank_string() -> String:
	match rank:
		1:  return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_:  return str(rank)


## 返回花色符号（♠, ♥, ♦, ♣）。
func get_suit_symbol() -> String:
	match suit:
		0: return "♠"
		1: return "♥"
		2: return "♦"
		3: return "♣"
		_: return "?"


## 如果此纸牌是红色花色（红桃或方块）则返回 true。
func is_red() -> bool:
	return suit == 1 or suit == 2


# ---------------------------------------------------------------------------
# 输入处理
# ---------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click:
				# 忽略双击的所有阶段，避免快速连续的 start_drag / end_drag
				# 导致 tween 动画互相冲突，纸牌被移到错误位置。
				_is_dragging = false
				return
			if mb.pressed:
				card_clicked.emit(self)
				_is_dragging = true
				card_drag_started.emit(self)
			else:
				if _is_dragging:
					_is_dragging = false
					card_drag_ended.emit(self)
	# 触摸事件通过 project.godot 设置模拟为鼠标事件，
	# 因此这里不需要显式处理 InputEventScreenTouch。


# ---------------------------------------------------------------------------
# 绘制辅助函数
# ---------------------------------------------------------------------------
func _draw_face_up() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 纸牌阴影
	var shadow_rect := Rect2(Vector2(2, 2), size)
	_draw_rounded_rect_fill(shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.25))

	# 白色圆角背景（略大于纹理以覆盖边缘）
	_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color.WHITE)

	# 绘制缩放到纸牌大小的正面纹理
	if _face_texture != null:
		draw_texture_rect(_face_texture, rect, false)

	# 细边框覆盖层
	draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(0.25, 0.25, 0.25, 0.3), 0.5)


func _draw_face_down() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 纸牌阴影
	var shadow_rect := Rect2(Vector2(2, 2), size)
	_draw_rounded_rect_fill(shadow_rect, CORNER_RADIUS, Color(0, 0, 0, 0.25))

	# 绘制缩放到纸牌大小的背面纹理
	if _back_texture != null:
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color.WHITE)
		draw_texture_rect(_back_texture, rect, false)
	else:
		# 后备方案：深蓝色图案
		_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color("#0c1f3d"))


func _draw_highlight_glow() -> void:
	var glow_rect := Rect2(Vector2(-6, -6), size + Vector2(12, 12))
	_draw_rounded_rect_fill(glow_rect, CORNER_RADIUS + 3, Color(1.0, 0.9, 0.0, 0.50))
	draw_rounded_rect_outline(glow_rect, CORNER_RADIUS + 3, Color(1.0, 1.0, 0.3, 1.0), 5.0)

func _draw_highlight() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	# 高饱和度金色发光覆盖层（提示效果更明显）
	_draw_rounded_rect_fill(rect, CORNER_RADIUS, Color(1.0, 0.92, 0.0, 0.55))
	draw_rounded_rect_outline(rect, CORNER_RADIUS, Color(1.0, 1.0, 0.5, 1.0), 4.0)
	# 内部细亮线
	draw_rounded_rect_outline(rect.grow(-4), CORNER_RADIUS - 1, Color(1.0, 1.0, 0.9, 0.9), 2.0)


## 用给定颜色填充圆角矩形。
func _draw_rounded_rect_fill(rect: Rect2, radius: float, color: Color) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	# 中心矩形
	var inner := Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(r * 2, 0))
	draw_rect(inner, color)
	var inner_v := Rect2(rect.position + Vector2(0, r), rect.size - Vector2(0, r * 2))
	draw_rect(inner_v, color)
	# 四个角圆
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


## 使用多个 draw_arc / draw_line 调用绘制圆角矩形轮廓。
func draw_rounded_rect_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r: float = min(radius, min(rect.size.x * 0.5, rect.size.y * 0.5))
	var tl := rect.position + Vector2(r, r)
	var tr := rect.position + Vector2(rect.size.x - r, r)
	var br := rect.position + rect.size - Vector2(r, r)
	var bl := rect.position + Vector2(r, rect.size.y - r)

	# 四条直边
	draw_line(tl + Vector2(-r, 0), tr + Vector2(r, 0), color, width)
	draw_line(tr + Vector2(0, -r), br + Vector2(0, r), color, width)
	draw_line(br + Vector2(r, 0), bl + Vector2(-r, 0), color, width)
	draw_line(bl + Vector2(0, r), tl + Vector2(0, -r), color, width)

	# 四个角弧线
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
