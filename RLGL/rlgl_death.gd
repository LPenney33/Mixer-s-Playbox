extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))
func _on_quit_button_pressed():
	get_tree().quit()
