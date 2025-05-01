extends Node3D

var active_platform : Node3D

func update_platform(selected_color):
	print("Updating platform color to: ", selected_color)

	var tiles = active_platform.get_children()
	## print("Number of tiles: ", tiles.size())

	for tile in tiles:
		#print(tile.get_class())
		if tile is ThatTile:
			if ThatTile.color_dict[tile.color] != selected_color:
				tile.not_selected()
			else:
				tile.selected()
