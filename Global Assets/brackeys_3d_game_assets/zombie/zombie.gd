extends Node3D

@export var speed: float = 3.0
@export var goal: Node3D
@onready var raycast = $RayCast3D  # Ensure you have a RayCast3D node

func _ready():
	raycast.target_position = Vector3.FORWARD * 1.5  # Adjust distance

func _process(delta):
	if goal and not raycast.is_colliding():  # Stops if hitting an object
		var direction = (goal.global_transform.origin - global_transform.origin).normalized()
		global_translate(direction * speed * delta)
