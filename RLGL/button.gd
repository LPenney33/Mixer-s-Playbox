extends Button


func _on_restart_button_pressed():
	get_tree().reload_current_scene()  # Restart the level
func _on_quit_button_pressed():
	get_tree().quit()
