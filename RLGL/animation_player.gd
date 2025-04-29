extends AnimationPlayer

@onready var anim_player = $"../AnimationPlayer"
@onready var timer = $Timer
@onready var status_light = $"../Rig/Skeleton3D/Skeleton_Mage_Hat/RedGreenLight" # Adjust path to your light node

var is_red_light = false  # Track if it's red light

func _ready():
	anim_player.play("Startup")  
	anim_player.animation_finished.connect(_on_animation_finished)
	timer.timeout.connect(_on_Timer_timeout)
	if is_red_light:
		print("🚦 Red Light is active!")
func _process(_delta):
	# Check light status every frame (or use signals if you optimize later)
	if RlglManager.is_red_light:
		status_light.light_color = Color.RED
	else:
		status_light.light_color = Color.LIME_GREEN  # Or use Color(0, 1, 0)

func _on_animation_started(anim_name):
	if anim_name == "Red_Light":  # Make sure the name matches the animation
		get_node("../Player").set_red_light(true)
	elif anim_name == "Green_Light":
		get_node("../Player").set_red_light(false)

func _on_animation_finished(anim_name):
	if anim_name == "Startup":
		play_green_light()  
	elif anim_name == "Green_Light":
		play_idle()
	elif anim_name == "Red_Light":
		play_idle()

func play_green_light():
	is_red_light = false  # Green Light → Safe to move
	anim_player.play("Green_Light")
	timer.start(5)  

func play_red_light():
	is_red_light = true  # Red Light → Don't move!
	anim_player.play("Red_Light")
	timer.start(4)  

func play_idle():
	anim_player.play("RLGL_Idle")
	timer.start(randf_range(1.5, 4.0))  # Random wait time

func _on_Timer_timeout():
	if anim_player.current_animation == "RLGL_Idle":  # ✅ Use current_animation instead
		if is_red_light:
			play_green_light()
			RlglManager.set_red_light(false)
		else:
			play_red_light()
			RlglManager.set_red_light(true)

func _pon_animation_started(anim_name):
	if anim_name == "Red_Light":
		get_node("../Player").set_red_light(true)
		print("🚦 Red light started.")
		RlglManager.is_red_light = true
	elif anim_name == "Green_Light":
		get_node("../Player").set_red_light(false)
		print("🚦 Green light started.")
		RlglManager.is_red_light = false
