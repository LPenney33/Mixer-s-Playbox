extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Controller look sensitivity
@export var controller_look_sensitivity : float = 4.0  
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

## Controller Look Inputs
@export var input_look_right : String = "look_right"
@export var input_look_left : String = "look_left"
@export var input_look_up : String = "look_up"
@export var input_look_down : String = "look_down"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around (Mouse)
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative * look_speed)

	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Apply jumping
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	# Modify speed based on sprinting
	move_speed = sprint_speed if (can_sprint and Input.is_action_pressed(input_sprint)) else base_speed

	# Apply movement
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = move_dir.x * move_speed if move_dir else move_toward(velocity.x, 0, move_speed)
		velocity.z = move_dir.z * move_speed if move_dir else move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	move_and_slide()

	# Apply controller look (Right Stick)
	var look_x = Input.get_action_strength(input_look_right) - Input.get_action_strength(input_look_left)
	var look_y = Input.get_action_strength(input_look_down) - Input.get_action_strength(input_look_up)
	if look_x != 0 or look_y != 0:
		rotate_look(Vector2(look_x, look_y) * controller_look_sensitivity * delta)


## Rotate look (Mouse & Controller)
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
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

## Checks if some Input Actions haven't been created.
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
		"input_look_down": input_look_down
	}
	
	for key in actions.keys():
		if not InputMap.has_action(actions[key]):
			push_error(key + " disabled. No InputAction found for: " + actions[key])
			set(key, false)
