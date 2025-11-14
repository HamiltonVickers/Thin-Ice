extends Node2D

@onready var popup := $"OnlinePopup"
@onready var ip := $OnlinePopup/IP
@onready var Match := preload("res://Scenes/Match.tscn")

var default: Color = Color(255, 255, 255)

func _is_mouse_click(event):
	return (event is InputEventMouseButton) and (event.pressed) and (event.button_index <= 2)
	
func _ready() -> void:
	# base colour is actually hovered color
	# because override colours are restricted and defaults are not
	# so we override to white and remove override on hover
	for b in get_children():
		if not (b is RichTextLabel): continue
		b.add_theme_color_override("default_color", default)
		b.mouse_exited.connect(_on_mouse_exited.bind(b))
		b.mouse_entered.connect(_on_mouse_entered.bind(b))
	
	multiplayer.connected_to_server.connect(func():
		Settings.online = true
		get_tree().change_scene_to_packed(Match)
	)

func _on_mouse_exited(element) -> void:
	element.add_theme_color_override("default_color", default)

func _on_mouse_entered(element) -> void:
	element.remove_theme_color_override("default_color")

func _on_new_match_gui_input(event: InputEvent) -> void:
	if _is_mouse_click(event):
		Settings.online = false
		get_tree().change_scene_to_packed(Match)

func _on_online_match_gui_input(event: InputEvent) -> void:
	if _is_mouse_click(event):
		popup.popup()

func _on_settings_gui_input(event: InputEvent) -> void:
	if _is_mouse_click(event):
		Settings.visible = true
		Settings.prev_scene = get_tree().current_scene
		Settings.prev_scene.visible = false

func _on_exit_gui_input(event: InputEvent) -> void:
	if _is_mouse_click(event):
		get_tree().quit()

func _on_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(1317, 1)
	multiplayer.multiplayer_peer = peer
	Settings.online = true
	get_tree().change_scene_to_packed(Match)

func _on_join_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip.text, 1317)
	multiplayer.multiplayer_peer = peer

func _on_online_popup_focus_exited() -> void:
	popup.hide()
