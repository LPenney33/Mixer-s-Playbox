# res://RLGL/rlgl_manager.gd
extends Node

signal player_caught(player_idx: int)
signal player_finished(player_idx: int)

@export var buffer_time := 0.5
@export var red_duration_min := 3.0
@export var red_duration_max := 6.0
@export var green_duration_min := 2.0
@export var green_duration_max := 5.0

const MOVE_EPSILON := 0.01

enum Phase { START, GAME, DONE }
var phase := Phase.START

var start_time_left := 5.0
var game_time_left := 55.0

var is_red_light := false
var buffer_expired := false
var pos1_buf := Vector3.ZERO
var pos2_buf := Vector3.ZERO

var died1 := false
var died2 := false
var won1 := false
var won2 := false

# Cached nodes
var buffer_timer    : Timer
var player1         : CharacterBody3D
var player2         : CharacterBody3D
var single_canvas   : CanvasLayer
var single_mask     : Control
var start_timer_ui  : Control
var game_timer_ui   : Control
var start_label     : Label
var game_label      : Label
var split_canvas    : CanvasLayer
var split_mask      : Control
var left_vp         : SubViewport
var right_vp        : SubViewport
var ui_menu         : Control

func _ready() -> void:
	set_process(true)
	buffer_timer = Timer.new()
	buffer_timer.one_shot = true
	buffer_timer.wait_time = buffer_time
	add_child(buffer_timer)
	buffer_timer.timeout.connect(_on_buffer_timeout)
	connect("player_caught", Callable(self, "_on_player_caught"))
	connect("player_finished", Callable(self, "_on_player_finished"))
	call_deferred("_init_scene")

func _init_scene() -> void:
	var scene = get_tree().get_current_scene()
	if scene == null or scene.name != "RLGL":
		return  # only in RLGL scene

	_disable_all_movement()

	player1 = scene.get_node_or_null("Player1")
	player2 = scene.get_node_or_null("Player2")
	if player1 != null:
		player1.input_prefix = "p1"
		player1.configure_inputs()
	if player2 != null:
		player2.input_prefix = "p2"
		player2.configure_inputs()

	single_canvas = scene.get_node_or_null("SinglePlayerCanvas")
	if single_canvas != null:
		single_mask     = single_canvas.get_node_or_null("Mask") as Control
		start_timer_ui  = single_canvas.get_node_or_null("StartTimer") as Control
		game_timer_ui   = single_canvas.get_node_or_null("GameTimer") as Control
		if start_timer_ui != null:
			start_label = start_timer_ui.get_node_or_null("Background/CountLabel") as Label
		if game_timer_ui != null:
			game_label = game_timer_ui.get_node_or_null("Background/CountLabel") as Label
			game_timer_ui.visible = false

	ui_menu = scene.get_node_or_null("UIMenuLayer/Menu") as Control
	if ui_menu != null:
		ui_menu.visible = false

	split_canvas = scene.get_node_or_null("SplitCanvas") as CanvasLayer
	if split_canvas != null:
		split_mask = split_canvas.get_node_or_null("Mask") as Control
		left_vp    = split_canvas.get_node_or_null("SplitScreen/LeftContainer/LeftViewport") as SubViewport
		right_vp   = split_canvas.get_node_or_null("SplitScreen/RightContainer/RightViewport") as SubViewport
		if GlobalInfo.multiplayer_active and player2 != null:
			player2.visible = true
			_enable_split_screen()

func _disable_all_movement() -> void:
	if player1 != null:
		player1.can_move = false
	if player2 != null:
		player2.can_move = false
		player2.visible  = false

func _process(delta: float) -> void:
	var scene = get_tree().get_current_scene()
	if scene == null or scene.name != "RLGL":
		return

	if phase == Phase.START:
		if player1 != null:
			player1.can_move = false
		if player2 != null:
			player2.can_move = false

		start_time_left -= delta
		if start_label != null:
			var secs = int(ceil(start_time_left))
			var txt = ""
			if secs < 10:
				txt = "0" + str(secs)
			else:
				txt = str(secs)
			start_label.text = ":" + txt

		if start_time_left <= 0.0:
			_on_start_finished()
		return

	if phase == Phase.GAME:
		game_time_left -= delta
		if game_label != null:
			var gs = int(ceil(game_time_left))
			var txt = ""
			if gs < 10:
				txt = "0" + str(gs)
			else:
				txt = str(gs)
			game_label.text = ":" + txt

		if player1 != null and not died1 and not won1 and player1.global_transform.origin.x > 195.0:
			won1 = true
			emit_signal("player_finished", 1)
		if GlobalInfo.multiplayer_active and player2 != null and not died2 and not won2 and player2.global_transform.origin.x > 195.0:
			won2 = true
			emit_signal("player_finished", 2)

		if game_time_left <= 0.0:
			phase = Phase.DONE
			if GlobalInfo.multiplayer_active:
				if not won1:
					died1 = true
				if not won2:
					died2 = true
				_maybe_end_multiplayer()
			else:
				if not won1:
					died1 = true
				_end_game()
		return

