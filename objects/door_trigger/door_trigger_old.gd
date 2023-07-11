@tool
extends Area2D


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum ORIENTATION {Horizontal=0, Vertical=1}
enum STATE {Opened=0, Closed=1}


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var orientation : ORIENTATION = ORIENTATION.Horizontal
@export var initial_state : STATE = STATE.Closed
@export var trigger_area : float = 10.0:						set = set_trigger_area
@export var auto_open : bool = false
@export var nav_point_group : String = "":						set = set_nav_point_group
@export var nav_point_color : Color = Color.YELLOW_GREEN:		set = set_nav_point_color


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _state : STATE = STATE.Closed
var _bodies : Dictionary = {}

var _navpoint : NavPoint = null


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _coll_shape : CollisionShape2D  = $CollisionShape2D

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_trigger_area(a : float) -> void:
	if a > 0.0 and a != trigger_area:
		trigger_area = a
		if _coll_shape != null:
			_coll_shape.shape.radius = trigger_area

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
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	_UpdateNavPoint()
	_state = initial_state
	_coll_shape.shape.radius = trigger_area

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	if auto_open:
		if not body.name in _bodies:
			_bodies[body.name] = body
		if _state != STATE.Opened:
			_on_interacted(body)
	elif body.has_signal("interacted"):
		if not body.interacted.is_connected(_on_interacted.bind(body)):
			body.interacted.connect(_on_interacted.bind(body))

func _on_body_exited(body : Node2D) -> void:
	if auto_open:
		if body.name in _bodies:
			_bodies.erase(body.name)
		if _bodies.is_empty() and _state != STATE.Closed:
			_on_interacted(body)
	elif body.has_signal("interacted"):
		if body.interacted.is_connected(_on_interacted.bind(body)):
			body.interacted.disconnect(_on_interacted.bind(body))

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

