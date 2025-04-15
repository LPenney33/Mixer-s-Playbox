extends Node3D

@onready var platform_manager = $PLATFORMS
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player = $ProtoController
@onready var color_square = $HUD/ColorRect
@onready var start_label = $HUD/ColorSwitchLabel
@onready var timer = $HUD/ColorSwitchTimer
@onready var timer_label = $HUD/TimerLabel


var red = Color(1, 0, 0)    # Red
var orange = Color(1, 0.647, 0)    # Orange
var yellow = Color(1, 1, 0)    # Yellow
var green = Color(0, 1, 0)    # Green
var blue = Color(0, 0, 1)    # Blue
var purple = Color(0.5, 0, 1)    # Purple

var colors = [red, orange, yellow, green, blue, purple]


var target_position = Vector3(-0.032, 1.596, 0.504) ## Players starting point

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
	timer.start()
	hide_all()
	cameraPlayer.current = true
	cameraStart.current = false
	var random_index = randi() % platform_manager.get_children().size() ## Picks a random platform_manager child (PlatformV1 - V5)
	platform_manager.get_children()[random_index].visible = true ## Makes picked platform_manager visible
	print("Platform ", random_index, " is now visible.") ## Tells Output to print what platform_manager is visible
	button.visible = false
	start_label.visible = false
	color_square.visible = true
	timer_label.visible = true
	starting_platform.visible = false
	player.global_transform.origin = target_position ## Teleports player to starting point

	#Chooses starting color
	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	platform_manager.active_platform = platform_manager.get_children()[random_index]

	platform_manager.update_platform(selected_color)


func _process(_delta):
	timer_label.text = ":" + str(roundf(timer.get_time_left())) ## Displays time left in Output

func _on_color_switch_timer_timeout():

	#Chooses new color
	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	platform_manager.update_platform(selected_color)

	timer.start()
