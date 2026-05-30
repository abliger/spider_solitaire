class_name RulesEngine
extends RefCounted

const RANKS := 13
const SUITS := 4
const DECKS := 8
const TOTAL_CARDS := 104
const COLUMNS := 10

enum Suit { SPADES, HEARTS, DIAMONDS, CLUBS }

class CardData:
	var suit: int
	var rank: int  # 1-13 (A-K)
	var face_up: bool = false
	
	func _init(s: int, r: int) -> void:
		suit = s
		rank = r
	
	func can_place_on(other: CardData) -> bool:
		# 蜘蛛纸牌：任意花色，点数必须恰好大 1
		return other.rank == rank + 1
	
	func is_same_suit(other: CardData) -> bool:
		return suit == other.suit
	
	func get_suit_symbol() -> String:
		match suit:
			0: return "♠"
			1: return "♥"
			2: return "♦"
			3: return "♣"
			_: return "?"
	
	func get_rank_string() -> String:
		match rank:
			1: return "A"
			11: return "J"
			12: return "Q"
			13: return "K"
			_: return str(rank)
	
	func is_red() -> bool:
		return suit == 1 or suit == 2

static func create_deck(num_suits: int) -> Array[CardData]:
	var deck: Array[CardData] = []
	# 蜘蛛纸牌总共使用 104 张牌。
	# 牌组数量取决于使用了多少种花色。
	var decks := TOTAL_CARDS / (num_suits * RANKS)
	for _i in range(decks):
		for s in range(num_suits):
			for r in range(1, RANKS + 1):
				deck.append(CardData.new(s, r))
	return deck

static func shuffle(deck: Array[CardData]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := deck[i]
		deck[i] = deck[j]
		deck[j] = temp

static func get_movable_sequence(cards: Array[CardData]) -> Array[CardData]:
	# 返回顶部可以一起移动的最长序列
	# 序列必须点数递减且花色相同
	if cards.is_empty():
		return []
	
	var result: Array[CardData] = [cards[cards.size() - 1]]
	for i in range(cards.size() - 2, -1, -1):
		var current := cards[i]
		var next := result[result.size() - 1]
		if current.face_up and current.is_same_suit(next) and next.rank == current.rank - 1:
			result.append(current)
		else:
			break
	return result

static func is_valid_move(moving_cards: Array[CardData], target_cards: Array[CardData]) -> bool:
	if moving_cards.is_empty():
		return false
	
	if target_cards.is_empty():
		# 空列：只能放置 K 或以 K 开头的序列
		return moving_cards[0].rank == 13
	
	var top_target := target_cards[target_cards.size() - 1]
	if not top_target.face_up:
		return false
	
	return moving_cards[0].can_place_on(top_target)

static func find_complete_sequence(cards: Array[CardData]) -> int:
	# 返回 K->A 完整同花色序列的起始索引，如果没有则返回 -1
	if cards.size() < 13:
		return -1
	
	for start in range(cards.size() - 13, -1, -1):
		if not cards[start].face_up:
			continue
		if cards[start].rank != 13:
			continue
		
		var valid := true
		for i in range(13):
			var card := cards[start + i]
			if not card.face_up:
				valid = false
				break
			if card.rank != 13 - i:
				valid = false
				break
			if i > 0 and not card.is_same_suit(cards[start + i - 1]):
				valid = false
				break
		
		if valid:
			return start
	
	return -1

static func has_any_valid_move(columns: Array) -> bool:
	# 检查面板上是否存在任何合法移动。
	# 期望一个 Column 节点数组。
	for from_col in range(columns.size()):
		var col = columns[from_col]
		if col == null or not col.has_method("get_cards"):
			continue
		var raw_cards: Array = col.get_cards()
		if raw_cards.is_empty():
			continue
		var from_data: Array[CardData] = _cards_to_data(raw_cards)
		var movable := get_movable_sequence(from_data)
		if movable.is_empty():
			continue
		
		for to_col in range(columns.size()):
			if from_col == to_col:
				continue
			var target_col = columns[to_col]
			if target_col == null or not target_col.has_method("get_cards"):
				continue
			var target_raw: Array = target_col.get_cards()
			var to_data: Array[CardData] = _cards_to_data(target_raw)
			if is_valid_move(movable, to_data):
				return true
	return false


static func _cards_to_data(cards: Array) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards:
		if card is CardData:
			result.append(card)
		elif ("suit" in card) and ("rank" in card):
			# 将 Card 节点转换为 CardData
			var data := CardData.new(card.suit, card.rank)
			if "face_up" in card:
				data.face_up = card.face_up
			result.append(data)
	return result
