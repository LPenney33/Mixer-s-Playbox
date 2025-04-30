extends Node
@export var player: CharacterBody3D
@onready var playerr = $"../Player"
var is_red_light: bool = false

func set_red_light(state: bool):
	is_red_light = state
	print("🚦 Red Light changed: ", is_red_light)

func _ready():
	if not playerr:
		print("❌ Player is NOT assigned in the Inspector!")
	else:
		print("✅ Player assigned:", playerr.name)

func _physics_process(delta):

	if is_red_light:
		print("🚦 RED light is ON")
		if player_is_moving():
			print("🚨 Player is moving!")
			player.die()
		else:
			print("🟩 Player is NOT moving.")

func player_is_moving() -> bool:
	if player == null:
		return false
	return player.velocity.length() > 0.1  # adjust threshold if needed
