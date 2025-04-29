extends Control
signal names_chosen(p1_name: String, p2_name: String)

const MIN_NAME_LEN : int = 1
const MAX_NAME_LEN : int = 3

var prohibited_words : Array[String] = []
var p1_ready : bool = false
var p2_ready : bool = false

@onready var p1UName       : LineEdit  = $P1_Control/Panel/P1_NameEntry
@onready var p1Confirm     : Button    = $P1_Control/Panel/P1_ConfirmButton
@onready var p1Indicator   : CheckBox  = $P1_Control/Panel/P1_Indicator

@onready var p2UName       : LineEdit  = $P2_Control/Panel/P2_NameEntry
@onready var p2Confirm     : Button    = $P2_Control/Panel/P2_ConfirmButton
@onready var p2Indicator   : CheckBox  = $P2_Control/Panel/P2_Indicator

@onready var panelEnabler  : CheckBox  = $P2_Control/MultiplayerToggle
@onready var panelDisabler : Control   = $P2_Control/Panel/P2PanelDisabler

func _ready() -> void:
	# ensure backspace action
	if not InputMap.has_action("delete_char"):
		InputMap.add_action("delete_char")
		var ev = InputEventKey.new()
		ev.keycode = Key.KEY_BACKSPACE
		InputMap.action_add_event("delete_char", ev)
	set_process(true)

	_load_prohibited_words()

	# initial lock
	p1Confirm.disabled    = true
	p2Confirm.disabled    = true
	panelDisabler.visible = true
	p2UName.editable      = false

	p1UName.text_changed.connect(_on_p1_text_changed)
	p1Confirm.pressed.connect(_on_p1_confirmed)
	panelEnabler.toggled.connect(Callable(self, "_on_multiplayer_toggled"))
	p2UName.text_changed.connect(_on_p2_text_changed)
	p2Confirm.pressed.connect(_on_p2_confirmed)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("delete_char"):
		if p1UName.has_focus():
			var t = p1UName.text
			if t.length() > 0:
				var new_t = t.substr(0, t.length() - 1)
				p1UName.text = new_t
				p1UName.caret_column = new_t.length()
				_on_p1_text_changed(new_t)
		elif p2UName.has_focus() and panelEnabler.button_pressed:
			var t2 = p2UName.text
			if t2.length() > 0:
				var new_t2 = t2.substr(0, t2.length() - 1)
				p2UName.text = new_t2
				p2UName.caret_column = new_t2.length()
				_on_p2_text_changed(new_t2)

func _load_prohibited_words() -> void:
	var script_dir = get_script().resource_path.get_base_dir()
	var path = "%s/ProhibitedWords.md" % script_dir
	var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if f == null:
		push_error("Cannot open ProhibitedWords.md at: " + path)
		return
	while not f.eof_reached():
		var line = f.get_line().strip_edges()
		if line.begins_with("- "):
			prohibited_words.append(line.substr(2).to_lower())
	f.close()

func _is_valid_name(s : String) -> bool:
	var name = s.strip_edges()
	var l = name.length()
	if l < MIN_NAME_LEN or l > MAX_NAME_LEN:
		return false
	if prohibited_words.has(name.to_lower()):
		return false
	return true

func _on_p1_text_changed(txt : String) -> void:
	p1Confirm.disabled = not _is_valid_name(txt)

func _on_p2_text_changed(txt : String) -> void:
	var clean = txt.strip_edges()
	var dup = clean.to_lower() == p1UName.text.strip_edges().to_lower()
	p2Confirm.disabled = (not _is_valid_name(clean)) or dup

func _on_p1_confirmed() -> void:
	var name = p1UName.text.strip_edges()
	if prohibited_words.has(name.to_lower()):
		p1Confirm.disabled = true
		return
	p1Indicator.button_pressed = true
	p1UName.editable    = false
	p1Confirm.disabled  = true
	print("Player1_Username:", name)

	if not panelEnabler.button_pressed:
		emit_signal("names_chosen", name, "")
	else:
		p1_ready = true
		# if P2 already ready, emit now
		if p2_ready:
			emit_signal("names_chosen", name, p2UName.text.strip_edges())

func _on_p2_confirmed() -> void:
	var name = p2UName.text.strip_edges()
	if name.to_lower() == p1UName.text.strip_edges().to_lower():
		return
	if prohibited_words.has(name.to_lower()):
		p2Confirm.disabled = true
		return
	print("Player2_Username:", name)
	p2Indicator.button_pressed = true
	p2UName.editable    = false
	p2Confirm.disabled  = true
	p2_ready            = true

	if not panelEnabler.button_pressed:
		return  # single-player should never hit P2
	if p1_ready:
		emit_signal("names_chosen", p1UName.text.strip_edges(), name)

func _on_multiplayer_toggled(enabled : bool) -> void:
	panelDisabler.visible      = not enabled
	p2UName.editable           = enabled
	if not enabled:
		p2UName.text               = ""
		p2Confirm.disabled         = true
		p2Indicator.button_pressed = false
		p2_ready                   = false
