extends "res://addons/gut/test.gd"


class TestCardData:
	extends "res://addons/gut/test.gd"

	func test_can_place_on_returns_true_when_rank_exactly_one_higher():
		var lower := RulesEngine.CardData.new(0, 5)
		var higher := RulesEngine.CardData.new(0, 6)
		assert_true(lower.can_place_on(higher))

	func test_can_place_on_returns_false_when_rank_not_one_higher():
		var lower := RulesEngine.CardData.new(0, 5)
		var same := RulesEngine.CardData.new(0, 5)
		assert_false(lower.can_place_on(same))

	func test_is_same_suit_returns_true_for_same_suit():
		var a := RulesEngine.CardData.new(1, 5)
		var b := RulesEngine.CardData.new(1, 10)
		assert_true(a.is_same_suit(b))

	func test_is_same_suit_returns_false_for_different_suits():
		var a := RulesEngine.CardData.new(0, 5)
		var b := RulesEngine.CardData.new(1, 5)
		assert_false(a.is_same_suit(b))

	func test_get_suit_symbol_returns_expected_symbols():
		assert_eq(RulesEngine.CardData.new(0, 1).get_suit_symbol(), "♠")
		assert_eq(RulesEngine.CardData.new(1, 1).get_suit_symbol(), "♥")
		assert_eq(RulesEngine.CardData.new(2, 1).get_suit_symbol(), "♦")
		assert_eq(RulesEngine.CardData.new(3, 1).get_suit_symbol(), "♣")

	func test_get_rank_string_returns_expected_values():
		assert_eq(RulesEngine.CardData.new(0, 1).get_rank_string(), "A")
		assert_eq(RulesEngine.CardData.new(0, 10).get_rank_string(), "10")
		assert_eq(RulesEngine.CardData.new(0, 11).get_rank_string(), "J")
		assert_eq(RulesEngine.CardData.new(0, 12).get_rank_string(), "Q")
		assert_eq(RulesEngine.CardData.new(0, 13).get_rank_string(), "K")

	func test_is_red_returns_true_for_hearts_and_diamonds():
		assert_true(RulesEngine.CardData.new(1, 1).is_red())
		assert_true(RulesEngine.CardData.new(2, 1).is_red())

	func test_is_red_returns_false_for_spades_and_clubs():
		assert_false(RulesEngine.CardData.new(0, 1).is_red())
		assert_false(RulesEngine.CardData.new(3, 1).is_red())


class TestCreateDeck:
	extends "res://addons/gut/test.gd"

	func test_create_deck_easy_has_104_cards():
		var deck := RulesEngine.create_deck(1)
		assert_eq(deck.size(), 104)

	func test_create_deck_medium_has_104_cards():
		var deck := RulesEngine.create_deck(2)
		assert_eq(deck.size(), 104)

	func test_create_deck_hard_has_104_cards():
		var deck := RulesEngine.create_deck(4)
		assert_eq(deck.size(), 104)

	func test_create_deck_easy_all_spades():
		var deck := RulesEngine.create_deck(1)
		for card in deck:
			assert_eq(card.suit, RulesEngine.Suit.SPADES)

	func test_create_deck_hard_has_four_suits():
		var deck := RulesEngine.create_deck(4)
		var suits_found := {}
		for card in deck:
			suits_found[card.suit] = true
		assert_eq(suits_found.size(), 4)


