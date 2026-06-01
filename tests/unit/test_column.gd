extends "res://tests/unit/test_base.gd"


class TestColumnBasics:
	extends "res://tests/unit/test_base.gd"

	var _col: Column = null

	func before_each() -> void:
		_col = Column.new()
		add_child(_col)

	func after_each() -> void:
		if is_instance_valid(_col):
			_col.queue_free()

	func test_initially_empty() -> void:
		assert_true(_col.is_empty())
		assert_eq(_col.get_card_count(), 0)

	func test_add_single_card() -> void:
		var card := Card.new()
		_col.add_cards([card])
		assert_eq(_col.get_card_count(), 1)
		assert_false(_col.is_empty())
		card.queue_free()

	func test_add_multiple_cards() -> void:
		var cards: Array[Card] = []
		for i in range(3):
			var c := Card.new()
			cards.append(c)
		_col.add_cards(cards)
		assert_eq(_col.get_card_count(), 3)
		for c in cards:
			c.queue_free()

	func test_get_cards_returns_copy() -> void:
		var card := Card.new()
		_col.add_cards([card])
		var copy := _col.get_cards()
		assert_eq(copy.size(), 1)
		assert_eq(copy[0], card)
		card.queue_free()

	func test_get_top_card_returns_top() -> void:
		var c1 := Card.new()
		var c2 := Card.new()
		c1.rank = 5
		c2.rank = 3
		_col.add_cards([c1, c2])
		assert_eq(_col.get_top_card(), c2)
		c1.queue_free()
		c2.queue_free()

	func test_get_top_card_empty_returns_null() -> void:
		assert_null(_col.get_top_card())

	func test_has_card_true_when_present() -> void:
		var card := Card.new()
		_col.add_cards([card])
		assert_true(_col.has_card(card))
		card.queue_free()

	func test_has_card_false_when_absent() -> void:
		var card := Card.new()
		assert_false(_col.has_card(card))
		card.queue_free()

	func test_remove_cards_returns_top_cards() -> void:
		var c1 := Card.new()
		var c2 := Card.new()
		var c3 := Card.new()
		_col.add_cards([c1, c2, c3])
		var removed := _col.remove_cards(2)
		assert_eq(removed.size(), 2)
		# pop_back 顺序：先 c3 后 c2
		assert_eq(removed[0], c3)
		assert_eq(removed[1], c2)
		assert_eq(_col.get_card_count(), 1)
		c1.queue_free()
		c2.queue_free()
		c3.queue_free()

	func test_remove_cards_flips_face_down_card() -> void:
		var c1 := Card.new()
		c1.face_up = false
		var c2 := Card.new()
		c2.face_up = true
		_col.add_cards([c1, c2])
		_col.remove_cards(1)
		assert_true(c1.face_up)
		assert_eq(_col.last_revealed_card, c1)
		c1.queue_free()
		c2.queue_free()

	func test_remove_cards_does_not_flip_when_disabled() -> void:
		var c1 := Card.new()
		c1.face_up = false
		var c2 := Card.new()
		c2.face_up = true
		_col.add_cards([c1, c2])
		_col.remove_cards(1, false)
		assert_false(c1.face_up)
		c1.queue_free()
		c2.queue_free()

	func test_remove_cards_invalid_count_returns_empty() -> void:
		assert_eq(_col.remove_cards(1).size(), 0)
		assert_eq(_col.remove_cards(0).size(), 0)

	func test_remove_specific_cards() -> void:
		var c1 := Card.new()
		var c2 := Card.new()
		var c3 := Card.new()
		_col.add_cards([c1, c2, c3])
		_col.remove_specific_cards([c2, c3])
		assert_eq(_col.get_card_count(), 1)
		assert_true(_col.has_card(c1))
		c1.queue_free()
		c2.queue_free()
		c3.queue_free()

	func test_add_cards_emits_signal() -> void:
		watch_signals(_col)
		var card := Card.new()
		_col.add_cards([card])
		assert_signal_emitted(_col, "cards_added")
		card.queue_free()

	func test_remove_cards_emits_signal() -> void:
		var card := Card.new()
		_col.add_cards([card])
		watch_signals(_col)
		_col.remove_cards(1)
		assert_signal_emitted(_col, "cards_removed")
		card.queue_free()


