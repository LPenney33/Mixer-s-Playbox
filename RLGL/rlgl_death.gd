# File: res://RLGL/rlgl_death.gd
extends Control

func _ready() -> void:
	# Start hidden
	visible = false
	$P1_DeathScreen.visible           = false
	$P2_DeathScreen.visible           = false
	$SinglePlayer_DeathScreen.visible = false

	# Listen to the autoloaded manager
	print("rlgl_death: connecting to RlglManager →", RlglManager)
	RlglManager.connect("player_caught", Callable(self, "_on_player_caught"))

	# Only the single-player panel has a button
	$SinglePlayer_DeathScreen/LobbyButton.connect("pressed", Callable(self, "_on_lobby"))


func _on_player_caught(player_idx: int) -> void:
	print("rlgl_death: _on_player_caught(", player_idx, ")")

	# Disable & hide that player
	var root = get_tree().get_current_scene()
	var p_node = root.get_node_or_null("Player1") if player_idx == 1 else root.get_node_or_null("Player2")
	if p_node:
		p_node.can_move = false
		p_node.visible  = false

	# Hide split-screen so UI is on top
	var split = root.get_node_or_null("SplitCanvas")
	if split:
		split.visible = false

	# Show this menu (don’t reset the other death screen in multiplayer)
	visible = true
	$SinglePlayer_DeathScreen.visible = false

	if GlobalInfo.multiplayer_active:
		if player_idx == 1:
			$P1_DeathScreen.visible = true
			$P1_DeathScreen/P1_NameLabel.text = GlobalInfo.p2_name
		else:
			$P2_DeathScreen.visible = true
			$P2_DeathScreen/P2_NameLabel.text = GlobalInfo.p1_name
	else:
		$SinglePlayer_DeathScreen.visible = true


func _on_lobby() -> void:
	get_tree().change_scene_to_file("res://LOBBY/Scenes/lobby.tscn")
