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
	# If the NPC hasn't started yet, wait for the delay to be over
	if not started:
		delay_timer -= delta
		if delay_timer <= 0:
			started = true
		else:
			return

	# Detect if red light state changed since last frame
	if RlglManager.is_red_light != last_red_light_state:
		last_red_light_state = RlglManager.is_red_light
		if RlglManager.is_red_light:
			# Red light just turned on — roll to decide if cheating
			ignoring_red_light = randf() < 0.1
		else:
			# Green light just turned on — always allow movement
			ignoring_red_light = true

	# If it's red light and they're not cheating, freeze the zombie
	if RlglManager.is_red_light and not ignoring_red_light:
		if zom_player.is_playing() and zom_player.current_animation != "Idle":
			print("Stopping animation during red light.")
			zom_player.stop()  # Stop animation during red light
		return  # Stop movement and animation during red light

	# Otherwise, move forward if allowed
	move_forward(delta)

	# If the zombie is moving, play "Run", otherwise stop the animation
	if is_moving:
		# Only play "Run" animation if it's not already playing
		if !zom_player.is_playing() or zom_player.current_animation != "Run":
			print("Playing run animation.")
			zom_player.play("Run")
	else:
		# Stop animation if zombie is not moving
		if zom_player.is_playing():
			print("Stopping animation, zombie is idle.")
			zom_player.stop()

# Move the NPC forward (on green light or if they are cheating)
func move_forward(delta):
	var forward = global_transform.basis.z.normalized()
	var velocity = forward * move_speed * delta
	global_translate(velocity)

	# Update the moving status based on whether there is any movement
	if velocity.length() > 0:
		is_moving = true  # Zombie is moving
	else:
		is_moving = false  # Zombie is not moving

	# Debugging: Print the position to ensure it's moving
	print("Zombie Position: ", global_position)
