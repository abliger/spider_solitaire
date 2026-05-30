extends Control

signal back_pressed
signal settings_changed

@onready var background: ColorRect = $Background
@onready var panel: Panel = $CenterContainer/Panel
@onready var sound_toggle: CheckBox = $CenterContainer/Panel/VBoxContainer/SoundToggle
@onready var music_toggle: CheckBox = $CenterContainer/Panel/VBoxContainer/MusicToggle
@onready var difficulty_label: Label = $CenterContainer/Panel/VBoxContainer/DifficultyLabel
@onready var difficulty_option: OptionButton = $CenterContainer/Panel/VBoxContainer/DifficultyOption
@onready var language_label: Label = $CenterContainer/Panel/VBoxContainer/LanguageLabel
@onready var language_option: OptionButton = $CenterContainer/Panel/VBoxContainer/LanguageOption
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/BackButton
@onready var reset_scores_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/ResetScoresButton

func _ready() -> void:
	sound_toggle.toggled.connect(_on_sound_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	language_option.item_selected.connect(_on_language_selected)
	back_button.pressed.connect(func(): back_pressed.emit())
	reset_scores_button.pressed.connect(_on_reset_scores_pressed)
	Localization.locale_changed.connect(_update_ui_text)

func show_settings() -> void:
	visible = true
	sound_toggle.button_pressed = SettingsData.sound_enabled
	music_toggle.button_pressed = SettingsData.music_enabled
	_update_ui_text()

	difficulty_option.clear()
	difficulty_option.add_item(Localization.translate("easy"), 0)
	difficulty_option.add_item(Localization.translate("medium"), 1)
	difficulty_option.add_item(Localization.translate("hard"), 2)

	match SettingsData.last_difficulty:
		1:
			difficulty_option.select(0)
		2:
			difficulty_option.select(1)
		4:
			difficulty_option.select(2)
		_:
			difficulty_option.select(0)

	language_option.clear()
	language_option.add_item(Localization.translate("lang_en"), 0)
	language_option.add_item(Localization.translate("lang_zh"), 1)
	match SettingsData.locale:
		"en":
			language_option.select(0)
		"zh":
			language_option.select(1)
		_:
			language_option.select(0)

func hide_settings() -> void:
	visible = false

func _on_sound_toggled(enabled: bool) -> void:
	SettingsData.sound_enabled = enabled
	settings_changed.emit()

func _on_music_toggled(enabled: bool) -> void:
	SettingsData.music_enabled = enabled
	settings_changed.emit()
	if enabled:
		SoundManager.play_music("bgm")
	else:
		SoundManager.stop_music()

func _on_difficulty_selected(index: int) -> void:
	var difficulty: int = 1
	match index:
		0:
			difficulty = 1
		1:
			difficulty = 2
		2:
			difficulty = 4
	SettingsData.last_difficulty = difficulty
	settings_changed.emit()

func _on_language_selected(index: int) -> void:
	var locale: String = "en"
	match index:
		0:
			locale = "en"
		1:
			locale = "zh"
	Localization.set_locale(locale)

func _update_ui_text() -> void:
	$CenterContainer/Panel/VBoxContainer/TitleLabel.text = Localization.translate("settings_title")
	sound_toggle.text = Localization.translate("sound_effects")
	music_toggle.text = Localization.translate("music")
	difficulty_label.text = Localization.translate("default_difficulty")
	language_label.text = Localization.translate("language")
	back_button.text = Localization.translate("back")
	reset_scores_button.text = Localization.translate("reset_best_scores")
	# Refresh dropdown items if they exist
	if difficulty_option.item_count >= 3:
		difficulty_option.set_item_text(0, Localization.translate("easy"))
		difficulty_option.set_item_text(1, Localization.translate("medium"))
		difficulty_option.set_item_text(2, Localization.translate("hard"))
	if language_option.item_count >= 2:
		language_option.set_item_text(0, Localization.translate("lang_en"))
		language_option.set_item_text(1, Localization.translate("lang_zh"))

func _on_reset_scores_pressed() -> void:
	SoundManager.play_sfx("click")
	SettingsData.best_scores = {}
	settings_changed.emit()
