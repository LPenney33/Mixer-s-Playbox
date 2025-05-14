# File: res://LOBBY/Scenes/lobby.gd
extends Node3D

@onready var name_selector   : Control         = $NameSelector
@onready var player1         : CharacterBody3D = $Player1
@onready var player2         : CharacterBody3D = $Player2

@onready var split_canvas    : CanvasLayer     = $SplitCanvas
@onready var left_viewport   : SubViewport     = $SplitCanvas/SplitScreen/LeftContainer/LeftViewport
@onready var right_viewport  : SubViewport     = $SplitCanvas/SplitScreen/RightContainer/RightViewport

func _ready() -> void:
	name_selector.show()
	player1.can_move = false
	player2.can_move = false
	player2.visible  = false
	name_selector.connect("names_chosen", Callable(self, "_on_names_chosen"))

func _on_names_chosen(p1_name: String, p2_name: String) -> void:
	# — Store into our global info singleton —
	GlobalInfo.p1_name              = p1_name
	GlobalInfo.p2_name              = p2_name
	GlobalInfo.multiplayer_active   = (p2_name != "")

	# — Player 1 setup —
	player1.input_prefix = "p1"
	player1.configure_inputs()
	player1.username     = p1_name
	player1.can_move     = true

	# — Player 2 setup (if multiplayer) —
	if GlobalInfo.multiplayer_active:
		player2.visible      = true
		player2.input_prefix = "p2"
		player2.configure_inputs()
		player2.username     = p2_name
		player2.can_move     = true
		_enable_split_screen()

	# remove the name‐selector UI
	name_selector.queue_free()

func _enable_split_screen() -> void:
	# disable any “main” cameras
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	# show our split‐screen canvas
	split_canvas.visible = true

	# attach each player’s camera to its viewport
	var c1 = player1.get_node("Head/Camera3D") as Camera3D
	var c2 = player2.get_node("Head/Camera3D") as Camera3D
	RenderingServer.viewport_attach_camera(left_viewport.get_viewport_rid(),  c1.get_camera_rid())
	RenderingServer.viewport_attach_camera(right_viewport.get_viewport_rid(), c2.get_camera_rid())
