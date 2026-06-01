extends Control

# 暂停菜单发出的信号 / Signals emitted by the pause menu
signal resume         # 请求继续游戏 / Request to resume the game
signal restart        # 请求重新开始 / Request to restart
signal open_settings  # 请求打开设置 / Request to open settings
signal main_menu      # 请求返回主菜单 / Request to return to main menu

# 暂停菜单 UI 节点引用 / Pause menu UI node references
@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $CenterContainer/Panel
@onready var resume_button: Button = $CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CenterContainer/Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $CenterContainer/Panel/VBoxContainer/MainMenuButton

func _ready() -> void:
	# 初始状态下隐藏暂停菜单
	visible = false

	# 连接按钮按下事件到对应信号
	resume_button.pressed.connect(func(): resume.emit())
	restart_button.pressed.connect(func(): restart.emit())
	settings_button.pressed.connect(func(): open_settings.emit())
	main_menu_button.pressed.connect(func(): main_menu.emit())

	# 监听语言切换并初始化 UI 文本
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	# 根据当前语言更新暂停菜单的所有文本
	$CenterContainer/Panel/VBoxContainer/TitleLabel.text = Localization.translate("paused")
	resume_button.text = Localization.translate("resume")
	restart_button.text = Localization.translate("restart")
	settings_button.text = Localization.translate("settings")
	main_menu_button.text = Localization.translate("main_menu")


