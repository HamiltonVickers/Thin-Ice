extends Node

@onready var Board = $Board

#DEFAULTS
func get_legal_moves_default(cxy: Vector2i) -> Array:
	var moves: Array = []
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var nxy = cxy + direction
		if !Board.is_free(nxy):
			if Board.is_frozen(nxy): # push frozen piece
				var exy = nxy
				while Board.is_free(exy + direction):
					exy += direction
				if Board.get_ice(exy + direction) == Board.IceType.Water: continue # can't slide into water
				if exy == nxy: continue # can't push at all
				moves.push_back(nxy)
			else:
				continue # can't move this direction
		
		while Board.is_free(nxy) and Board.get_ice(nxy) == Board.IceType.SmoothIce:
			nxy += direction # slide along smoothice
		if Board.get_ice(nxy) == Board.IceType.Water: continue # can't slide into water
		if !Board.is_free(nxy): nxy -= direction # end on tile before obstruction
		moves.push_back(nxy)
	return moves

func get_illegal_actions_default(cxy: Vector2i) -> Array:
	var illegal_actions := []
	for x in range(Board.width):
		for y in range(Board.height):
			var v = Vector2i(x, y)
			if !Board.is_free(v): illegal_actions.append(v)
	return illegal_actions

func move_piece_default(from: Vector2i, to: Vector2i, callback: Callable = func(from, to):) -> void:
	var dir: Vector2i = (to - from).sign()
	
	if Board.is_frozen(to): # push frozen piece
		while Board.is_free(to + dir):
			await Board.animate_move(to, to + dir, func(from, to): Board.set_ice(from, Board.IceType.SmoothIce))
			to += dir
	else: # normal movement
		while from != to:
			await Board.animate_move(from, from + dir, callback)
			from = from + dir


#REACTOR
func reactor_move(from, to):
	move_piece_default(from, to, func(from, to): Board.set_ice(from, Board.IceType.Water))


# FIRE
func fire_illegal_actions(from) -> Array:
	var illegal_actions := []
	for x in range(Board.width):
		for y in range(Board.height):
			var v = Vector2i(x, y)
			if Board.get_piece(v) == -1:
				if !Board.is_free(v): illegal_actions.append(v)
			else:
				if !(Board.is_frozen(v) and Board.mhd(from, v) <= 2): illegal_actions.append(v)
	return illegal_actions

func fire_act(_from, to):
	if Board.get_piece(to) != -1:
		Board.set_frost(to, 0)
	else:
		var melted;
		if Board.get_ice(to) == Board.IceType.Ice:
			melted = Board.IceType.Water
		else:
			melted = Board.IceType.Ice
		Board.set_ice(to, melted)


# WATER
func water_illegal_actions(from) -> Array:
	var illegal_actions := []
	for x in range(Board.width):
		for y in range(Board.height):
			var v = Vector2i(x, y)
			if Board.get_piece(v) == -1:
				if !Board.get_ice(v) == Board.IceType.Ice: illegal_actions.append(v)
			else:
				if Board.is_frozen(v) or !(Board.mhd(from, v) <= 2): illegal_actions.append(v)
	return illegal_actions

func water_act(_from, to):
	if Board.get_piece(to) != -1:
		Board.set_frost(to, 1)
	else:
		Board.set_ice(to, Board.IceType.SmoothIce)
		for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if Board.is_free(to + d): Board.set_ice(to + d, Board.IceType.SmoothIce)
