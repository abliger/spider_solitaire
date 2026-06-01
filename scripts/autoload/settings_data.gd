extends Node

const SAVE_PATH := "user://settings.json"  # 设置文件保存路径 / Settings save file path
const SAVE_DEBOUNCE_MS := 500  # 防抖间隔（毫秒）/ Debounce interval

var sound_enabled: bool = true:
	set(value):
		sound_enabled = value
		_request_save()

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		_request_save()

var last_difficulty: int = 1:
	set(value):
		last_difficulty = value
		_request_save()

var locale: String = "en":
	set(value):
		locale = value
		_request_save()

var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_fullscreen()
		_request_save()

var best_scores: Dictionary = {}:  # 各难度的最高分记录 { "difficulty_1": {score, time, moves} }
	set(value):
		best_scores = value
		_request_save()

var _save_timer: Timer = null  # 防抖保存定时器 / Debounce timer

func _ready() -> void:
	_load_settings()
	_save_timer = Timer.new()
	_save_timer.wait_time = SAVE_DEBOUNCE_MS / 1000.0
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_save_settings)
	add_child(_save_timer)

func _save_settings() -> void:
	# 将所有设置序列化为 JSON 并写入文件
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"last_difficulty": last_difficulty,
		"locale": locale,
		"fullscreen": fullscreen,
		"best_scores": best_scores
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_settings() -> void:
	# 从文件读取并反序列化设置，若文件不存在则使用默认值
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(text)
	if result is Dictionary:
		sound_enabled = result.get("sound_enabled", true)
		music_enabled = result.get("music_enabled", true)
		last_difficulty = result.get("last_difficulty", 1)
		locale = result.get("locale", "en")
		fullscreen = result.get("fullscreen", false)
		var loaded_scores = result.get("best_scores", {})
		if loaded_scores is Dictionary:
			best_scores = loaded_scores

func _apply_fullscreen() -> void:
	# 应用全屏设置 / Apply fullscreen setting
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _request_save() -> void:
	# 请求防抖保存；若定时器已启动则重置时间
	if _save_timer != null:
		_save_timer.start()

func update_best_score(difficulty: int, new_score: int, time: int, moves: int) -> void:
	# 更新指定难度的最佳记录：以分数为首要指标，同分时取时间/步数更优者
	var key := "difficulty_%d" % difficulty
	var current = best_scores.get(key, {"score": 0, "time": 99999, "moves": 99999})
	var should_update := false
	if new_score > current["score"]:
		should_update = true
	elif new_score == current["score"]:
		if time < current["time"] or moves < current["moves"]:
			should_update = true
	if should_update:
		best_scores[key] = {"score": new_score, "time": time, "moves": moves}
		_request_save()
