extends Node3D

@onready var platform_manager = $PLATFORMS
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player = $ProtoController
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


var red = Color(1, 0, 0)    # Red
var orange = Color(1, 0.647, 0)    # Orange
var yellow = Color(1, 1, 0)    # Yellow
var green = Color(0, 1, 0)    # Green
var blue = Color(0, 0, 1)    # Blue
var purple = Color(0.5, 0, 1)    # Purple

var colors = [red, orange, yellow, green, blue, purple]

var target_position = Vector3(-0.032, 1.596, 0.504) ## Players starting point
var target_platform_position = Vector3(0, 0, 0)
var target_start_platform_position = Vector3(0, 50, 0)
var death_position = Vector3(-32, 1, 0)

var last_index = -1

var new_index = last_index

@onready var cameraStart = %CameraStart

@onready var cameraPlayer = %CameraPlayer

var score = 0

var add_more_score = 0

var first_time = 0

func _ready():
	button.connect("pressed", _on_start_button_pressed)
	hide_all()
	cameraStart.current = true
	cameraPlayer.current = false

func hide_all():
	for platform in platform_manager.get_children():
		platform.visible = false

func _on_start_button_pressed():
	int_timer.start()
	speed_timer.start()
	hide_all()
	cameraPlayer.current = true
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
	player.global_transform.origin = target_position ## Teleports player to starting point
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

	if player.global_position.y <= -2:
		player.global_position = death_position
		death()

func _on_intermission_timer_timeout():
	int_timer_label.visible = false
	timer_label.visible = true
	color_square.visible = true
	pmosybau_label.visible = false

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

	player.can_jump = true

	color_timer.start()
	int_timer.stop()

	if first_time > 0:
		score += add_more_score

	first_time += 1


func _on_color_switch_timer_timeout():
	int_timer_label.visible = true
	timer_label.visible = false

	var selected_color = colors[new_index]

	platform_manager.update_platform(selected_color)

	player.can_jump = false

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
	pass

func death():
	print("You died.")
	player.can_move = false
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
