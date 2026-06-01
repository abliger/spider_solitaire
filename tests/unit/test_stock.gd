extends "res://tests/unit/test_base.gd"


class TestStockBasics:
	extends "res://tests/unit/test_base.gd"

	var _stock: Stock = null

	func before_each() -> void:
		_stock = Stock.new()
		add_child(_stock)

	func after_each() -> void:
		if is_instance_valid(_stock):
			_stock.queue_free()

	func test_initially_empty() -> void:
		assert_true(_stock.is_empty())

	func test_set_remaining_updates_count() -> void:
		_stock.set_remaining(5)
		assert_false(_stock.is_empty())

	func test_set_remaining_zero_becomes_empty() -> void:
		_stock.set_remaining(0)
		assert_true(_stock.is_empty())

	func test_set_remaining_negative_becomes_empty() -> void:
		_stock.set_remaining(-1)
		assert_true(_stock.is_empty())

	func test_deal_requested_signal() -> void:
		watch_signals(_stock)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		_stock._gui_input(event)
		assert_signal_emitted(_stock, "deal_requested")

	func test_custom_minimum_size_is_set() -> void:
		assert_eq(_stock.custom_minimum_size, Vector2(100, 140))

	func test_size_is_set() -> void:
		assert_eq(_stock.size, Vector2(100, 140))
