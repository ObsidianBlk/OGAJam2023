@tool
extends Enemy


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

var _face_direction : bool = true
var _facing_offset : float = 0.0

var _hunt_target : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _nav_agent : EnemyNavigationAgent = $NavAgent
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
	_nav_agent.navigation_finished.connect(_on_nav_finished)
	_nav_agent.debug_enabled = debug
	_SetSpriteFrames(FRAMES_XENO)
	_SetBodySprite($ASprite2D)
	super._ready()

func _draw() -> void:
	if not (debug and _nav_agent.is_active()): return
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
	_ChangeState(STATE.Patrolling)

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
	else:
		print("Offset Only")
		mem.facing = _direction.normalized()
	
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
			var nstate : STATE = STATE.Patrolling if _rng.randf() < 0.95 else STATE.Nest
			_ChangeState(nstate)
#	elif MEM_PATROLLING in _state_mem or _rng.randf() < 0.005:
#		if not MEM_PATROLLING in _state_mem:
#			print("Adding a patrol to my search!")
#		_State_Patrolling(delta)

func _State_Patrolling(_delta : float) -> void:
	#print("Patrolling: ", _direction)
	if not MEM_PATROLLING in _state_mem:
		print("New Patrolling memory")
		_state_mem[MEM_PATROLLING] = {
			"nav_point": weakref(null),
			"reset": false
		}
	if not MEM_SEARCHING in _state_mem:
		set_speed_multiplier(0.25)
	
	var mem : Dictionary = _state_mem[MEM_PATROLLING]
	var CalcNavPoint : Callable = func():
		print("Setting Nav Point")
		var map : RID = _nav_agent.get_navigation_map()
		var nav_point = Game.get_random_reachable_nav_point_in_group(
			nav_point_group, map, global_position, mem.nav_point.get_ref()
		)
		if nav_point == null: return
		mem.nav_point = weakref(nav_point)
		_SetNavTargetPosition.call_deferred(nav_point.global_position, true)
	
	var nav_req : Dictionary = {}
	if not _nav_agent.is_active():
		if mem.nav_point.get_ref() == null:
			CalcNavPoint.call()
		elif mem.reset == true:
			if _nav_agent.target_position.is_equal_approx(mem.nav_point.get_ref().global_position):
				CalcNavPoint.call()
			else:
				_nav_agent.target_position = mem.nav_point.get_ref().global_position

	if not MEM_SEARCHING in _state_mem and _rng.randf() < 0.005:
		print("Patrolling add search")
		_ChangeState(STATE.Searching)


func _State_Hunting(_delta : float) -> void:
	set_speed_multiplier(1.0)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ChangeState(new_state : STATE) -> void:
	if new_state == _state: return
	match new_state:
		STATE.Nest:
			pass
		STATE.Searching:
			if not MEM_PATROLLING in _state_mem:
				print("Searching State")
				_nav_agent.activate(false)
			else:
				_state_mem[MEM_PATROLLING].reset = true
				print("Searching/Patrolling State")
		STATE.Patrolling:
			print("Patrolling State")
			pass
		STATE.Hunting:
			print("Hunting State")
			_nav_agent.activate(true)
	_state = new_state

func _SetNavTargetPosition(target_position : Vector2, activate : bool = true) -> void:
	if not _nav_agent.target_position.is_equal_approx(target_position):
		_nav_agent.target_position = target_position
		if _nav_agent.is_active() != activate:
			_nav_agent.activate(activate)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_nav_target_unreachable() -> void:
	print("Target is unreachable")

func _on_nav_finished() -> void:
	print("Finished")
	match _state:
		STATE.Patrolling:
			print("Patrolling done")
			_nav_agent.activate(false)
			_state_mem.erase(MEM_PATROLLING)
			var rnd : float = _rng.randf()
			if rnd < -0.08: # Remove the negative to reactivate
				_ChangeState(STATE.Nest)
			elif rnd < -0.3:
				_state_mem.erase(MEM_PATROLLING)
				_ChangeState(STATE.Searching)
		STATE.Searching:
			print("Searching active... probably finished patrolling")
			_nav_agent.activate(false)
			# Patrolling done, let's let searching finish.
			_state_mem.erase(MEM_PATROLLING)
		STATE.Hunting:
			print("Hunting done")
			_ChangeState.call_deferred(STATE.Searching)

func _on_sight_system_detected(body : Node2D, distance : float) -> void:
	if _hunt_target.get_ref() == null:
		if body.has_method("damage"):
			print("Detected target")
			_hunt_target = weakref(body)
			_nav_agent.follow_target(body)
			_ChangeState.call_deferred(STATE.Hunting)
		else:
			_sight_system.drop_detected()

func _on_sight_system_lost_detection():
	if _hunt_target.get_ref() != null:
		_hunt_target = weakref(null)
		_nav_agent.follow_target(null)

func _on_attack_area_body_entered(body : Node2D) -> void:
	pass

func _on_attack_area_body_exited(body : Node2D) -> void:
	pass


