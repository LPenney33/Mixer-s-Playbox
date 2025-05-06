extends Control

@onready var return_button = $VBoxContainer/ReturnButton

func _ready():
	return_button.pressed.connect(_on_return_button_pressed)

func _on_return_button_pressed():
	get_tree().change_scene_to_file("res://LOBBY/lobby.tscn")
