extends Node2D

@onready var vp := get_viewport()
@onready var PieceManager := $PieceManager
@onready var Board := $PieceManager/Pieces/Board

enum TurnPhase { Selecting, Moving, Acting }
var selected_piece: Vector2i = Vector2i(-1, -1)
var move_options: Array = []
var illegal_actions: Array = []
var phase: TurnPhase = TurnPhase.Selecting
var player: bool = 0
var has_moved_reactor: bool = 0
var used_pieces: Array[Vector2i] = []

#TODO
#	pieces freeze when not near heat (and if they don't move for a while?)

func _input(event) -> void:
	if (event is InputEventKey) and has_moved_reactor: # this will become a ui button eventually
		player = !player
		has_moved_reactor = false
		used_pieces = []
		Board.radiate()
	
	if not (event is InputEventMouseButton and event.pressed): return # only process mouse clicks from here
	var cxy = Vector2i(vp.get_mouse_position() / 32)
	
	match phase:
		TurnPhase.Selecting:
			if Board.get_team(cxy) != int(player): return
			if Board.is_frozen(cxy): return
			if cxy in used_pieces: return
			
			selected_piece = cxy
			if event.button_index == MOUSE_BUTTON_LEFT:
				move_options = PieceManager.get_legal_moves(cxy)
				Board.set_ui_tiles(move_options, Board.UIType.Highlight)
				phase = TurnPhase.Moving
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if Board.get_piece(selected_piece) == Board.PieceType.Reactor: return
				illegal_actions = PieceManager.get_illegal_actions(cxy)
				Board.set_ui_tiles(illegal_actions, Board.UIType.Lowlight)
				phase = TurnPhase.Acting
		TurnPhase.Moving:
			if cxy in move_options:
				used_pieces.push_back(cxy)
				if Board.get_piece(selected_piece) == Board.PieceType.Reactor: 
					has_moved_reactor = true
				PieceManager.move_piece(selected_piece, cxy)
			phase = TurnPhase.Selecting
			move_options = []
			Board.set_ui_tiles(move_options, Board.UIType.Highlight)
		TurnPhase.Acting:
			if cxy not in illegal_actions:
				used_pieces.push_back(selected_piece)
				PieceManager.act_piece(selected_piece, cxy)
			phase = TurnPhase.Selecting
			illegal_actions = []
			Board.set_ui_tiles(illegal_actions, Board.UIType.Lowlight)
