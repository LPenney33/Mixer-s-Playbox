extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player: Node3D = get_node("/root/Level/Map/Player")  # Ensure this path is correct

@export var SPEED: float = 5.0

func _physics_process(delta: float) -> void:
	# Continuously update the agent's target position to the player's location.
	nav_agent.target_position = player.global_transform.origin

	# If there's a valid path, compute the next waypoint.
	if not nav_agent.is_navigation_finished():
		var next_point: Vector3 = nav_agent.get_next_path_position()
		var direction: Vector3 = (next_point - global_transform.origin).normalized()
		velocity = direction * SPEED
		
		# Optionally, rotate to face the direction of movement.
		if velocity.length() > 0:
			look_at(global_transform.origin + velocity, Vector3.UP)
	else:
		velocity = Vector3.ZERO  # Stop when there's no valid path.

	# Apply movement every frame.
	move_and_slide()
