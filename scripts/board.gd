class_name Board
extends Control

## 当新游戏设置完成后发出此信号。
signal board_ready
## 从发牌堆向各列发一批 10 张纸牌后发出此信号。
signal stock_dealt(cards_dealt: Array)
## 当发现并成功移除一组完整的 K-A 同花色序列时发出此信号。
signal sequence_completed(sequence: Array)
## 当完成全部 8 组序列时发出此信号（游戏胜利）。
signal game_won

# ---------------------------------------------------------------------------
# 场景引用
# ---------------------------------------------------------------------------
@export var column_scene: PackedScene
@export var card_scene: PackedScene

@onready var columns_container: Control = $ColumnsContainer
@onready var stock_count_label: Label = $StockCountLabel
@onready var stock_node: Stock = $Stock

# ---------------------------------------------------------------------------
# 布局常量
# ---------------------------------------------------------------------------
const NUM_COLUMNS: int = 10
const NUM_FOUNDATIONS: int = 8
const CARDS_PER_DEAL: int = 10
const FULL_SEQUENCE_LENGTH: int = 13

# 初始发牌：4 列各得 6 张牌，6 列各得 5 张牌
const INITIAL_SIX_CARD_COLS: int = 4
const INITIAL_FIVE_CARD_COLS: int = 6

# 列布局
const COLUMN_WIDTH: int = 100
const COLUMN_SPACING: int = 18
const COLUMNS_START_X: int = 40
const COLUMNS_START_Y: int = 140

# ---------------------------------------------------------------------------
# 面板状态
# ---------------------------------------------------------------------------
## 面板上的 10 列纸牌。
var columns: Array[Column] = []

## 发牌堆（尚未发出的 Card 节点数组）。
var stock: Array[Card] = []

## 从面板移除的完整序列（最多 8 组）。
var foundations: Array[Array] = []

## 当前难度（影响花色数量）。
var current_difficulty: int = 1

## 是否正在执行发牌动画，防止重复点击。
var _is_dealing: bool = false

## 用于存放未进入场景树的发牌堆纸牌与完成序列纸牌的容器，防止退出时泄漏。
var _stock_container: Node
var _foundation_container: Node

# ---------------------------------------------------------------------------
# 内置函数重写
# ---------------------------------------------------------------------------
func _ready() -> void:
	# 如果在检查器中未分配，则加载默认场景
	if column_scene == null:
		column_scene = preload("res://scenes/column.tscn")
	if card_scene == null:
		card_scene = preload("res://scenes/card.tscn")
	DragSystem.register_board(self)

	_stock_container = Node.new()
	_stock_container.name = "StockContainer"
	add_child(_stock_container)

	_foundation_container = Node.new()
	_foundation_container.name = "FoundationContainer"
	add_child(_foundation_container)


# ---------------------------------------------------------------------------
# 游戏设置
# ---------------------------------------------------------------------------
## 以给定难度开始新游戏（1 = 简单，2 = 中等，4 = 困难）。
func setup_new_game(difficulty: int) -> void:
	current_difficulty = difficulty
	_clear_board()

	# 使用现有的 RulesEngine 创建牌组
	var deck_data: Array[RulesEngine.CardData] = RulesEngine.create_deck(current_difficulty)
	RulesEngine.shuffle(deck_data)

	# 将 CardData 转换为 Card 节点
	var all_cards: Array[Card] = []
	for data in deck_data:
		var card = _create_card_from_data(data)
		all_cards.append(card)

	# --- 初始发牌 ---
	# 4 列 × 6 张 + 6 列 × 5 张 = 24 + 30 = 54 张
	var dealt_count := 0
	for col_idx in range(NUM_COLUMNS):
		var col = _create_column(col_idx)
		var card_count := 6 if col_idx < INITIAL_SIX_CARD_COLS else 5
		var cards_for_col: Array[Card] = []
		for i in range(card_count):
			var card = all_cards[dealt_count]
			# 所有纸牌初始为背面朝上；稍后只有最底部的纸牌被翻开
			card.face_up = false
			cards_for_col.append(card)
			dealt_count += 1
		col.add_cards(cards_for_col)

	# 将每列最顶部的纸牌翻为正面朝上
	for col in columns:
		var cards = col.get_cards()
		if not cards.is_empty():
			cards[cards.size() - 1].flip()

	# --- 发牌堆 ---
	# 剩余 104 - 54 = 50 张
	for i in range(dealt_count, all_cards.size()):
		var card: Card = all_cards[i]
		stock.append(card)
		_stock_container.add_child(card)
		card.visible = false

	_update_stock_label()
	_position_columns()

	# 设置每列最大高度，避免纸牌过多时超出可视区域
	var max_col_height := 520.0
	if columns_container:
		max_col_height = columns_container.size.y
	for col in columns:
		col.max_column_height = max_col_height

	GameState.start_game(current_difficulty)
	board_ready.emit()


