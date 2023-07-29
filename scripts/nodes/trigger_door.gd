@tool
extends Trigger
class_name TriggerDoor


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum ORIENTATION {Horizontal=0, Vertical=1}
enum STATE {Opened=0, Closed=1}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Door Trigger")
@export var orientation : ORIENTATION = ORIENTATION.Horizontal
@export var single_cell : bool = false
@export var initial_state : STATE = STATE.Closed
@export var radius : float = 10.0:								set = set_radius
@export_flags_2d_physics var collision_mask : int = 1:			set = set_collision_mask
@export var auto_open : bool = false:							set = set_auto_open
@export var input : Trigger = null:								set = set_input
@export var nav_point_group : String = "":						set = set_nav_point_group
@export var nav_point_color : Color = Color.YELLOW_GREEN:		set = set_nav_point_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _area : Area2D = null
var _collision : CollisionShape2D = null

var _state : STATE = STATE.Closed
var _bodies : Dictionary = {}

var _navpoint : NavPoint = null

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

func set_auto_open(a : bool) -> void:
	if input != null:
		auto_open = false
	else:
		auto_open = a

func set_input(i : Trigger) -> void:
	if i != input:
		if input != null:
			if input.activated.is_connected(_on_activated):
				input.activated.disconnect(_on_activated)
			if input.deactivated.is_connected(_on_deactivated):
				input.deactivated.disconnect(_on_deactivated)
		input = i
		if input != null:
			auto_open = false
			if not Engine.is_editor_hint():
				if not input.activated.is_connected(_on_activated):
					input.activated.connect(_on_activated)
				if not input.deactivated.is_connected(_on_deactivated):
					input.deactivated.connect(_on_deactivated)
				if input.is_activated():
					_on_activated()
				else:
					_on_deactivated()

func set_nav_point_group(npg : String) -> void:
	if npg != nav_point_group:
		nav_point_group = npg
		_UpdateNavPoint()

func set_nav_point_color(c : Color) -> void:
	if c != nav_point_color:
		nav_point_color = c
		if _navpoint != null:
			_navpoint.group_color = nav_point_color

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateArea()
	_UpdateNavPoint()
	_state = initial_state

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
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

func _UpdateNavPoint() -> void:
	if nav_point_group.is_empty():
		if _navpoint != null:
			remove_child(_navpoint)
			_navpoint.queue_free()
			_navpoint = null
	else:
		if _navpoint == null:
			_navpoint = NavPoint.new()
			_navpoint.group_name = nav_point_group
			_navpoint.group_color = nav_point_color
			add_child(_navpoint)
		else:
			_navpoint.group_name = nav_point_group
			_navpoint.group_color = nav_point_color


func _ChangeTilemapCell(tilemap : TileMap, cell : Vector2i, dir : Vector2i) -> void:
	var atlas : Vector2i = tilemap.get_cell_atlas_coords(0, cell)
	var source_id : int = tilemap.get_cell_source_id(0, cell)
	tilemap.set_cell(0, cell, source_id, atlas + dir)

func _ToggleDoorState() -> void:
	var parent = get_parent()
	if not is_instance_of(parent, TileMap): return
	
	var dir : Vector2i = Vector2i.UP
	match orientation:
		ORIENTATION.Horizontal:
			dir = Vector2i.UP if _state == STATE.Opened else Vector2i.DOWN
		ORIENTATION.Vertical:
			dir = Vector2i.LEFT if _state == STATE.Opened else Vector2i.RIGHT
	
	
	var cell : Vector2i = parent.local_to_map(position)
	if _state == STATE.Opened:
		for body in _bodies:
			var body_cell : Vector2i = parent.local_to_map(body.position)
			if body_cell == cell:
				body.position = parent.map_to_local(body_cell + dir)
	
	_ChangeTilemapCell(parent, cell, dir)
	if not single_cell:
		match orientation:
			ORIENTATION.Horizontal:
				_ChangeTilemapCell(parent, cell + Vector2i.LEFT, dir)
				_ChangeTilemapCell(parent, cell + Vector2i.RIGHT, dir)
			ORIENTATION.Vertical:
				_ChangeTilemapCell(parent, cell + Vector2i.UP, dir)
				_ChangeTilemapCell(parent, cell + Vector2i.DOWN, dir)
	_state = STATE.Closed if _state == STATE.Opened else STATE.Opened

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_activated(a : bool) -> void:
	var old : bool = _activated
	super.set_activated(a)
	if _activated != old:
		if _activated and _state == STATE.Closed:
			_ToggleDoorState()
		elif not _activated and _state == STATE.Opened:
			_ToggleDoorState()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_activated() -> void:
	set_activated.call_deferred(true)

func _on_deactivated() -> void:
	set_activated.call_deferred(false)

func _on_body_entered(body : Node2D) -> void:
	if auto_open:
		if not body.name in _bodies:
			_bodies[body.name] = body
		if _state != STATE.Opened:
			set_activated.call_deferred(true)
			_on_interacted(body)
	elif body.has_signal("interacted"):
		if not body.interacted.is_connected(_on_interacted):
			body.interacted.connect(_on_interacted)

func _on_body_exited(body : Node2D) -> void:
	if auto_open:
		if body.name in _bodies:
			_bodies.erase(body.name)
		if _bodies.is_empty() and _state != STATE.Closed:
			set_activated.call_deferred(false)
			_on_interacted(body)
	elif body.has_signal("interacted"):
		if body.interacted.is_connected(_on_interacted):
			body.interacted.disconnect(_on_interacted)

func _on_interacted(body : Node2D) -> void:
	var parent = get_parent()
	if not is_instance_of(parent, TileMap): return
	
	var dir : Vector2i = Vector2i.UP
	match orientation:
		ORIENTATION.Horizontal:
			dir = Vector2i.UP if _state == STATE.Opened else Vector2i.DOWN
		ORIENTATION.Vertical:
			dir = Vector2i.LEFT if _state == STATE.Opened else Vector2i.RIGHT
	
	
	var cell : Vector2i = parent.local_to_map(position)
	if _state == STATE.Opened:
		var body_cell : Vector2i = parent.local_to_map(body.position)
		if body_cell == cell:
			body.position = parent.map_to_local(body_cell + dir)
	
	_ChangeTilemapCell(parent, cell, dir)
	match orientation:
		ORIENTATION.Horizontal:
			_ChangeTilemapCell(parent, cell + Vector2i.LEFT, dir)
			_ChangeTilemapCell(parent, cell + Vector2i.RIGHT, dir)
		ORIENTATION.Vertical:
			_ChangeTilemapCell(parent, cell + Vector2i.UP, dir)
			_ChangeTilemapCell(parent, cell + Vector2i.DOWN, dir)
	_state = STATE.Closed if _state == STATE.Opened else STATE.Opened
