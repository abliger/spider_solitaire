extends Control

# 设置界面发出的信号 / Signals emitted by the settings panel
signal back_pressed      # 返回按钮被按下 / Back button pressed
signal settings_changed  # 设置项发生变化 / A setting has changed

# 设置界面 UI 节点引用 / Settings UI node references
@onready var background: ColorRect = $Background
@onready var panel: Panel = $CenterContainer/Panel
@onready var sound_toggle: CheckBox = $CenterContainer/Panel/VBoxContainer/SoundToggle
@onready var music_toggle: CheckBox = $CenterContainer/Panel/VBoxContainer/MusicToggle
@onready var fullscreen_toggle: CheckBox = $CenterContainer/Panel/VBoxContainer/FullscreenToggle
@onready var difficulty_label: Label = $CenterContainer/Panel/VBoxContainer/DifficultyLabel
@onready var difficulty_option: OptionButton = $CenterContainer/Panel/VBoxContainer/DifficultyOption
@onready var language_label: Label = $CenterContainer/Panel/VBoxContainer/LanguageLabel
@onready var language_option: OptionButton = $CenterContainer/Panel/VBoxContainer/LanguageOption
@onready var back_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/BackButton
@onready var reset_scores_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonRow/ResetScoresButton

func _ready() -> void:
	# 连接所有设置控件的交互信号
	sound_toggle.toggled.connect(_on_sound_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	language_option.item_selected.connect(_on_language_selected)
	back_button.pressed.connect(func(): back_pressed.emit())
	reset_scores_button.pressed.connect(_on_reset_scores_pressed)
	Localization.locale_changed.connect(_update_ui_text)

func show_settings() -> void:
	# 显示设置界面并同步控件状态到当前设置值
	visible = true
	sound_toggle.button_pressed = SettingsData.sound_enabled
	music_toggle.button_pressed = SettingsData.music_enabled
	fullscreen_toggle.button_pressed = SettingsData.fullscreen
	_update_ui_text()

	# 填充并选中默认难度下拉框
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

	# 填充并选中语言下拉框
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
	# 隐藏设置界面
	visible = false

func _on_sound_toggled(enabled: bool) -> void:
	# 切换音效开关
	SettingsData.sound_enabled = enabled
	settings_changed.emit()

func _on_music_toggled(enabled: bool) -> void:
	# 切换音乐开关，开启时自动播放背景音乐
	SettingsData.music_enabled = enabled
	settings_changed.emit()
	if enabled:
		SoundManager.play_music("bgm")
	else:
		SoundManager.stop_music()

func _on_fullscreen_toggled(enabled: bool) -> void:
	# 切换全屏开关
	SettingsData.fullscreen = enabled
	settings_changed.emit()

func _on_difficulty_selected(index: int) -> void:
	# 根据下拉框索引映射到实际难度值并保存
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
	# 根据下拉框索引切换语言
	var locale: String = "en"
	match index:
		0:
			locale = "en"
		1:
			locale = "zh"
	Localization.set_locale(locale)

func _update_ui_text() -> void:
	# 根据当前语言更新设置界面所有文本
	$CenterContainer/Panel/VBoxContainer/TitleLabel.text = Localization.translate("settings_title")
	sound_toggle.text = Localization.translate("sound_effects")
	music_toggle.text = Localization.translate("music")
	fullscreen_toggle.text = Localization.translate("fullscreen")
	difficulty_label.text = Localization.translate("default_difficulty")
	language_label.text = Localization.translate("language")
	back_button.text = Localization.translate("back")
	reset_scores_button.text = Localization.translate("reset_best_scores")
	# 如果下拉框已有选项，刷新其文本以匹配当前语言
	if difficulty_option.item_count >= 3:
		difficulty_option.set_item_text(0, Localization.translate("easy"))
		difficulty_option.set_item_text(1, Localization.translate("medium"))
		difficulty_option.set_item_text(2, Localization.translate("hard"))
	if language_option.item_count >= 2:
		language_option.set_item_text(0, Localization.translate("lang_en"))
		language_option.set_item_text(1, Localization.translate("lang_zh"))

func _on_reset_scores_pressed() -> void:
	# 重置最高分记录
	SoundManager.play_sfx("click")
	SettingsData.best_scores = {}
	settings_changed.emit()
