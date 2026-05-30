extends Control

# 主菜单发出的信号 / Signals emitted by the main menu
signal start_game(difficulty: int)  # 请求以指定难度开始新游戏 / Request to start a new game with difficulty
signal continue_game                # 请求继续之前的游戏 / Request to continue a previous game
signal open_settings                # 请求打开设置界面 / Request to open settings
signal quit                         # 请求退出游戏 / Request to quit the game

# 菜单 UI 节点引用 / Menu UI node references
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
	# 根据是否有进行中的游戏显示/隐藏继续按钮
	continue_button.visible = _has_saved_game()

	# 主菜单按钮连接
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(func(): continue_game.emit())
	settings_button.pressed.connect(func(): open_settings.emit())
	quit_button.pressed.connect(func(): quit.emit())

	# 难度选择按钮连接
	easy_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.EASY))
	medium_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.MEDIUM))
	hard_button.pressed.connect(func(): _start_with_difficulty(GameState.Difficulty.HARD))
	back_button.pressed.connect(_on_difficulty_back_pressed)

	# 监听语言切换并初始化 UI 文本
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	# 根据当前语言更新所有按钮和标题文本
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
	# 判断是否存在可以继续的游戏（步数或时间大于 0）
	return GameState.move_count > 0 or GameState.elapsed_time > 0

func _on_new_game_pressed() -> void:
	# 点击新游戏：隐藏主菜单按钮，显示难度选择面板
	buttons_container.visible = false
	difficulty_panel.visible = true
	SoundManager.play_sfx("click")

func _start_with_difficulty(difficulty: int) -> void:
	# 选择难度后发出开始游戏信号
	SoundManager.play_sfx("click")
	start_game.emit(difficulty)

func _on_difficulty_back_pressed() -> void:
	# 返回主菜单按钮列表
	SoundManager.play_sfx("click")
	difficulty_panel.visible = false
	buttons_container.visible = true

func show_menu() -> void:
	# 显示主菜单，并重新检查是否显示继续按钮
	visible = true
	continue_button.visible = _has_saved_game()
	buttons_container.visible = true
	difficulty_panel.visible = false
