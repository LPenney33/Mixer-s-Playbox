extends Node3D

@onready var platforms = $PLATFORMS.get_children()
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player = $ProtoController
@onready var color_square = $HUD/ColorRect
@onready var start_label = $HUD/ColorSwitchLabel
@onready var timer = $HUD/ColorSwitchTimer

var colors = [
	Color(1, 0, 0),    # Red
	Color(1, 0.647, 0), # Orange
	Color(1, 1, 0),    # Yellow
	Color(0, 1, 0),    # Green
	Color(0, 0, 1),    # Blue
	Color(0.5, 0, 1)   # Purple
]

var target_position = Vector3(-0.032, 1.596, 0.504)

var last_index = -1

var new_index = last_index

func _ready():
	button.connect("pressed", _on_start_button_pressed)
	hide_all()

func hide_all():
	for platform in platforms:
		platform.visible = false

func _on_start_button_pressed():
	hide_all()
	timer.start()
	var random_index = randi() % platforms.size()
	platforms[random_index].visible = true
	print("Platform ", random_index, " is now visible.")
	button.visible = false
	start_label.visible = false
	starting_platform.visible = false
	player.global_transform.origin = target_position

func _process(_delta):
	print("Time left: " + timer.time_left())

func _on_color_switch_timer_timeout():

	# Ensure a different index is selected
	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index  # Update last selected index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)

	timer.start()
