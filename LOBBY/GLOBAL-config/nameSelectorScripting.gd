# nameSelectorScripting.gd
extends Control

signal names_chosen(p1_name: String, p2_name: String)

# Use a normal var so we never accidentally write to it
var ALPHABET : Array = [
	"A","B","C","D","E","F","G","H","I","J",
	"K","L","M","N","O","P","Q","R","S","T",
	"U","V","W","X","Y","Z"
]

var p1_slot      : int = 0
var p2_slot      : int = 0
var p1_indices   : Array = [0, 0, 0]
var p2_indices   : Array = [0, 0, 0]
var p1_confirmed : bool = false
var p2_confirmed : bool = false

@onready var p1_label1     : Label   = $P1_Control/Panel/Letter1
@onready var p1_label2     : Label   = $P1_Control/Panel/Letter2
@onready var p1_label3     : Label   = $P1_Control/Panel/Letter3
var p1_labels              : Array

@onready var p1_indicator  : CheckBox = $P1_Control/Panel/P1_Indicator

@onready var p2_label1     : Label   = $P2_Control/Panel/Letter1
@onready var p2_label2     : Label   = $P2_Control/Panel/Letter2
@onready var p2_label3     : Label   = $P2_Control/Panel/Letter3
var p2_labels              : Array

@onready var p2_indicator  : CheckBox = $P2_Control/Panel/P2_Indicator

@onready var panelEnabler  : CheckBox = $P2_Control/MultiplayerToggle
@onready var panelDisabler : Control  = $P2_Control/Panel/P2PanelDisabler

func _ready() -> void:
	# Build the label arrays
	p1_labels = [p1_label1, p1_label2, p1_label3]
	p2_labels = [p2_label1, p2_label2, p2_label3]

	# Initialize both players' name slots to 'A'
	for i in range(3):
		p1_labels[i].text = ALPHABET[0]
		p2_labels[i].text = ALPHABET[0]

	# Disable P2 panel until multiplayer is toggled on
	panelDisabler.visible = true
	panelEnabler.connect("toggled", Callable(self, "_on_multiplayer_toggled"))

	# Start processing gamepad input
	set_process(true)

func _process(_delta: float) -> void:
	# --- Player 1 input (if not yet confirmed) ---
	if not p1_confirmed:
		if Input.is_action_just_pressed("p1_up"):
			_cycle_letter(p1_indices, p1_labels, p1_slot, +1)
		elif Input.is_action_just_pressed("p1_down"):
			_cycle_letter(p1_indices, p1_labels, p1_slot, -1)
		elif Input.is_action_just_pressed("p1_l1"):
			p1_slot = min(p1_slot + 1, 2)
		elif Input.is_action_just_pressed("p1_a") and p1_slot == 2:
			_confirm_player(1)

	# --- Player 2 input (if multiplayer enabled & not yet confirmed) ---
	if panelEnabler.pressed and not p2_confirmed:
		if Input.is_action_just_pressed("p2_up"):
			_cycle_letter(p2_indices, p2_labels, p2_slot, +1)
		elif Input.is_action_just_pressed("p2_down"):
			_cycle_letter(p2_indices, p2_labels, p2_slot, -1)
		elif Input.is_action_just_pressed("p2_l1"):
			p2_slot = min(p2_slot + 1, 2)
		elif Input.is_action_just_pressed("p2_a") and p2_slot == 2:
			_confirm_player(2)

func _cycle_letter(indices: Array, labels: Array, slot: int, dir: int) -> void:
	var count : int = ALPHABET.size()
	indices[slot] = (indices[slot] + dir + count) % count
	labels[slot].text = ALPHABET[ indices[slot] ]

func _confirm_player(player: int) -> void:
	if player == 1:
		p1_confirmed = true
		p1_indicator.pressed = true
		var name1 : String = ""
		for idx in p1_indices:
			name1 += ALPHABET[idx]
		print("Player1_Username:", name1)
		# In single-player, emit immediately
		if not panelEnabler.pressed:
			emit_signal("names_chosen", name1, "")

	elif player == 2:
		p2_confirmed = true
		p2_indicator.pressed = true
		var name2 : String = ""
		for idx in p2_indices:
			name2 += ALPHABET[idx]
		print("Player2_Username:", name2)

	# If both confirmed in multiplayer, emit once
	if panelEnabler.pressed and p1_confirmed and p2_confirmed:
		var n1 : String = ""
		for idx in p1_indices:
			n1 += ALPHABET[idx]
		var n2 : String = ""
		for idx in p2_indices:
			n2 += ALPHABET[idx]
		emit_signal("names_chosen", n1, n2)

func _on_multiplayer_toggled(enabled: bool) -> void:
	panelDisabler.visible = not enabled
	if not enabled:
		# Reset Player2 selection on toggle off
		p2_confirmed = false
		p2_slot      = 0
		p2_indices   = [0, 0, 0]
		for i in range(3):
			p2_labels[i].text = ALPHABET[0]
		p2_indicator.pressed = false
