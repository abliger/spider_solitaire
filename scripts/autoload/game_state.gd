extends Node

# 游戏状态变化信号 / Game state change signals
signal score_changed(new_score: int)      # 分数变化时发出 / Emitted when score changes
signal move_count_changed(new_count: int)  # 步数变化时发出 / Emitted when move count changes
signal time_changed(new_time: int)         # 时间变化时发出 / Emitted when elapsed time changes
signal game_won                             # 游戏胜利时发出 / Emitted when the game is won
signal game_started                         # 游戏开始时发出 / Emitted when the game starts
signal game_reset                           # 游戏重置时发出 / Emitted when the game is reset

# 难度枚举：数值同时表示花色数量 / Difficulty enum: values also represent suit count
enum Difficulty { EASY = 1, MEDIUM = 2, HARD = 4 }

var current_difficulty: Difficulty = Difficulty.EASY  # 当前难度 / Current difficulty level

var score: int = 500:
	set(value):
		score = value
		score_changed.emit(score)  # 通知监听者分数已更新 / Notify listeners of score update

var move_count: int = 0:
	set(value):
		move_count = value
		move_count_changed.emit(move_count)  # 通知监听者步数已更新 / Notify listeners of move count update

var elapsed_time: int = 0:
	set(value):
		elapsed_time = value
		time_changed.emit(elapsed_time)  # 通知监听者时间已更新 / Notify listeners of time update

var is_game_active: bool = false  # 游戏是否正在进行中 / Whether the game is currently active

var _timer: Timer  # 用于计时的内部计时器 / Internal timer for tracking elapsed time

func _ready() -> void:
	# 创建并配置每秒触发一次的计时器
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func start_game(difficulty: Difficulty = current_difficulty) -> void:
	# 初始化游戏状态并开始计时
	current_difficulty = difficulty
	score = 500
	move_count = 0
	elapsed_time = 0
	is_game_active = true
	_timer.start()
	game_started.emit()

func end_game() -> void:
	# 结束游戏，停止计时并发出胜利信号
	is_game_active = false
	_timer.stop()
	game_won.emit()

func reset_game() -> void:
	# 重置所有游戏状态到初始值
	is_game_active = false
	_timer.stop()
	score = 500
	move_count = 0
	elapsed_time = 0
	game_reset.emit()

func add_score(delta: int) -> void:
	# 增加（或减少）分数，最低为 0 / Add or subtract from the score, clamped to minimum 0
	score = maxi(0, score + delta)

func increment_move() -> void:
	# 步数加一 / Increment the move counter by one
	move_count += 1

func _on_timer_timeout() -> void:
	# 每秒触发一次：如果游戏进行中，增加已用时间
	if is_game_active:
		elapsed_time += 1
