extends "res://tests/unit/test_base.gd"


class TestLocalization:
	extends "res://tests/unit/test_base.gd"

	var _loc = null

	func before_each() -> void:
		var script: GDScript = load("res://scripts/autoload/localization.gd") as GDScript
		_loc = Node.new()
		_loc.set_script(script)
		add_child(_loc)
		_loc._current_locale = "en"

	func after_each() -> void:
		if is_instance_valid(_loc):
			_loc.queue_free()

	func test_translate_returns_english_default() -> void:
		assert_eq(_loc.translate("new_game"), "New Game")

	func test_translate_returns_key_if_missing() -> void:
		assert_eq(_loc.translate("nonexistent_key"), "nonexistent_key")

	func test_set_locale_changes_language() -> void:
		_loc.set_locale("zh")
		assert_eq(_loc.translate("new_game"), "新游戏")

	func test_set_locale_emits_signal() -> void:
		watch_signals(_loc)
		_loc.set_locale("zh")
		assert_signal_emitted(_loc, "locale_changed")

	func test_set_locale_same_does_not_emit() -> void:
		watch_signals(_loc)
		_loc.set_locale("en")
		assert_signal_not_emitted(_loc, "locale_changed")

	func test_set_locale_unsupported_does_nothing() -> void:
		_loc.set_locale("fr")
		assert_eq(_loc.get_locale(), "en")

	func test_get_locale() -> void:
		assert_eq(_loc.get_locale(), "en")

	func test_get_supported_locales() -> void:
		var locales = _loc.get_supported_locales()
		assert_true(locales.has("en"))
		assert_true(locales.has("zh"))

	func test_get_locale_display_name() -> void:
		assert_eq(_loc.get_locale_display_name("en"), "English")
		_loc.set_locale("zh")
		assert_eq(_loc.get_locale_display_name("zh"), "中文")

	func test_translate_zh_stock_left() -> void:
		_loc.set_locale("zh")
		assert_eq(_loc.translate("stock_left"), "剩余 %d")
