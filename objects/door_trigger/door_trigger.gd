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


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _state : STATE = STATE.Closed


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_state = initial_state

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ChangeTilemapCell(tilemap : TileMap, cell : Vector2i, dir : Vector2i) -> void:
	var atlas : Vector2i = tilemap.get_cell_atlas_coords(0, cell)
	var source_id : int = tilemap.get_cell_source_id(0, cell)
	tilemap.set_cell(0, cell, source_id, atlas + dir)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	if body.has_signal("interacted"):
		if not body.interacted.is_connected(_on_interacted.bind(body)):
			body.interacted.connect(_on_interacted.bind(body))

func _on_body_exited(body : Node2D) -> void:
	if body.has_signal("interacted"):
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

