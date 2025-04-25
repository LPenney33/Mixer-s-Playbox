extends Node
@export var player: CharacterBody3D

var is_red_light: bool = false

func set_red_light(state: bool):
	is_red_light = state
	print("🚦 Red Light changed: ", is_red_light)

func _ready():
	if not player:
		print("❌ Player is NOT assigned in the Inspector!")
	else:
		print("✅ Player assigned:", player.name)

func _physics_process(delta):
	if player == null:
		return  # Don't do anything if player isn't ready yet

	if is_red_light and player_is_moving():
		print("Player moved during red light!")
		player.die()


func player_is_moving() -> bool:
	if player == null:
		return false
	return player.velocity.length() > 0.1  # adjust threshold if needed

func check_player_movement():
	if is_red_light and player_is_moving():
		print("Player moved during red light!")
		player.die()
