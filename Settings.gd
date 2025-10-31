extends Node2D

@onready var save := $"Save"
@onready var exit := $"Exit"
@onready var warn := $"WarnToggle"
@onready var speed := $"AnimationSpeed"
@onready var speedpopup: PopupMenu = speed.get_popup()
@onready var sfx := $"SfxVolume"
@onready var music := $"MusicVolume"
@onready var musictext := $"MusicVolume/MusicText"
@onready var sfxtext := $"SfxVolume/SFXText"
@onready var musicplayer := $MusicPlayer

var default: Color = Color(255, 255, 255)

var SFXVolume = 1
var MusicVolume = 1
var AnimationSpeed = 2
var ShouldWarn = true
var path: String = 'user://settings.ice'
var prev_scene;

func _ready() -> void:
	load_settings()
	update_music()
	update_sfx()
	speed.text = ["Instant", "Fast", "Medium", "Slow"][AnimationSpeed]
	warn.text = ["No", "Yes"][int(ShouldWarn)]
	
	# see title._ready
	for b in [save, exit, warn]:
		b.add_theme_color_override("default_color", default)
		b.mouse_exited.connect(_on_mouse_exited.bind(b))
		b.mouse_entered.connect(_on_mouse_entered.bind(b))
	
	speedpopup.id_pressed.connect(_on_animation_speed_changed)

# TODO
# simplify hover colours using dynamic signal connections iterating children, extend to title

func save_settings() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return;
	file.store_string(
		str(SFXVolume) + '\n' + 
		str(MusicVolume) + '\n' +
		str(AnimationSpeed) + '\n' +
		str(int(ShouldWarn))
	)
	print(file.get_as_text())

func load_settings() -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null: # no error
		var t = file.get_as_text()
		t = t.split_floats('\n')
		SFXVolume = t[0]
		MusicVolume = t[1]
		AnimationSpeed = t[2]
		ShouldWarn = bool(t[3])
	#otherwise default settings work

func _on_mouse_exited(element) -> void:
	element.add_theme_color_override("default_color", default)

func _on_mouse_entered(element) -> void:
	element.remove_theme_color_override("default_color")

func _on_exit_mouse_entered() -> void:
	exit.remove_theme_color_override("default_color")

func _on_warn_toggle_mouse_entered() -> void:
	warn.remove_theme_color_override("default_color")

func _on_exit_mouse_exited() -> void:
	exit.add_theme_color_override("default_color", default)

func _on_warn_toggle_mouse_exited() -> void:
	warn.add_theme_color_override("default_color", default)

func _on_sfx_volume_value_changed(v: float) -> void:
	SFXVolume = v / 100  # for some reason v is [0, 100] not [0, 1]
	update_sfx()

func update_sfx() -> void:
	sfxtext.text = "SFX Volume: " + str(int(SFXVolume * 100)) + "%"
	sfx.set_value_no_signal(SFXVolume * 100)

func _on_music_volume_value_changed(v: float) -> void:
	MusicVolume = v / 100
	update_music()

func update_music() -> void:
	musictext.text = "Music Volume: " + str(int(MusicVolume * 100)) + "%"
	music.set_value_no_signal(MusicVolume * 100) # only matters for initial load
	musicplayer.volume_db = MusicVolume * 30 - 30
	if MusicVolume == 0: musicplayer.volume_db = -100

func _on_animation_speed_changed(i: int) -> void:
	speed.text = ["Instant", "Fast", "Medium", "Slow"][i]
	AnimationSpeed = i

func _on_warn_toggle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		ShouldWarn = !ShouldWarn
		warn.text = ["No", "Yes"][int(ShouldWarn)]

func _on_save_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		save_settings()

func _on_exit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		visible = false
		prev_scene.visible = true

func _on_music_player_finished() -> void:
	musicplayer.play()
