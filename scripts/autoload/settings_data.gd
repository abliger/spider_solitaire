extends Node

const SAVE_PATH := "user://settings.json"

var sound_enabled: bool = true:
	set(value):
		sound_enabled = value
		_save_settings()

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		_save_settings()

var last_difficulty: int = 1:
	set(value):
		last_difficulty = value
		_save_settings()

var locale: String = "en":
	set(value):
		locale = value
		_save_settings()

var best_scores: Dictionary = {}  # { "difficulty_1": {score, time, moves} }

func _ready() -> void:
	_load_settings()

func _save_settings() -> void:
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
