class_name Column
extends Control

## 当新纸牌被添加到此列后发出此信号。
signal cards_added(added)
## 当纸牌从此列移除后发出此信号。
signal cards_removed(removed)

# ---------------------------------------------------------------------------
# 布局常量
# ---------------------------------------------------------------------------
const CARD_WIDTH: int = 100
const CARD_HEIGHT: int = 140
const FACE_UP_OVERLAP: int = 56   # ~60% overlap → 40% visible = 56 px
								  # ~60% 重叠 → 40% 可见 = 56 像素
const FACE_DOWN_OVERLAP: int = 20 # Face-down cards overlap more (less visible)
								  # 背面朝上的纸牌重叠更多（可见部分更少）

# ---------------------------------------------------------------------------
# 列状态
# ---------------------------------------------------------------------------
## 当前在此列中的纸牌，按从底到顶排序。
var _cards: Array[Card] = []

## 记录最近一次 remove_cards / remove_specific_cards 时翻开的牌。
var last_revealed_card: Card = null

## 列的最大可见高度。当纸牌堆叠总高度超过此值时自动压缩间距。
## Maximum visible height for the column; overlaps are auto-scaled down when exceeded.
var max_column_height: float = 0.0

## 是否高亮显示（用于提示目标列）。
var is_highlighted: bool = false:
	set(value):
		is_highlighted = value
		queue_redraw()

# ---------------------------------------------------------------------------
# 内置函数重写
# ---------------------------------------------------------------------------
func _ready() -> void:
	# 大小固定为纸牌宽度；高度动态增长。
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_set_dynamic_height()


# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------
## 将一组纸牌追加到此列的顶部。
func add_cards(cards_array: Array[Card]) -> void:
	if cards_array.is_empty():
		return

	for card in cards_array:
		_disconnect_drag_signals(card)
		if not _cards.has(card):
			_cards.append(card)
		if card.get_parent() != null and card.get_parent() != self:
			card.get_parent().remove_child(card)
		if card.get_parent() != self:
			add_child(card)
		card.visible = true
		# 确保纸牌可以接收输入
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.card_drag_started.connect(_on_card_drag_started)
		card.card_drag_ended.connect(_on_card_drag_ended)

	_reposition_cards()
	cards_added.emit(cards_array.duplicate())


## 从此列移除并返回顶部 `count` 张纸牌。
## 如果 `flip_revealed` 为 false，则新暴露的顶部纸牌不会被翻为正面朝上。
func remove_cards(count: int, flip_revealed: bool = true) -> Array[Card]:
	if count <= 0 or count > _cards.size():
		return []

	var removed: Array[Card] = []
	for i in range(count):
		var card: Card = _cards.pop_back()
		_disconnect_drag_signals(card)
		remove_child(card)
		removed.append(card)

	# 如果新顶部纸牌存在且背面朝上，则将其翻为正面朝上
	last_revealed_card = null
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()
			last_revealed_card = top

	_reposition_cards()
	cards_removed.emit(removed.duplicate())
	return removed


## 返回此列中所有纸牌的浅拷贝（从底到顶）。
func get_cards() -> Array[Card]:
	return _cards.duplicate()


## 返回最顶部的纸牌，如果列为空则返回 null。
func get_top_card() -> Card:
	if _cards.is_empty():
		return null
	return _cards[_cards.size() - 1]


## 返回下一张要添加的纸牌应该放置的本地位置。
func get_next_card_position() -> Vector2:
	var overlaps := _get_compressed_overlaps()
	var current_y: float = 0.0
	for o in overlaps:
		current_y += o
	return Vector2(0, current_y)


## 返回此列顶部最长的可移动序列。
## 可移动序列必须点数递减且花色相同。
func get_movable_sequence() -> Array[Card]:
	if _cards.is_empty():
		return []

	var result: Array[Card] = [_cards[_cards.size() - 1]]
	for i in range(_cards.size() - 2, -1, -1):
		var current: Card = _cards[i]
		var next: Card = result[result.size() - 1]
		if current.face_up and current.suit == next.suit and next.rank == current.rank - 1:
			result.append(current)
		else:
			break

	# 反转使结果从上到下排列（与视觉堆叠顺序相同）
	result.reverse()
	return result


