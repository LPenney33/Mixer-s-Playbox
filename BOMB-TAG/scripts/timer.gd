extends Timer

signal countdown_finished

@onready var timer: Timer = $StartGameTimer  # Ensure you have a Timer node as a child.

func start_countdown():
	# Set how many seconds you want (5 in your case).
	timer.wait_time = 5.0
	timer.start()

func _on_Timer_timeout():
	# This function is connected to the Timer’s "timeout" signal.
	emit_signal("countdown_finished")
