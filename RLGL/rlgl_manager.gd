extends Node

var is_red_light: bool = false

func set_red_light(state: bool):
	is_red_light = state
	print("🚦 Red Light changed: ", is_red_light)
