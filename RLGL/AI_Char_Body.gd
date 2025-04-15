extends CharacterBody3D


@export var speed: float = 3.0  # Movement speed
@export var goal: Node3D  # Assign the goal position in the Inspector

func _physics_process(delta):
	if goal:
		var direction = (goal.global_transform.origin - global_transform.origin).normalized()
		velocity = direction * speed
		move_and_slide()
