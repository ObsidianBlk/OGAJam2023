extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BACKGROUNDS : Dictionary = {
	"MainMenu": preload("res://scenes/menu_background/menu_background.tscn"),
	"Victory": preload("res://scenes/victory_background/victory_background.tscn")
}

const DIALOGUE_BALLOON : PackedScene = preload("res://scenes/ui/balloon/balloon.tscn")

#const INITIAL_LEVEL_PATH : String = "res://scenes/levels/test_level/test_level.tscn"
const INITIAL_LEVEL_PATH : String = "res://scenes/levels/level_001/level_001.tscn"
#const INITIAL_LEVEL_PATH : String = "res://scenes/levels/level_002/level_002.tscn"
#const INITIAL_LEVEL_PATH : String = "res://scenes/levels/level_003/level_003.tscn"
#const INITIAL_LEVEL_PATH : String = "res://scenes/levels/level_escape/level_escape.tscn"

const NICE_PLANET_SEEDS : Array = [
	1.0, 1.192, 1.448, 1.704,
	2.281, 2.345,
	2.537, 2.601, 2.793,
	3.306, 3.37, 3.691, 3.947,
	4.203, 4.459, 4.587,
	5.1, 5.292, 5.42, 5.612, 5.868,
	6.189, 6.253, 6.702,
	7.022, 7.086, 7.278, 7.534,
	8.175, 8.431, 8.495, 8.751, 8.943,
	9.199, 9.327, 9.519
]

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _background : CanvasLayer = null
var _background_request : StringName = &""

var _planet_seed : float = 1.0

var _level : GameLevel = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _game_view : SubViewport = $CanvasLayer/CSubView/GameView
@onready var _ui : CanvasLayer = $UI
@onready var _heat_haze : ColorRect = %HeatHaze
@onready var _hud : Control = %HUD
@onready var _asp_music: AudioStreamPlayer = %ASP_Music


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.dialogue_requested.connect(_on_dialog_requested)
	DialogueManager.dialogue_ended.connect(_on_dialog_ended)
	_heat_haze.visible = false
	_planet_seed = _GetNicePlanetSeed()
	if _background_request != &"":
		_SetBackground(_background_request)
	Game.load_config.call_deferred()
	_MusicFadeIn()

func _unhandled_input(event: InputEvent) -> void:
	if _level != null and get_tree().paused == false:
		if event.is_action_pressed("ui_cancel"):
			get_tree().paused = true
			_ui.show_menu(&"QuickMenu")

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetNicePlanetSeed() -> float:
	var idx : int = randi_range(0, NICE_PLANET_SEEDS.size() - 1)
	return NICE_PLANET_SEEDS[idx]

func _SetBackground(background_name : StringName) -> void:
	if _game_view == null:
		_background_request = background_name
		return
	
	if background_name == &"" or background_name in BACKGROUNDS:
		if _background != null:
			var parent : Node = _background.get_parent()
			if parent != null:
				parent.remove_child(_background)
			_background.queue_free()
			_background = null
		
		if background_name != &"":
			_background = BACKGROUNDS[background_name].instantiate()
			if _background != null:
				if _background.has_method("set_seed"):
					_background.set_seed(_planet_seed)
				_game_view.add_child(_background)

func _DropCurrentLevel() -> void:
	if _level == null or _game_view == null: return
	if _level.temprature_changed.is_connected(_on_temprature_changed):
		_level.temprature_changed.disconnect(_on_temprature_changed)
	if _level.requested.is_connected(_on_level_requested):
		_level.requested.disconnect(_on_level_requested)
	#_heat_haze.enable(false)
	_heat_haze.visible = false
	_game_view.remove_child(_level)
	_level.queue_free()
	_level = null

func _LoadLevel(level_path : String) -> int:
	if ResourceLoader.exists(level_path):
		var packedLevel = ResourceLoader.load(level_path)
		if not is_instance_of(packedLevel, PackedScene):
			printerr("File ", level_path, " is not a packed scene resource.")
			return ERR_FILE_UNRECOGNIZED
		
		var level = packedLevel.instantiate()
		if not is_instance_of(level, GameLevel):
			printerr("File ", level_path, " is not a game level.")
			return ERR_INVALID_DECLARATION
		
		_DropCurrentLevel()
		_level = level
		if not _level.temprature_changed.is_connected(_on_temprature_changed):
			_level.temprature_changed.connect(_on_temprature_changed)
		if not _level.requested.is_connected(_on_level_requested):
			_level.requested.connect(_on_level_requested)
		_game_view.add_child(_level)
		_hud.set_level(_level)
		_level.initialize()
		_on_temprature_changed(_level.initial_temprature)
		return OK
	return ERR_FILE_NOT_FOUND

func _MusicFadeIn() -> void:
	if _asp_music.playing: return
	_asp_music.volume_db = -80.0
	_asp_music.play()
	var tween : Tween = create_tween()
	tween.tween_property(_asp_music, "volume_db", 0.0, 3.0)

func _MusicFadeOut() -> void:
	if not _asp_music.playing: return
	var tween : Tween = create_tween()
	tween.tween_property(_asp_music, "volume_db", -80.0, 3.0)
	await tween.finished
	_asp_music.stop()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_temprature_changed(temprature : float) -> void:
	if not _heat_haze.visible:
		_heat_haze.visible = true
	_heat_haze.set_temprature(temprature)

func _on_dialog_requested(dialogue : DialogueResource, start : String) -> void:
	if dialogue == null or start.is_empty(): return
	var balloon : Node = DIALOGUE_BALLOON.instantiate()
	if balloon == null: return
	add_child(balloon)
	get_tree().paused = true
	balloon.start(dialogue, start)

func _on_dialog_ended(_dialogue : DialogueResource) -> void:
	get_tree().paused = false

func _on_level_requested(request : Dictionary) -> void:
	if "action" in request:
		match request.action:
			&"load_level":
				if not "payload" in request: return
				if _LoadLevel(request.payload) == OK:
					get_tree().paused = false
					_ui.show_menu(&"")
					_SetBackground(&"")
			&"game_lost":
				pass
			&"game_won":
				_DropCurrentLevel()
				get_tree().paused = true
				_ui.show_menu(&"VictoryScreen")


func _on_ui_requested(request : Dictionary) -> void:
	if "action" in request:
		match request.action:
			&"start_game":
				if _LoadLevel(INITIAL_LEVEL_PATH) == OK:
					_MusicFadeOut()
					get_tree().paused = false
					_ui.show_menu(&"")
					_SetBackground(&"")
			&"quit_game":
				_DropCurrentLevel()
				_ui.show_menu(&"MainMenu")
				_MusicFadeIn()
			&"resume_game":
				if _level != null and get_tree().paused == true:
					_ui.show_menu(&"")
					get_tree().paused = false
			&"background":
				if not "payload" in request: return
				_SetBackground(request.payload)
			&"quit_application":
				get_tree().quit()
