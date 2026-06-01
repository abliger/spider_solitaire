extends Control

## 根游戏管理器，处理场景流程：主菜单 -> 游戏面板 -> 暂停 / 胜利。

@onready var board: Board = $Board
@onready var stock: Stock = $Board/Stock
@onready var foundation: Foundation = $Board/Foundation
@onready var hud: Control = $HUD
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var settings_panel: Control = $Settings
@onready var victory_panel: Control = $VictoryPanel
@onready var rules_panel: Control = $RulesPanel

func _ready() -> void:
	# 将模态弹出窗口放入高层 CanvasLayer，使其渲染在拖拽的纸牌之上
	var modal_layer := CanvasLayer.new()
	modal_layer.name = "ModalLayer"
	modal_layer.layer = 200
	add_child(modal_layer)

	# 将模态 UI 元素重新父级到覆盖层
	if pause_menu.get_parent() != modal_layer:
		pause_menu.get_parent().remove_child(pause_menu)
		modal_layer.add_child(pause_menu)
	if settings_panel.get_parent() != modal_layer:
		settings_panel.get_parent().remove_child(settings_panel)
		modal_layer.add_child(settings_panel)
	if victory_panel.get_parent() != modal_layer:
		victory_panel.get_parent().remove_child(victory_panel)
		modal_layer.add_child(victory_panel)
	if rules_panel.get_parent() != modal_layer:
		rules_panel.get_parent().remove_child(rules_panel)
		modal_layer.add_child(rules_panel)

	# 连接主菜单信号
	main_menu.start_game.connect(_on_start_game)
	main_menu.continue_game.connect(_on_continue_game)
	main_menu.open_settings.connect(_on_open_settings_from_menu)
	main_menu.quit.connect(_on_quit)

	# 连接 HUD 信号
	hud.rules_pressed.connect(_on_rules_pressed)
	hud.undo_pressed.connect(_on_undo_pressed)
	hud.hint_pressed.connect(_on_hint_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)

	# 连接暂停菜单信号
	pause_menu.resume.connect(_on_resume)
	pause_menu.restart.connect(_on_restart)
	pause_menu.open_settings.connect(_on_open_settings_from_pause)
	pause_menu.main_menu.connect(_on_return_to_main_menu)

	# 连接设置面板信号
	settings_panel.back_pressed.connect(_on_settings_back)

	# 连接胜利面板信号
	victory_panel.play_again.connect(_on_play_again)
	victory_panel.main_menu.connect(_on_return_to_main_menu)

	# 连接规则面板信号
	rules_panel.close_pressed.connect(_on_rules_closed)

	# 连接发牌堆信号
	stock.deal_requested.connect(_on_deal_requested)

	# 连接游戏面板信号
	board.board_ready.connect(_on_board_ready)
	board.sequence_completed.connect(_on_sequence_completed)
	board.game_won.connect(_on_game_won)

	# 从主菜单开始
	_show_main_menu()


# ---------------------------------------------------------------------------
# 场景流程
# ---------------------------------------------------------------------------
func _show_main_menu() -> void:
	main_menu.visible = true
	board.visible = false
	hud.visible = false
	pause_menu.visible = false
	victory_panel.visible = false
	settings_panel.visible = false
	rules_panel.hide_rules()

func _start_game(difficulty: int) -> void:
	main_menu.visible = false
	board.visible = true
	hud.visible = true
	pause_menu.visible = false
	victory_panel.visible = false
	settings_panel.visible = false
	rules_panel.hide_rules()
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
	# TODO: 加载已保存的游戏状态
	_start_game(SettingsData.last_difficulty)

func _on_quit() -> void:
	get_tree().quit()


# ---------------------------------------------------------------------------
# HUD 操作
# ---------------------------------------------------------------------------
func _on_undo_pressed() -> void:
	if not MoveHistory.can_undo():
		SoundManager.play_sfx("error")
		return
	var record := MoveHistory.undo_last_move()
	if record == null:
		return
	SoundManager.play_sfx("click")

	# 1. 先还回完成的序列牌（如果有）
	for seq_info in record.completed_sequences:
		foundation.remove_completed_sequence()
		if board.foundations.size() > 0:
			board.foundations.pop_back()
		var seq_col: Column = board.columns[seq_info.column_index]
		if is_instance_valid(seq_col):
			seq_col.add_cards(seq_info.cards)

	# 2. 将玩家手动移动的纸牌移回，不记录历史、跳过规则检查、不翻转翻开的纸牌
	board.move_cards(record.to_column, record.from_column, record.cards_moved.size(), false, true, false, false)
	GameState.move_count -= 1  # 抵消 move_cards 内部的 increment_move
	GameState.add_score(-record.score_delta)

	# 3. 如果原始移动中翻开了某张牌，则将其翻回背面
	if record.flipped_card:
		var col: Column = board.columns[record.from_column]
		if is_instance_valid(col):
			# 如果 from_column 还回了序列牌，需要调整索引
			var extra_cards := 0
			for seq_info in record.completed_sequences:
				if seq_info.column_index == record.from_column:
					extra_cards += seq_info.cards.size()
			var flipped_idx := col.get_card_count() - record.cards_moved.size() - 1 - extra_cards
			if flipped_idx >= 0:
				var cards := col.get_cards()
				if flipped_idx < cards.size():
					cards[flipped_idx].face_up = false

func _on_hint_pressed() -> void:
	if not GameState.is_game_active:
		return
	board.show_hint()

func _on_rules_pressed() -> void:
	GameState.is_game_active = false
	DragSystem.force_end_drag()
	rules_panel.show_rules()

func _on_pause_pressed() -> void:
	GameState.is_game_active = false
	DragSystem.force_end_drag()
	pause_menu.visible = true


# ---------------------------------------------------------------------------
# 暂停菜单
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

func _on_rules_closed() -> void:
	rules_panel.hide_rules()
	if board.visible:
		GameState.is_game_active = true

func _on_return_to_main_menu() -> void:
	GameState.reset_game()
	board._clear_board()
	_show_main_menu()


# ---------------------------------------------------------------------------
# 发牌堆与基础区
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
