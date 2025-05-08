# File: res://COLOR_SWITCH/color_switch.gd
extends Node3D

@onready var platform_manager    = $PLATFORMS
@onready var button              = $HUD/StartButton
@onready var starting_platform   = $BlankPlatform
@onready var player1             = $Player1
@onready var player2             = $Player2
@onready var color_square        = $HUD/ColorRect
@onready var start_label         = $HUD/ColorSwitchLabel
@onready var pmosybau_label      = $HUD/GetReadyLabel
@onready var color_timer         = $HUD/ColorSwitchTimer
@onready var timer_label         = $HUD/TimerLabel
@onready var int_timer           = $Timers/IntermissionTimer
@onready var int_timer_label     = $HUD/IntermissionTimerLabel
@onready var speed_timer         = $Timers/SpeedUpTimer
@onready var speed_timer2        = $Timers/SpeedUpTimer2
@onready var speed_timer3        = $Timers/SpeedUpTimer3
@onready var death_button        = $DeathScreen/MainMenuButton
@onready var death_label         = $DeathScreen/YouDiedLabel
@onready var death_square        = $DeathScreen/DeathColorRect
@onready var score_label         = $HUD/ScoreLabel
@onready var score_label_other   = $HUD/ScoreLabel2
@onready var player1mesh         = $Player1/Mesh
@onready var player2mesh         = $Player2/Mesh

@onready var split_canvas        : CanvasLayer = $SplitCanvas
@onready var left_viewport       : SubViewport = $SplitCanvas/SplitScreen/LeftContainer/LeftViewport
@onready var right_viewport      : SubViewport = $SplitCanvas/SplitScreen/RightContainer/RightViewport

# — match these exactly to your scene —
@onready var cameraStart        : Camera3D = $CameraStart
@onready var cameraPlayer1      : Camera3D = $Player1/Head/Camera3D
@onready var cameraPlayer2      : Camera3D = $Player2/Head/Camera3D
# — end camera refs —

var red     = Color(1, 0, 0)
var orange  = Color(1, 0.647, 0)
var yellow  = Color(1, 1, 0)
var green   = Color(0, 1, 0)
var blue    = Color(0, 0, 1)
var purple  = Color(0.5, 0, 1)

var colors = [red, orange, yellow, green, blue, purple]

var target_position                = Vector3(-2.238, 3.923, 0)
var color_square_position            = Vector2(860, 120)
var target_position_other          = Vector3(1.369, 4.85, 0)
var target_platform_position       = Vector3(0, 0, 0)
var target_start_platform_position = Vector3(0, 50, 0)
var player1_death_position         = Vector3(-31, 1, -1)
var player2_death_position         = Vector3(-33, 1, 1)

var last_index = -1
var new_index  = last_index

var score          = 0
var add_more_score = 0
var score_other    = 0
var add_more_score_other = 0
var first_time     = 0

# will be overridden by lobby
var multiplayer_enabled = false

var multiplayer_death = false

var p1dead = false

var p2dead = false

func _ready():
	button.connect("pressed", _on_start_button_pressed)
	hide_all()

	# disable any “main_cameras”
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	cameraStart.current   = true
	cameraPlayer1.current = false
	split_canvas.visible  = false

	# read lobby’s multiplayer flag & toggle P2 visibility
	multiplayer_enabled = GlobalInfo.multiplayer_active
	player2.visible     = multiplayer_enabled

	# both players disabled until start
	player1.can_move = false
	player2.can_move = false

func hide_all():
	for platform in platform_manager.get_children():
		platform.visible = false

func _on_multiplayer_button_pressed():
	multiplayer_enabled = true
	player2.visible     = true

func _on_start_button_pressed():
	# — Player 1 setup —
	player1.input_prefix   = "p1"
	player1.input_left     = "p1_left"
	player1.input_right    = "p1_right"
	player1.input_forward  = "p1_up"
	player1.input_back     = "p1_down"
	player1.configure_inputs()
	player1.has_gravity    = true
	player1.can_move       = true
	player1.username       = GlobalInfo.p1_name
	player1mesh.visible    = true
	player1.global_transform.origin = target_position

	# — Player 2 setup if multiplayer —
	if multiplayer_enabled:
		player2.input_prefix   = "p2"
		player2.input_left     = "p2_left"
		player2.input_right    = "p2_right"
		player2.input_forward  = "p2_up"
		player2.input_back     = "p2_down"
		player2.configure_inputs()
		player2.has_gravity    = true
		player2.can_move       = true
		player2.username       = GlobalInfo.p2_name
		player2mesh.visible    = true
		player2.global_transform.origin = target_position_other
		color_square.global_position = color_square_position
		multiplayer_death = true
		_enable_split_screen()
	else:
		cameraPlayer1.current = true

	# — Start timers & UI —
	int_timer.start()
	speed_timer.start()
	hide_all()

	cameraStart.current    = false
	cameraPlayer1.current  = true
	button.visible         = false
	start_label.visible    = false
	pmosybau_label.visible = true
	int_timer_label.visible= false
	timer_label.visible    = false
	score_label.visible    = true
	if multiplayer_enabled:
		score_label_other.visible = true
	starting_platform.visible = true

	score          = 0
	score_other    = 0
	add_more_score = 100
	add_more_score_other = 100
	first_time     = 0

	# — Choose and show a random platform —
	var idx = randi() % platform_manager.get_child_count()
	var plat = platform_manager.get_children()[idx]
	plat.visible = false
	starting_platform.visible = true
	plat.global_transform.origin = target_platform_position
	platform_manager.active_platform = plat
	print("Platform ", idx, " is now visible.")

	# — Pick starting color —
	while new_index == last_index:
		new_index = randi() % colors.size()
	last_index = new_index
	color_square.self_modulate = colors[new_index]
	print("Selected Color: ", colors[new_index])

