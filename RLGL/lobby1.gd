extends Button

@export var LevelPath: String = "res://LOBBY/Scenes/lobby.tscn"

var Level: PackedScene  # <-- declare the variable here

func _ready():
	Level = load(LevelPath)  # <-- load the scene dynamically

func _on_pressed():
	get_tree().change_scene_to_packed(Level)
