# res://LOBBY/GLOBAL-config/nameSelectorScripting.gd
extends Control

signal names_chosen(p1_name: String, p2_name: String)

# — Mutable alphabet —
var alphabet = [
	"A","B","C","D","E","F","G","H","I","J",
	"K","L","M","N","O","P","Q","R","S","T",
	"U","V","W","X","Y","Z"
]

# — Prohibited words —
var prohibited_words: Array = []

# — Per‐letter indices and slot selection —
var p1_slot      = 0
var p1_index1    = 0
var p1_index2    = 0
var p1_index3    = 0
var p1_confirmed = false

var p2_slot      = 0
var p2_index1    = 0
var p2_index2    = 0
var p2_index3    = 0
var p2_confirmed = false

# — Node references (exact paths) —
@onready var p1_label1         : Label    = $P1_Control/Panel/P1_Letter1
@onready var p1_label2         : Label    = $P1_Control/Panel/P1_Letter2
@onready var p1_label3         : Label    = $P1_Control/Panel/P1_Letter3
@onready var p1_indicator      : CheckBox = $P1_Control/Panel/P1_Indicator
@onready var p1_confirm_button : Button   = $P1_Control/Panel/P1_ConfirmButton

@onready var p2_label1         : Label    = $P2_Control/Panel/P2_Letter1
@onready var p2_label2         : Label    = $P2_Control/Panel/P2_Letter2
@onready var p2_label3         : Label    = $P2_Control/Panel/P2_Letter3
@onready var p2_indicator      : CheckBox = $P2_Control/Panel/P2_Indicator
@onready var p2_confirm_button : Button   = $P2_Control/Panel/P2_ConfirmButton

@onready var toggle            : CheckBox = $P2_Control/MultiplayerToggle
@onready var disabler          : Control  = $P2_Control/Panel/P2PanelDisabler

func _ready() -> void:
	# Load prohibited words
	_load_prohibited_words()

	# Initialize all letters to "A"
	p1_label1.text = alphabet[p1_index1]
	p1_label2.text = alphabet[p1_index2]
	p1_label3.text = alphabet[p1_index3]
	p2_label1.text = alphabet[p2_index1]
	p2_label2.text = alphabet[p2_index2]
	p2_label3.text = alphabet[p2_index3]

	# Disable Confirm buttons initially
	p1_confirm_button.disabled = true
	p2_confirm_button.disabled = true

	# Hide Player 2 panel until multiplayer is toggled on
	disabler.visible = true
	toggle.connect("toggled", Callable(self, "_on_multiplayer_toggled"))

	set_process(true)
	_update_ui()

func _process(_delta: float) -> void:
	# Player 1 letter cycling & confirm
	if not p1_confirmed:
		# joystick up/down unchanged
		if Input.is_action_just_pressed("p1_up"):
			if p1_slot == 0:
				p1_index1 = (p1_index1 + 1) % alphabet.size()
				p1_label1.text = alphabet[p1_index1]
			elif p1_slot == 1:
				p1_index2 = (p1_index2 + 1) % alphabet.size()
				p1_label2.text = alphabet[p1_index2]
			else:
				p1_index3 = (p1_index3 + 1) % alphabet.size()
				p1_label3.text = alphabet[p1_index3]
		elif Input.is_action_just_pressed("p1_down"):
			if p1_slot == 0:
				p1_index1 = (p1_index1 - 1 + alphabet.size()) % alphabet.size()
				p1_label1.text = alphabet[p1_index1]
			elif p1_slot == 1:
				p1_index2 = (p1_index2 - 1 + alphabet.size()) % alphabet.size()
				p1_label2.text = alphabet[p1_index2]
			else:
				p1_index3 = (p1_index3 - 1 + alphabet.size()) % alphabet.size()
				p1_label3.text = alphabet[p1_index3]

		# slot selection: R1 to next, L1 to previous
		elif Input.is_action_just_pressed("p1_r1") and p1_slot < 2:
			p1_slot += 1
		elif Input.is_action_just_pressed("p1_l1") and p1_slot > 0:
			p1_slot -= 1

		# confirm on slot 3
		elif Input.is_action_just_pressed("p1_a") and p1_slot == 2 and not p1_confirm_button.disabled:
			_confirm(1)

	# Player 2 letter cycling & confirm (multiplayer only)
	if toggle.is_pressed() and not p2_confirmed:
		if Input.is_action_just_pressed("p2_up"):
			if p2_slot == 0:
				p2_index1 = (p2_index1 + 1) % alphabet.size()
				p2_label1.text = alphabet[p2_index1]
			elif p2_slot == 1:
				p2_index2 = (p2_index2 + 1) % alphabet.size()
				p2_label2.text = alphabet[p2_index2]
			else:
				p2_index3 = (p2_index3 + 1) % alphabet.size()
				p2_label3.text = alphabet[p2_index3]
		elif Input.is_action_just_pressed("p2_down"):
			if p2_slot == 0:
				p2_index1 = (p2_index1 - 1 + alphabet.size()) % alphabet.size()
				p2_label1.text = alphabet[p2_index1]
			elif p2_slot == 1:
				p2_index2 = (p2_index2 - 1 + alphabet.size()) % alphabet.size()
				p2_label2.text = alphabet[p2_index2]
			else:
				p2_index3 = (p2_index3 - 1 + alphabet.size()) % alphabet.size()
				p2_label3.text = alphabet[p2_index3]

		# slot selection: R1 to next, L1 to previous
		elif Input.is_action_just_pressed("p2_r1") and p2_slot < 2:
			p2_slot += 1
		elif Input.is_action_just_pressed("p2_l1") and p2_slot > 0:
			p2_slot -= 1

		# confirm on slot 3
		elif Input.is_action_just_pressed("p2_a") and p2_slot == 2 and not p2_confirm_button.disabled:
			_confirm(2)

	_update_ui()

