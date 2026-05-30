extends Control

signal resume
signal restart
signal open_settings
signal main_menu

@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $CenterContainer/Panel
@onready var resume_button: Button = $CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CenterContainer/Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $CenterContainer/Panel/VBoxContainer/MainMenuButton

func _ready() -> void:
	visible = false

	resume_button.pressed.connect(func(): resume.emit())
	restart_button.pressed.connect(func(): restart.emit())
	settings_button.pressed.connect(func(): open_settings.emit())
	main_menu_button.pressed.connect(func(): main_menu.emit())

	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	$CenterContainer/Panel/VBoxContainer/TitleLabel.text = Localization.translate("paused")
	resume_button.text = Localization.translate("resume")
	restart_button.text = Localization.translate("restart")
	settings_button.text = Localization.translate("settings")
	main_menu_button.text = Localization.translate("main_menu")

func show_pause() -> void:
	visible = true
	SoundManager.play_sfx("click")

func hide_pause() -> void:
	visible = false