# ---------------------------------------------------------------------------
# 发牌堆发牌
# ---------------------------------------------------------------------------
## 从发牌堆向 10 列各发一张牌。
## 如果成功发牌返回 true，如果发牌堆为空返回 false。
func deal_from_stock() -> bool:
	if not GameState.is_game_active:
		return false
	if stock.is_empty():
		return false
	if stock.size() < CARDS_PER_DEAL:
		return false

	# 验证没有空列（蜘蛛纸牌规则：如果有空列则不能发牌）
	for col in columns:
		if col.is_empty():
			return false
	if _is_dealing:
		return false

	_is_dealing = true

	var stock_global_pos := stock_node.global_position
	var dealt: Array[Card] = []
	var target_positions: Array[Vector2] = []

	for col_idx in range(columns.size()):
		var col = columns[col_idx]
		var card = stock.pop_back()
		card.visible = true
		card.face_up = true
		if card.get_parent() == _stock_container:
			_stock_container.remove_child(card)
		dealt.append(card)

		# 先计算目标本地位置，再加入列
		var target_local := col.get_next_card_position()
		col.add_cards([card])

		# 记录目标全局位置
		target_positions.append(card.global_position)

		# 将牌重置到牌堆位置作为动画起点
		card.global_position = stock_global_pos
		# 临时提高 z_index，确保飞行动画可见
		card.z_index = 100 + col_idx

	# 创建并发 tween，从左到右依次延迟
	var tween := create_tween()
	tween.set_parallel(true)

	for i in range(dealt.size()):
		var card = dealt[i]
		var target_pos = target_positions[i]
		var card_tween := tween.tween_property(card, "global_position", target_pos, 0.2)
		card_tween.set_delay(i * 0.06)
		card_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.finished.connect(func():
		if not is_instance_valid(self):
			return
		for col in columns:
			col._reposition_cards()
		_check_all_columns_for_sequences()
		_is_dealing = false
		stock_dealt.emit(dealt)
	)

	GameState.increment_move()
	SoundManager.play_sfx("deal")
	_update_stock_label()
	return true


# ---------------------------------------------------------------------------
# 纸牌移动
# ---------------------------------------------------------------------------
## 将 `count` 张纸牌从 `from_col` 索引列移动到 `to_col` 索引列。
## 如果移动合法并已执行则返回 true。
func move_cards(from_col: int, to_col: int, count: int, record_history: bool = true, ignore_rules: bool = false, check_sequences: bool = true, flip_revealed: bool = true) -> bool:
	if from_col < 0 or from_col >= NUM_COLUMNS:
		return false
	if to_col < 0 or to_col >= NUM_COLUMNS:
		return false
	if from_col == to_col:
		return false

	var source = columns[from_col]
	var target = columns[to_col]

	var moving_cards = _get_top_cards(source, count)
	if moving_cards.is_empty():
		return false

	var target_cards = target.get_cards()
	if not ignore_rules:
		var moving_data = _cards_to_data(moving_cards)
		var target_data = _cards_to_data(target_cards)
		if not RulesEngine.is_valid_move(moving_data, target_data):
			SoundManager.play_sfx("error")
			return false

	# 执行移动
	var removed = source.remove_cards(count, flip_revealed)
	removed.reverse()
	target.add_cards(removed)

	var source_flipped := source.last_revealed_card != null

	GameState.increment_move()
	GameState.add_score(-1)
	SoundManager.play_sfx("move")

	# 记录移动以便撤销
	var record: MoveHistory.MoveRecord = null
	if record_history:
		record = MoveHistory.record_move(from_col, to_col, removed, false, 0, -1)

	# 移动后检查是否有完成的序列
	if check_sequences:
		var seq_result := _check_all_columns_for_sequences()
		if record != null:
			if seq_result.count > 0:
				MoveHistory.update_last_record(source_flipped, seq_result.count, seq_result.count * 100, seq_result.sequences)
			elif source_flipped:
				MoveHistory.update_last_record(true, 0, 0)

	return true