## 返回此列中纸牌的总数。
func get_card_count() -> int:
	return _cards.size()


## 如果此列为空则返回 true。
func is_empty() -> bool:
	return _cards.is_empty()


## 如果此列包含指定的纸牌则返回 true。
func has_card(card: Card) -> bool:
	return _cards.has(card)


## 移除特定的纸牌集合（用于拖拽子序列时）。
## 如果 `flip_revealed` 为 false，则新暴露的顶部纸牌不会被翻为正面朝上。
func remove_specific_cards(cards_to_remove: Array[Card], flip_revealed: bool = true) -> void:
	if cards_to_remove.is_empty():
		return

	for card in cards_to_remove:
		var idx: int = _cards.find(card)
		if idx != -1:
			_cards.remove_at(idx)
			_disconnect_drag_signals(card)
			remove_child(card)

	# 如果需要，翻开新的顶部纸牌
	last_revealed_card = null
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()
			last_revealed_card = top

	_reposition_cards()
	cards_removed.emit(cards_to_remove.duplicate())


# ---------------------------------------------------------------------------
# 内部布局
# ---------------------------------------------------------------------------
## 根据每张纸牌的索引和正面状态重新定位。
func _reposition_cards() -> void:
	var overlaps := _get_compressed_overlaps()
	if overlaps.size() < _cards.size():
		# 防御：间距计算异常时回退到固定间距，避免数组越界
		overlaps.resize(_cards.size())
		for i in range(_cards.size()):
			overlaps[i] = FACE_UP_OVERLAP if _cards[i].face_up else FACE_DOWN_OVERLAP
	var current_y: float = 0.0
	for i in range(_cards.size()):
		var card: Card = _cards[i]
		card.position = Vector2(0, current_y)
		card.z_index = i
		current_y += overlaps[i]

	_set_dynamic_height(overlaps)


## 计算原始间距数组（未压缩）。
func _get_raw_overlaps() -> Array[int]:
	var overlaps: Array[int] = []
	for card in _cards:
		overlaps.append(FACE_UP_OVERLAP if card.face_up else FACE_DOWN_OVERLAP)
	return overlaps


## 根据实际可用空间计算压缩后的间距。
## 动态参考当前视口高度，避免窗口变大后仍按固定小高度压缩。
## 背面朝上的纸牌压缩为固定小间距（保留可见边缘以便判断数量）；
## 正面朝上的纸牌分配剩余空间，若仍不足则再按比例压缩。
func _get_compressed_overlaps() -> Array[float]:
	var overlaps: Array[int] = _get_raw_overlaps()
	if overlaps.is_empty():
		return []

	var effective_max := _get_effective_max_height()
	if effective_max <= 0:
		return []

	# 计算当前视觉高度（n 张牌只需 n-1 个有效间距 + CARD_HEIGHT）
	var visual_height := float(CARD_HEIGHT)
	for i in range(overlaps.size() - 1):
		visual_height += overlaps[i]

	if visual_height <= effective_max:
		return overlaps.map(func(o): return float(o)) as Array[float]

	# 非等比例压缩策略
	const MIN_FACE_DOWN := 12.0  # 背面牌最小间距，保留边缘可见以便数牌 / Keep edges visible to count cards
	const MIN_FACE_UP := 24.0    # 正面牌最小保留可见高度，保证可辨认 / Face-up cards need enough visible height

	var face_up_count := 0
	var face_down_count := 0
	for card in _cards:
		if card.face_up:
			face_up_count += 1
		else:
			face_down_count += 1

	# 背面牌分配固定最小间距
	var reserved_for_face_down := face_down_count * MIN_FACE_DOWN

	# 正面牌分配剩余空间
	var remaining := effective_max - CARD_HEIGHT - reserved_for_face_down
	var face_up_overlap := MIN_FACE_UP
	if face_up_count > 0:
		face_up_overlap = remaining / face_up_count
		if face_up_overlap < MIN_FACE_UP:
			# 空间不足，等比例压缩正面牌（但不小于绝对最小值）
			var scale := remaining / (face_up_count * MIN_FACE_UP)
			if scale < 0.05:
				scale = 0.05
			face_up_overlap = MIN_FACE_UP * scale

	var result: Array[float] = []
	for card in _cards:
		if card.face_up:
			result.append(face_up_overlap)
		else:
			result.append(MIN_FACE_DOWN)

	return result


