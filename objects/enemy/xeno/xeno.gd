@tool
extends "res://objects/enemy/enemy.gd"


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Constants and ENUMS
# ------------------------------------------------------------------------------
const FRAMES_XENO : SpriteFrames = preload("res://objects/enemy/xeno/xeno_frames.tres")

const MEM_NEST : String = "nest"
const MEM_SEARCHING : String = "searching"
const MEM_PATROLLING : String = "patrolling"
const MEM_HUNTING : String = "hunting"

enum STATE {Nest = 0, Searching = 1, Patrolling = 2, Hunting = 3}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Xeno")
@export var nav_point_group : String = ""
@export_range(1, 360) var search_degrees_per_second : float = 10.0
@export var debug : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _nav_group : StringName = &""
var _target_nav_point : NavPoint = null
var _last_target_pos : Vector2 = Vector2.ZERO

var _state : STATE = STATE.Patrolling
var _state_mem : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _nav_agent : NavigationAgent2D = $NavAgent
@onready var _sight_area : Area2D = $SightArea
@onready var _attack_area : Area2D = $AttackArea


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_nav_point_group(npg : String) -> void:
	if npg != nav_point_group:
		nav_point_group = npg
		_target_nav_point = Game.get_random_nav_point_in_group(nav_point_group)

func set_debug(d : bool) -> void:
	if d != debug:
		debug = d
		if _nav_agent != null:
			_nav_agent.debug_enabled = debug

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_nav_agent.debug_enabled = debug
	set_face_direction(true)
	_SetSpriteFrames(FRAMES_XENO)
	_SetBodySprite($ASprite2D)
	super._ready()

func _draw() -> void:
	if not debug: return
	if _target_nav_point == null: return
	var target_pos : Vector2 = _target_nav_point.global_position - global_position
	draw_line(Vector2.ZERO, target_pos, Color.VIOLET, 1, true)

# ------------------------------------------------------------------------------
# Private Overrideable Methods
# ------------------------------------------------------------------------------
func _Process_Start(delta : float) -> void:
	match _state:
		STATE.Nest:
			_State_Nest(delta)
		STATE.Searching:
			_State_Searching(delta)
		STATE.Patrolling:
			_State_Patrolling(delta)
		STATE.Hunting:
			_State_Hunting(delta)
	#_TrackNavPoints(delta)

func _Process_End(delta : float) -> void:
	_sight_area.rotation = _facing.angle()
	queue_redraw()
	super._Process_End(delta)


# ------------------------------------------------------------------------------
# Private State Handling Methods
# ------------------------------------------------------------------------------
func _State_Nest(_delta : float) -> void:
	# TODO: Actually handle this state. For now, just bounce to Patrolling
	_state = STATE.Patrolling

func _State_Searching(delta : float) -> void:
	var dlength : float = _direction.length()
	print("Searching")
	if not MEM_SEARCHING in _state_mem:
		var angle : float = deg_to_rad(45.0)
		_state_mem[MEM_SEARCHING] = {
			"offset": angle if randf() < 0.5 else -angle,
			"scan_count": randi_range(1, 4),
			"facing": _facing if dlength < 0.01 else _direction.normalized()
		}
		set_speed_multiplier(0.1)
	
	var mem : Dictionary = _state_mem[MEM_SEARCHING]
	
	var rps : float = deg_to_rad(search_degrees_per_second)
	var off : float = get_facing_offset()
	var d : float = _ShortAngleDist(off, mem.offset)
	var weight : float = 1.0
	if d >= deg_to_rad(0.5):
		weight = min(1.0, rps / d)
	var angle : float = lerpf(off, mem.offset, weight)
	set_facing_offset(angle)
	if dlength <= 0.01:
		set_facing(mem.facing.rotated(angle))
	
	if weight > 0.998:
		if mem.offset != 0.0:
			mem.scan_count -= 1
			if mem.scan_count > 0:
				mem.offset = -mem.offset
			else:
				mem.offset = 0.0
		else:
			set_facing_offset(0.0)
			_state_mem.erase(MEM_SEARCHING)
			_state = STATE.Patrolling if randf() < 0.95 else STATE.Nest
	elif MEM_PATROLLING in _state_mem:
		_State_Patrolling(delta)

func _State_Patrolling(_delta : float) -> void:
	print("Patrolling")
	if not MEM_PATROLLING in _state_mem:
		_state_mem[MEM_PATROLLING] = {
			"last_target_pos": global_position,
			"target_nav_point": weakref(null)
		}
	if not MEM_SEARCHING in _state_mem:
		set_speed_multiplier(0.25)
	
	var mem : Dictionary = _state_mem[MEM_PATROLLING]
	
	var nav_point : NavPoint = mem.target_nav_point.get_ref()
	if nav_point == null:
		mem.last_target_pos = global_position
		nav_point = Game.get_random_nav_point_in_group(nav_point_group)
		mem.target_nav_point = weakref(nav_point)
	
	if not _nav_agent.target_position.is_equal_approx(nav_point.global_position):
		_nav_agent.target_position = nav_point.global_position
		set_direction(Vector2.ZERO)
	elif not _nav_agent.is_target_reachable():
		mem.target_nav_point = weakref(null)
	elif _nav_agent.is_target_reached():
		_HandleNavpointReached()
	else:
		var target_pos : Vector2 = _nav_agent.get_next_path_position()
		if not target_pos.is_equal_approx(mem.last_target_pos):
			_direction = global_position.direction_to(target_pos)
			mem.last_target_pos = target_pos
	
	if not MEM_SEARCHING in _state_mem and randf() < 0.05:
		_state = STATE.Searching


func _State_Hunting(_delta : float) -> void:
	# TODO: Actually handle this state. For now, just bounce to Patrolling
	_state = STATE.Patrolling

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _HandleNavpointReached() -> void:
	match _state:
		STATE.Patrolling:
			var rnd : float = randf()
			if rnd < -0.08: # Remove the negative to reactivate
				_state = STATE.Nest
			elif rnd < 0.3:
				_state_mem.erase(MEM_PATROLLING)
				_state = STATE.Searching
			else:
				_state_mem[MEM_PATROLLING].target_nav_point = weakref(null)
				# Otherwise... continue patrolling
		STATE.Searching:
			# Patrolling done, let's let searching finish.
			_state_mem.erase(MEM_PATROLLING)
		STATE.Hunting:
			# If we reached player... keep hunting.
			# Else if we reached last known position... search
			pass

func _TrackNavPoints(delta : float) -> void:
	if _target_nav_point == null:
		_last_target_pos = global_position
		_target_nav_point = Game.get_random_nav_point_in_group(nav_point_group)
	
	if not _nav_agent.target_position.is_equal_approx(_target_nav_point.global_position):
		_nav_agent.target_position = _target_nav_point.global_position
		_direction = Vector2.ZERO
	elif not _nav_agent.is_target_reachable():
		_target_nav_point = null
	else:
		if _nav_agent.is_target_reached():
			_target_nav_point = null
		
		var target_pos : Vector2 = _nav_agent.get_next_path_position()
		if not target_pos.is_equal_approx(_last_target_pos):
			_direction = global_position.direction_to(target_pos)
			_last_target_pos = target_pos
		elif not _target_nav_point == null:
			_nav_agent.target_position = _target_nav_point.global_position

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
#func face_position(pos : Vector2) -> void:
#	super.face_position(pos)
#	_sight_area.rotation = _facing.angle()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_attack_area_body_entered(body : Node2D) -> void:
	pass

func _on_attack_area_body_exited(body : Node2D) -> void:
	pass

