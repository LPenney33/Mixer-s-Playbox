extends CharacterBody3D

## Can we move around?
@export var can_move : bool = false  # Disabled until game start
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

# --------------------------------------------------
# Added for multiplayer setup
@export var input_prefix : String = "p1"
@export var username     : String = ""
# --------------------------------------------------

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var controller_look_sensitivity : float = 4.0
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
# These will get set by configure_inputs()
@export var input_left        : String = ""
@export var input_right       : String = ""
@export var input_forward     : String = ""
@export var input_back        : String = ""
@export var input_jump        : String = ""
@export var input_sprint      : String = "sprint"
@export var input_freefly     : String = "freefly"
@export var input_look_right  : String = ""
@export var input_look_left   : String = ""
@export var input_look_up     : String = ""
@export var input_look_down   : String = ""
@export var quit_action       : String = "quit_game"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	configure_inputs()
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	var level_node = get_node("/root/Level")
	if level_node:
		level_node.connect("game_started", Callable(self, "_on_game_started"))

func configure_inputs() -> void:
	# Build action names from prefix
	input_jump      = input_prefix + "_a"
	input_left      = input_prefix + "_b"
	input_forward   = input_prefix + "_l1"
	input_right     = input_prefix + "_r1"
	input_back      = input_prefix + "_l2"
	input_look_left  = input_prefix + "_joy_left"
	input_look_right = input_prefix + "_joy_right"
	input_look_up    = input_prefix + "_joy_up"
	input_look_down  = input_prefix + "_joy_down"

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	if Input.is_action_just_pressed(quit_action):
		get_tree().quit()
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative * look_speed)
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if can_freefly and freeflying:
		var dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(dir.x, 0, dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	if not can_move:
		velocity.x = 0
		velocity.z = 0
		if has_gravity and not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	move_speed = sprint_speed if (can_sprint and Input.is_action_pressed(input_sprint)) else base_speed
	var dir := Vector2(
		Input.get_action_strength(input_right) - Input.get_action_strength(input_left),
		Input.get_action_strength(input_back)  - Input.get_action_strength(input_forward)
	)
	var move_dir := (transform.basis * Vector3(dir.x, 0, dir.y)).normalized()
	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	var lx = Input.get_action_strength(input_look_right) - Input.get_action_strength(input_look_left)
	var ly = Input.get_action_strength(input_look_down)  - Input.get_action_strength(input_look_up)
	if lx != 0 or ly != 0:
		rotate_look(Vector2(lx, ly) * controller_look_sensitivity * delta)

func rotate_look(rot_input : Vector2):
	look_rotation.x = clamp(look_rotation.x - rot_input.y, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	var actions = {
		"input_left": input_left,
		"input_right": input_right,
		"input_forward": input_forward,
		"input_back": input_back,
		"input_jump": input_jump,
		"input_sprint": input_sprint,
		"input_freefly": input_freefly,
		"input_look_right": input_look_right,
		"input_look_left": input_look_left,
		"input_look_up": input_look_up,
		"input_look_down": input_look_down,
		"quit_action": quit_action
	}
	for key in actions.keys():
		if not InputMap.has_action(actions[key]):
			push_error("%s disabled. No InputAction found for: %s" % [key, actions[key]])
			set(key, false)

func kill():
	can_move = false
	velocity = Vector3.ZERO
	respawn()

func respawn():
	global_transform.origin = Vector3(0, 10, 0)
	velocity = Vector3.ZERO
	can_move = true

func _on_game_started() -> void:
	can_move = true
