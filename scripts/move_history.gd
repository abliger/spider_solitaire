extends Node

## 单例 / 自动加载，记录每一步移动以支持无限撤销。

class MoveRecord:
	var from_column: int
	var to_column: int
	var cards_moved: Array
	var flipped_card: bool
	var sequences_completed: int
	var score_delta: int
	var completed_sequences: Array = []

	func _init(
		p_from: int,
		p_to: int,
		p_cards: Array,
		p_flipped: bool,
		p_completed: int,
		p_score: int
	) -> void:
		from_column = p_from
		to_column = p_to
		cards_moved = p_cards.duplicate()
		flipped_card = p_flipped
		sequences_completed = p_completed
		score_delta = p_score


var _history: Array[MoveRecord] = []


## 将新移动记录到历史栈上。返回创建的记录，以便调用者稍后更新。
func record_move(
	from_column: int,
	to_column: int,
	cards_moved: Array,
	flipped_card: bool = false,
	sequences_completed: int = 0,
	score_delta: int = 0
) -> MoveRecord:
	var record := MoveRecord.new(from_column, to_column, cards_moved, flipped_card, sequences_completed, score_delta)
	_history.append(record)
	return record


## 移除并返回最近的移动记录，如果栈为空则返回 null。
func undo_last_move() -> MoveRecord:
	if _history.is_empty():
		return null
	return _history.pop_back()


## 当至少可以撤销一步移动时返回 true。
func can_undo() -> bool:
	return not _history.is_empty()


## 清空整个移动历史（例如开始新游戏时）。
func clear() -> void:
	_history.clear()


## 使用附加信息更新最近的移动记录。
func update_last_record(flipped_card: bool, sequences_completed: int, score_delta: int, completed_sequences: Array = []) -> void:
	if _history.is_empty():
		return
	var record: MoveRecord = _history[_history.size() - 1]
	record.flipped_card = flipped_card
	record.sequences_completed = sequences_completed
	record.score_delta += score_delta
	record.completed_sequences = completed_sequences


## 返回已记录的移动数量。
func get_history_count() -> int:
	return _history.size()
