extends "res://tests/unit/test_base.gd"


class TestGameState:
	extends "res://tests/unit/test_base.gd"

	var _gs = null
	var _score_changed_count: int = 0
	var _move_count_changed_count: int = 0

	func before_each() -> void:
		var script: GDScript = load("res://scripts/autoload/game_state.gd") as GDScript
		_gs = Node.new()
		_gs.set_script(script)
		add_child(_gs)
		_score_changed_count = 0
		_move_count_changed_count = 0
		_gs.score_changed.connect(func(_v): _score_changed_count += 1)
		_gs.move_count_changed.connect(func(_v): _move_count_changed_count += 1)

	func after_each() -> void:
		if is_instance_valid(_gs):
			_gs.queue_free()

	func test_start_game_resets_state() -> void:
		_gs.start_game(2)
		assert_eq(_gs.score, 500)
		assert_eq(_gs.move_count, 0)
		assert_eq(_gs.elapsed_time, 0)
		assert_true(_gs.is_game_active)
		assert_eq(_gs.current_difficulty, 2)

	func test_start_game_emits_game_started() -> void:
		watch_signals(_gs)
		_gs.start_game()
		assert_signal_emitted(_gs, "game_started")

	func test_end_game_sets_inactive() -> void:
		_gs.start_game()
		_gs.end_game()
		assert_false(_gs.is_game_active)

	func test_end_game_emits_game_won() -> void:
		watch_signals(_gs)
		_gs.start_game()
		_gs.end_game()
		assert_signal_emitted(_gs, "game_won")

	func test_reset_game_sets_inactive() -> void:
		_gs.start_game()
		_gs.reset_game()
		assert_false(_gs.is_game_active)

	func test_reset_game_emits_game_reset() -> void:
		watch_signals(_gs)
		_gs.start_game()
		_gs.reset_game()
		assert_signal_emitted(_gs, "game_reset")

	func test_add_score_increases_score() -> void:
		_gs.start_game()
		_gs.add_score(50)
		assert_eq(_gs.score, 550)

	func test_add_score_clamps_to_zero() -> void:
		_gs.start_game()
		_gs.add_score(-600)
		assert_eq(_gs.score, 0)

	func test_increment_move_increases_count() -> void:
		_gs.start_game()
		_gs.increment_move()
		assert_eq(_gs.move_count, 1)

	func test_score_changed_signal_emitted() -> void:
		_gs.start_game()
		_gs.add_score(10)
		# start_game sets score=500 (emits 1) + add_score(10) changes to 510 (emits 1) = 2 total
		assert_eq(_score_changed_count, 2)

	func test_move_count_changed_signal_emitted() -> void:
		_gs.start_game()
		_gs.increment_move()
		# start_game sets move_count=0 (emits 1) + increment_move (emits 1) = 2 total
		assert_eq(_move_count_changed_count, 2)

	func test_timer_increments_elapsed_time() -> void:
		_gs.start_game()
		_gs._on_timer_timeout()
		assert_eq(_gs.elapsed_time, 1)

	func test_timer_does_not_increment_when_inactive() -> void:
		_gs.elapsed_time = 0
		_gs.is_game_active = false
		_gs._on_timer_timeout()
		assert_eq(_gs.elapsed_time, 0)

	func test_difficulty_enum_values() -> void:
		assert_eq(_gs.Difficulty.EASY, 1)
		assert_eq(_gs.Difficulty.MEDIUM, 2)
		assert_eq(_gs.Difficulty.HARD, 4)
