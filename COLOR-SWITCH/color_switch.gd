extends Node3D

@onready var platform_manager = $PLATFORMS
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player = $ProtoController
@onready var color_square = $HUD/ColorRect
@onready var start_label = $HUD/ColorSwitchLabel
@onready var color_timer = $HUD/ColorSwitchTimer
@onready var timer_label = $HUD/TimerLabel
@onready var int_timer = $Timers/IntermissionTimer
@onready var int_timer_label = $HUD/IntermissionTimerLabel
@onready var speed_timer = $Timers/SpeedUpTimer


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

var last_index = -1

var new_index = last_index

@onready var cameraStart = %CameraStart

@onready var cameraPlayer = %CameraPlayer

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
	platform_manager.get_children()[random_index].visible = true ## Makes picked platform_manager visible
	print("Platform ", random_index, " is now visible.") ## Tells Output to print what platform_manager is visible
	button.visible = false
	start_label.visible = false
	color_square.visible = true
	int_timer_label.visible = true
	timer_label.visible = false
	starting_platform.visible = false
	starting_platform.global_position = target_start_platform_position
	player.global_transform.origin = target_position ## Teleports player to starting point

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
	timer_label.text = ":" + str(roundf(color_timer.get_time_left())) ## Displays time left in Output
	int_timer_label.text = ":" + str(roundf(int_timer.get_time_left()))

func _on_intermission_timer_timeout():
	int_timer_label.visible = false
	timer_label.visible = true

	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	for tile in platform_manager.active_platform.get_children():
		tile.selected()

	color_timer.start()
	int_timer.stop()

func _on_color_switch_timer_timeout():
	int_timer_label.visible = true
	timer_label.visible = false

	var selected_color = colors[new_index]

	platform_manager.update_platform(selected_color)

	color_timer.stop()
	int_timer.start()

func _on_speed_up_timer_timeout():
	color_timer.wait_time = 3
	int_timer.wait_time = 1
