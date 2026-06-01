extends Control

# 规则面板发出的信号 / Signals emitted by the rules panel
signal close_pressed  # 请求关闭规则面板 / Request to close the rules panel

# 规则面板 UI 节点引用 / Rules panel UI node references
@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var rules_label: Label = $CenterContainer/Panel/VBoxContainer/ScrollContainer/RulesLabel
@onready var close_button: Button = $CenterContainer/Panel/VBoxContainer/CloseButton

func _ready() -> void:
	# 初始状态下隐藏规则面板
	visible = false

	# 连接按钮按下事件
	close_button.pressed.connect(func(): close_pressed.emit())

	# 监听语言切换并初始化 UI 文本
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	# 根据当前语言更新规则面板的所有文本
	title_label.text = Localization.translate("rules_title")
	rules_label.text = Localization.translate("rules_text")
	close_button.text = Localization.translate("close")

func show_rules() -> void:
	# 显示规则面板并播放点击音效
	visible = true
	SoundManager.play_sfx("click")

func hide_rules() -> void:
	# 隐藏规则面板
	visible = false