func _on_start_finished() -> void:
	phase = Phase.GAME
	if player1 != null:
		player1.can_move = true
	if player2 != null:
		player2.visible  = GlobalInfo.multiplayer_active
		player2.can_move = GlobalInfo.multiplayer_active

	if start_timer_ui != null:
		start_timer_ui.visible = false
	if game_timer_ui != null:
		game_timer_ui.visible = true
	if single_mask != null:
		single_mask.visible = false
	if split_mask != null:
		split_mask.visible = false
	if GlobalInfo.multiplayer_active:
		_enable_split_screen()

	_start_red_green_cycle()

func set_red_light(state: bool) -> void:
	if phase != Phase.GAME:
		return
	if single_mask != null:
		single_mask.visible = state
	if split_mask != null:
		split_mask.visible = state

	is_red_light = state
	if state:
		buffer_expired = false
		buffer_timer.start()
	else:
		if buffer_expired:
			_check_player1()
			_check_player2()

func _on_buffer_timeout() -> void:
	if phase != Phase.GAME:
		return
	buffer_expired = true
	if player1 != null:
		pos1_buf = player1.global_transform.origin
	if player2 != null:
		pos2_buf = player2.global_transform.origin

func _start_red_green_cycle() -> void:
	while phase == Phase.GAME:
		set_red_light(true)
		await get_tree().create_timer(buffer_time).timeout
		await get_tree().create_timer(randf_range(red_duration_min, red_duration_max)).timeout
		set_red_light(false)
		await get_tree().create_timer(randf_range(green_duration_min, green_duration_max)).timeout

func _check_player1() -> void:
	if player1 != null and not died1 and not won1:
		if player1.global_transform.origin.distance_to(pos1_buf) > MOVE_EPSILON:
			died1 = true
			emit_signal("player_caught", 1)

func _check_player2() -> void:
	if player2 != null and GlobalInfo.multiplayer_active and not died2 and not won2:
		if player2.global_transform.origin.distance_to(pos2_buf) > MOVE_EPSILON:
			died2 = true
			emit_signal("player_caught", 2)

func _on_player_caught(idx: int) -> void:
	if idx == 1 and player1 != null:
		player1.can_move = false
		player1.visible  = false
	elif idx == 2 and player2 != null:
		player2.can_move = false
		player2.visible  = false
	_maybe_end_multiplayer()

func _on_player_finished(idx: int) -> void:
	if idx == 1:
		won1 = true
	else:
		won2 = true
	_maybe_end_multiplayer()

func _maybe_end_multiplayer() -> void:
	if not GlobalInfo.multiplayer_active:
		_end_game()
	elif (died1 or won1) and (died2 or won2):
		_end_game()

func _end_game() -> void:
	phase = Phase.DONE
	_disable_all_movement()
	if split_canvas != null:
		split_canvas.visible = false
	if ui_menu != null:
		ui_menu.visible = true
		_populate_menu()

func _populate_menu() -> void:
	if ui_menu == null:
		return
	for child in ui_menu.get_children():
		child.visible = false

	if not GlobalInfo.multiplayer_active:
		if died1:
			ui_menu.get_node("SinglePlayer_DeathScreen").visible = true
		else:
			ui_menu.get_node("SinglePlayer_WinScreen").visible   = true
		return

	if died1 and died2:
		ui_menu.get_node("MultiPlayer_DeathScreen").visible = true
		return
	if won1 and won2:
		ui_menu.get_node("MultiPlayer_WinScreen").visible   = true
		return
	if died1 and not (won2 or died2):
		var p1w = ui_menu.get_node("P1-ONLY_WinScreen")
		p1w.visible = true
		p1w.get_node("P1_NameLabel").text = GlobalInfo.p1_name
		return
	if died2 and not (won1 or died1):
		var p2w = ui_menu.get_node("P2-ONLY_WinScreen")
		p2w.visible = true
		p2w.get_node("P2_NameLabel").text = GlobalInfo.p2_name
		return
	if won1 and not (won2 or died2):
		var w1 = ui_menu.get_node("P1-ONLY_WinScreen")
		w1.visible = true
		w1.get_node("P1_NameLabel").text = GlobalInfo.p1_name
		return
	if won2 and not (won1 or died1):
		var w2 = ui_menu.get_node("P2-ONLY_WinScreen")
		w2.visible = true
		w2.get_node("P2_NameLabel").text = GlobalInfo.p2_name
		return

func _enable_split_screen() -> void:
	if split_canvas == null:
		return
	split_canvas.visible = true
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false
	var c1 = player1.get_node("Head/Camera3D") as Camera3D
	var c2 = player2.get_node("Head/Camera3D") as Camera3D
	RenderingServer.viewport_attach_camera(left_vp.get_viewport_rid(),  c1.get_camera_rid())
	RenderingServer.viewport_attach_camera(right_vp.get_viewport_rid(), c2.get_camera_rid())
