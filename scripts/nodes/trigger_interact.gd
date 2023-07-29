@tool
extends Trigger
class_name TriggerInteract

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal link_state_changed(state)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Interact Trigger")
@export var radius : float = 10.0:							set = set_radius
@export_flags_2d_physics var collision_mask : int = 1:		set = set_collision_mask
@export var key_name : String = ""
@export var consume_key_on_use : bool = false
@export var links : Array[TriggerInteract] = []
@export var once : bool = false
@export var reset_delay : float = 0.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _area : Area2D = null
var _collision : CollisionShape2D = null

var _blocked : bool = false
var _triggered : bool = false
var _link_states : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_radius(r : float) -> void:
	if r > 0.0 and r != radius:
		radius = r
		_UpdateArea()

func set_collision_mask(mask : int) -> void:
	if mask != collision_mask:
		collision_mask = mask
		_UpdateArea()

func set_links(l : Array[TriggerInteract]) -> void:
	links = l
	_UpdateLinks()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateLinks()
	_UpdateArea()

# ------------------------------------------------------------------------------
# Private Methods
# -----------_ResetTimer()-------------------------------------------------------------------
func _UpdateArea() -> void:
	if _area == null:
		_area = Area2D.new()
		_collision = CollisionShape2D.new()
		_collision.shape = CircleShape2D.new()
		add_child(_area)
		_area.add_child(_collision)
		if not Engine.is_editor_hint():
			_area.body_entered.connect(_on_body_entered)
			_area.body_exited.connect(_on_body_exited)

	if radius != _collision.shape.radius:
		_collision.shape.radius = radius
	if _area.collision_mask != collision_mask:
		_area.collision_mask = collision_mask

func _UpdateLinks() -> void:
	if Engine.is_editor_hint(): return
	var active : Dictionary = {}
	for idx in range(links.size()):
		# Store the trigger name in a dictionary for the second pass...
		if not links[idx].name in active:
			active[links[idx].name] = links[idx].name
		
		# If this trigger isn't already in the _link_states dictionary, put it there
		if not links[idx].name in _link_states:
			_link_states[links[idx].name] = weakref(links[idx])
		
		if not links[idx].link_state_changed.is_connected(_on_link_state_changed):
			links[idx].link_state_changed.connect(_on_link_state_changed)
	
	var keys : Array = _link_states.keys()
	for key in keys:
		var link : TriggerInteract = _link_states[key].get_ref()
		if link == null or not key in active:
			if link != null:
				if link.link_state_changed.is_connected(_on_link_state_changed):
					link.link_state_changed.disconnect(_on_link_state_changed)
			_link_states.erase(key)

func _ResetTimer() -> void:
	if not once and reset_delay > 0.0:
		_blocked = true
		link_state_changed.emit({"blocked": _blocked})
		get_tree().create_timer(reset_delay).timeout.connect(
			(func():
				_blocked = false
				set_activated(not _activated)
				),
			CONNECT_ONE_SHOT
		)

func _DictHasPropType(d : Dictionary, prop : String, type : int) -> bool:
	if not prop in d: return false
	return typeof(d[prop]) == type

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_activated(a : bool) -> void:
	var old = _activated
	super.set_activated(a)
	if _activated != old:
		link_state_changed.emit({
			"activated": _activated,
			"blocked": _blocked,
			"triggered": _triggered
		})

func reset() -> void:
	_triggered = false
	link_state_changed.emit({"triggered":_triggered})

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_link_state_changed(state : Dictionary) -> void:
	if _DictHasPropType(state, "blocked", TYPE_BOOL):
		_blocked = state.blocked
	if _DictHasPropType(state, "triggered", TYPE_BOOL):
		_triggered = state.triggered
		if once:
			if _triggered:
				if _area.body_entered.is_connected(_on_body_entered):
					_area.body_entered.disconnect(_on_body_entered)
			else:
				if not _area.body_entered.is_connected(_on_body_entered):
					_area.body_entered.connect(_on_body_entered)
	if _DictHasPropType(state, "activated", TYPE_BOOL):
		_activated = state.activated
		if _activated:
			activated.emit()
		else:
			deactivated.emit()

func _on_body_entered(body : Node2D) -> void:
	if body.has_signal("interacted"):
		if not body.interacted.is_connected(_on_interacted):
			body.interacted.connect(_on_interacted)

func _on_body_exited(body : Node2D) -> void:
	if body.has_signal("interacted"):
		if body.interacted.is_connected(_on_interacted):
			body.interacted.disconnect(_on_interacted)

func _on_interacted() -> void:
	if _blocked: return
	if not key_name.is_empty():
		var count : int = Game.get_inventory_item_count(key_name)
		if count <= 0: return
		if consume_key_on_use:
			Game.update_inventory(key_name, -1)
	
	_triggered = true
	if once:
		if _area.body_entered.is_connected(_on_body_entered):
			_area.body_entered.disconnect(_on_body_entered)
		# NOTE: Don't disconnect the body_exited signal, so as to clean connected signals from bodies that
		# may have been connected prior to this triggering.
		#if _area.body_exited.is_connected(_on_body_exited):
		#	_area.body_exited.disconnect(_on_body_exited)
	set_activated(not _activated)
	if _activated:
		_ResetTimer()