## 移动特定的纸牌序列（用于拖拽）。
## `cards` 必须是 `from_col` 列顶部连续的序列。
func move_card_sequence(from_col: int, to_col: int, cards: Array, record_history: bool = true, ignore_rules: bool = false, check_sequences: bool = true, flip_revealed: bool = true) -> bool:
	if from_col < 0 or from_col >= NUM_COLUMNS:
		return false
	if to_col < 0 or to_col >= NUM_COLUMNS:
		return false
	if from_col == to_col:
		return false
	if cards.is_empty():
		return false

	var source = columns[from_col]
	var target = columns[to_col]

	# 验证这些纸牌确实位于源列的顶部
	var source_cards = source.get_cards()
	var start_idx = source_cards.find(cards[0])
	if start_idx == -1:
		return false
	for i in range(cards.size()):
		if source_cards[start_idx + i] != cards[i]:
			return false
	# 确保它们是最顶部的纸牌
	if start_idx + cards.size() != source_cards.size():
		return false

	var target_cards = target.get_cards()
	if not ignore_rules:
		var moving_data = _cards_to_data(cards)
		var target_data = _cards_to_data(target_cards)
		if not RulesEngine.is_valid_move(moving_data, target_data):
			SoundManager.play_sfx("error")
			return false

	# 执行移动
	source.remove_specific_cards(cards, flip_revealed)
	target.add_cards(cards)

	var source_flipped := source.last_revealed_card != null

	GameState.increment_move()
	GameState.add_score(-1)
	SoundManager.play_sfx("move")

	# 记录移动以便撤销
	var record: MoveHistory.MoveRecord = null
	if record_history:
		record = MoveHistory.record_move(from_col, to_col, cards, false, 0, -1)

	# 移动后检查是否有完成的序列
	if check_sequences:
		var seq_result := _check_all_columns_for_sequences()
		if record != null:
			if seq_result.count > 0:
				MoveHistory.update_last_record(source_flipped, seq_result.count, seq_result.count * 100, seq_result.sequences)
			elif source_flipped:
				MoveHistory.update_last_record(true, 0, 0)

	return true


# ---------------------------------------------------------------------------
# 序列 / 胜利检查
# ---------------------------------------------------------------------------
## 扫描所有列以查找完整的 K-A 同花色序列。
func check_for_complete_sequence() -> void:
	_check_all_columns_for_sequences()


func _check_all_columns_for_sequences() -> Dictionary:
	var result := {"count": 0, "sequences": []}
	for col_idx in range(columns.size()):
		var col = columns[col_idx]
		while true:
			var cards = col.get_cards()
			var card_data = _cards_to_data(cards)
			var start_idx = RulesEngine.find_complete_sequence(card_data)
			if start_idx == -1:
				break

			# 移除 13 张纸牌的序列
			var sequence: Array[Card] = []
			var source_cards = col.get_cards()
			for i in range(start_idx, start_idx + FULL_SEQUENCE_LENGTH):
				sequence.append(source_cards[i])

			# 记录动画起始位置
			var start_positions: Array[Vector2] = []
			for i in range(sequence.size()):
				start_positions.append(sequence[i].global_position)

			col.remove_specific_cards(sequence)

			# 启动收集动画：牌飞到左上角的 Foundation 空位
			_animate_sequence_to_foundation(sequence, start_positions, foundations.size())

			foundations.append(sequence)

			GameState.add_score(100)
			SoundManager.play_sfx("win")
			sequence_completed.emit(sequence)
			result.count += 1
			result.sequences.append({"column_index": col_idx, "cards": sequence.duplicate()})

			# 检查是否全局胜利
			if foundations.size() >= NUM_FOUNDATIONS:
				GameState.end_game()
				game_won.emit()
				return result
	return result


