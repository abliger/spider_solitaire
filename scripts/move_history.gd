extends Node

## Singleton/Autoload that records every move for unlimited undo support.

class MoveRecord:
	var from_column: int
	var to_column: int
	var cards_moved: Array
	var flipped_card: bool
	var sequences_completed: int
	var score_delta: int

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


## Records a new move onto the history stack. Returns the created record so callers can update it later.
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


## Removes and returns the most recent move record, or null if the stack is empty.
func undo_last_move() -> MoveRecord:
	if _history.is_empty():
		return null
	return _history.pop_back()


## Returns true when at least one move can be undone.
func can_undo() -> bool:
	return not _history.is_empty()


## Clears the entire move history (e.g. when starting a new game).
func clear() -> void:
	_history.clear()


## Updates the most recent move record with additional information.
func update_last_record(flipped_card: bool, sequences_completed: int, score_delta: int) -> void:
	if _history.is_empty():
		return
	var record: MoveRecord = _history[_history.size() - 1]
	record.flipped_card = flipped_card
	record.sequences_completed = sequences_completed
	record.score_delta += score_delta


## Returns the number of recorded moves.
func get_history_count() -> int:
	return _history.size()
