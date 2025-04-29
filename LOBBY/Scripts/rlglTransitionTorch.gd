extends OmniLight3D

@export var hold_time := 3.5       # same as Torch1
@export var fade_time := 0.50      # same as Torch1
@export var overlap_time := 0.10   # same as Torch1

# The 6‑step rainbow palette:
@export var colors: Array[Color] = [
	Color(2, 0, 0),    # red
	Color(1, 0.5, 0),  # orange
	Color(1, 1, 0),    # yellow
	Color(0, 1, 0),    # green
	Color(0, 0, 1),    # blue
	Color(1, 0, 1)     # purple
]

var timer := 0.0
var is_holding := true
var current_idx := 0
var next_idx := 1

func _process(delta):
	timer += delta

	if is_holding:
		if timer >= hold_time:
			timer = 0.0
			is_holding = false
		else:
			# still holding current color
			light_color = colors[current_idx]
		return

	# fading phase
	var t = clamp(timer / fade_time, 0.0, 1.0)
	var fade_out_strength = 1.0 - t
	var fade_in_strength = 0.0

	var fade_in_start = fade_time - overlap_time
	if timer >= fade_in_start:
		fade_in_strength = clamp((timer - fade_in_start) / overlap_time, 0.0, 1.0)

	var from_color = colors[current_idx]
	var to_color   = colors[next_idx]
	light_color = from_color * fade_out_strength + to_color * fade_in_strength

	if timer >= fade_time:
		# move to next pair
		timer = 0.0
		is_holding = true
		current_idx = next_idx
		next_idx = (current_idx + 1) % colors.size()
