extends Control

# HUD 按钮按下信号 / HUD button press signals
signal undo_pressed   # 撤销按钮被按下 / Undo button pressed
signal hint_pressed   # 提示按钮被按下 / Hint button pressed
signal pause_pressed  # 暂停按钮被按下 / Pause button pressed

# 顶部栏 UI 节点引用 / Top bar UI node references
@onready var score_label: Label = $TopBar/StatsContainer/ScoreLabel
@onready var time_label: Label = $TopBar/StatsContainer/TimeLabel
@onready var moves_label: Label = $TopBar/StatsContainer/MovesLabel
@onready var difficulty_label: Label = $TopBar/StatsContainer/DifficultyLabel
@onready var undo_button: Button = $TopBar/ButtonsContainer/UndoButton
@onready var hint_button: Button = $TopBar/ButtonsContainer/HintButton
@onready var pause_button: Button = $TopBar/ButtonsContainer/PauseButton

func _ready() -> void:
	# HUD 是全屏控件，必须设为 IGNORE，否则它会拦截所有 _gui_input
	# 事件，导致 Board/Card/Stock 永远收不到点击。
	# TopBar（Panel，默认 STOP）和 Button（默认 STOP）仍然能正常接收事件。
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 监听语言切换，更新所有 UI 文本
	Localization.locale_changed.connect(_update_ui_text)
	_update_ui_text()

	# 初始化各项统计显示
	_update_difficulty_label()
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)

	# 连接游戏状态变化信号以实时更新 HUD
	GameState.score_changed.connect(_update_score_label)
	GameState.move_count_changed.connect(_update_moves_label)
	GameState.time_changed.connect(_update_time_label)
	GameState.game_started.connect(_on_game_started)
	GameState.game_won.connect(_on_game_won)

	# 连接按钮按下事件到信号发射
	undo_button.pressed.connect(func(): undo_pressed.emit())
	hint_button.pressed.connect(func(): hint_pressed.emit())
	pause_button.pressed.connect(func(): pause_pressed.emit())

func _on_game_started() -> void:
	# 游戏开始时重置并显示 HUD 所有数据
	_update_difficulty_label()
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)
	visible = true

func _on_game_won() -> void:
	# 游戏胜利时隐藏 HUD
	visible = false

func _update_ui_text() -> void:
	# 根据当前语言更新所有按钮和标签文本
	undo_button.text = Localization.translate("undo")
	hint_button.text = Localization.translate("hint")
	pause_button.text = Localization.translate("pause")
	# 使用当前值刷新统计标签
	_update_score_label(GameState.score)
	_update_time_label(GameState.elapsed_time)
	_update_moves_label(GameState.move_count)
	_update_difficulty_label()

func _update_score_label(new_score: int) -> void:
	# 更新分数标签显示
	score_label.text = Localization.translate("score") % new_score

func _update_time_label(new_time: int) -> void:
	# 将秒数转换为 MM:SS 格式并更新时间标签
	var minutes: int = new_time / 60
	var seconds: int = new_time % 60
	time_label.text = Localization.translate("time") % [minutes, seconds]

func _update_moves_label(new_count: int) -> void:
	# 更新步数标签显示
	moves_label.text = Localization.translate("moves") % new_count

func _update_difficulty_label() -> void:
	# 根据当前难度设置显示对应的难度文本
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