class TestGetMovableSequence:
	extends "res://addons/gut/test.gd"

	func test_empty_array_returns_empty():
		assert_eq(RulesEngine.get_movable_sequence([]).size(), 0)

	func test_single_card_returns_itself():
		var cards: Array[RulesEngine.CardData] = [RulesEngine.CardData.new(0, 5)]
		cards[0].face_up = true
		var result := RulesEngine.get_movable_sequence(cards)
		assert_eq(result.size(), 1)
		assert_eq(result[0].rank, 5)

	func test_descending_same_suit_returns_full_sequence():
		var cards: Array[RulesEngine.CardData] = []
		for r in range(13, 9, -1):
			var c := RulesEngine.CardData.new(0, r)
			c.face_up = true
			cards.append(c)
		var result := RulesEngine.get_movable_sequence(cards)
		assert_eq(result.size(), 4)

	func test_breaks_on_different_suit():
		var cards: Array[RulesEngine.CardData] = []
		var c1 := RulesEngine.CardData.new(0, 5)
		c1.face_up = true
		var c2 := RulesEngine.CardData.new(1, 4)
		c2.face_up = true
		cards.append(c1)
		cards.append(c2)
		var result := RulesEngine.get_movable_sequence(cards)
		assert_eq(result.size(), 1)
		assert_eq(result[0].rank, 4)

	func test_breaks_on_face_down_card():
		var cards: Array[RulesEngine.CardData] = []
		var c1 := RulesEngine.CardData.new(0, 5)
		c1.face_up = false
		var c2 := RulesEngine.CardData.new(0, 4)
		c2.face_up = true
		cards.append(c1)
		cards.append(c2)
		var result := RulesEngine.get_movable_sequence(cards)
		assert_eq(result.size(), 1)
		assert_eq(result[0].rank, 4)


class TestIsValidMove:
	extends "res://addons/gut/test.gd"

	func test_empty_moving_cards_returns_false():
		assert_false(RulesEngine.is_valid_move([], []))

	func test_invalid_sequence_returns_false():
		var moving: Array[RulesEngine.CardData] = [
			RulesEngine.CardData.new(0, 5),
			RulesEngine.CardData.new(0, 3),
		]
		assert_false(RulesEngine.is_valid_move(moving, []))

	func test_empty_target_returns_true_for_valid_sequence():
		var moving: Array[RulesEngine.CardData] = [
			RulesEngine.CardData.new(0, 5),
			RulesEngine.CardData.new(0, 4),
		]
		assert_true(RulesEngine.is_valid_move(moving, []))

	func test_target_face_down_returns_false():
		var moving: Array[RulesEngine.CardData] = [RulesEngine.CardData.new(0, 5)]
		var target: Array[RulesEngine.CardData] = [RulesEngine.CardData.new(0, 6)]
		target[0].face_up = false
		assert_false(RulesEngine.is_valid_move(moving, target))

	func test_valid_placement_on_target():
		var moving: Array[RulesEngine.CardData] = [RulesEngine.CardData.new(0, 5)]
		var target: Array[RulesEngine.CardData] = [RulesEngine.CardData.new(0, 6)]
		target[0].face_up = true
		assert_true(RulesEngine.is_valid_move(moving, target))


class TestFindCompleteSequence:
	extends "res://addons/gut/test.gd"

	func test_less_than_13_cards_returns_negative_one():
		var cards: Array[RulesEngine.CardData] = []
		for i in range(12):
			cards.append(RulesEngine.CardData.new(0, 13 - i))
		assert_eq(RulesEngine.find_complete_sequence(cards), -1)

	func test_finds_king_to_ace_sequence():
		var cards: Array[RulesEngine.CardData] = []
		for i in range(13):
			var c := RulesEngine.CardData.new(0, 13 - i)
			c.face_up = true
			cards.append(c)
		assert_eq(RulesEngine.find_complete_sequence(cards), 0)

	func test_does_not_find_when_suits_mixed():
		var cards: Array[RulesEngine.CardData] = []
		for i in range(13):
			var c := RulesEngine.CardData.new(i % 2, 13 - i)
			c.face_up = true
			cards.append(c)
		assert_eq(RulesEngine.find_complete_sequence(cards), -1)

	func test_finds_sequence_not_at_start():
		var cards: Array[RulesEngine.CardData] = []
		# 先加一些无关的牌
		cards.append(RulesEngine.CardData.new(0, 7))
		cards[0].face_up = true
		# 再加 K-A 序列
		for i in range(13):
			var c := RulesEngine.CardData.new(0, 13 - i)
			c.face_up = true
			cards.append(c)
		assert_eq(RulesEngine.find_complete_sequence(cards), 1)
