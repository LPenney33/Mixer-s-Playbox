extends Node3D

@onready var platforms = $PLATFORMS.get_children()
@onready var button = $HUD/StartButton
@onready var starting_platform = $BlankPlatform
@onready var player = $ProtoController

var target_position = Vector3(-0.032, 1.596, 0.504)

func _ready():
	button.connect("pressed", _on_start_button_pressed)
	hide_all()

func hide_all():
	for platform in platforms:
		platform.visible = false

func _on_start_button_pressed():
	hide_all()
	var random_index = randi() % platforms.size()
	platforms[random_index].visible = true
	print("Platform ", random_index, " is now visible.")
	button.visible = false
	starting_platform.visible = false
	player.global_transform.origin = target_position
