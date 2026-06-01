extends "res://tests/unit/test_base.gd"


class TestMoveHistory:
	extends "res://tests/unit/test_base.gd"

	var _history = null

	func before_each() -> void:
		# MoveHistory 是一个 Node 脚本，没有 class_name
		var script: GDScript = load("res://scripts/move_history.gd") as GDScript
		_history = Node.new()
		_history.set_script(script)
		add_child(_history)

	func after_each() -> void:
		if is_instance_valid(_history):
			_history.queue_free()

	func test_record_move_returns_record() -> void:
		var record = _history.record_move(0, 1, [], false, 0, 0)
		assert_is(record, load("res://scripts/move_history.gd").MoveRecord)

	func test_can_undo_after_record() -> void:
		assert_false(_history.can_undo())
		_history.record_move(0, 1, [], false, 0, 0)
		assert_true(_history.can_undo())

	func test_undo_last_move_returns_last_record() -> void:
		var r1 = _history.record_move(0, 1, [1], false, 0, 0)
		var r2 = _history.record_move(2, 3, [2], true, 1, 100)
		var undone = _history.undo_last_move()
		assert_eq(undone, r2)

	func test_undo_last_move_empty_returns_null() -> void:
		assert_null(_history.undo_last_move())

	func test_clear_empties_history() -> void:
		_history.record_move(0, 1, [], false, 0, 0)
		_history.clear()
		assert_false(_history.can_undo())
		assert_eq(_history.get_history_count(), 0)

	func test_get_history_count() -> void:
		assert_eq(_history.get_history_count(), 0)
		_history.record_move(0, 1, [], false, 0, 0)
		assert_eq(_history.get_history_count(), 1)
		_history.record_move(2, 3, [], false, 0, 0)
		assert_eq(_history.get_history_count(), 2)

	func test_update_last_record_modifies_record() -> void:
		var record = _history.record_move(0, 1, [], false, 0, 0)
		_history.update_last_record(true, 2, 200)
		assert_eq(record.flipped_card, true)
		assert_eq(record.sequences_completed, 2)
		assert_eq(record.score_delta, 200)

	func test_update_last_record_when_empty_does_not_crash() -> void:
		_history.update_last_record(true, 1, 100)
		assert_true(true)

	func test_record_cards_are_duplicated() -> void:
		var cards = [1, 2, 3]
		var record = _history.record_move(0, 1, cards, false, 0, 0)
		cards.append(4)
		assert_eq(record.cards_moved.size(), 3)
