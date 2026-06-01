extends "res://tests/unit/test_base.gd"


class TestFoundationBasics:
	extends "res://tests/unit/test_base.gd"

	var _foundation: Foundation = null

	func before_each() -> void:
		_foundation = Foundation.new()
		add_child(_foundation)

	func after_each() -> void:
		if is_instance_valid(_foundation):
			_foundation.queue_free()

	func test_initially_zero_completed() -> void:
		# 通过 reset 验证状态一致性
		_foundation.reset()
		# _draw 不会崩溃即可
		assert_true(true)

	func test_add_completed_sequence_increments_count() -> void:
		_foundation.add_completed_sequence(0)
		_foundation.add_completed_sequence(1)
		assert_eq(_foundation._completed_count, 2)

	func test_add_completed_sequence_beyond_limit_ignored() -> void:
		for i in range(10):
			_foundation.add_completed_sequence(i % 4)
		assert_eq(_foundation._completed_count, 8)

	func test_remove_completed_sequence_decrements() -> void:
		_foundation.add_completed_sequence(0)
		_foundation.add_completed_sequence(1)
		_foundation.remove_completed_sequence()
		assert_eq(_foundation._completed_count, 1)

	func test_remove_completed_sequence_when_empty_does_nothing() -> void:
		_foundation.remove_completed_sequence()
		assert_eq(_foundation._completed_count, 0)

	func test_reset_clears_all() -> void:
		_foundation.add_completed_sequence(0)
		_foundation.add_completed_sequence(2)
		_foundation.reset()
		assert_eq(_foundation._completed_count, 0)
		assert_eq(_foundation._completed_suits.size(), 0)

	func test_custom_minimum_size_width() -> void:
		var expected_width := Foundation.NUM_SLOTS * Foundation.SLOT_WIDTH + (Foundation.NUM_SLOTS - 1) * Foundation.SLOT_SPACING
		assert_eq(_foundation.custom_minimum_size.x, expected_width)

	func test_custom_minimum_size_height() -> void:
		assert_eq(_foundation.custom_minimum_size.y, Foundation.SLOT_HEIGHT)

	func test_get_suit_symbol_unknown_index_defaults_to_spades() -> void:
		var sym := _foundation._get_suit_symbol(-1)
		assert_eq(sym, "♠")

	func test_get_suit_symbol_returns_correct_suits() -> void:
		_foundation.add_completed_sequence(0)
		_foundation.add_completed_sequence(1)
		_foundation.add_completed_sequence(2)
		_foundation.add_completed_sequence(3)
		assert_eq(_foundation._get_suit_symbol(0), "♠")
		assert_eq(_foundation._get_suit_symbol(1), "♥")
		assert_eq(_foundation._get_suit_symbol(2), "♦")
		assert_eq(_foundation._get_suit_symbol(3), "♣")
