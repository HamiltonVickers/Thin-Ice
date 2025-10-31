extends Node2D

@onready var new_match := $"New Match"
@onready var settings := $"Settings"
@onready var exit := $"Exit"
@onready var Match := preload("res://Scenes/Match.tscn")

var default: Color = Color(255, 255, 255)

func _ready() -> void:
	# base colour is actually hovered color
	# because override colours are restricted and defaults are not
	# so we override to white and remove override on hover
	for b in [new_match, settings, exit]:
		b.add_theme_color_override("default_color", default)
		b.mouse_exited.connect(_on_mouse_exited.bind(b))
		b.mouse_entered.connect(_on_mouse_entered.bind(b))

func _on_mouse_exited(element) -> void:
	element.add_theme_color_override("default_color", default)

func _on_mouse_entered(element) -> void:
	element.remove_theme_color_override("default_color")

func _on_new_match_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_packed(Match)

func _on_settings_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Settings.visible = true
		Settings.prev_scene = get_tree().current_scene
		Settings.prev_scene.visible = false

func _on_exit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().quit()
