extends Node3D

@onready var platform_manager = $PLATFORMS
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player1 = $Player1
@onready var player2 = $Player2
@onready var color_square = $HUD/ColorRect
@onready var start_label = $HUD/ColorSwitchLabel
@onready var pmosybau_label = $HUD/GetReadyLabel
@onready var color_timer = $HUD/ColorSwitchTimer
@onready var timer_label = $HUD/TimerLabel
@onready var int_timer = $Timers/IntermissionTimer
@onready var int_timer_label = $HUD/IntermissionTimerLabel
@onready var speed_timer = $Timers/SpeedUpTimer
@onready var speed_timer2 = $Timers/SpeedUpTimer2
@onready var speed_timer3 = $Timers/SpeedUpTimer3
@onready var death_button = $DeathScreen/MainMenuButton
@onready var death_label = $DeathScreen/YouDiedLabel
@onready var death_square = $DeathScreen/DeathColorRect
@onready var score_label = $HUD/ScoreLabel
@onready var player1mesh = $Player1/Mesh
@onready var player2mesh = $Player2/Mesh

@onready var split_canvas: CanvasLayer = $SplitCanvas
@onready var left_viewport: SubViewport = $SplitCanvas/SplitScreen/LeftContainer/LeftViewport
@onready var right_viewport: SubViewport = $SplitCanvas/SplitScreen/RightContainer/RightViewport


var red = Color(1, 0, 0)    # Red
var orange = Color(1, 0.647, 0)    # Orange
var yellow = Color(1, 1, 0)    # Yellow
var green = Color(0, 1, 0)    # Green
var blue = Color(0, 0, 1)    # Blue
var purple = Color(0.5, 0, 1)    # Purple

var colors = [red, orange, yellow, green, blue, purple]

var target_position = Vector3(-2.238, 3.923, 0) ## Players starting point
var target_position_other = Vector3(1.369, 4.85, 0)
var target_platform_position = Vector3(0, 0, 0)
var target_start_platform_position = Vector3(0, 50, 0)
var player1_death_position = Vector3(-31, 1, -1)
var player2_death_position = Vector3(-33, 1, 1)

var last_index = -1

var new_index = last_index

@onready var cameraStart = %CameraStart

@onready var cameraPlayer1 = %Camera3D

@onready var cameraPlayer2 = %Camera3D2

var score = 0

var add_more_score = 0

var first_time = 0

var multiplayer_enabled

func _ready():
	button.connect("pressed", _on_start_button_pressed)
	hide_all()
	cameraStart.current = true
	cameraPlayer1.current = false
	multiplayer_enabled = false

func hide_all():
	for platform in platform_manager.get_children():
		platform.visible = false


func _on_multiplayer_button_pressed():
	multiplayer_enabled = true


func _on_start_button_pressed():

	player1.input_prefix   = "p1"
	player1.input_left     = "p1_left"
	player1.input_right    = "p1_right"
	player1.input_forward  = "p1_up"
	player1.input_back     = "p1_down"

	if multiplayer_enabled == true:
		player2.input_prefix   = "p2"
		player2.input_left     = "p2_left"
		player2.input_right    = "p2_right"
		player2.input_forward  = "p2_up"
		player2.input_back     = "p2_down"
		player2.can_move = true
		player2mesh.visible = true
		player1mesh.visible = true
		player2.global_transform.origin = target_position_other
		_enable_split_screen()



	int_timer.start()
	speed_timer.start()
	hide_all()
	cameraPlayer1.current = true
	cameraStart.current = false
	var random_index = randi() % platform_manager.get_children().size() ## Picks a random platform_manager child (PlatformV1 - V5)
	platform_manager.get_children()[random_index].visible = false ## Makes picked platform_manager visible
	print("Platform ", random_index, " is now visible.") ## Tells Output to print what platform_manager is visible
	button.visible = false
	start_label.visible = false
	pmosybau_label.visible = true
	int_timer_label.visible = false
	timer_label.visible = false
	score_label.visible = true
	starting_platform.visible = true
	player1.global_transform.origin = target_position ## Teleports player to starting point
	score = 0
	add_more_score = 100
	first_time = 0

	#Chooses starting color
	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	platform_manager.active_platform = platform_manager.get_children()[random_index]

	platform_manager.active_platform.global_position = target_platform_position


