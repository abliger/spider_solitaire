extends Control

signal start_game(difficulty: int)
signal continue_game
signal open_settings
signal quit

@onready var title_label: Label = $CenterContainer/MenuPanel/VBoxContainer/TitleLabel
@onready var buttons_container: VBoxContainer = $CenterContainer/MenuPanel/VBoxContainer/ButtonsContainer
@onready var new_game_button: Button = $CenterContainer/MenuPanel/VBoxContainer/ButtonsContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/MenuPanel/VBoxContainer/ButtonsContainer/ContinueButton
@onready var settings_button: Button = $CenterContainer/MenuPanel/VBoxContainer/ButtonsContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/MenuPanel/VBoxContainer/ButtonsContainer/QuitButton
@onready var difficulty_panel: Panel = $CenterContainer/DifficultyPanel
@onready var easy_button: Button = $CenterContainer/DifficultyPanel/VBoxContainer/EasyButton
@onready var medium_button: Button = $CenterContainer/DifficultyPanel/VBoxContainer/MediumButton
@onready var hard_button: Button = $CenterContainer/DifficultyPanel/VBoxContainer/HardButton
@onready var back_button: Button = $CenterContainer/DifficultyPanel/VBoxContainer/BackButton

func _ready() -> void:
	continue_button.visible = _has_saved_game()

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(func(): continue_game.emit())
	settings_button.pressed.connect(func(): open_settings.emit())
	quit_button.pressed.connect(func(): quit.emit())

	easy_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.EASY))
	medium_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.MEDIUM))
	hard_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.HARD))
	back_button.pressed.connect(_on_difficulty_back_pressed)

	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	title_label.text = Localization.translate("title")
	new_game_button.text = Localization.translate("new_game")
	continue_button.text = Localization.translate("continue")
	settings_button.text = Localization.translate("settings")
	quit_button.text = Localization.translate("quit")
	$CenterContainer/DifficultyPanel/VBoxContainer/DifficultyTitle.text = Localization.translate("select_difficulty")
	easy_button.text = Localization.translate("easy")
	medium_button.text = Localization.translate("medium")
	hard_button.text = Localization.translate("hard")
	back_button.text = Localization.translate("back")

func _has_saved_game() -> bool:
	return GameState.move_count > 0 or GameState.elapsed_time > 0

func _on_new_game_pressed() -> void:
	buttons_container.visible = false
	difficulty_panel.visible = true
	SoundManager.play_sfx("click")

func _start_with_difficulty(difficulty: int) -> void:
	SoundManager.play_sfx("click")
	start_game.emit(difficulty)

func _on_difficulty_back_pressed() -> void:
	SoundManager.play_sfx("click")
	difficulty_panel.visible = false
	buttons_container.visible = true

func show_menu() -> void:
	visible = true
	continue_button.visible = _has_saved_game()
	buttons_container.visible = true
	difficulty_panel.visible = false
