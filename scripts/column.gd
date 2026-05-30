class_name Column
extends Control

## Emitted after new cards are added to this column.
signal cards_added(added)
## Emitted after cards are removed from this column.
signal cards_removed(removed)

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------
const CARD_WIDTH: int = 100
const CARD_HEIGHT: int = 140
const FACE_UP_OVERLAP: int = 56   # ~60% overlap → 40% visible = 56 px
const FACE_DOWN_OVERLAP: int = 20 # Face-down cards overlap more (less visible)

# ---------------------------------------------------------------------------
# Column state
# ---------------------------------------------------------------------------
## The cards currently in this column, ordered bottom-to-top.
var _cards: Array[Card] = []

## Area2D used for drop-target detection.
var drop_area: Area2D

# ---------------------------------------------------------------------------
# Built-in overrides
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Size is fixed to card width; height grows dynamically.
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	drop_area = $DropArea
	_update_drop_area()
	_set_dynamic_height()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
## Appends an array of cards to the top of this column.
func add_cards(cards_array: Array[Card]) -> void:
	if cards_array.is_empty():
		return

	for card in cards_array:
		_disconnect_drag_signals(card)
		_cards.append(card)
		add_child(card)
		# Ensure the card can receive input
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.card_drag_started.connect(_on_card_drag_started)
		card.card_drag_ended.connect(_on_card_drag_ended)

	_reposition_cards()
	cards_added.emit(cards_array.duplicate())


## Removes and returns the top `count` cards from this column.
## If `flip_revealed` is false, the newly exposed top card will not be flipped face-up.
func remove_cards(count: int, flip_revealed: bool = true) -> Array[Card]:
	if count <= 0 or count > _cards.size():
		return []

	var removed: Array[Card] = []
	for i in range(count):
		var card: Card = _cards.pop_back()
		_disconnect_drag_signals(card)
		remove_child(card)
		removed.append(card)

	# Flip the new top card face-up if it exists and is face-down
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()

	_reposition_cards()
	cards_removed.emit(removed.duplicate())
	return removed


## Returns a shallow copy of all cards in this column (bottom-to-top).
func get_cards() -> Array[Card]:
	return _cards.duplicate()


## Returns the top-most card, or null if the column is empty.
func get_top_card() -> Card:
	if _cards.is_empty():
		return null
	return _cards[_cards.size() - 1]


## Returns the longest movable sequence from the top of this column.
## A movable sequence must be descending in rank and all the same suit.
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

	# Reverse so the result is top-to-bottom (same order as visual stacking)
	result.reverse()
	return result


## Returns the total number of cards in this column.
func get_card_count() -> int:
	return _cards.size()


## Returns true if this column is empty.
func is_empty() -> bool:
	return _cards.is_empty()


## Removes a specific set of cards (used when dragging a sub-sequence).
## If `flip_revealed` is false, the newly exposed top card will not be flipped face-up.
func remove_specific_cards(cards_to_remove: Array[Card], flip_revealed: bool = true) -> void:
	if cards_to_remove.is_empty():
		return

	for card in cards_to_remove:
		var idx: int = _cards.find(card)
		if idx != -1:
			_cards.remove_at(idx)
			_disconnect_drag_signals(card)
			remove_child(card)

	# Flip new top card if needed
	if flip_revealed and not _cards.is_empty():
		var top: Card = _cards[_cards.size() - 1]
		if not top.face_up:
			top.flip()

	_reposition_cards()
	cards_removed.emit(cards_to_remove.duplicate())


# ---------------------------------------------------------------------------
# Internal layout
# ---------------------------------------------------------------------------
## Repositions every card based on its index and face-up state.
func _reposition_cards() -> void:
	var current_y: float = 0.0
	for i in range(_cards.size()):
		var card: Card = _cards[i]
		card.position = Vector2(0, current_y)
		card.z_index = i

		var overlap: int = FACE_UP_OVERLAP if card.face_up else FACE_DOWN_OVERLAP
		current_y += overlap

	_set_dynamic_height()


## Adjusts the column's minimum size so it can fit all stacked cards.
func _set_dynamic_height() -> void:
	if _cards.is_empty():
		custom_minimum_size.y = CARD_HEIGHT
	else:
		var total_overlap := 0
		for card in _cards:
			total_overlap += FACE_UP_OVERLAP if card.face_up else FACE_DOWN_OVERLAP

		# The last card contributes its full height, not just the overlap
		custom_minimum_size.y = float(total_overlap - (FACE_UP_OVERLAP if _cards[_cards.size() - 1].face_up else FACE_DOWN_OVERLAP) + CARD_HEIGHT)
	_update_drop_area()



## Resizes the Area2D collision shape to match the column's current height.
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


## Removes any existing drag signal connections so moved cards always report to their current column.
func _disconnect_drag_signals(card: Card) -> void:
	var my_drag_started := _on_card_drag_started
	var my_drag_ended := _on_card_drag_ended
	if card.card_drag_started.is_connected(my_drag_started):
		card.card_drag_started.disconnect(my_drag_started)
	if card.card_drag_ended.is_connected(my_drag_ended):
		card.card_drag_ended.disconnect(my_drag_ended)
