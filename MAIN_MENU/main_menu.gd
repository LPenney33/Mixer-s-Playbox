extends Control

var LobbyPath = "res://LOBBY/Scenes/lobby.tscn"

var Level: PackedScene

func _ready() -> void:
	Level = load(LobbyPath)
	
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(Level)



func _on_quit_button_pressed() -> void:
	get_tree().quit()
