extends "res://tests/unit/test_base.gd"


class TestSettingsData:
	extends "res://tests/unit/test_base.gd"

	var _settings = null

	func before_each() -> void:
		var script: GDScript = load("res://scripts/autoload/settings_data.gd") as GDScript
		_settings = Node.new()
		_settings.set_script(script)
		add_child(_settings)
		# 重置为默认值，避免文件加载影响
		_settings.sound_enabled = true
		_settings.music_enabled = true
		_settings.last_difficulty = 1
		_settings.locale = "en"
		_settings.fullscreen = false
		_settings.best_scores = {}

	func after_each() -> void:
		if is_instance_valid(_settings):
			_settings.queue_free()

	func test_default_values() -> void:
		assert_true(_settings.sound_enabled)
		assert_true(_settings.music_enabled)
		assert_eq(_settings.last_difficulty, 1)
		assert_eq(_settings.locale, "en")
		assert_false(_settings.fullscreen)
		assert_eq(_settings.best_scores.size(), 0)

	func test_set_sound_enabled_triggers_save_request() -> void:
		_settings.sound_enabled = false
		assert_false(_settings.sound_enabled)

	func test_set_music_enabled_triggers_save_request() -> void:
		_settings.music_enabled = false
		assert_false(_settings.music_enabled)

	func test_set_last_difficulty() -> void:
		_settings.last_difficulty = 2
		assert_eq(_settings.last_difficulty, 2)

	func test_set_locale() -> void:
		_settings.locale = "zh"
		assert_eq(_settings.locale, "zh")

	func test_set_fullscreen() -> void:
		_settings.fullscreen = true
		assert_true(_settings.fullscreen)

	func test_set_best_scores() -> void:
		var scores := {"difficulty_1": {"score": 100, "time": 60, "moves": 10}}
		_settings.best_scores = scores
		assert_eq(_settings.best_scores["difficulty_1"]["score"], 100)

	func test_update_best_score_new_high() -> void:
		_settings.update_best_score(1, 200, 120, 20)
		var record = _settings.best_scores["difficulty_1"]
		assert_eq(record["score"], 200)

	func test_update_best_score_does_not_update_lower() -> void:
		_settings.update_best_score(1, 200, 120, 20)
		_settings.update_best_score(1, 100, 60, 10)
		var record = _settings.best_scores["difficulty_1"]
		assert_eq(record["score"], 200)

	func test_update_best_score_same_score_better_time() -> void:
		_settings.update_best_score(1, 200, 120, 20)
		_settings.update_best_score(1, 200, 100, 20)
		var record = _settings.best_scores["difficulty_1"]
		assert_eq(record["time"], 100)

	func test_update_best_score_same_score_better_moves() -> void:
		_settings.update_best_score(1, 200, 120, 20)
		_settings.update_best_score(1, 200, 120, 15)
		var record = _settings.best_scores["difficulty_1"]
		assert_eq(record["moves"], 15)

	func test_save_and_load_settings() -> void:
		_settings.sound_enabled = false
		_settings.last_difficulty = 4
		_settings.best_scores = {"difficulty_1": {"score": 300, "time": 90, "moves": 15}}
		_settings._save_settings()

		var new_settings = Node.new()
		new_settings.set_script(load("res://scripts/autoload/settings_data.gd"))
		add_child(new_settings)
		new_settings._load_settings()

		assert_false(new_settings.sound_enabled)
		assert_eq(new_settings.last_difficulty, 4)
		assert_eq(new_settings.best_scores["difficulty_1"]["score"], 300)

		new_settings.queue_free()
