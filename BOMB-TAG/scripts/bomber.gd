extends CharacterBody3D

const SPEED = 4.0
const ATTACK_RANGE = 2.0

@export var can_chase: bool = false  # Remains false until game start

@onready var player = get_node("../Map/Player")
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $zombie/AnimationPlayer
@onready var tag_area = $TagArea

func _ready():
	if player == null:
		push_warning("Player not found at '../Map/Player'")
	var level_node = get_node("/root/Level")  # Adjust if your structure is different
	if level_node:
		level_node.connect("game_started", Callable(self, "_on_game_started"))
	if tag_area:
		tag_area.body_entered.connect(_on_TagArea_body_entered)

func _physics_process(delta):
	if not can_chase:
		return
	if player == null:
		return

	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
	rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
	if global_position.distance_to(player.global_position) < ATTACK_RANGE:
		anim_player.play("zombie_idle/T-pose")
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	else:
		anim_player.play("zombie_run/Run")
	move_and_slide()

func _on_TagArea_body_entered(body: Node) -> void:
	# When the player enters the tag area, immediately kill them.
	if body == player:
		player.kill()

func _hit_finished():
	if player and global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)

func _on_game_started() -> void:
	can_chase = true
