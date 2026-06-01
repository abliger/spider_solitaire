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
var _cached_font: Font = null        # 缓存的主题字体 / Cached theme font


func _ready() -> void:
	# 根据槽位数量计算控件总宽度
	custom_minimum_size = Vector2(
		NUM_SLOTS * SLOT_WIDTH + (NUM_SLOTS - 1) * SLOT_SPACING,
		SLOT_HEIGHT
	)
	size = custom_minimum_size
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
		Drawing.rounded_rect_fill(self, rect, CORNER_RADIUS, Color(0.06, 0.18, 0.1, 0.6))
		Drawing.rounded_rect_outline(self, rect, CORNER_RADIUS, Color(0.6, 0.5, 0.2, 0.5), 2.0)
		# 内部细金色线条
		var inner_outline := rect.grow(-4)
		Drawing.rounded_rect_outline(self, inner_outline, CORNER_RADIUS - 2, Color(0.5, 0.42, 0.15, 0.35), 1.0)

		# 如果该槽位有完成的序列，绘制填充的牌背风格指示器
		if i < _completed_count:
			var inner_rect := rect.grow(-6)
			Drawing.rounded_rect_fill(self, inner_rect, CORNER_RADIUS - 1, Color("#0c1f3d"))
			var ii_rect := inner_rect.grow(-3)
			Drawing.rounded_rect_fill(self, ii_rect, CORNER_RADIUS - 2, Color("#0f2850"))
			Drawing.rounded_rect_outline(self, ii_rect, CORNER_RADIUS - 2, Color("#1a3d6e"), 1.0)

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


