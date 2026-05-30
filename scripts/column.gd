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

## 用于放置目标检测的 Area2D。
var drop_area: Area2D

# ---------------------------------------------------------------------------
# 内置函数重写
# ---------------------------------------------------------------------------
func _ready() -> void:
	# 大小固定为纸牌宽度；高度动态增长。
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	drop_area = $DropArea
	_update_drop_area()
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
		_cards.append(card)
		add_child(card)
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
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()

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
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()

	_reposition_cards()
	cards_removed.emit(cards_to_remove.duplicate())


# ---------------------------------------------------------------------------
# 内部布局
# ---------------------------------------------------------------------------
## 根据每张纸牌的索引和正面状态重新定位。
func _reposition_cards() -> void:
	var current_y: float = 0.0
	for i in range(_cards.size()):
		var card: Card = _cards[i]
		card.position = Vector2(0, current_y)
		card.z_index = i

		var overlap: int = FACE_UP_OVERLAP if card.face_up else FACE_DOWN_OVERLAP
		current_y += overlap

	_set_dynamic_height()


## 调整列的最小大小以适应所有堆叠的纸牌。
func _set_dynamic_height() -> void:
	if _cards.is_empty():
		custom_minimum_size.y = CARD_HEIGHT
	else:
		var total_overlap := 0
		for card in _cards:
			total_overlap += FACE_UP_OVERLAP if card.face_up else FACE_DOWN_OVERLAP

		# 最后一张纸牌贡献其完整高度，而不仅仅是重叠部分
		custom_minimum_size.y = float(total_overlap - (FACE_UP_OVERLAP if _cards[_cards.size() - 1].face_up else FACE_DOWN_OVERLAP) + CARD_HEIGHT)
	_update_drop_area()



## 调整 Area2D 碰撞形状的大小以匹配列的当前高度。
func _update_drop_area() -> void:
	if drop_area == null:
		return
	var shape_node: CollisionShape2D = drop_area.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		return
	var shape: RectangleShape2D = shape_node.shape
	if shape == null:
		return
	shape.size = Vector2(CARD_WIDTH, custom_minimum_size.y)
	shape_node.position = Vector2(CARD_WIDTH / 2.0, custom_minimum_size.y / 2.0)


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