func _process(_delta):
	timer_label.text = ":" + str(int(roundf(color_timer.get_time_left()))) ## Displays time left in Output
	int_timer_label.text = ":" + str(int(roundf(int_timer.get_time_left())))
	score_label.text = "Score: " + str(int(score))

	if player1.global_position.y <= -2:
		player1.global_position = player1_death_position
		player1_death()

	if player2.global_position.y <= -2:
		player2.global_position = player2_death_position
		player2_death()

func _on_intermission_timer_timeout():
	int_timer_label.visible = false
	timer_label.visible = true
	color_square.visible = true
	pmosybau_label.visible = false
	starting_platform.visible = false

	for platform in platform_manager.get_children():
		platform.visible = false

	platform_manager.active_platform.global_position = target_start_platform_position

	var random_index = randi() % platform_manager.get_children().size() ## Picks a random platform_manager child (PlatformV1 - V5)
	platform_manager.active_platform = platform_manager.get_children()[random_index]
	platform_manager.get_children()[random_index].visible = true ## Makes picked platform_manager visible

	platform_manager.active_platform.global_position = target_platform_position

	starting_platform.global_position = target_start_platform_position


	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	for tile in platform_manager.active_platform.get_children():
		tile.selected()

	player1.can_jump = true

	color_timer.start()
	int_timer.stop()

	if first_time > 0:
		score += add_more_score

	first_time += 1


func _enable_split_screen() -> void:
	# 1) Turn off all cameras in “main_cameras”
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	# 2) Show our split-screen CanvasLayer (with its full-screen mask + two SubViewports)
	split_canvas.visible = true

	# 3) Attach each player’s Camera3D into its SubViewport
	var cam1 = player1.get_node("Head/Camera3D") as Camera3D
	var cam2 = player2.get_node("Head/Camera3D2") as Camera3D

	RenderingServer.viewport_attach_camera(
		left_viewport.get_viewport_rid(),
		cam1.get_camera_rid()
	)
	RenderingServer.viewport_attach_camera(
		right_viewport.get_viewport_rid(),
		cam2.get_camera_rid()
	)


func _on_color_switch_timer_timeout():
	int_timer_label.visible = true
	timer_label.visible = false

	var selected_color = colors[new_index]

	platform_manager.update_platform(selected_color)

	player1.can_jump = false

	color_timer.stop()
	int_timer.start()

func _on_speed_up_timer_timeout():
	color_timer.wait_time = 4
	int_timer.wait_time = 2
	speed_timer.stop()
	speed_timer2.start()
	add_more_score = 150

func _on_speed_up_timer2_timeout():
	color_timer.wait_time = 2
	int_timer.wait_time = 1
	speed_timer2.stop()
	speed_timer3.start()
	add_more_score = 200

func _on_speed_up_timer3_timeout():
	color_timer.wait_time = 1.5
	int_timer.wait_time = 0.5
	speed_timer3.stop()
	add_more_score = 300

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://LOBBY/Scenes/lobby.tscn")

func player1_death():
	print("You died.")
	player1.can_move = false
	death_button.visible = true
	death_label.visible = true
	death_square.visible = true

	color_square.visible = false
	pmosybau_label.visible = false
	timer_label.visible = false
	int_timer_label.visible = false
	start_label.visible = false
	score_label.visible = false

	color_timer.stop()
	int_timer.stop()
	speed_timer.stop()
	speed_timer2.stop()
	speed_timer3.stop()

func player2_death():
	print("You died.")
	player2.can_move = false
	death_button.visible = true
	death_label.visible = true
	death_square.visible = true

	color_square.visible = false
	pmosybau_label.visible = false
	timer_label.visible = false
	int_timer_label.visible = false
	start_label.visible = false
	score_label.visible = false

	color_timer.stop()
	int_timer.stop()
	speed_timer.stop()
	speed_timer2.stop()
	speed_timer3.stop()

func game_stop():
	pass
