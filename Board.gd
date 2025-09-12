extends Node

@onready var IceTM := $IceTileMap
@onready var PieceTM := $PieceTileMap
@onready var UITM := $UITileMap
@onready var AnimTM := $AnimationMap

enum PieceType { Reactor, FirePiece, WaterPiece }
enum IceType { Water, Rock, Ice, SmoothIce }
enum UIType { Highlight, Lowlight }

var height := 11
var width  := 20

func _ready() -> void:
	lay_pieces()
	generate_rocks()
	
func get_piece(cxy: Vector2i) -> PieceType:
	return PieceTM.get_cell_source_id(cxy)

func get_team(cxy: Vector2i) -> int:
	return PieceTM.get_cell_atlas_coords(cxy).x # tilesets are arranged with p0, p1 at x= 0, 1

func is_frozen(cxy: Vector2i) -> bool:
	return PieceTM.get_cell_atlas_coords(cxy).y == 1 # tilesets are arranged with unfrozen, frozen at y= 0, 1

func get_ice(cxy: Vector2i) -> IceType:
	return IceTM.get_cell_source_id(cxy)

func set_ice(cxy: Vector2i, ice: IceType) -> void:
	IceTM.set_cell(cxy, ice, Vector2i.ZERO)

func set_frost(cxy: Vector2i, state: int) -> void:
	var piece_type = get_piece(cxy)
	var piece_team = get_team(cxy)
	PieceTM.set_cell(cxy, piece_type, Vector2i(piece_team, state)) # see get_piece, is_frozen

# used to highlight / lowlight move options
func set_ui_tiles(tiles: Array, tile: UIType) -> void:
	UITM.clear()
	for cxy in tiles:
		UITM.set_cell(cxy, tile, Vector2i.ZERO)

func animate_move(from: Vector2i, to: Vector2i, callback: Callable) -> void:
	var piece_type: PieceType = get_piece(from)
	var piece_team: int = get_team(from)
	var frozen: int = int(is_frozen(from))
	
	AnimTM.set_cell(from, piece_type, Vector2i(piece_team, frozen))
	PieceTM.set_cell(from, -1)
	callback.call(from, to)
	
	var tween := create_tween()
	tween.tween_property(AnimTM, "position", Vector2((to - from) * 32), 0.1)
	tween.connect("finished", func():
		PieceTM.set_cell(to, piece_type, Vector2i(piece_team, frozen))
		AnimTM.clear()
		AnimTM.position = Vector2.ZERO
	)
	await tween.finished

func is_free(cxy) -> bool:
	return get_piece(cxy) == -1 and get_ice(cxy) >= IceType.Ice

func lay_pieces() -> void:
	var s = PieceType.size()
	var centered_start = (height - s) / 2
	for i in range(s):
		PieceTM.set_cell(Vector2i(0, centered_start + i), i, Vector2i(0, 0))
		PieceTM.set_cell(Vector2i(width - 1, height - centered_start - i - 1), i, Vector2i(1, 0))

func generate_rocks() -> void:
	var x: int
	var y: int
	# rocks can overwrite each other
	for i in range(4):
		x = randi_range(3, width / 2 - 1)
		y = randi_range(0, width / 2 - 1)
		IceTM.set_cell(Vector2i(x, y), IceType.Rock, Vector2i.ZERO)
		IceTM.set_cell(Vector2i(width - x - 1, height - y - 1), IceType.Rock, Vector2i.ZERO)
		# 180deg rotational symmetry

func radiate() -> void:
	for x in range(width):
		for y in range(height):
			var v = Vector2i(x, y)
			if get_piece(v) == PieceType.Reactor:
				for cxy in PieceTM.get_surrounding_cells(v):
					if get_piece(cxy) != -1: set_frost(cxy, 0)
