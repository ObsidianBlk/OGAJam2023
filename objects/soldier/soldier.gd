@tool
extends CharacterBody2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal collided(last_collision, collision_count)
signal interacted()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const FRAMES_GREEN_SOLDIER : SpriteFrames = preload("res://objects/soldier/green_soldier.tres")
const FRAMES_RED_SOLDIER : SpriteFrames = preload("res://objects/soldier/red_soldier.tres")

const BULLET_HIT_NODE : PackedScene = preload("res://objects/bullet_hit/bullet_hit.tscn")

const DIRECTIONAL_THRESHOLD : float = 0.1

enum SOLDIER {Green=0, Red=1}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var soldier : SOLDIER = SOLDIER.Red:				set = set_soldier
@export var max_speed : float = 100.0:						set = set_max_speed

@export var rof : float = 0.2
@export var bps : int = 1

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _action : StringName = &"idle"
var _firing : bool = false

var _facing : Vector2 = Vector2.DOWN
var _direction : Vector2 = Vector2.ZERO

var _enemies : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body : AnimatedSprite2D = $Body
@onready var _muzzle : AnimatedSprite2D = $Muzzle
@onready var _hit_area : Area2D = $HitArea

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_soldier(s : SOLDIER) -> void:
	if s != soldier:
		soldier = s
		_UpdateViz()

func set_max_speed(m : float) -> void:
	if m > 0.0 and m != max_speed:
		max_speed = m

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not Engine.is_editor_hint():
		_hit_area.body_entered.connect(_on_body_entered)
		_hit_area.body_exited.connect(_on_body_exited)
	_UpdateViz()

func _physics_process(_delta : float) -> void:
	if _direction.length_squared() > DIRECTIONAL_THRESHOLD:
		velocity = _direction * max_speed
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.7)
	
	if move_and_slide():
		collided.emit(get_last_slide_collision(), get_slide_collision_count())
	
	_action = &"move" if velocity.length() > 0.1 else &"idle"
	_UpdateViz()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _VecToFacingName(f : Vector2) -> StringName:
	var angle : float = rad_to_deg(f.angle()) + 180.0
	if angle > 45 and angle <= 135:
		return &"north"
	if angle > 135 and angle <= 225:
		return &"east"
	if angle > 225 and angle <= 315:
		return &"south"
	return &"west"

func _UpdateViz() -> void:
	match soldier:
		SOLDIER.Green:
			if _body.sprite_frames != FRAMES_GREEN_SOLDIER:
				_body.sprite_frames = FRAMES_GREEN_SOLDIER
		SOLDIER.Red:
			if _body.sprite_frames != FRAMES_RED_SOLDIER:
				_body.sprite_frames = FRAMES_RED_SOLDIER
	
	if Engine.is_editor_hint(): return
	var facing : StringName = _VecToFacingName(_facing)
	_body.play("%s_%s"%[_action, facing])
	_muzzle.visible = _firing
	_muzzle.play(facing)

func _CastTo(pos : Vector2, coll_mask : int = 4294967295) -> Dictionary:
	return  get_world_2d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(global_position, pos, coll_mask)
	)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func face_position(pos : Vector2) -> void:
	if pos.is_equal_approx(position): return
	_facing = position.direction_to(pos)
	_hit_area.rotation = _facing.angle()
	_UpdateViz()

func move(dir : Vector2) -> void:
	_direction = dir

func get_direction() -> Vector2:
	return _direction

func attack(active : bool = true) -> void:
	_firing = active
	_UpdateViz()
	_attack_interval()

func interact() -> void:
	interacted.emit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _attack_interval() -> void:
	if not _firing: return
	var ename : Array = _enemies.keys()
	var visible_enemies : Array = []
	
	for i in range(ename.size()):
		if _enemies[ename[i]].get_ref() == null:
			_enemies.erase(ename[i])
		var enemy = _enemies[ename[i]].get_ref()
		var result : Dictionary = _CastTo(enemy.global_position, _hit_area.collision_mask)
		if not result.is_empty() and result.collider == enemy:
			visible_enemies.append(enemy)
	
	if visible_enemies.size() > 0:
		for i in range(bps):
			var idx : int = randi_range(0, visible_enemies.size() - 1)
			# TODO: Use distance and an "accuracy" variable to determine chance to hit.
			var enemy : Node2D = visible_enemies[idx]
			enemy.damage(1.0)
			var hit : Node2D = BULLET_HIT_NODE.instantiate()
			hit.hit_type = 1
			enemy.add_child(hit)
	
	get_tree().create_timer(rof).timeout.connect(_attack_interval, CONNECT_ONE_SHOT)

func _on_body_entered(body : Node2D) -> void:
	if not body.name in _enemies and body.has_method("damage"):
		print("See Enemy: ", body.name)
		_enemies[body.name] = weakref(body)

func _on_body_exited(body : Node2D) -> void:
	if body.name in _enemies:
		print("No longer see: ", body.name)
		_enemies.erase(body.name)

