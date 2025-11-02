extends Node

@onready var IceTM := $IceTileMap
@onready var PieceTM := $PieceTileMap
@onready var UITM := $UITileMap
@onready var AnimTM := $AnimationMap
@onready var SFXPlayer := $SFXPlayer
@onready var sizzle := load('res://Sounds/sizzle.ogg')
@onready var freeze := load('res://Sounds/freeze.ogg')

enum PieceType { Reactor, FirePiece, WaterPiece }
enum IceType { Water, Rock, Ice, SmoothIce }
enum UIType { Highlight, Lowlight }

var height := 11
var width  := 20
var rocks : Array
var tween : Tween

func _ready() -> void:
	lay_pieces()
	rocks = generate_rocks()

func get_piece(cxy: Vector2i) -> PieceType:
	return PieceTM.get_cell_source_id(cxy)

func get_team(cxy: Vector2i) -> int:
	return PieceTM.get_cell_atlas_coords(cxy).x # tilesets are arranged with p0, p1 at x= 0, 1

func is_frozen(cxy: Vector2i) -> bool:
	return PieceTM.get_cell_atlas_coords(cxy).y == 1 # tilesets are arranged with unfrozen, frozen at y= 0, 1

func get_ice(cxy: Vector2i) -> IceType:
	return IceTM.get_cell_source_id(cxy)

func set_ice(cxy: Vector2i, ice: IceType) -> void:
	if Settings.SFXVolume > 0:
		if ice == IceType.Water:
			SFXPlayer.stream = sizzle
		elif ice == IceType.SmoothIce:
			SFXPlayer.stream = freeze
		SFXPlayer.volume_db = Settings.SFXVolume * 20 - 10
		SFXPlayer.play()
	IceTM.set_cell(cxy, ice, Vector2i.ZERO)

func set_frost(cxy: Vector2i, state: int) -> void:
	if Settings.SFXVolume > 0:
		if state == 0:
			SFXPlayer.stream = sizzle
		elif state == 1:
			SFXPlayer.stream = freeze
		SFXPlayer.volume_db = Settings.SFXVolume * 20 - 10
		SFXPlayer.play()
	
	var piece_type = get_piece(cxy)
	var piece_team = get_team(cxy)
	PieceTM.set_cell(cxy, piece_type, Vector2i(piece_team, state)) # see get_piece, is_frozen

# used to highlight / lowlight move options
func set_ui_tiles(tiles: Array, tile: UIType) -> void:
	UITM.clear()
	for cxy in tiles:
		UITM.set_cell(cxy, tile, Vector2i.ZERO)

func animate_move(from: Vector2i, to: Vector2i, callback: Callable) -> void:
	if tween != null: if tween.is_running(): tween.custom_step(99) # finish immediately
	var piece_type: PieceType = get_piece(from)
	var piece_team: int = get_team(from)
	var frozen: int = int(is_frozen(from))
	
	AnimTM.set_cell(from, piece_type, Vector2i(piece_team, frozen))
	PieceTM.set_cell(from, -1)
	
	tween = create_tween()
	tween.tween_property(AnimTM, "position", Vector2((to - from) * 64), Settings.AnimationSpeed * 0.2)
	tween.connect("finished", func():
		PieceTM.set_cell(to, piece_type, Vector2i(piece_team, frozen))
		callback.call(from, to)
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

func generate_rocks() -> Array:
	# rocks can overwrite each other
	var r = []
	for i in range(4):
		var x = randi_range(3, width / 2 - 1)
		var y = randi_range(0, width / 2 - 1)
		r.append(Vector2i(x, y))
	return r

func set_rocks(rocks: Array) -> void:
	for r in rocks:
		IceTM.set_cell(r, IceType.Rock, Vector2i(randi_range(0, 2), 0))
		IceTM.set_cell(Vector2i(width - r.x - 1, height - r.y - 1), IceType.Rock, Vector2i(randi_range(0, 2), 0))
		# 180deg rotational symmetry

func generate_ice() -> void:
	for x in range(width):
		for y in range(height):
			var ice := randi_range(0, 2)
			IceTM.set_cell(Vector2i(x, y), IceType.Ice, Vector2i(ice, 0))

func radiate() -> void:
	for x in range(width):
		for y in range(height):
			var v = Vector2i(x, y)
			if get_piece(v) != PieceType.Reactor: continue
			for x2 in range(-2, 2):
				for y2 in range(-2, 2):
					var v2 = v + Vector2i(x2, y2)
					if get_piece(v2) != -1 and is_frozen(v2): set_frost(v2, 0)

func mhd(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)
