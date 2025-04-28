extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/RestartButton.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	$VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))
func _on_restart_button_pressed():
	print("Restart button clicked!")  # Debugging output
	get_tree().reload_current_scene()  # Restart the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Hide cursor again for gameplay
func _on_quit_button_pressed():
	get_tree().quit()
