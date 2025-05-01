extends CharacterBody3D

const SPEED = 8.5
const ATTACK_RANGE = 2.0

# This flag will be false until the Level node emits "game_started"
var can_chase: bool = false

@onready var player = get_node("../Map/Player")
@onready var nav_agent = $NavigationAgent3D
@onready var tag_area = $TagArea

func _ready():
	if player == null:
		push_warning("Player not found at '../Map/Player'")
	# Connect to the "game_started" signal from the Level node
	var level_node = get_node("/root/Level")
	if level_node:
		level_node.connect("game_started", Callable(self, "_on_game_started"))
	# Connect the TagArea's signal to handle tagging
	if tag_area:
		tag_area.body_entered.connect(_on_TagArea_body_entered)

func _on_game_started() -> void:
	# Called when the cutscene has finished and the game starts
	can_chase = true

func _physics_process(delta: float) -> void:
	# Don't move until the game has started
	if not can_chase:
		return

	if player == null:
		return

	# Update the navigation target to the player's position
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	
	# Move toward the next navigation point
	velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
	
	# Smoothly rotate to face the movement direction
	rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
	
	# If close enough to the player, adjust facing direction to look at them
	if global_position.distance_to(player.global_position) < ATTACK_RANGE:
		look_at(Vector3(player.global_position.x, global_transform.origin.y, player.global_position.z), Vector3.UP)
	
	# Apply movement (Godot 4.3: move_and_slide() uses the internal velocity)
	move_and_slide()

# Tagging: when the TagArea collides with the player, call the player's kill() function.
func _on_TagArea_body_entered(body: Node) -> void:
	if body == player:
		player.kill()

# Optional: Called after an attack, if used elsewhere.
func _hit_finished():
	if player and global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
