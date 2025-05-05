extends Node


var is_red_light := false

func _ready():
	pass

func _physics_process(_delta):

	if is_red_light:
		print("🚦 RED light is ON")


func set_red_light(state: bool):
	is_red_light = state
	print("🚦 Red Light changed:", state)
