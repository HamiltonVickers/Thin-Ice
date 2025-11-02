extends Node2D

@onready var vp := get_viewport()
@onready var PieceManager := $PieceManager
@onready var Board := $PieceManager/Pieces/Board
@onready var next_turn := $NextTurn
@onready var popup := $Popup
@onready var yes := $Popup/YesButton
@onready var no := $Popup/NoButton
@onready var popuptext := $Popup/RichTextLabel
@onready var turnlabel := $TurnLabel
@onready var music := $MusicPlayer

enum TurnPhase { Selecting, Moving, Acting }
var selected_piece: Vector2i = Vector2i(-1, -1)
var move_options: Array = []
var illegal_actions: Array = []
var phase: TurnPhase = TurnPhase.Selecting
var player: bool = 0
var has_moved_reactor: bool = 0
var used_pieces: Array[Vector2i] = []
var online: bool = false

func _ready() -> void:
	if multiplayer.is_server(): # this should be called is_not_client
		Board.set_rocks(Board.rocks)
		multiplayer.peer_connected.connect(func(i): online = true; rpc("sync_rocks", Board.rocks))
		multiplayer.peer_disconnected.connect(func(i): win(false))
	else: 
		online = true
		multiplayer.server_disconnected.connect(func(i): win(true))

func _process(_delta) -> void:
	var cxy = Vector2i(vp.get_mouse_position() / 64)
	
	if phase == TurnPhase.Acting:
		if cxy in illegal_actions:
			Board.set_ui_tiles([cxy], Board.UIType.Lowlight)
		else:
			Board.set_ui_tiles([cxy], Board.UIType.Highlight)

func _input(event) -> void:
	if Settings.visible: return # don't read input while settings is open
	if not (event is InputEventMouseButton and event.pressed and event.button_index <= 2): return # only process mouse clicks from here
	if online and multiplayer.is_server() == player: return # only process input on this client's turn
	
	var cxy = Vector2i(vp.get_mouse_position() / 64)
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
				phase = TurnPhase.Acting
		TurnPhase.Moving:
			if cxy in move_options:
				used_pieces.push_back(cxy)
				if Board.get_piece(selected_piece) == Board.PieceType.Reactor: 
					has_moved_reactor = true
				do_move(selected_piece, cxy)
			phase = TurnPhase.Selecting
			move_options = []
			Board.set_ui_tiles(move_options, Board.UIType.Highlight)
		TurnPhase.Acting:
			if cxy not in illegal_actions:
				used_pieces.push_back(selected_piece)
				do_act(selected_piece, cxy)
			phase = TurnPhase.Selecting
			illegal_actions = []
			Board.set_ui_tiles([], -1)

func _on_next_turn_pressed() -> void:
	if online and player == multiplayer.is_server(): return
	if has_moved_reactor:
		do_progress_turn()
		return
	if Settings.ShouldWarn:
		popup.title = "Warning!"
		popuptext.text = "You haven't moved your reactor. Are you sure you want to forfeit?"
		popup.popup()
		return
	do_win(!player)
	
func end_game():
	if online: rpc('win', multiplayer.is_server())
	get_tree().change_scene_to_file("res://Scenes/Title.tscn")

@rpc('any_peer')
func sync_rocks(rocks):
	Board.set_rocks(rocks)

@rpc('any_peer')
func win(player):
	yes.visible = false
	no.visible = false
	popup.title = "Victory"
	popuptext.text = ["Black", "White"][int(player)] + " has won"
	popup.popup()
	popup.popup_hide.connect(end_game)

func do_win(player):
	if online: rpc('win', player)
	win(player)

@rpc('any_peer')
func progress_turn() -> void:
	player = !player
	turnlabel.text = ["Black", "White"][int(player)] + " to play"
	has_moved_reactor = false
	used_pieces = []
	Board.radiate()

func do_progress_turn() -> void:
	progress_turn()
	if online: rpc('progress_turn')

# assumes move is legal
@rpc('any_peer')
func move(from, to):
	PieceManager.move_piece(from, to)

# ditto above
@rpc('any_peer')
func act(from, to):
	PieceManager.act_piece(from, to)

# universal (local or online) move method
func do_move(from, to):
	move(from, to)
	if online: rpc('move', from, to)

func do_act(from, to):
	act(from, to)
	if online: rpc('act', from, to)

func _on_settings_button_pressed() -> void:
	Settings.visible = true
	Settings.prev_scene = get_tree().current_scene
	self.visible = false

func _on_exit_button_pressed() -> void:
	if Settings.ShouldWarn:
		popup.title = "Exit?"
		popuptext.text = "Are you sure you want to exit?"
		popup.popup()
		return
	end_game()

func _on_popup_focus_exited() -> void:
	popup.hide()

func _on_no_button_pressed() -> void:
	popup.hide()

func _on_yes_button_pressed() -> void:
	if popup.title == "Warning!": # forfeiting
		do_win(!player)
	else: #exiting
		end_game()
