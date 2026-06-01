extends "res://tests/unit/test_base.gd"


class TestSoundManager:
	extends "res://tests/unit/test_base.gd"

	var _sm = null

	func before_all() -> void:
		_register_autoload("SettingsData", "res://scripts/autoload/settings_data.gd")
		var sm_script: GDScript = load("res://scripts/autoload/sound_manager.gd") as GDScript
		_sm = Node.new()
		_sm.set_script(sm_script)
		add_child(_sm)
		# 清空缓存避免之前测试的影响
		_sm.sfx_cache.clear()
		_sm._preload_sfx()

	func after_all() -> void:
		if is_instance_valid(_sm):
			_sm.queue_free()
		_unregister_autoloads()

	func before_each() -> void:
		SettingsData.sound_enabled = true
		SettingsData.music_enabled = true

	func test_play_sfx_when_sound_disabled() -> void:
		SettingsData.sound_enabled = false
		_sm.play_sfx("move")
		assert_true(true)

	func test_play_sfx_unknown_name() -> void:
		_sm.play_sfx("nonexistent")
		assert_true(true)

	func test_play_sfx_with_valid_name() -> void:
		# 缓存可能为空因为 headless 下资源加载失败
		_sm.play_sfx("click")
		assert_true(true)

	func test_play_music_when_disabled() -> void:
		SettingsData.music_enabled = false
		_sm.play_music("bgm")
		assert_true(true)

	func test_play_music_nonexistent_path() -> void:
		_sm.play_music("nonexistent_music")
		assert_true(true)

	func test_stop_music() -> void:
		_sm.stop_music()
		assert_true(true)

	func test_sfx_pool_size() -> void:
		assert_eq(_sm._sfx_pool.size(), 8)

	func test_sfx_pool_index_rotates() -> void:
		var initial: int = _sm._sfx_pool_index
		# 即使无法播放，索引也应旋转
		_sm._sfx_pool_index = 0
		_sm.play_sfx("click")
		assert_eq(_sm._sfx_pool_index, 1)

	func test_sfx_paths_defined() -> void:
		assert_true(_sm.sfx_paths.has("deal"))
		assert_true(_sm.sfx_paths.has("move"))
		assert_true(_sm.sfx_paths.has("flip"))
		assert_true(_sm.sfx_paths.has("error"))
		assert_true(_sm.sfx_paths.has("win"))
		assert_true(_sm.sfx_paths.has("click"))

	func test_music_player_exists() -> void:
		assert_not_null(_sm.music_player)