## 将完成的 K-A 序列动画飞到 Foundation 对应槽位，动画结束后将牌隐藏保留在 _foundation_container 中以便撤销。
func _animate_sequence_to_foundation(sequence: Array[Card], start_positions: Array[Vector2], slot_index: int) -> void:
	var foundation_node := get_node_or_null("Foundation") as Foundation
	if foundation_node == null:
		# 无 Foundation 节点则直接隐藏
		for card in sequence:
			_foundation_container.add_child(card)
			card.visible = false
		return

	# 将牌加入 _foundation_container 并恢复起始全局位置
	for i in range(sequence.size()):
		var card := sequence[i]
		if card.get_parent() != null:
			card.get_parent().remove_child(card)
		_foundation_container.add_child(card)
		card.global_position = start_positions[i]
		card.z_index = 200 + i
		card.visible = true

	var target_global_pos := foundation_node.global_position + Vector2(
		slot_index * (Foundation.SLOT_WIDTH + Foundation.SLOT_SPACING),
		0
	)

	var tween := create_tween()
	tween.set_parallel(true)
	for i in range(sequence.size()):
		var card := sequence[i]
		tween.tween_property(card, "global_position", target_global_pos, 0.35) \
			.set_delay(i * 0.08) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	# 动画结束后隐藏纸牌（保留在 _foundation_container 中以支持撤销）
	tween.chain().tween_callback(func():
		for card in sequence:
			if is_instance_valid(card) and card.get_parent() == _foundation_container:
				card.visible = false
	)


## 显示一个提示高亮。如果没有合法移动则播放错误音效。
func show_hint() -> void:
	_clear_hint_highlight()

	var hint := RulesEngine.find_hint_move(columns)
	if hint.is_empty():
		SoundManager.play_sfx("error")
		return

	var from_col: int = hint["from_col"]
	var to_col: int = hint["to_col"]
	var count: int = hint["count"]

	# 高亮源列的可移动牌串
	var source = columns[from_col]
	var moving_cards = _get_top_cards(source, count)
	for card in moving_cards:
		card.is_highlighted = true

	# 高亮目标列
	columns[to_col].is_highlighted = true

	SoundManager.play_sfx("click")

	# 2 秒后自动清除高亮
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_clear_hint_highlight)


## 清除所有提示高亮。
func _clear_hint_highlight() -> void:
	for col in columns:
		col.is_highlighted = false
		for card in col.get_cards():
			card.is_highlighted = false


# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
## 根据 CardData 创建并返回 Card 节点。
func _create_card_from_data(data: RulesEngine.CardData) -> Card:
	var card: Card = card_scene.instantiate() as Card
	card.set_card_data(data.suit, data.rank)
	card.face_up = data.face_up
	return card


## 创建 Column 节点并将其添加到面板。
func _create_column(index: int) -> Column:
	var col: Column = column_scene.instantiate() as Column
	col.name = "Column_%d" % index
	columns.append(col)
	# 如果可用则添加到列容器，否则添加到自身
	if columns_container:
		columns_container.add_child(col)
	else:
		add_child(col)
	return col


## 返回一列顶部 `count` 张纸牌组成的数组。
func _get_top_cards(col: Column, count: int) -> Array[Card]:
	var cards := col.get_cards()
	if count > cards.size():
		return []
	var result: Array[Card] = []
	for i in range(cards.size() - count, cards.size()):
		result.append(cards[i])
	return result


## 将 Card 节点数组转换为 RulesEngine.CardData 以便进行规则检查。
func _cards_to_data(cards: Array) -> Array[RulesEngine.CardData]:
	var result: Array[RulesEngine.CardData] = []
	for card in cards:
		var data = RulesEngine.CardData.new(card.suit, card.rank)
		data.face_up = card.face_up
		result.append(data)
	return result


## 在列容器内将 10 列水平排列。
func _position_columns() -> void:
	for i in range(columns.size()):
		var col = columns[i]
		# 位置相对于父节点（Board 或 ColumnsContainer）
		if columns_container and col.get_parent() == columns_container:
			col.position = Vector2(
				i * (COLUMN_WIDTH + COLUMN_SPACING),
				0
			)
		else:
			col.position = Vector2(
				COLUMNS_START_X + i * (COLUMN_WIDTH + COLUMN_SPACING),
				COLUMNS_START_Y
			)


## 更新发牌堆计数标签文本。
func _update_stock_label() -> void:
	if stock_count_label:
		stock_count_label.text = Localization.translate("stock_left") % stock.size()


## 移除所有列和纸牌，并重置发牌堆 / 基础区。
func _clear_board() -> void:
	# 清理前强制结束任何活跃的拖拽
	DragSystem.force_end_drag()

	# 移除现有列
	for col in columns:
		if is_instance_valid(col):
			col.queue_free()
	columns.clear()

	# 发牌堆中剩余的纸牌
	for card in _stock_container.get_children():
		if is_instance_valid(card):
			card.queue_free()
	stock.clear()

	# 清空基础区
	for card in _foundation_container.get_children():
		if is_instance_valid(card):
			card.queue_free()
	foundations.clear()

	_update_stock_label()
	_is_dealing = false
