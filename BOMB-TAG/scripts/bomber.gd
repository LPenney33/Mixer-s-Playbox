# File: res://BOMB-TAG/scripts/bomber.gd
extends CharacterBody3D

const SPEED        = 8.5
const ATTACK_RANGE = 2.0

var can_chase : bool   = false
var players   : Array  = []

@onready var nav_agent = $NavigationAgent3D
@onready var tag_area  = $TagArea

func _ready():
	# both Player1 & Player2 are direct children of Level
	var lvl = get_node("/root/Level")
	if lvl.has_node("Player1"):
		players.append(lvl.get_node("Player1"))
	if lvl.has_node("Player2"):
		players.append(lvl.get_node("Player2"))

	# wait for the cutscene to finish
	if lvl:
		lvl.connect("game_started", Callable(self, "_on_game_started"))

	# connect tag area
	if tag_area:
		tag_area.body_entered.connect(_on_TagArea_body_entered)

func _on_game_started():
	can_chase = true

func _physics_process(delta):
	if not can_chase or players.is_empty():
		return

	# pick nearest if multiplayer, else the only one
	var target = players[0]
	if GlobalInfo.multiplayer_active and players.size() > 1:
		var best = INF
		for p in players:
			var d = global_transform.origin.distance_to(p.global_transform.origin)
			if d < best:
				best = d
				target = p

	nav_agent.set_target_position(target.global_transform.origin)
	var next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_transform.origin).normalized() * SPEED

	rotation.y = lerp_angle(
		rotation.y,
		atan2(-velocity.x, -velocity.z),
		delta * 10.0
	)
	if global_position.distance_to(target.global_position) < ATTACK_RANGE:
		look_at(
			Vector3(
				target.global_position.x,
				global_transform.origin.y,
				target.global_position.z
			),
			Vector3.UP
		)

	move_and_slide()

func _on_TagArea_body_entered(body):
	if body in players:
		body.kill()