class TestColumnMovableSequence:
	extends "res://tests/unit/test_base.gd"

	var _col: Column = null

	func before_each() -> void:
		_col = Column.new()
		add_child(_col)

	func after_each() -> void:
		if is_instance_valid(_col):
			_col.queue_free()

	func test_empty_column_returns_empty() -> void:
		assert_eq(_col.get_movable_sequence().size(), 0)

	func test_single_face_up_card_returns_itself() -> void:
		var card := Card.new()
		card.suit = 0
		card.rank = 5
		card.face_up = true
		_col.add_cards([card])
		var seq := _col.get_movable_sequence()
		assert_eq(seq.size(), 1)
		assert_eq(seq[0], card)
		card.queue_free()

	func test_descending_same_suit_sequence() -> void:
		var cards: Array[Card] = []
		for r in range(5, 2, -1):
			var c := Card.new()
			c.suit = 1
			c.rank = r
			c.face_up = true
			cards.append(c)
		_col.add_cards(cards)
		var seq := _col.get_movable_sequence()
		assert_eq(seq.size(), 3)
		for c in cards:
			c.queue_free()

	func test_breaks_on_wrong_rank() -> void:
		var c1 := Card.new()
		c1.suit = 0
		c1.rank = 5
		c1.face_up = true
		var c2 := Card.new()
		c2.suit = 0
		c2.rank = 3
		c2.face_up = true
		_col.add_cards([c1, c2])
		var seq := _col.get_movable_sequence()
		assert_eq(seq.size(), 1)
		assert_eq(seq[0], c2)
		c1.queue_free()
		c2.queue_free()

	func test_breaks_on_wrong_suit() -> void:
		var c1 := Card.new()
		c1.suit = 0
		c1.rank = 6
		c1.face_up = true
		var c2 := Card.new()
		c2.suit = 1
		c2.rank = 5
		c2.face_up = true
		_col.add_cards([c1, c2])
		var seq := _col.get_movable_sequence()
		assert_eq(seq.size(), 1)
		c1.queue_free()
		c2.queue_free()

	func test_breaks_on_face_down_card() -> void:
		var c1 := Card.new()
		c1.suit = 0
		c1.rank = 6
		c1.face_up = false
		var c2 := Card.new()
		c2.suit = 0
		c2.rank = 5
		c2.face_up = true
		_col.add_cards([c1, c2])
		var seq := _col.get_movable_sequence()
		assert_eq(seq.size(), 1)
		c1.queue_free()
		c2.queue_free()


class TestColumnLayout:
	extends "res://tests/unit/test_base.gd"

	var _col: Column = null

	func before_each() -> void:
		_col = Column.new()
		add_child(_col)

	func after_each() -> void:
		if is_instance_valid(_col):
			_col.queue_free()

	func test_custom_minimum_size_default() -> void:
		assert_eq(_col.custom_minimum_size.x, 100)

	func test_get_next_card_position_starts_at_zero() -> void:
		var pos := _col.get_next_card_position()
		assert_eq(pos, Vector2.ZERO)

	func test_added_card_gets_positioned() -> void:
		var card := Card.new()
		_col.add_cards([card])
		assert_eq(card.position, Vector2.ZERO)
		card.queue_free()

	func test_is_highlighted_setter_triggers_redraw() -> void:
		# 只是验证不会崩溃
		_col.is_highlighted = true
		assert_true(_col.is_highlighted)
		_col.is_highlighted = false
		assert_false(_col.is_highlighted)
