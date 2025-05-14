extends Button
extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect buttons to functions
	$StartButton.connect("pressed", self, "_on_start_button_pressed")
	$QuitButton.connect("pressed", self, "_on_quit_button_pressed")

# Function to start the game
func _on_start_button_pressed():
	# Load the next scene (replace "GameScene" with your actual game scene filename)
	get_tree().change_scene("res://GameScene.tscn")

# Function to quit the game
func _on_quit_button_pressed():
	# Exit the game
	get_tree().quit()
