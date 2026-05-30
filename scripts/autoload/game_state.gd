extends Node

signal score_changed(new_score: int)
signal move_count_changed(new_count: int)
signal time_changed(new_time: int)
signal game_won
signal game_started
signal game_reset

enum Difficulty { EASY = 1, MEDIUM = 2, HARD = 4 }

var current_difficulty: Difficulty = Difficulty.EASY
var score: int = 500:
	set(value):
		score = value
		score_changed.emit(score)
var move_count: int = 0:
	set(value):
		move_count = value
		move_count_changed.emit(move_count)
var elapsed_time: int = 0:
	set(value):
		elapsed_time = value
		time_changed.emit(elapsed_time)
var is_game_active: bool = false

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func start_game(difficulty: Difficulty = current_difficulty) -> void:
	current_difficulty = difficulty
	score = 500
	move_count = 0
	elapsed_time = 0
	is_game_active = true
	_timer.start()
	game_started.emit()

func end_game() -> void:
	is_game_active = false
	_timer.stop()
	game_won.emit()

func reset_game() -> void:
	is_game_active = false
	_timer.stop()
	score = 500
	move_count = 0
	elapsed_time = 0
	game_reset.emit()

func add_score(delta: int) -> void:
	score += delta

func increment_move() -> void:
	move_count += 1

func _on_timer_timeout() -> void:
	if is_game_active:
		elapsed_time += 1
