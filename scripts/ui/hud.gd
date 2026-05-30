extends Control

signal undo_pressed
signal hint_pressed
signal pause_pressed

@onready var score_label: Label = $TopBar/StatsContainer/ScoreLabel
@onready var time_label: Label = $TopBar/StatsContainer/TimeLabel
@onready var moves_label: Label = $TopBar/StatsContainer/MovesLabel
@onready var difficulty_label: Label = $TopBar/StatsContainer/DifficultyLabel
@onready var undo_button: Button = $TopBar/ButtonsContainer/UndoButton
@onready var hint_button: Button = $TopBar/ButtonsContainer/HintButton
@onready var pause_button: Button = $TopBar/ButtonsContainer/PauseButton

func _ready() -> void:
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

	_update_difficulty_label()
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)

	GameState.score_changed.connect(_update_score_label)
	GameState.move_count_changed.connect(_update_moves_label)
	GameState.time_changed.connect(_update_time_label)
	GameState.game_started.connect(_on_game_started)
	GameState.game_won.connect(_on_game_won)

	undo_button.pressed.connect(func(): undo_pressed.emit())
	hint_button.pressed.connect(func(): hint_pressed.emit())
	pause_button.pressed.connect(func(): pause_pressed.emit())

func _on_game_started() -> void:
	_update_difficulty_label()
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)
	visible = true

func _on_game_won() -> void:
	visible = false

func _update_ui_text() -> void:
	undo_button.text = Localization.translate("undo")
	hint_button.text = Localization.translate("hint")
	pause_button.text = Localization.translate("pause")
	# Refresh stat labels with current values
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)
	_update_difficulty_label()

func _update_score_label(new_score: int) -> void:
	score_label.text = Localization.translate("score") % new_score

func _update_time_label(new_time: int) -> void:
	var minutes: int = new_time / 60
	var seconds: int = new_time % 60
	time_label.text = Localization.translate("time") % [minutes, seconds]

func _update_moves_label(new_count: int) -> void:
	moves_label.text = Localization.translate("moves") % new_count

func _update_difficulty_label() -> void:
	var diff_key := "diff_easy"
	match GameState.current_difficulty:
		GameState.Difficulty.EASY:
			diff_key = "diff_easy"
		GameState.Difficulty.MEDIUM:
			diff_key = "diff_medium"
		GameState.Difficulty.HARD:
			diff_key = "diff_hard"
		_:
			diff_key = "diff_easy"
	difficulty_label.text = Localization.translate("difficulty") % Localization.translate(diff_key)
