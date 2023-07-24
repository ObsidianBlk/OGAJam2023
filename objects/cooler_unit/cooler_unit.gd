extends Node2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal coolant_discharged(amount)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const GREEN_OFFSET : Vector2i = Vector2i(6, 14)
const TILE_OFFSET : Dictionary = {
	Vector2i(7, 14): {"min": 0.0, "max":0.251},		# Blue
	Vector2i(6, 14): {"min":0.251, "max":0.62},		# Green
	Vector2i(6, 13): {"min":0.62, "max":0.711},		# Yellow
	Vector2i(8, 14): {"min":0.711, "max": 0.86},	# Orange
	Vector2i(5, 14): {"min":0.86, "max":1.01}		# Red
}

enum STATE {Idle=0, Priming=1, Discharging=2}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Cooling Unit")
@export var min_coolant_per_second : float = 0.1
@export var max_coolant_per_second : float = 1.0
@export var discharge_time : float = 5.0
@export var buildup_time : float = 3.0
@export var trigger : Trigger = null:				set = set_trigger

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _state : STATE = STATE.Idle
var _time : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _mpl: ModulatingPointLight = %MPL

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_trigger(t : Trigger) -> void:
	if t != trigger:
		_DisconnectTrigger()
		trigger = t
		_ConnectTrigger()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ConnectTrigger()

func _physics_process(delta: float) -> void:
	match _state:
		STATE.Priming:
			_time += delta
			var weight : float = 1.0 - (min(1.0, _time / discharge_time) * 0.5)
			_mpl.modulation_offset = weight
			if abs(0.5 - weight) < 0.001:
				_mpl.modulation_offset = 0.5
				_state = STATE.Idle
				_time = 0.0
			_UpdateTile()
		STATE.Discharging:
			_time += delta
			var weight : float = min(1.0, _time / discharge_time)
			_mpl.modulation_offset = weight
			
			coolant_discharged.emit(lerp(max_coolant_per_second, min_coolant_per_second, weight) * delta)
			
			if abs(1.0 - weight) < 0.001:
				_mpl.modulation_offset = 1.0
				_state = STATE.Priming
				_time = 0.0
			_UpdateTile()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DisconnectTrigger() -> void:
	if trigger == null: return
	if trigger.activated.is_connected(_on_trigger_activated):
		trigger.activated.disconnect(_on_trigger_activated)
	if trigger.deactivated.is_connected(_on_trigger_deactivated):
		trigger.deactivated.disconnect(_on_trigger_deactivated)

func _ConnectTrigger() -> void:
	if trigger == null: return
	if not trigger.activated.is_connected(_on_trigger_activated):
		trigger.activated.connect(_on_trigger_activated)
	if not trigger.deactivated.is_connected(_on_trigger_deactivated):
		trigger.deactivated.connect(_on_trigger_deactivated)

func _GetTileOffset(weight : float) -> Vector2i:
	for offset in TILE_OFFSET:
		if TILE_OFFSET[offset].min >= weight and TILE_OFFSET[offset].max < weight:
			return offset
	return Vector2i.ZERO

func _UpdateTile() -> void:
	var parent = get_parent()
	if is_instance_of(parent, TileMap):
		var map_coord = parent.local_to_map(global_position)
		var offset : Vector2i = _GetTileOffset(_mpl.modulation_offset)
		parent.set_cell(0, map_coord, 0, offset)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_activated() -> void:
	match _state:
		STATE.Idle:
			_state = STATE.Discharging
		STATE.Priming:
			var offset : Vector2i = _GetTileOffset(_mpl.modulation_offset)
			if offset == GREEN_OFFSET:
				var weight : float = (1.0 - _mpl.modulation_offset) / 0.5
				_time = discharge_time * (1.0 - weight)
				_state = STATE.Discharging

func _on_trigger_deactivated() -> void:
	pass


