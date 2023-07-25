extends Node2D
class_name EnemySpawnManager


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const XENO : PackedScene = preload("res://objects/enemy/xeno/xeno.tscn")


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy Spawn Manager")
@export var max_enemies : int = 1
@export var spawn_container : Node2D = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _enemies : Dictionary = {}
var _spawn_points : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for s in get_children():
		if is_instance_of(s, EnemySpawnPoint):
			_spawn_points[s.name] = s


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetRandomSpawnPoint() -> Dictionary:
	var keys : Array = _spawn_points.keys()
	if keys.size() <= 0: return {}
	var idx : int = randi_range(0, keys.size() - 1)
	var pos : Vector2 = _spawn_points[keys[idx]].get_random_spawn_position()
	return {
		"origin": _spawn_points[keys[idx]].global_position,
		"position": pos
	}

func _SpawnEnemy() -> void:
	if _enemies.size() >= max_enemies: return
	var spawn : Dictionary = _GetRandomSpawnPoint()
	if spawn.is_empty(): return
	
	var e : Enemy = XENO.instantiate()
	spawn_container.add_child(e)
	e.global_position = spawn.position
	_enemies[e.name] = weakref(e)
	if e.has_method("spawn_from"):
		e.spawn_from(spawn.origin)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_enemy_despawned(e : Enemy) -> void:
	if e.name in _enemies:
		_enemies.erase(e.name)