func _confirm(player: int) -> void:
	if player == 1:
		p1_confirmed = true
		p1_indicator.set_pressed(true)
		var name1 = p1_label1.text + p1_label2.text + p1_label3.text
		print("Player1_Username:", name1)
		if not toggle.is_pressed():
			emit_signal("names_chosen", name1, "")
	else:
		p2_confirmed = true
		p2_indicator.set_pressed(true)
		var name2 = p2_label1.text + p2_label2.text + p2_label3.text
		print("Player2_Username:", name2)

	if toggle.is_pressed() and p1_confirmed and p2_confirmed:
		var n1 = p1_label1.text + p1_label2.text + p1_label3.text
		var n2 = p2_label1.text + p2_label2.text + p2_label3.text
		emit_signal("names_chosen", n1, n2)

func _update_ui() -> void:
	# Player 1 highlighting
	if not p1_confirmed and p1_slot == 0:
		p1_label1.modulate = Color(0, 0, 0)
	else:
		p1_label1.modulate = Color(0.5, 0.5, 0.5)

	if not p1_confirmed and p1_slot == 1:
		p1_label2.modulate = Color(0, 0, 0)
	else:
		p1_label2.modulate = Color(0.5, 0.5, 0.5)

	if not p1_confirmed and p1_slot == 2:
		p1_label3.modulate = Color(0, 0, 0)
	else:
		p1_label3.modulate = Color(0.5, 0.5, 0.5)

	# Player 2 highlighting
	if toggle.is_pressed():
		if not p2_confirmed and p2_slot == 0:
			p2_label1.modulate = Color(0, 0, 0)
		else:
			p2_label1.modulate = Color(0.5, 0.5, 0.5)

		if not p2_confirmed and p2_slot == 1:
			p2_label2.modulate = Color(0, 0, 0)
		else:
			p2_label2.modulate = Color(0.5, 0.5, 0.5)

		if not p2_confirmed and p2_slot == 2:
			p2_label3.modulate = Color(0, 0, 0)
		else:
			p2_label3.modulate = Color(0.5, 0.5, 0.5)
	else:
		p2_label1.modulate = Color(0.5, 0.5, 0.5)
		p2_label2.modulate = Color(0.5, 0.5, 0.5)
		p2_label3.modulate = Color(0.5, 0.5, 0.5)

	# Confirm-button enable/disable logic
	var nm1 = (p1_label1.text + p1_label2.text + p1_label3.text).to_lower()
	if p1_confirmed:
		p1_confirm_button.disabled = true
	else:
		if p1_slot == 2 and not prohibited_words.has(nm1):
			p1_confirm_button.disabled = false
		else:
			p1_confirm_button.disabled = true

	var nm2 = (p2_label1.text + p2_label2.text + p2_label3.text).to_lower()
	var dup = nm2 == nm1
	if not toggle.is_pressed() or p2_confirmed or p2_slot != 2 or prohibited_words.has(nm2) or dup:
		p2_confirm_button.disabled = true
	else:
		p2_confirm_button.disabled = false

func _on_multiplayer_toggled(enabled: bool) -> void:
	disabler.visible = not enabled
	if not enabled:
		p2_confirmed = false
		p2_slot      = 0
		p2_index1    = 0
		p2_index2    = 0
		p2_index3    = 0
		p2_label1.text = alphabet[0]
		p2_label2.text = alphabet[0]
		p2_label3.text = alphabet[0]
		p2_label1.modulate = Color(0.5, 0.5, 0.5)
		p2_label2.modulate = Color(0.5, 0.5, 0.5)
		p2_label3.modulate = Color(0.5, 0.5, 0.5)
		p2_indicator.set_pressed(false)
		p2_confirm_button.disabled = true

func _load_prohibited_words() -> void:
	var dir = get_script().resource_path.get_base_dir()
	var f = FileAccess.open(dir + "/ProhibitedWords.md", FileAccess.ModeFlags.READ)
	if f:
		while not f.eof_reached():
			var line = f.get_line().strip_edges()
			if line.begins_with("- "):
				prohibited_words.append(line.substr(2).to_lower())
		f.close()
