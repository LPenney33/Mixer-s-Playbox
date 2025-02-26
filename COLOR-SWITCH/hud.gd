extends CanvasLayer

var colors = [
	Color(1, 0, 0),    # Red
	Color(1, 0.647, 0), # Orange
	Color(1, 1, 0),    # Yellow
	Color(0, 1, 0),    # Green
	Color(0, 0, 1),    # Blue
	Color(0.5, 0, 1)   # Purple
]

@onready var color_square = $ColorRect
var last_index = -1  # Store last selected index

func _on_start_button_pressed():
	var new_index = last_index

	# Ensure a different index is selected
	while new_index == last_index:
		new_index = randi() % colors.size()

	last_index = new_index  # Update last selected index
	var selected_color = colors[new_index]

	color_square.self_modulate = selected_color

	print("Selected Color: ", selected_color)
