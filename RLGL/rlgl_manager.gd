extends Node

signal player_caught(player_idx: int)

# — Configurable buffer after RED light —
@export var buffer_time : float = 0.5

# — State —
var is_red_light      : bool    = false
var buffer_expired    : bool    = false
var pos1_after_buffer : Vector3 = Vector3.ZERO
var pos2_after_buffer : Vector3 = Vector3.ZERO

# — Internals —
var buffer_timer : Timer

# — Node refs (refreshed each toggle) —
var player1      : CharacterBody3D
var player2      : CharacterBody3D
var split_canvas : CanvasLayer
var menu         : Control

func _ready() -> void:
	# Create the one‐shot buffer timer
	buffer_timer = Timer.new()
	buffer_timer.one_shot  = true
	buffer_timer.wait_time = buffer_time
	add_child(buffer_timer)
	buffer_timer.connect("timeout", Callable(self, "_on_buffer_timeout"))
	print("rlgl_manager: buffer_time =", buffer_time)

	# If multiplayer was active at load, enable split-screen immediately
	var root = get_tree().get_current_scene()
	if root and GlobalInfo.multiplayer_active:
		split_canvas = root.get_node_or_null("SplitCanvas")
		if split_canvas:
			_enable_split_screen()

func set_red_light(state: bool) -> void:
	# Refresh references
	var root = get_tree().get_current_scene()
	if not root:
		push_error("rlgl_manager: no current scene!")
		return
	player1      = root.get_node_or_null("Player1")
	player2      = root.get_node_or_null("Player2")
	split_canvas = root.get_node_or_null("SplitCanvas")
	menu         = root.get_node_or_null("UIMenuLayer/Menu")

	# If multiplayer turned on mid‐run, re-enable split-screen
	if GlobalInfo.multiplayer_active and split_canvas and not split_canvas.visible:
		_enable_split_screen()

	is_red_light = state

	if is_red_light:
		buffer_expired = false
		print("🔴 RED → starting buffer")
		buffer_timer.start()
	else:
		print("🟢 GREEN → buffer_expired =", buffer_expired)
		if buffer_expired:
			print("rlgl_manager: checking players…")
			_check_player1()
			_check_player2()
		else:
			print("rlgl_manager: skipping checks; GREEN before buffer")
		buffer_timer.stop()

func _on_buffer_timeout() -> void:
	buffer_expired = true
	if player1:
		pos1_after_buffer = player1.global_transform.origin
		print("buffer expired → pos1 =", pos1_after_buffer)
	if player2:
		pos2_after_buffer = player2.global_transform.origin
		print("buffer expired → pos2 =", pos2_after_buffer)
	print("rlgl_manager: ready for next GREEN")

func _check_player1() -> void:
	if not player1:
		print("Skipping P1 (missing)")
		return
	var cur = player1.global_transform.origin
	print("[P1] cur =", cur, " buf =", pos1_after_buffer)
	if cur != pos1_after_buffer:
		print("Player 1 Moved On Red")
		player1.can_move = false
		player1.visible  = false
		emit_signal("player_caught", 1)
	else:
		print("P1 stayed still")

func _check_player2() -> void:
	if not GlobalInfo.multiplayer_active:
		print("Skipping P2 (singleplayer)")
		return
	if not player2:
		print("Skipping P2 (missing)")
		return
	var cur = player2.global_transform.origin
	print("[P2] cur =", cur, " buf =", pos2_after_buffer)
	if cur != pos2_after_buffer:
		print("Player 2 Moved On Red")
		player2.can_move = false
		player2.visible  = false
		emit_signal("player_caught", 2)
	else:
		print("P2 stayed still")

func _enable_split_screen() -> void:
	var root = get_tree().get_current_scene()
	if root:
		player1      = root.get_node_or_null("Player1")
		player2      = root.get_node_or_null("Player2")
		split_canvas = root.get_node_or_null("SplitCanvas")

	if not split_canvas:
		push_error("rlgl_manager: SplitCanvas missing")
		return

	# 1) Turn off all other cameras
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	# 2) Show split-screen UI
	split_canvas.visible = true
	print("rlgl_manager: Split-screen enabled")

	# 3) Configure each player's inputs and visibility
	if player1:
		player1.input_prefix = "p1"
		player1.configure_inputs()
		player1.can_move = true
		player1.visible  = true
	if player2 and GlobalInfo.multiplayer_active:
		player2.input_prefix = "p2"
		player2.configure_inputs()
		player2.can_move = true
		player2.visible  = true

	# 4) Attach each player's Camera3D into its SubViewport
	var lv = split_canvas.get_node("SplitScreen/LeftContainer/LeftViewport")  as SubViewport
	var rv = split_canvas.get_node("SplitScreen/RightContainer/RightViewport") as SubViewport
	if not lv or not rv:
		push_error("rlgl_manager: Viewports missing")
		return

	var c1 = player1.get_node_or_null("Head/Camera3D") as Camera3D
	var c2 = player2.get_node_or_null("Head/Camera3D") as Camera3D
	print("Found cameras:", c1, c2)
	if c1 and c2:
		RenderingServer.viewport_attach_camera(lv.get_viewport_rid(),  c1.get_camera_rid())
		RenderingServer.viewport_attach_camera(rv.get_viewport_rid(), c2.get_camera_rid())
		c1.current = true
		c2.current = true
		print("Cameras attached ✔")
	else:
		push_error("rlgl_manager: Could not find Head/Camera3D on players")
