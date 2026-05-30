extends Control

signal play_again
signal main_menu

@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/ScoreLabel
@onready var time_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var moves_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/MovesLabel
@onready var play_again_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonsContainer/PlayAgainButton
@onready var main_menu_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonsContainer/MainMenuButton

var _title_base_scale := Vector2.ONE
var _animation_time := 0.0

func _ready() -> void:
	visible = false
	play_again_button.pressed.connect(func(): play_again.emit())
	main_menu_button.pressed.connect(func(): main_menu.emit())
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	title_label.text = Localization.translate("you_won")
	play_again_button.text = Localization.translate("play_again")
	main_menu_button.text = Localization.translate("main_menu")

func show_victory(final_score: int, final_time: int, final_moves: int) -> void:
	visible = true
	score_label.text = Localization.translate("final_score") % final_score
	var minutes: int = final_time / 60
	var seconds: int = final_time % 60
	time_label.text = Localization.translate("time") % [minutes, seconds]
	moves_label.text = Localization.translate("moves") % final_moves

	_animation_time = 0.0
	_title_base_scale = title_label.scale
	title_label.scale = Vector2.ZERO
	set_process(true)

func _process(delta: float) -> void:
	if not visible:
		return

	_animation_time += delta * 3.0
	var t := clampf(_animation_time, 0.0, 1.0)
	var bounce := 1.0 + 0.2 * sin(t * PI * 2.0) * (1.0 - t)
	var scale_val := ease_out_back(t) * bounce
	title_label.scale = Vector2(scale_val, scale_val)

	if t >= 1.0:
		set_process(false)

func ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

func hide_victory() -> void:
	visible = false
