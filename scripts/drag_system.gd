extends Node

## Singleton/Autoload for handling card drag-and-drop across the board.

signal drag_started(cards)
signal drag_ended(success: bool, target_column: Column)
signal invalid_move_attempted

const DRAG_LAYER: int = 100

var _board: Board = null
var _drag_container: CanvasLayer
var _dragged_cards: Array[Card] = []
var _source_column: Column = null
var _original_positions: Array[Vector2] = []
var _drag_offset: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _touch_pos: Vector2 = Vector2.ZERO
var _using_touch: bool = false


func _ready() -> void:
	_drag_container = CanvasLayer.new()
	_drag_container.layer = DRAG_LAYER
	add_child(_drag_container)


## Registers the active game board so the drag system can query columns and execute moves.
func register_board(board: Board) -> void:
	_board = board


## Forces an immediate end to any active drag without animation. Used when resetting the board.
func force_end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	for card in _dragged_cards:
		if is_instance_valid(card):
			if card.get_parent() == _drag_container:
				_drag_container.remove_child(card)
			if is_instance_valid(_source_column):
				_source_column.add_child(card)
			else:
				card.queue_free()
	_cleanup_drag()


## Begins dragging the movable sequence that contains `card` from `source_column`.
func start_drag(source_column: Column, card: Card) -> void:
	if _is_dragging:
		return
	if _board == null:
		return
	if not GameState.is_game_active:
		return

	var movable = source_column.get_movable_sequence()
	if movable.is_empty() or not card in movable:
		return

	_source_column = source_column
	_dragged_cards = movable.duplicate()
	_original_positions.clear()

	var input_pos := _get_input_position()
	_drag_offset = card.global_position - input_pos

	for i in range(_dragged_cards.size()):
		var c: Card = _dragged_cards[i]
		_original_positions.append(c.position)
		var global_pos := c.global_position
		c.get_parent().remove_child(c)
		_drag_container.add_child(c)
		c.global_position = global_pos
		c.z_index = DRAG_LAYER + i

	_is_dragging = true
	drag_started.emit(_dragged_cards.duplicate())


## Ends the current drag, validates the drop, and either commits the move or animates back.
func end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false

	var drop_pos := _get_input_position()
	var target_column := _detect_column_at_position(drop_pos)
	var success := false

	# Reparent back to source so Board methods work correctly.
	_reparent_to_source_immediate()

	if target_column != null and target_column != _source_column:
		var target_cards = target_column.get_cards()
		var moving_data := _cards_to_data(_dragged_cards)
		var target_data := _cards_to_data(target_cards)

		if RulesEngine.is_valid_move(moving_data, target_data):
			var from_idx: int = _board.columns.find(_source_column)
			var to_idx: int = _board.columns.find(target_column)
			if from_idx != -1 and to_idx != -1:
				success = _board.move_card_sequence(from_idx, to_idx, _dragged_cards)

	if success:
		_cleanup_drag()
		drag_ended.emit(true, target_column)
	else:
		invalid_move_attempted.emit()
		_animate_to_original()


func _process(_delta: float) -> void:
	if _is_dragging:
		var pos := _get_input_position()
		var base_pos := pos + _drag_offset
		for i in range(_dragged_cards.size()):
			var card: Card = _dragged_cards[i]
			card.global_position = base_pos + Vector2(0, i * Column.FACE_UP_OVERLAP)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _is_dragging:
				end_drag()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_pos = touch.position
			_using_touch = true
		else:
			if _is_dragging:
				end_drag()
			_using_touch = false
	elif event is InputEventScreenDrag:
		_touch_pos = event.position
		_using_touch = true
	elif event is InputEventMouseMotion:
		_using_touch = false


func _get_input_position() -> Vector2:
	if _using_touch:
		return _touch_pos
	return get_viewport().get_mouse_position()


## Raycasts for a Column Area2D under the given position.
func _detect_column_at_position(pos: Vector2) -> Column:
	if _board == null:
		return null

	var space_state := get_viewport().world_2d.direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 2  # Columns are on layer 2
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results := space_state.intersect_point(query, 1)
	if results.is_empty():
		return null

	var collider: Area2D = results[0].collider
	if collider == null:
		return null

	var parent := collider.get_parent()
	if parent is Column:
		return parent

	return null


## Reparents dragged cards back to the source column without animation.
func _reparent_to_source_immediate() -> void:
	if not is_instance_valid(_source_column):
		return
	for i in range(_dragged_cards.size()):
		var card: Card = _dragged_cards[i]
		if card.get_parent() == _drag_container:
			var gpos := card.global_position
			_drag_container.remove_child(card)
			_source_column.add_child(card)
			card.global_position = gpos


## Animates cards back to their original positions within the source column.
func _animate_to_original() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for i in range(_dragged_cards.size()):
		var card: Card = _dragged_cards[i]
		tween.tween_property(card, "position", _original_positions[i], 0.25) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUAD)

	await tween.finished
	if is_instance_valid(_source_column):
		_source_column._reposition_cards()
	_cleanup_drag()
	drag_ended.emit(false, null)


func _cleanup_drag() -> void:
	# Note: z_index is managed by Column._reposition_cards(), do not reset it here.
	_dragged_cards.clear()
	_original_positions.clear()
	_source_column = null
	_drag_offset = Vector2.ZERO
	_using_touch = false


func _cards_to_data(cards: Array[Card]) -> Array[RulesEngine.CardData]:
	var result: Array[RulesEngine.CardData] = []
	for card in cards:
		result.append(RulesEngine.CardData.new(card.suit, card.rank))
	return result
