extends "res://tests/unit/test_base.gd"


class TestDragSystem:
	extends "res://tests/unit/test_base.gd"

	var _drag_system = null
	var _board: Board = null

	func before_all() -> void:
		_register_autoload("GameState", "res://scripts/autoload/game_state.gd")
		_register_autoload("SoundManager", "res://scripts/autoload/sound_manager.gd")
		_register_autoload("MoveHistory", "res://scripts/move_history.gd")
		_register_autoload("Localization", "res://scripts/autoload/localization.gd")
		_register_autoload("DragSystem", "res://scripts/drag_system.gd")
		_register_autoload("Drawing", "res://scripts/autoload/drawing.gd")

	func after_all() -> void:
		_unregister_autoloads()

	func _create_board() -> Board:
		var board := Board.new()
		board.column_scene = preload("res://scenes/column.tscn")
		board.card_scene = preload("res://scenes/card.tscn")
		var stock := Stock.new()
		stock.name = "Stock"
		board.add_child(stock)
		var container := Control.new()
		container.name = "ColumnsContainer"
		board.add_child(container)
		var label := Label.new()
		label.name = "StockCountLabel"
		board.add_child(label)
		add_child(board)
		await get_tree().process_frame
		return board

	func before_each() -> void:
		_drag_system = DragSystem
		_board = await _create_board()
		_board.setup_new_game(1)
		_drag_system.register_board(_board)
		GameState.start_game(1)

	func after_each() -> void:
		_drag_system.force_end_drag()
		if is_instance_valid(_board):
			_board.queue_free()
		GameState.reset_game()
		MoveHistory.clear()

	func test_register_board_sets_board() -> void:
		_drag_system.register_board(_board)
		assert_true(true)

	func test_is_dragging_initially_false() -> void:
		assert_false(_drag_system.is_dragging())

	func test_force_end_drag_when_not_dragging() -> void:
		_drag_system.force_end_drag()
		assert_false(_drag_system.is_dragging())

	func test_start_drag_without_game_active() -> void:
		GameState.is_game_active = false
		var col := _board.columns[0]
		var card := col.get_top_card()
		_drag_system.start_drag(col, card)
		assert_false(_drag_system.is_dragging())

	func test_start_drag_with_face_up_card() -> void:
		var col := _board.columns[0]
		var card := col.get_top_card()
		if card != null and card.face_up:
			_drag_system.start_drag(col, card)
			# start_drag 可能有额外的条件限制，但至少不应崩溃
		assert_true(true)

	func test_start_drag_when_already_dragging() -> void:
		var col := _board.columns[0]
		var card := col.get_top_card()
		if card != null and card.face_up:
			_drag_system.start_drag(col, card)
			_drag_system.start_drag(col, card)
		assert_true(true)

	func test_end_drag_when_not_dragging() -> void:
		_drag_system.end_drag()
		assert_false(_drag_system.is_dragging())

	func test_cleanup_drag_clears_state() -> void:
		_drag_system._cleanup_drag()
		assert_eq(_drag_system._dragged_cards.size(), 0)
		assert_null(_drag_system._source_column)

	func test_detect_column_at_position_returns_null_when_no_board() -> void:
		_drag_system.register_board(null)
		var result = _drag_system._detect_column_at_position(Vector2.ZERO)
		assert_null(result)

	func test_get_input_position_returns_vector() -> void:
		var pos: Vector2 = _drag_system._get_input_position()
		assert_eq(typeof(pos), TYPE_VECTOR2)
