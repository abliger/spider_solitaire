extends Node

## 单例 / 自动加载，用于处理整个面板的纸牌拖拽。

signal drag_started(cards)
signal drag_ended(success: bool, target_column: Column)
signal invalid_move_attempted

const DRAG_LAYER: int = 100

var _board: Board = null
var _drag_container: Control
var _dragged_cards: Array[Card] = []
var _source_column: Column = null
var _original_positions: Array[Vector2] = []
var _drag_offset: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _is_ending_drag: bool = false
var _touch_pos: Vector2 = Vector2.ZERO
var _using_touch: bool = false
var _return_tween: Tween = null


func _ready() -> void:
	_drag_container = Control.new()
	_drag_container.name = "DragContainer"
	_drag_container.z_index = DRAG_LAYER
	_drag_container.top_level = true
	_drag_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drag_container)


## 注册活跃的游戏面板，以便拖拽系统可以查询列并执行移动。
func register_board(board: Board) -> void:
	_board = board


## 强制立即结束任何活跃的拖拽（无动画）。重置面板时使用。
func force_end_drag() -> void:
	# 终止可能正在运行的返回动画 tween
	if _return_tween != null:
		_return_tween.kill()
		_return_tween = null

	# 如果没有正在拖拽且没有残留的返回动画牌，直接返回
	if not _is_dragging and _dragged_cards.is_empty():
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
	if is_instance_valid(_source_column):
		_source_column._reposition_cards()
	_cleanup_drag()


## 开始拖拽 `source_column` 中包含 `card` 的可移动序列。
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

	# 只移动从点击的牌开始到顶部的子序列，而不是整串可移动牌。
	# 例如 movable = [K, Q, J]，点击 Q 则只移动 [Q, J]。
	var card_index := movable.find(card)
	if card_index == -1:
		return

	_source_column = source_column
	_dragged_cards = movable.slice(card_index, movable.size())
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


## 结束当前拖拽，验证放置，然后提交移动或播放返回动画。
func end_drag() -> void:
	if not _is_dragging or _is_ending_drag:
		return
	_is_ending_drag = true
	_is_dragging = false

	var drop_pos := _get_input_position()
	var target_column := _detect_column_at_position(drop_pos)
	var success := false

	# 重新父级到源列，以便 Board 方法正常工作。
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
		_is_ending_drag = false
		drag_ended.emit(true, target_column)
	else:
		invalid_move_attempted.emit()
		await _animate_to_original()
		_is_ending_drag = false


func _process(_delta: float) -> void:
	if _is_dragging:
		var pos := _get_input_position()
		var base_pos := pos + _drag_offset
		for i in range(_dragged_cards.size()):
			var card: Card = _dragged_cards[i]
			card.global_position = base_pos + Vector2(0, i * Column.FACE_UP_OVERLAP)
	elif not _dragged_cards.is_empty() and not _is_ending_drag and _return_tween == null:
		# 防御：鼠标已释放但仍有残留牌在拖拽容器中，自动放回原位
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_is_ending_drag = true
			await _animate_to_original()
			_is_ending_drag = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _is_dragging:
				end_drag()
			elif not _dragged_cards.is_empty() and not _is_ending_drag and _return_tween == null:
				# 防御：鼠标已释放但仍有残留牌在拖拽容器中，自动放回原位
				_is_ending_drag = true
				await _animate_to_original()
				_is_ending_drag = false
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_pos = touch.position
			_using_touch = true
		else:
			if _is_dragging:
				end_drag()
			elif not _dragged_cards.is_empty() and not _is_ending_drag and _return_tween == null:
				_is_ending_drag = true
				await _animate_to_original()
				_is_ending_drag = false
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


## 在给定位置下进行射线检测以查找 Column Area2D。
func _detect_column_at_position(pos: Vector2) -> Column:
	if _board == null:
		return null

	var space_state := get_viewport().world_2d.direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	# 将视口坐标转换为世界坐标，以兼容 Camera2D
	var camera := get_viewport().get_camera_2d()
	if camera:
		query.position = camera.get_canvas_transform().affine_inverse() * pos
	else:
		query.position = pos
	query.collision_mask = 2  # Columns are on layer 2
	# 列位于碰撞层 2
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


## 将拖拽的纸牌无动画地重新父级到源列。
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


## 将纸牌动画回到源列中的原始位置。
func _animate_to_original() -> void:
	if _dragged_cards.is_empty():
		_cleanup_drag()
		drag_ended.emit(false, null)
		return

	# 确保所有牌都已回到源列，防止因异步中断导致牌仍留在 _drag_container
	_reparent_to_source_immediate()

	_return_tween = create_tween()
	_return_tween.set_parallel(true)
	for i in range(_dragged_cards.size()):
		var card: Card = _dragged_cards[i]
		# 使用全局坐标做动画，避免父节点变化导致坐标混乱
		var target_global := _source_column.global_position + _original_positions[i]
		_return_tween.tween_property(card, "global_position", target_global, 0.25) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUAD)

	await _return_tween.finished
	_return_tween = null
	if is_instance_valid(_source_column):
		_source_column._reposition_cards()
	_cleanup_drag()
	drag_ended.emit(false, null)


func _cleanup_drag() -> void:
	# 注意：z_index 由 Column._reposition_cards() 管理，不要在这里重置。
	_dragged_cards.clear()
	_original_positions.clear()
	_source_column = null
	_drag_offset = Vector2.ZERO
	_using_touch = false


func _cards_to_data(cards: Array[Card]) -> Array[RulesEngine.CardData]:
	var result: Array[RulesEngine.CardData] = []
	for card in cards:
		var data := RulesEngine.CardData.new(card.suit, card.rank)
		data.face_up = card.face_up
		result.append(data)
	return result
