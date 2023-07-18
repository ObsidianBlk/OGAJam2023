extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BACKGROUNDS : Dictionary = {
	"MainMenu": preload("res://scenes/menu_background/menu_background.tscn")
}

const INITIAL_LEVEL_PATH : String = "res://scenes/levels/test_level/test_level.tscn"

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


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_planet_seed = _GetNicePlanetSeed()
	if _background_request != &"":
		_SetBackground(_background_request)

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
	_heat_haze.enable(false)
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
		_game_view.add_child(_level)
		_hud.set_level(_level)
		_on_temprature_changed(_level.initial_temprature)
		return OK
	return ERR_FILE_NOT_FOUND

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_temprature_changed(temprature : float) -> void:
	if not _heat_haze.is_enabled():
		_heat_haze.enable(true)
	_heat_haze.set_temprature(temprature)

func _on_ui_requested(request : Dictionary) -> void:
	if "action" in request:
		match request.action:
			&"start_game":
				if _LoadLevel(INITIAL_LEVEL_PATH) == OK:
					_ui.show_menu(&"")
					_SetBackground(&"")
			&"load_level":
				if not "payload" in request: return
				if _LoadLevel(request.payload) == OK:
					_ui.show_menu(&"")
					_SetBackground(&"")
			&"background":
				if not "payload" in request: return
				_SetBackground(request.payload)
			&"quit_application":
				get_tree().quit()