func _process(_delta):
	timer_label.text        = ":" + str(int(roundf(color_timer.get_time_left())))
	int_timer_label.text    = ":" + str(int(roundf(int_timer.get_time_left())))
	score_label.text        = GlobalInfo.p1_name + " Score: " + str(score)
	score_label_other.text = GlobalInfo.p2_name + " Score: " + str(score_other)

	if p1dead and p2dead:
		both_players_dead()

	if player1.global_transform.origin.y <= -2:
		player1.global_transform.origin = player1_death_position
		player1_death()

	if multiplayer_enabled and player2.global_transform.origin.y <= -2:
		player2.global_transform.origin = player2_death_position
		player2_death()

func _on_intermission_timer_timeout():
	int_timer_label.visible     = false
	timer_label.visible         = true
	color_square.visible        = true
	pmosybau_label.visible      = false
	starting_platform.visible   = false

	hide_all()
	platform_manager.active_platform.global_transform.origin = target_start_platform_position

	var idx = randi() % platform_manager.get_child_count()
	var plat = platform_manager.get_children()[idx]
	plat.visible = true
	plat.global_transform.origin = target_platform_position
	platform_manager.active_platform = plat

	while new_index == last_index:
		new_index = randi() % colors.size()
	last_index = new_index
	color_square.self_modulate = colors[new_index]
	print("Selected Color: ", colors[new_index])

	for tile in plat.get_children():
		tile.selected()

	player1.can_jump  = true
	player2.can_jump  = true
	color_timer.start()
	int_timer.stop()

	if first_time > 0 and p1dead == false:
		score += add_more_score

	if first_time > 0 and p2dead == false:
		if multiplayer_death == true:
			score_other += add_more_score_other

	first_time += 1

	var t = starting_platform.global_transform
	t.origin.y = -50
	starting_platform.global_transform = t

func _enable_split_screen() -> void:
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false
	split_canvas.visible = true
	RenderingServer.viewport_attach_camera(
		left_viewport.get_viewport_rid(),
		cameraPlayer1.get_camera_rid()
	)
	RenderingServer.viewport_attach_camera(
		right_viewport.get_viewport_rid(),
		cameraPlayer2.get_camera_rid()
	)

func _on_color_switch_timer_timeout():
	int_timer_label.visible = true
	timer_label.visible     = false
	platform_manager.update_platform(colors[new_index])
	player1.can_jump = false
	player2.can_jump = false
	color_timer.stop()
	int_timer.start()

func _on_speed_up_timer_timeout():
	color_timer.wait_time = 4
	int_timer.wait_time   = 2
	speed_timer.stop()
	speed_timer2.start()
	add_more_score = 150
	add_more_score_other = 150

func _on_speed_up_timer2_timeout():
	color_timer.wait_time = 2
	int_timer.wait_time   = 1
	speed_timer2.stop()
	speed_timer3.start()
	add_more_score = 200
	add_more_score_other = 200

func _on_speed_up_timer3_timeout():
	color_timer.wait_time = 1.5
	int_timer.wait_time   = 0.5
	speed_timer3.stop()
	add_more_score = 300
	add_more_score_other = 300

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://LOBBY/Scenes/lobby.tscn")



func player1_death():
	player1.can_move         = false
	p1dead = true

	if multiplayer_death == false:
		p2dead = true
	else:
		pass

func player2_death():
	player2.can_move         = false
	p2dead = true


func both_players_dead():
	death_button.visible     = true
	death_label.visible      = true
	death_square.visible     = true
	color_square.visible     = false
	pmosybau_label.visible   = false
	timer_label.visible      = false
	int_timer_label.visible  = false
	start_label.visible      = false
	score_label.visible      = false
	score_label_other.visible = false
	p1dead = false
	p2dead = false
	color_timer.stop()
	int_timer.stop()
	speed_timer.stop()
	speed_timer2.stop()
	speed_timer3.stop()

func game_stop():
	pass
