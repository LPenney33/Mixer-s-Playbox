# lobby.gd
extends Node3D

@onready var name_selector  : Control          = $NameSelector
@onready var player1        : CharacterBody3D  = $Player1
@onready var player2        : CharacterBody3D  = $Player2

@onready var split_canvas   : CanvasLayer      = $SplitCanvas
@onready var left_viewport  : SubViewport      = $SplitCanvas/SplitScreen/LeftContainer/LeftViewport
@onready var right_viewport : SubViewport      = $SplitCanvas/SplitScreen/RightContainer/RightViewport

func _ready() -> void:
	# Show the name selector, lock both players & hide Player2
	name_selector.show()
	player1.can_move = false
	player2.can_move = false
	player2.visible  = false

	# Connect signal for when names are chosen
	name_selector.connect("names_chosen", Callable(self, "_on_names_chosen"))

func _on_names_chosen(p1_name: String, p2_name: String) -> void:
	# Configure Player1
	player1.input_prefix   = "p1"
	player1.username       = p1_name
	player1.input_left     = "p1_left"
	player1.input_right    = "p1_right"
	player1.input_forward  = "p1_up"
	player1.input_back     = "p1_down"
	player1.can_move       = true

	# If multiplayer, configure Player2 and enable split-screen
	if p2_name != "":
		player2.visible        = true
		player2.input_prefix   = "p2"
		player2.username       = p2_name
		player2.input_left     = "p2_left"
		player2.input_right    = "p2_right"
		player2.input_forward  = "p2_up"
		player2.input_back     = "p2_down"
		player2.can_move       = true
		_enable_split_screen()

	# Remove the name selector UI
	name_selector.queue_free()

func _enable_split_screen() -> void:
	# 1) Turn off all cameras in “main_cameras”
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	# 2) Show our split-screen CanvasLayer (with its full-screen mask + two SubViewports)
	split_canvas.visible = true

	# 3) Attach each player’s Camera3D into its SubViewport
	var cam1 = player1.get_node("Head/Camera3D") as Camera3D
	var cam2 = player2.get_node("Head/Camera3D") as Camera3D

	RenderingServer.viewport_attach_camera(
		left_viewport.get_viewport_rid(),
		cam1.get_camera_rid()
	)
	RenderingServer.viewport_attach_camera(
		right_viewport.get_viewport_rid(),
		cam2.get_camera_rid()
	)
