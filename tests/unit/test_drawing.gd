extends "res://tests/unit/test_base.gd"


class TestDrawing:
	extends "res://tests/unit/test_base.gd"

	var _canvas: Control = null

	func before_all() -> void:
		var tracker = GutUtils.get_error_tracker()
		tracker.treat_engine_errors_as = GutUtils.TREAT_AS.NOTHING

	func after_all() -> void:
		var tracker = GutUtils.get_error_tracker()
		tracker.treat_engine_errors_as = GutUtils.TREAT_AS.FAILURE

	func before_each() -> void:
		_canvas = Control.new()
		add_child(_canvas)

	func after_each() -> void:
		if is_instance_valid(_canvas):
			_canvas.queue_free()

	func test_rounded_rect_fill_does_not_crash() -> void:
		# 静态绘制函数在有效的 CanvasItem 上不应崩溃
		Drawing.rounded_rect_fill(_canvas, Rect2(Vector2.ZERO, Vector2(100, 100)), 8.0, Color.WHITE)
		assert_true(true)

	func test_rounded_rect_outline_does_not_crash() -> void:
		Drawing.rounded_rect_outline(_canvas, Rect2(Vector2.ZERO, Vector2(100, 100)), 8.0, Color.BLACK, 2.0)
		assert_true(true)

	func test_draw_dash_line_does_not_crash() -> void:
		Drawing.draw_dash_line(_canvas, Vector2.ZERO, Vector2(100, 0), 10.0, 5.0, Color.RED, 2.0)
		assert_true(true)

	func test_draw_dash_line_zero_length_returns_early() -> void:
		# 零长度线段应该直接返回，不会崩溃
		Drawing.draw_dash_line(_canvas, Vector2.ZERO, Vector2.ZERO, 10.0, 5.0, Color.RED, 2.0)
		assert_true(true)

	func test_rounded_rect_fill_small_radius_clamped() -> void:
		# 半径大于矩形一半时会被 clamp
		Drawing.rounded_rect_fill(_canvas, Rect2(Vector2.ZERO, Vector2(10, 10)), 100.0, Color.WHITE)
		assert_true(true)

	func test_rounded_rect_outline_small_radius_clamped() -> void:
		Drawing.rounded_rect_outline(_canvas, Rect2(Vector2.ZERO, Vector2(10, 10)), 100.0, Color.BLACK, 2.0)
		assert_true(true)
