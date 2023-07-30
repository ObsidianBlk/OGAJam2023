extends Node2D
class_name EnemySpawnManager


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const XENO : PackedScene = preload("res://objects/enemy/xeno/xeno.tscn")
const DEFAULT_SPAWN_DELAY : float = 0.2

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy Spawn Manager")
@export var max_enemies : int = 1
@export var min_spawn_delay : float = 2.0
@export var max_spawn_delay : float = 30.0
@export var spawn_container : Node2D = null
@export var nav_point_group : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _enemies : Dictionary = {}
var _spawn_points : Dictionary = {}

var _heartbeating : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for s in get_children():
		if is_instance_of(s, EnemySpawnPoint):
			_spawn_points[s.name] = s
	_StartSpawnHeartbeat()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetRandomSpawnPoint() -> Dictionary:
	var keys : Array = _spawn_points.keys()
	if keys.size() <= 0: return {}
	var idx : int = randi_range(0, keys.size() - 1)
	var pos : Vector2 = _spawn_points[keys[idx]].get_random_spawn_position()
	if pos.is_equal_approx(_spawn_points[keys[idx]].global_position):
		return {}
	return {
		"origin": _spawn_points[keys[idx]].global_position,
		"position": pos
	}

func _SpawnEnemy() -> int:
	if _enemies.size() >= max_enemies: return ERR_CANT_CREATE
	var spawn : Dictionary = _GetRandomSpawnPoint()
	if spawn.is_empty():
		return ERR_CANT_CREATE
	
	var e : Enemy = XENO.instantiate()
	e.max_health = 200
	spawn_container.add_child(e)
	e.global_position = spawn.position
	# WARNING: Currently nav_point_group is Xeno specific... Yay
	e.nav_point_group = nav_point_group
	if not e.despawned.is_connected(_on_enemy_despawned.bind(e)):
		e.despawned.connect(_on_enemy_despawned.bind(e))
	_enemies[e.name] = weakref(e)
	if e.has_method("spawn_from"):
		e.spawn_from(spawn.origin)
	return OK

func _StartSpawnHeartbeat() -> void:
	if _heartbeating: return
	_heartbeating = true
	var interval = randf_range(min_spawn_delay, max_spawn_delay)
	get_tree().create_timer(interval).timeout.connect(_on_spawn_timeout, CONNECT_ONE_SHOT)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_spawn_timeout() -> void:
	if _enemies.size() < max_enemies:
		var interval : float = DEFAULT_SPAWN_DELAY
		var err : int = _SpawnEnemy()
		if err == OK:
			interval = randf_range(min_spawn_delay, max_spawn_delay)
		get_tree().create_timer(interval).timeout.connect(_on_spawn_timeout, CONNECT_ONE_SHOT)
	else:
		_heartbeating = false

func _on_enemy_despawned(e : Enemy) -> void:
	if e.name in _enemies:
		_enemies.erase(e.name)
		if not _heartbeating:
			_StartSpawnHeartbeat()
