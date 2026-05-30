extends Control

## Root game manager that handles scene flow: Main Menu -> Game Board -> Pause / Victory.

@onready var board: Board = $Board
@onready var stock: Stock = $Board/Stock
@onready var foundation: Foundation = $Board/Foundation
@onready var hud: Control = $HUD
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var settings_panel: Control = $Settings
@onready var victory_panel: Control = $VictoryPanel

func _ready() -> void:
	# Put modal popups into a high-layer CanvasLayer so they render above dragged cards
	var modal_layer := CanvasLayer.new()
	modal_layer.name = "ModalLayer"
	modal_layer.layer = 200
	add_child(modal_layer)

	# Reparent modal UI elements into the overlay layer
	if pause_menu.get_parent() != modal_layer:
		pause_menu.get_parent().remove_child(pause_menu)
		modal_layer.add_child(pause_menu)
	if settings_panel.get_parent() != modal_layer:
		settings_panel.get_parent().remove_child(settings_panel)
		modal_layer.add_child(settings_panel)
	if victory_panel.get_parent() != modal_layer:
		victory_panel.get_parent().remove_child(victory_panel)
		modal_layer.add_child(victory_panel)

	# Wire up Main Menu
	main_menu.start_game.connect(_on_start_game)
	main_menu.continue_game.connect(_on_continue_game)
	main_menu.open_settings.connect(_on_open_settings_from_menu)
	main_menu.quit.connect(_on_quit)

	# Wire up HUD
	hud.undo_pressed.connect(_on_undo_pressed)
	hud.hint_pressed.connect(_on_hint_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)

	# Wire up Pause Menu
	pause_menu.resume.connect(_on_resume)
	pause_menu.restart.connect(_on_restart)
	pause_menu.open_settings.connect(_on_open_settings_from_pause)
	pause_menu.main_menu.connect(_on_return_to_main_menu)

	# Wire up Settings
	settings_panel.back_pressed.connect(_on_settings_back)

	# Wire up Victory Panel
	victory_panel.play_again.connect(_on_play_again)
	victory_panel.main_menu.connect(_on_return_to_main_menu)

	# Wire up Stock
	stock.deal_requested.connect(_on_deal_requested)

	# Wire up Board
	board.board_ready.connect(_on_board_ready)
	board.sequence_completed.connect(_on_sequence_completed)
	board.game_won.connect(_on_game_won)

	# Start at main menu
	_show_main_menu()


# ---------------------------------------------------------------------------
# Scene flow
# ---------------------------------------------------------------------------
func _show_main_menu() -> void:
	main_menu.visible = true
	board.visible = false
	hud.visible = false
	pause_menu.visible = false
	victory_panel.visible = false
	settings_panel.visible = false

func _start_game(difficulty: int) -> void:
	main_menu.visible = false
	board.visible = true
	hud.visible = true
	pause_menu.visible = false
	victory_panel.visible = false
	settings_panel.visible = false
	MoveHistory.clear()
	board.setup_new_game(difficulty)

func _on_board_ready() -> void:
	stock.set_remaining(board.stock.size())
	foundation.reset()

func _on_sequence_completed(_sequence: Array) -> void:
	foundation.add_completed_sequence()

func _on_start_game(difficulty: int) -> void:
	_start_game(difficulty)

func _on_continue_game() -> void:
	# TODO: load saved game state
	_start_game(SettingsData.last_difficulty)

func _on_quit() -> void:
	get_tree().quit()


# ---------------------------------------------------------------------------
# HUD actions
# ---------------------------------------------------------------------------
func _on_undo_pressed() -> void:
	if not MoveHistory.can_undo():
		SoundManager.play_sfx("error")
		return
	var record := MoveHistory.undo_last_move()
	if record == null:
		return
	SoundManager.play_sfx("click")
	# Move cards back without recording history, bypassing rule checks, and without flipping revealed cards
	board.move_cards(record.to_column, record.from_column, record.cards_moved.size(), false, true, false, false)
	GameState.add_score(-record.score_delta)

	# If a card was flipped during the original move, flip it back face-down
	if record.flipped_card:
		var col: Column = board.columns[record.from_column]
		if is_instance_valid(col):
			var flipped_idx := col.get_card_count() - record.cards_moved.size() - 1
			if flipped_idx >= 0:
				var cards := col.get_cards()
				if flipped_idx < cards.size():
					cards[flipped_idx].face_up = false

	# If sequences were completed, undo the foundation progress
	for i in range(record.sequences_completed):
		foundation.remove_completed_sequence()
		# Remove the sequence cards from foundations and return them to the board
		# (they were already moved back by board.move_cards above, so just clean up foundations array)
		if board.foundations.size() > 0:
			board.foundations.pop_back()

func _on_hint_pressed() -> void:
	# TODO: implement hint highlighting
	SoundManager.play_sfx("click")

func _on_pause_pressed() -> void:
	GameState.is_game_active = false
	DragSystem.force_end_drag()
	pause_menu.visible = true


# ---------------------------------------------------------------------------
# Pause menu
# ---------------------------------------------------------------------------
func _on_resume() -> void:
	GameState.is_game_active = true
	pause_menu.visible = false

func _on_restart() -> void:
	pause_menu.visible = false
	_start_game(GameState.current_difficulty)

func _on_open_settings_from_pause() -> void:
	pause_menu.visible = false
	settings_panel.show_settings()
	settings_panel.visible = true

func _on_open_settings_from_menu() -> void:
	main_menu.visible = false
	settings_panel.show_settings()
	settings_panel.visible = true

func _on_settings_back() -> void:
	settings_panel.visible = false
	if board.visible:
		pause_menu.visible = true
	else:
		main_menu.visible = true

func _on_return_to_main_menu() -> void:
	GameState.reset_game()
	_show_main_menu()


# ---------------------------------------------------------------------------
# Stock & Foundation
# ---------------------------------------------------------------------------
func _on_deal_requested() -> void:
	if board.deal_from_stock():
		stock.set_remaining(board.stock.size())

func _on_game_won() -> void:
	SettingsData.update_best_score(
		GameState.current_difficulty,
		GameState.score,
		GameState.elapsed_time,
		GameState.move_count
	)
	victory_panel.show_victory(GameState.score, GameState.elapsed_time, GameState.move_count)
	victory_panel.visible = true

func _on_play_again() -> void:
	victory_panel.visible = false
	_start_game(GameState.current_difficulty)
