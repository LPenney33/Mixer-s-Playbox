extends Node3D

@export var move_speed: float = 2.0
var started := false
var delay_timer := 0.0
var ignoring_red_light := false  # Should this NPC break the rules this round?
var last_red_light_state := false  # To track if red light changed

func _ready():
	# Random delay before NPC starts moving (personality quirk)
	delay_timer = randf_range(0.0, 2.0)

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

	# If it's red light and they're not cheating, freeze
	if RlglManager.is_red_light and not ignoring_red_light:
		return  # Do not move if it's red light and not allowed to cheat

	# Otherwise, move forward if allowed
	move_forward(delta)

# Move the NPC forward (on green light or if they are cheating)
func move_forward(delta):
	var forward = global_transform.basis.z.normalized()
	global_translate(forward * move_speed * delta)
