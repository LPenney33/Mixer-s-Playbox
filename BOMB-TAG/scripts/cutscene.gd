# File: res://BOMB-TAG/scenes/level.tscn/cutscene.gd
extends Node3D

signal game_started

# — Cameras (grab by exact node paths) —
@onready var revolve_camera : Camera3D         = get_node("Cutscene Camera")
@onready var player_cam1    : Camera3D         = get_node("Player1/Head/Camera3D")
@onready var player_cam2    : Camera3D         = get_node("Player2/Head/Camera3D")

# — Player bodies (for input setup & visibility) —
@onready var player1_node   : CharacterBody3D  = get_node("Player1")
@onready var player2_node   : CharacterBody3D  = get_node("Player2")

# — UI —
@onready var start_menu     : Control           = get_node("StartMenu")
@onready var start_button   : Button            = get_node("StartMenu/Button")
@export    var skip_cutscene : bool             = false

# — Orbit parameters —
@export var revolve_center          : Vector3 = Vector3.ZERO
@export var orbit_radius            : float   = 20.0
@export var orbit_speed             : float   = 0.1
@export var transition_speed        : float   = 0.7
@export var spiral_duration         : float   = 3.0
@export var forced_y_if_collision   : float   = 12.0
@export var collision_bump          : float   = 2.0

# — Countdown UI (under Level) —
var countdown_active : bool  = false
var countdown_time   : float = 5.0
@onready var canvas_layer    : CanvasLayer = get_node("CanvasLayer")
@onready var countdown_label : Label       = get_node("CanvasLayer/CountdownLabel")

# — Split-screen UI (under Level) —
@onready var split_canvas    : CanvasLayer = get_node("SplitCanvas")
@onready var left_viewport   : SubViewport = get_node("SplitCanvas/SplitScreen/LeftContainer/LeftViewport")
@onready var right_viewport  : SubViewport = get_node("SplitCanvas/SplitScreen/RightContainer/RightViewport")

# — Internal orbit state —
var orbit_angle    : float = 0.0
var is_spiraling   : bool  = false
var spiral_start_angle
var spiral_end_angle
var spiral_start_radius
var spiral_end_radius
var spiral_start_y
var spiral_end_y

var _spiral_param : float = 0.0
var spiral_param := 0.0:
	set(v):
		_spiral_param = v
		var old_pos = revolve_camera.global_transform.origin
		var angle   = lerp(spiral_start_angle, spiral_end_angle, v)
		var r       = lerp(spiral_start_radius, spiral_end_radius, v)
		var y       = lerp(spiral_start_y, spiral_end_y, v)
		var x = revolve_center.x + r * cos(angle)
		var z = revolve_center.z + r * sin(angle)
		var desired = Vector3(x, y, z)
		var rq = PhysicsRayQueryParameters3D.new()
		rq.from    = old_pos
		rq.to      = desired
		rq.exclude = [revolve_camera]
		var col = get_world_3d().direct_space_state.intersect_ray(rq)
		if col:
			desired.y = max(col.position.y + collision_bump, forced_y_if_collision)
		revolve_camera.global_transform.origin = desired
		revolve_camera.look_at(revolve_center, Vector3.UP)
	get:
		return _spiral_param

func _ready():
	# hide UI
	canvas_layer.visible = false
	split_canvas.visible = false

	# toggle player2 visibility based on multiplayer flag
	player2_node.visible = GlobalInfo.multiplayer_active

	# register cameras for easy toggling
	revolve_camera.add_to_group("main_cameras")
	player_cam1.add_to_group("main_cameras")
	player_cam2.add_to_group("main_cameras")

	start_button.connect("pressed", Callable(self, "_on_button_pressed"))

	if skip_cutscene:
		_end_cutscene()
		return

	# begin orbit cutscene
	revolve_camera.current = true
	player_cam1.current   = false
	start_menu.visible    = true

	var sp = revolve_camera.global_transform.origin
	orbit_angle = atan2(sp.z - revolve_center.z, sp.x - revolve_center.x)
	if orbit_radius <= 0.0:
		orbit_radius = (sp - revolve_center).length()
	revolve_camera.global_transform.origin = Vector3(
		revolve_center.x + orbit_radius * cos(orbit_angle),
		max(sp.y, forced_y_if_collision),
		revolve_center.z + orbit_radius * sin(orbit_angle)
	)

func _process(delta):
	if not skip_cutscene and not is_spiraling:
		orbit_angle -= orbit_speed * delta
		var old_pos = revolve_camera.global_transform.origin
		var x = revolve_center.x + orbit_radius * cos(orbit_angle)
		var z = revolve_center.z + orbit_radius * sin(orbit_angle)
		var desired = Vector3(x, old_pos.y, z)
		var rq = PhysicsRayQueryParameters3D.new()
		rq.from    = old_pos
		rq.to      = desired
		rq.exclude = [revolve_camera]
		var col = get_world_3d().direct_space_state.intersect_ray(rq)
		if col:
			desired.y = max(col.position.y + collision_bump, forced_y_if_collision)
		revolve_camera.global_transform.origin = desired
		revolve_camera.look_at(revolve_center, Vector3.UP)

	if countdown_active:
		countdown_time -= delta
		var secs_left = int(ceil(countdown_time))
		countdown_label.text = ":" + str(secs_left)
		if countdown_time <= 0.0:
			countdown_active = false
			canvas_layer.visible = false
			_end_cutscene()

func _on_button_pressed():
	# set up each player's input prefix
	player1_node.input_prefix = "p1"
	player1_node.configure_inputs()
	if GlobalInfo.multiplayer_active:
		player2_node.input_prefix = "p2"
		player2_node.configure_inputs()

	# multiplayer: skip spiral
	if GlobalInfo.multiplayer_active:
		start_menu.visible = false
		_on_spiral_done()
		return

	# otherwise run spiral
	if is_spiraling:
		return
	is_spiraling = true

	spiral_start_angle  = orbit_angle
	spiral_start_radius = orbit_radius
	spiral_start_y      = revolve_camera.global_transform.origin.y

	var endp = player_cam1.global_transform.origin
	spiral_end_angle  = _shortest_arc(
		spiral_start_angle,
		atan2(endp.z - revolve_center.z, endp.x - revolve_center.x)
	)
	spiral_end_radius = (endp - revolve_center).length()
	spiral_end_y      = endp.y

	var tw = get_tree().create_tween()
	tw.tween_property(self, "spiral_param", 1.0, spiral_duration * transition_speed)\
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(Callable(self, "_on_spiral_done"))

	start_menu.visible = false

func _on_spiral_done():
	for cam in get_tree().get_nodes_in_group("main_cameras"):
		cam.current = false

	if GlobalInfo.multiplayer_active:
		split_canvas.visible = true
		RenderingServer.viewport_attach_camera(
			left_viewport.get_viewport_rid(),  player_cam1.get_camera_rid()
		)
		RenderingServer.viewport_attach_camera(
			right_viewport.get_viewport_rid(), player_cam2.get_camera_rid()
		)
	else:
		player_cam1.current = true

	canvas_layer.visible = true
	countdown_active     = true
	countdown_time       = 5.0

func _end_cutscene():
	emit_signal("game_started")

func _shortest_arc(cur, tgt):
	var d = fmod(tgt - cur, TAU)
	if d > PI:  d -= TAU
	if d < -PI: d += TAU
	return cur + d
