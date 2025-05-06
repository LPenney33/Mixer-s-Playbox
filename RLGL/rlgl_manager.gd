extends Node


var is_red_light := false

func _ready():
	pass

func _physics_process(_delta):
	pass


func set_red_light(state: bool):
	is_red_light = state
