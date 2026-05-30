extends Control

# 胜利面板发出的信号 / Signals emitted by the victory panel
signal play_again   # 请求再玩一次 / Request to play again
signal main_menu    # 请求返回主菜单 / Request to return to main menu

# 胜利面板 UI 节点引用 / Victory panel UI node references
@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/ScoreLabel
@onready var time_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var moves_label: Label = $CenterContainer/Panel/VBoxContainer/StatsContainer/MovesLabel
@onready var play_again_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonsContainer/PlayAgainButton
@onready var main_menu_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonsContainer/MainMenuButton

var _title_base_scale := Vector2.ONE  # 标题标签的原始缩放 / Base scale of the title label
var _animation_time := 0.0            # 动画已运行的时间 / Elapsed animation time

func _ready() -> void:
	# 初始状态下隐藏胜利面板
	visible = false

	# 连接按钮按下事件
	play_again_button.pressed.connect(func(): play_again.emit())
	main_menu_button.pressed.connect(func(): main_menu.emit())

	# 监听语言切换并初始化 UI 文本
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

func _update_ui_text() -> void:
	# 根据当前语言更新胜利面板文本
	title_label.text = Localization.translate("you_won")
	play_again_button.text = Localization.translate("play_again")
	main_menu_button.text = Localization.translate("main_menu")

func show_victory(final_score: int, final_time: int, final_moves: int) -> void:
	# 显示胜利面板并填充最终统计数据
	visible = true
	score_label.text = Localization.translate("final_score") % final_score
	# 将秒数转换为 MM:SS 格式
	var minutes: int = final_time / 60
	var seconds: int = final_time % 60
	time_label.text = Localization.translate("time") % [minutes, seconds]
	moves_label.text = Localization.translate("moves") % final_moves

	# 初始化标题动画：从零缩放开始，配合弹性效果
	_animation_time = 0.0
	_title_base_scale = title_label.scale
	title_label.scale = Vector2.ZERO
	set_process(true)

func _process(delta: float) -> void:
	# 处理标题弹性动画
	if not visible:
		return

	_animation_time += delta * 3.0
	var t := clampf(_animation_time, 0.0, 1.0)
	# 计算弹性 bounce 效果：前半段放大，后半段回弹
	var bounce := 1.0 + 0.2 * sin(t * PI * 2.0) * (1.0 - t)
	var scale_val := ease_out_back(t) * bounce
	title_label.scale = Vector2(scale_val, scale_val)

	# 动画完成后停止处理
	if t >= 1.0:
		set_process(false)

func ease_out_back(t: float) -> float:
	# 缓动函数：带回弹效果的 ease-out
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

func hide_victory() -> void:
	# 隐藏胜利面板
	visible = false
