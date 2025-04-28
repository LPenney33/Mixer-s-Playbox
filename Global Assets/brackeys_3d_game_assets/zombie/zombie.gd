extends Node3D

@onready var zom_player = $Skeleton3D/AnimationPlayer  # Reference to the AnimationPlayer

@export var move_speed: float = 2.0
var started := false
var delay_timer := 0.0
var ignoring_red_light := false  # Should this NPC break the rules this round?
var last_red_light_state := false  # To track if red light changed
var is_moving = false

func _ready():
	# Random delay before NPC starts moving (personality quirk)
	delay_timer = randf_range(0.0, 2.0)

	# Print to check if animation player is found
	if zom_player == null:
		print("Error: AnimationPlayer not found!")

	# Start with an idle animation (or you can leave it empty to default to no animation)
	if !zom_player.is_playing():
		zom_player.play("Idle")  # Or change this to a default pose name if you have one

func _physics_process(delta):
	if not started:
		delay_timer -= delta
		if delay_timer <= 0:
			started = true
		else:
			return

	# Detect red light change just to decide if this NPC might cheat
	if RlglManager.is_red_light != last_red_light_state:
		last_red_light_state = RlglManager.is_red_light
		if RlglManager.is_red_light:
			# Decide whether this zombie will *try* to cheat during this red light
			ignoring_red_light = randf() < 0.2
		else:
			ignoring_red_light = true  # Always allowed to move on green

	# If it's red light
	if RlglManager.is_red_light:
		if ignoring_red_light:
			# Move and check for punishment every frame
			var moved = move_forward(delta)
			if moved:
				print("💀 Zombie got caught cheating! Deleting...")
				queue_free()
				return
		else:
			is_moving = false
			if zom_player.is_playing():
				zom_player.stop()
			return  # Stay still during red light if not cheating
	if ignoring_red_light:
		print("🧠 Cheating decision made: Will CHEAT 🔴")
	else:
		print("🧠 Cheating decision made: Will OBEY 🛑")
	# If green light
	move_forward(delta)

	# Animation control
	if is_moving:
		if !zom_player.is_playing() or zom_player.current_animation != "Run":
			zom_player.play("Run")
	else:
		if zom_player.is_playing():
			zom_player.stop()


func move_forward(delta):
	var forward = global_transform.basis.z.normalized()
	var velocity = forward * move_speed * delta
	global_translate(velocity)

	is_moving = velocity.length() > 0.001
	return is_moving  # Return if we moved

	# Debugging: Print the position to ensure it's moving
	print("Zombie Position: ", global_position)
