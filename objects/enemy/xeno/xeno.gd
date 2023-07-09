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
@export var debug : bool = false:										set = set_debug

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

var _state : STATE = STATE.Patrolling
var _state_mem : Dictionary = {}

var _nav_active : bool = false
var _nav_last_position : Vector2 = Vector2.ZERO

var _face_direction : bool = true
var _facing_offset : float = 0.0

var _hunt_target : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _nav_agent : NavigationAgent2D = $NavAgent
@onready var _sight_area : Area2D = $SightArea
@onready var _attack_area : Area2D = $AttackArea
@onready var _sight_system : SightSystemNode2D = $SightSystem


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_debug(d : bool) -> void:
	if d != debug:
		debug = d
		if _nav_agent != null:
			_nav_agent.debug_enabled = debug

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_rng.randomize()
	_nav_agent.path_changed.connect(_on_nav_path_changed)
	_nav_agent.navigation_finished.connect(_on_nav_finished)
	_nav_agent.debug_enabled = debug
	_SetSpriteFrames(FRAMES_XENO)
	_SetBodySprite($ASprite2D)
	super._ready()

func _draw() -> void:
	if not (debug and _nav_active): return
	var target_pos : Vector2 = _nav_agent.target_position - global_position
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
	_sight_area.rotation = fmod(_facing.angle() + _facing_offset, PI * 2)
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
	#print("Searching")
	if not MEM_SEARCHING in _state_mem:
		var angle : float = deg_to_rad(45.0)
		_state_mem[MEM_SEARCHING] = {
			"offset": angle if _rng.randf() < 0.5 else -angle,
			"scan_count": _rng.randi_range(1, 4),
			"facing": _facing if dlength < 0.01 else _direction.normalized()
		}
		set_speed_multiplier(0.1)
	
	var mem : Dictionary = _state_mem[MEM_SEARCHING]
	
	var rps : float = deg_to_rad(search_degrees_per_second) * delta
	var off : float = _facing_offset
	var d : float = abs(_ShortAngleDist(off, mem.offset))
	var weight : float = 1.0
	if d >= deg_to_rad(0.5):
		weight = min(1.0, rps / d)
	var angle : float = lerpf(off, mem.offset, weight)
	
	_facing_offset = angle
	if dlength <= 0.01:
		set_facing(mem.facing.rotated(angle))
	
	if weight == 1.0:
		if mem.offset != 0.0:
			mem.scan_count -= 1
			if mem.scan_count > 0:
				mem.offset = -mem.offset
			else:
				mem.offset = 0.0
		else:
			_facing_offset = 0.0
			_state_mem.erase(MEM_SEARCHING)
			_state = STATE.Patrolling if _rng.randf() < 0.95 else STATE.Nest
	elif MEM_PATROLLING in _state_mem or _rng.randf() < 0.005:
		if not MEM_PATROLLING in _state_mem:
			print("Adding a patrol to my search!")
		_State_Patrolling(delta)

func _State_Patrolling(_delta : float) -> void:
	#print("Patrolling: ", _direction)
	if not MEM_PATROLLING in _state_mem:
		_state_mem[MEM_PATROLLING] = {
			"nav_point": weakref(null)
		}
	if not MEM_SEARCHING in _state_mem:
		set_speed_multiplier(0.25)
	
	var mem : Dictionary = _state_mem[MEM_PATROLLING]
	
	var nav_req : Dictionary = {}
	if not _nav_active:
		var nav_point = Game.get_random_nav_point_in_group(nav_point_group, mem.nav_point.get_ref())
		if nav_point == null: return
		mem.nav_point = weakref(nav_point)
		nav_req["target"] = nav_point.global_position
	
	_ProcessNavigation(nav_req)

	if not MEM_SEARCHING in _state_mem and _rng.randf() < 0.005:
		_state = STATE.Searching


func _State_Hunting(delta : float) -> void:
	var target : Node2D = _hunt_target.get_ref()
	if target == null:
		_state = STATE.Patrolling
		return
	
	if not MEM_HUNTING in _state_mem:
		_state_mem[MEM_HUNTING] = {
			"update_time_remaining": 0.0
		}
		set_speed_multiplier(1.0)
	var mem : Dictionary = _state_mem[MEM_HUNTING]
	
	mem.update_time_remaining -= delta
	
	var nav_req : Dictionary = {}
	if mem.update_time_remaining <= 0.0:
		print("Hunting Update: ", target.name, " | Nav Active: ", _nav_active)
		mem.update_time_remaining = 0.1
		if _sight_system.can_see(target):
			print("Can see ", target.name)
			nav_req["target"] = target.global_position
		elif _nav_active == false:
			print("Cannot see target")
			_state_mem.erase(MEM_HUNTING)
			_hunt_target = weakref(null)
			_state = STATE.Searching
	_ProcessNavigation(nav_req)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProcessNavigation(request : Dictionary = {}) -> void:
	if not _nav_active and request.is_empty(): return
	if _state == STATE.Hunting:
		print("Hunt Navigation")
	
	if not request.is_empty():
		var target = _nav_agent.target_position
		if "target" in request and typeof(request["target"]) == TYPE_VECTOR2:
			target = request["target"]
		if not _nav_agent.target_position.is_equal_approx(target):
			_nav_active = true
			_nav_agent.target_position = target
			set_direction(Vector2.ZERO)
	elif _nav_active:
		if not _nav_agent.is_target_reachable():
			if _state == STATE.Hunting:
				print("Unreachable!")
			_nav_active = false
			set_direction(Vector2.ZERO)
		else:
			var target_pos : Vector2 = _nav_agent.get_next_path_position()
			if not target_pos.is_equal_approx(_nav_last_position):
				_direction = global_position.direction_to(target_pos)
				_nav_last_position = target_pos

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_nav_path_changed() -> void:
	if not MEM_PATROLLING in _state_mem: return
	var mem : Dictionary = _state_mem[MEM_PATROLLING]
	
	var target_pos : Vector2 = _nav_agent.get_next_path_position()
	_direction = global_position.direction_to(target_pos)
	_nav_last_position = target_pos


func _on_nav_finished() -> void:
	print("Finished")
	_nav_active = false
	set_direction(Vector2.ZERO)
	match _state:
		STATE.Patrolling:
			var rnd : float = _rng.randf()
			if rnd < -0.08: # Remove the negative to reactivate
				_state = STATE.Nest
			elif rnd < -0.3:
				_state_mem.erase(MEM_PATROLLING)
				_state = STATE.Searching
		STATE.Searching:
			# Patrolling done, let's let searching finish.
			_state_mem.erase(MEM_PATROLLING)
		STATE.Hunting:
			var target : Node2D = _hunt_target.get_ref()
			if target == null or not _sight_system.can_see(target):
				_sight_system.render_detection_lines = true
				_hunt_target = weakref(null)
				_state_mem.erase(MEM_HUNTING)
				_state = STATE.Searching

func _on_sight_system_detected(body : Node2D, distance : float) -> void:
	if _hunt_target.get_ref() == null and body.has_method("damage"):
		_hunt_target = weakref(body)
		_state = STATE.Hunting
		_sight_system.render_detection_lines = false

func _on_attack_area_body_entered(body : Node2D) -> void:
	pass

func _on_attack_area_body_exited(body : Node2D) -> void:
	pass


