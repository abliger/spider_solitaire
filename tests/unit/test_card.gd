extends "res://tests/unit/test_base.gd"


class TestCardProperties:
	extends "res://tests/unit/test_base.gd"

	var _card: Card = null

	func before_each() -> void:
		_card = Card.new()
		add_child(_card)

	func after_each() -> void:
		if is_instance_valid(_card):
			_card.queue_free()

	func test_default_suit_is_spades() -> void:
		assert_eq(_card.suit, 0)

	func test_default_rank_is_ace() -> void:
		assert_eq(_card.rank, 1)

	func test_default_face_up_is_false() -> void:
		assert_false(_card.face_up)

	func test_set_card_data_updates_suit_and_rank() -> void:
		_card.set_card_data(2, 10)
		assert_eq(_card.suit, 2)
		assert_eq(_card.rank, 10)

	func test_flip_toggles_face_up() -> void:
		assert_false(_card.face_up)
		_card.flip()
		assert_true(_card.face_up)
		_card.flip()
		assert_false(_card.face_up)

	func test_set_highlight_updates_flag() -> void:
		assert_false(_card.is_highlighted)
		_card.set_highlight(true)
		assert_true(_card.is_highlighted)
		_card.set_highlight(false)
		assert_false(_card.is_highlighted)

	func test_get_rank_string_ace() -> void:
		_card.rank = 1
		assert_eq(_card.get_rank_string(), "A")

	func test_get_rank_string_number() -> void:
		_card.rank = 7
		assert_eq(_card.get_rank_string(), "7")

	func test_get_rank_string_face_cards() -> void:
		_card.rank = 11
		assert_eq(_card.get_rank_string(), "J")
		_card.rank = 12
		assert_eq(_card.get_rank_string(), "Q")
		_card.rank = 13
		assert_eq(_card.get_rank_string(), "K")

	func test_get_suit_symbol_all_suits() -> void:
		_card.suit = 0
		assert_eq(_card.get_suit_symbol(), "♠")
		_card.suit = 1
		assert_eq(_card.get_suit_symbol(), "♥")
		_card.suit = 2
		assert_eq(_card.get_suit_symbol(), "♦")
		_card.suit = 3
		assert_eq(_card.get_suit_symbol(), "♣")

	func test_is_red_for_hearts_and_diamonds() -> void:
		_card.suit = 1
		assert_true(_card.is_red())
		_card.suit = 2
		assert_true(_card.is_red())

	func test_is_red_false_for_spades_and_clubs() -> void:
		_card.suit = 0
		assert_false(_card.is_red())
		_card.suit = 3
		assert_false(_card.is_red())

	func test_custom_minimum_size_is_set() -> void:
		assert_eq(_card.custom_minimum_size, Vector2(100, 140))

	func test_size_is_set() -> void:
		assert_eq(_card.size, Vector2(100, 140))


class TestCardSignals:
	extends "res://tests/unit/test_base.gd"

	var _card: Card = null

	func before_each() -> void:
		_card = Card.new()
		add_child(_card)

	func after_each() -> void:
		if is_instance_valid(_card):
			_card.queue_free()

	func test_card_clicked_signal_emitted() -> void:
		watch_signals(_card)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		_card._gui_input(event)
		assert_signal_emitted(_card, "card_clicked")

	func test_card_drag_started_signal_emitted() -> void:
		watch_signals(_card)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		_card._gui_input(event)
		assert_signal_emitted(_card, "card_drag_started")

	func test_card_drag_ended_signal_emitted() -> void:
		watch_signals(_card)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		_card._gui_input(press)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		_card._gui_input(release)
		assert_signal_emitted(_card, "card_drag_ended")

	func test_double_click_does_not_emit_drag() -> void:
		watch_signals(_card)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.double_click = true
		_card._gui_input(event)
		assert_signal_not_emitted(_card, "card_drag_started")
