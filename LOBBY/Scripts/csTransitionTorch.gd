extends OmniLight3D

@export var hold_time := 5.0      # Time to hold each color
@export var fade_time := .50       # Time to fade each color out
@export var overlap_time := 0.10   # Time before end of fade-out to start fade-in

var timer = 0.0
var is_holding = true
var is_fading_to_red = true

func _process(delta):
	timer += delta

	if is_holding:
		if timer >= hold_time:
			timer = 0.0
			is_holding = false  # Start fading
	else:
		var t = timer / fade_time
		t = clamp(t, 0.0, 1.0)

		# Fade OUT current color
		var fade_out_strength = 1.0 - t

		# Fade IN new color, starts when overlap_time triggers
		var fade_in_strength = 0.0
		var fade_in_start = fade_time - overlap_time

		if timer >= fade_in_start:
			var in_t = (timer - fade_in_start) / overlap_time
			fade_in_strength = clamp(in_t, 0.0, 1.0)

		# Pick colors based on direction
		var from_color = Color(0, 1, 0) if is_fading_to_red else Color(2, 0, 0)
		var to_color = Color(2, 0, 0) if is_fading_to_red else Color(0, 1, 0)

		# Apply strengths
		light_color = (from_color * fade_out_strength) + (to_color * fade_in_strength)

		if timer >= fade_time:
			timer = 0.0
			is_holding = true
			is_fading_to_red = !is_fading_to_red
