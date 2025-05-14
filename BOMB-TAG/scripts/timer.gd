# File: res://BOMB-TAG/scripts/timer.gd
extends Timer

signal countdown_finished

func _ready():
	# connect this Timer’s own timeout
	connect("timeout", Callable(self, "_on_Timer_timeout"))

func start_countdown():
	wait_time = 5.0
	start()

func _on_Timer_timeout():
	emit_signal("countdown_finished")