## 动态计算当前列实际可用的最大高度。
## 综合考虑 Board 传入的预设值与当前视口剩余空间。
func _get_effective_max_height() -> float:
	var effective := max_column_height

	var viewport := get_viewport()
	if viewport != null:
		var viewport_height := viewport.get_visible_rect().size.y
		var available := viewport_height - global_position.y - 20.0
		available = max(available, 200.0)  # 至少保留 200px，避免过度压缩
		if effective > 0:
			effective = max(effective, available)
		else:
			effective = available

	return effective


## 调整列的最小大小以适应所有堆叠的纸牌。
func _set_dynamic_height(overlaps: Array[float] = []) -> void:
	if _cards.is_empty():
		custom_minimum_size.y = CARD_HEIGHT
	else:
		if overlaps.is_empty():
			overlaps = _get_compressed_overlaps()
		var total_y: float = 0.0
		# n 张牌只需要 n-1 个间距来决定高度，最后一张牌的 overlap 留给下一张预测用
		for i in range(overlaps.size() - 1):
			total_y += overlaps[i]
		custom_minimum_size.y = total_y + CARD_HEIGHT


func _on_card_drag_started(card: Card) -> void:
	DragSystem.start_drag(self, card)


func _on_card_drag_ended(_card: Card) -> void:
	DragSystem.end_drag()


## 移除任何现有的拖拽信号连接，以便移动的纸牌始终向其当前列报告。
func _disconnect_drag_signals(card: Card) -> void:
	var my_drag_started := _on_card_drag_started
	var my_drag_ended := _on_card_drag_ended
	if card.card_drag_started.is_connected(my_drag_started):
		card.card_drag_started.disconnect(my_drag_started)
	if card.card_drag_ended.is_connected(my_drag_ended):
		card.card_drag_ended.disconnect(my_drag_ended)


func _draw() -> void:
	if is_highlighted:
		var rect := Rect2(Vector2.ZERO, size)
		# 高饱和度金色填充（提示效果更明显）
		draw_rect(rect, Color(1.0, 0.85, 0.0, 0.30))
		# 金色边框
		draw_rect(rect, Color(1.0, 0.95, 0.2, 0.90), false, 3.5)
	elif _cards.is_empty():
		_draw_empty_placeholder()


## 在空列底部绘制占位矩形边框，提示此处可以放置纸牌。
func _draw_empty_placeholder() -> void:
	var padding := 4.0
	var rect := Rect2(Vector2(padding, padding), Vector2(CARD_WIDTH - padding * 2, CARD_HEIGHT - padding * 2))
	# 半透明填充
	draw_rect(rect, Color(0.9, 0.9, 0.9, 0.06))
	# 虚线风格边框：使用浅灰色短线段
	var dash_len := 8.0
	var gap_len := 4.0
	var line_width := 2.0
	var color := Color(0.85, 0.85, 0.85, 0.40)
	Drawing.draw_dash_line(self, Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y), dash_len, gap_len, color, line_width)
	Drawing.draw_dash_line(self, Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y), dash_len, gap_len, color, line_width)
	Drawing.draw_dash_line(self, Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.position.y + rect.size.y), dash_len, gap_len, color, line_width)
	Drawing.draw_dash_line(self, Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y), dash_len, gap_len, color, line_width)


