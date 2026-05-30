extends Node

const SAVE_PATH := "user://settings.json"  # 设置文件保存路径 / Settings save file path

var sound_enabled: bool = true:
	set(value):
		sound_enabled = value
		_save_settings()  # 修改后自动保存 / Auto-save on change

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		_save_settings()  # 修改后自动保存 / Auto-save on change

var last_difficulty: int = 1:
	set(value):
		last_difficulty = value
		_save_settings()  # 修改后自动保存 / Auto-save on change

var locale: String = "en":
	set(value):
		locale = value
		_save_settings()  # 修改后自动保存 / Auto-save on change

var best_scores: Dictionary = {}  # 各难度的最高分记录 { "difficulty_1": {score, time, moves} }

func _ready() -> void:
	# 启动时加载已保存的设置
	_load_settings()

func _save_settings() -> void:
	# 将所有设置序列化为 JSON 并写入文件
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"last_difficulty": last_difficulty,
		"locale": locale,
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
		var loaded_scores = result.get("best_scores", {})
		if loaded_scores is Dictionary:
			best_scores = loaded_scores

func update_best_score(difficulty: int, new_score: int, time: int, moves: int) -> void:
	# 更新指定难度的最佳记录（分数更高、时间更短、步数更少即更新）
	var key := "difficulty_%d" % difficulty
	var current = best_scores.get(key, {"score": 0, "time": 99999, "moves": 99999})
	var updated := false
	if new_score > current["score"]:
		current["score"] = new_score
		updated = true
	if time < current["time"]:
		current["time"] = time
		updated = true
	if moves < current["moves"]:
		current["moves"] = moves
		updated = true
	if updated:
		best_scores[key] = current
		_save_settings()
