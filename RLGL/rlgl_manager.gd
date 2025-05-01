extends Node

@export var player: CharacterBody3D
var is_red_light := false

func _ready():

	
	if player != null:
		print("✅ Player assigned or found:", player.name)
	else:
		print("❌ Still no player found.")

func _physics_process(_delta):
	if player == null:
		print("❌ No player found.")
		return

	if is_red_light:
		print("🚦 RED light is ON")
		if player_is_moving():
			print("🚨 Player is moving!")
			player.die()
		else:
			print("🟩 Player is NOT moving.")

func set_red_light(state: bool):
	is_red_light = state
	print("🚦 Red Light changed:", state)

func player_is_moving() -> bool:
	return player != null and player.velocity.length() > 0.1
