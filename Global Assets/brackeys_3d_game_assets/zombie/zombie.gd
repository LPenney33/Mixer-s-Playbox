extends Node3D

@export var move_speed: float = 2.0
@export var stop_x_position: float = 217.0  # X position to stop at
var started := false
var delay_timer := 0.0
var ignoring_red_light := false  # Should this NPC break the rules this round?
var last_red_light_state := false  # To track if red light changed
var is_moving = false

func _ready():
	# Random delay before NPC starts moving (personality quirk)
	delay_timer = randf_range(0.0, 2.0)

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
				queue_free()
				return
		else:
			is_moving = false
			return  # Stay still during red light if not cheating

	# Check if the X position has passed the target
	if global_position.x >= stop_x_position:
		is_moving = false  # Stop moving once we pass the X threshold
		return

	# Keep moving forward until the stop position is reached
	move_forward(delta)

func move_forward(delta):
	var forward = global_transform.basis.z.normalized()
	var velocity = forward * move_speed * delta
	global_translate(velocity)

	is_moving = velocity.length() > 0.001
	return is_moving  # Return if we moved
