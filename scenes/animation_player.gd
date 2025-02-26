extends AnimationPlayer

@onready var anim_player = $"../AnimationPlayer"
@onready var timer = $Timer  

var current_phase = "Startup"
var last_phase = ""  # Keeps track of the last played phase

func _ready():
	anim_player.play("Startup")  
	anim_player.animation_finished.connect(_on_animation_finished)
	timer.timeout.connect(_on_Timer_timeout)  

func _on_animation_finished(anim_name):
	print("Animation finished:", anim_name)

	if anim_name == "Startup":
		play_green_light()  

	elif anim_name == "Green_Light":
		last_phase = "Green_Light"  # Track the last phase
		play_idle()  

	elif anim_name == "Red_Light":
		last_phase = "Red_Light"  # Track the last phase
		play_idle()  

func play_green_light():
	current_phase = "Green_Light"
	anim_player.play("Green_Light")
	timer.start(5)  # Green Light duration

func play_red_light():
	current_phase = "Red_Light"
	anim_player.play("Red_Light")
	timer.start(4)  # Red Light duration

func play_idle():
	current_phase = "RLGL_Idle"
	anim_player.play("RLGL_Idle")
	timer.start(3)  # Idle before switching to next phase

func _on_Timer_timeout():
	print("Timer triggered. Current phase:", current_phase)

	if current_phase == "RLGL_Idle":
		if last_phase == "Green_Light":
			play_red_light()
		else:
			play_green_light()
