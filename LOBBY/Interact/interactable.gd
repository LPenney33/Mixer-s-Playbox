extends CollisionObject3D
class_name Interactable

@export var prompt_message = "⚠️⚠️⚠️ Press to interact! ⚠️⚠️⚠️"
@export var prompt_input = "p1_x"
@export var LevelPath: String = "res://LOBBY/Scenes/lobby.tscn"

var Level: PackedScene  # <-- declare the variable here

func _ready():
	Level = load(LevelPath)  # <-- load the scene dynamically

func get_prompt() -> String:
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
	return prompt_message + "\n[" + key_name + "]"

func interact(body):
	print(body.name, "interacted with", name)
	print("starting new scene")
	if Level:
		get_tree().change_scene_to_packed(Level)
	else:
		print("Error: Level failed to load!")
