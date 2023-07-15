extends Control


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _level : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _tgage : ProgressBar = %TGage

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false

func _process(_delta : float) -> void:
	if _level.get_ref() == null and visible:
		visible = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_level(level : GameLevel) -> void:
	if _level.get_ref() != level:
		if _level.get_ref() != null:
			var l : GameLevel = _level.get_ref()
			if l.temprature_changed.is_connected(_on_temprature_changed):
				l.temprature_changed.disconnect(_on_temprature_changed)
		
		_level = weakref(level)
		if level != null:
			visible = true
			if not level.temprature_changed.is_connected(_on_temprature_changed):
				level.temprature_changed.connect(_on_temprature_changed)
		else:
			visible = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_temprature_changed(temp : float) -> void:
	_tgage.value = temp
