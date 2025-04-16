extends Node3D
class_name ThatTile

enum TileColor {BLANK, RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE}

static var red = Color(1, 0, 0)    # Red
static var orange = Color(1, 0.647, 0)    # Orange
static var yellow = Color(1, 1, 0)    # Yellow
static var green = Color(0, 1, 0)    # Green
static var blue = Color(0, 0, 1)    # Blue
static var purple = Color(0.5, 0, 1)    # Purple

static var color_dict = {
	TileColor.RED: red,
	TileColor.ORANGE: orange,
	TileColor.YELLOW: yellow,
	TileColor.GREEN: green,
	TileColor.BLUE: blue,
	TileColor.PURPLE: purple
}

@export var color : TileColor = TileColor.BLANK

func not_selected():
	print("tile is not the selected color.")
	self.visible = false
	for tile : StaticBody3D in get_children():
		tile.collision_layer = 0
		tile.collision_mask = 0


func selected():
	print("tile is the selected color.")
	self.visible = true
	for tile : StaticBody3D in get_children():
		tile.collision_layer = 1
		tile.collision_mask = 1
