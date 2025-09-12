extends Node

@onready var Pieces = $Pieces
@onready var Board = $Pieces/Board

func get_legal_moves(cxy: Vector2i) -> Array:
	match Board.get_piece(cxy):
		-1: push_error("no piece here"); return []
		_: return Pieces.get_legal_moves_default(cxy)

func get_illegal_actions(cxy: Vector2i) -> Array:
	match Board.get_piece(cxy):
		-1: push_error("no piece here"); return []
		Board.PieceType.FirePiece: return Pieces.fire_illegal_actions()
		Board.PieceType.WaterPiece: return Pieces.water_illegal_actions()
		_: return Pieces.get_illegal_actions_default(cxy)

func move_piece(from: Vector2i, to: Vector2i) -> void:
	match Board.get_piece(from):
		-1: push_error("no piece here"); return
		Board.PieceType.Reactor: Pieces.reactor_move(from, to)
		_: Pieces.move_piece_default(from, to)

func act_piece(from: Vector2i, to: Vector2i) -> void:
	match Board.get_piece(from):
		-1: push_error("no piece here"); return
		Board.PieceType.FirePiece: Pieces.fire_act(from, to)
		Board.PieceType.WaterPiece: Pieces.water_act(from, to)
