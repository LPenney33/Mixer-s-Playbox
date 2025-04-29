extends Node3D

signal game_started

@export var revolve_camera: Camera3D
@export var player_camera: Camera3D

@export var start_menu: Control
@export var start_button: Button

@export var skip_cutscene: bool = false
@export var revolve_center: Vector3 = Vector3.ZERO
@export var orbit_radius: float = 20.0
@export var orbit_speed: float = 0.1
@export var transition_speed: float = 0.7
@export var spiral_duration: float = 3.0
@export var forced_y_if_collision: float = 12.0
@export var collision_bump: float = 2.0

# Countdown variables
var countdown_active = false
var countdown_time = 5.0
# Now the countdown label is directly under CanvasLayer.
@onready var countdown_label: Label = $CanvasLayer/CountdownLabel
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var orbit_angle: float = 0.0
var is_spiraling: bool = false

var spiral_start_angle: float
var spiral_end_angle: float
var spiral_start_radius: float
var spiral_end_radius: float
var spiral_start_y: float
var spiral_end_y: float

var _spiral_param: float = 0.0
var spiral_param := 0.0:
	set(value):
		_spiral_param = value

		var old_pos = revolve_camera.global_transform.origin
		var angle = lerp(spiral_start_angle, spiral_end_angle, value)
		var r = lerp(spiral_start_radius, spiral_end_radius, value)
		var y = lerp(spiral_start_y, spiral_end_y, value)
		var x = revolve_center.x + r * cos(angle)
		var z = revolve_center.z + r * sin(angle)
		var desired_pos = Vector3(x, y, z)

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = old_pos
		query.to = desired_pos
		query.exclude = [revolve_camera]
		var collision = space_state.intersect_ray(query)
		if collision:
			desired_pos.y = max(collision.position.y + collision_bump, forced_y_if_collision)

		revolve_camera.global_transform.origin = desired_pos
		revolve_camera.look_at(revolve_center, Vector3.UP)
	get:
		return _spiral_param

func _ready():
	# Hide the entire UI until the countdown starts.
	if canvas_layer:
		canvas_layer.visible = false

	# Connect start button signal if available
	if start_button:
		start_button.connect("pressed", Callable(self, "_on_button_pressed"))
    
	if skip_cutscene:
		revolve_camera.current = false
		player_camera.current = true
		if start_menu:
			start_menu.visible = false
		emit_signal("game_started")
		return

	revolve_camera.current = true
	player_camera.current = false

	if start_menu:
		start_menu.visible = true

	var start_pos = revolve_camera.global_transform.origin
	orbit_angle = atan2(start_pos.z - revolve_center.z, start_pos.x - revolve_center.x)
	if orbit_radius <= 0.0:
		orbit_radius = (start_pos - revolve_center).length()

	revolve_camera.global_transform.origin = Vector3(
		revolve_center.x + orbit_radius * cos(orbit_angle),
		max(start_pos.y, forced_y_if_collision),
		revolve_center.z + orbit_radius * sin(orbit_angle)
	)

func _process(delta: float) -> void:
	# Normal orbit movement during cutscene (if not spiraling)
	if skip_cutscene or is_spiraling == false:
		var old_pos = revolve_camera.global_transform.origin
		orbit_angle -= orbit_speed * delta
		var x = revolve_center.x + orbit_radius * cos(orbit_angle)
		var z = revolve_center.z + orbit_radius * sin(orbit_angle)
		var desired_pos = Vector3(x, old_pos.y, z)
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = old_pos
		query.to = desired_pos
		query.exclude = [revolve_camera]
		var collision = space_state.intersect_ray(query)
		if collision:
			desired_pos.y = max(collision.position.y + collision_bump, forced_y_if_collision)
		revolve_camera.global_transform.origin = desired_pos
		revolve_camera.look_at(revolve_center, Vector3.UP)
    
	# Update countdown if active
	if countdown_active:
		countdown_time -= delta
		var seconds_left = ceil(countdown_time)
		# Only display seconds in the format :05, :04, etc.
		if seconds_left < 10:
			countdown_label.text = ":0" + str(seconds_left)
		else:
			countdown_label.text = ":" + str(seconds_left)
		if countdown_time <= 0:
			countdown_active = false
			canvas_layer.visible = false
			emit_signal("game_started")

func _on_button_pressed() -> void:
	print("Button pressed! Hiding start_menu...")
	if skip_cutscene:
		revolve_camera.current = false
		player_camera.current = true
		if start_menu:
			start_menu.visible = false
		emit_signal("game_started")
		return

	if start_menu:
		start_menu.visible = false

	if is_spiraling:
		return
	is_spiraling = true

	spiral_start_angle = orbit_angle
	spiral_start_radius = orbit_radius
	spiral_start_y = revolve_camera.global_transform.origin.y

	var end_pos = player_camera.global_transform.origin
	spiral_end_angle = _shortest_arc(
		spiral_start_angle,
		atan2(end_pos.z - revolve_center.z, end_pos.x - revolve_center.x)
	)
	spiral_end_radius = (end_pos - revolve_center).length()
	spiral_end_y = end_pos.y

	var tween = get_tree().create_tween()
	tween.tween_property(self, "spiral_param", 1.0, spiral_duration * transition_speed)\
		 .set_trans(Tween.TRANS_SINE)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_spiral_done"))

func _on_spiral_done() -> void:
	revolve_camera.current = false
	player_camera.current = true
	# Activate the countdown UI
	canvas_layer.visible = true
	countdown_active = true
	countdown_time = 5.0

func _shortest_arc(current_angle: float, target_angle: float) -> float:
	var diff = fmod(target_angle - current_angle, TAU)
	if diff > PI:
		diff -= TAU
	if diff < -PI:
		diff += TAU
	return current_angle + diff
