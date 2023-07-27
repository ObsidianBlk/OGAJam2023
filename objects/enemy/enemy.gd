#@tool
extends CharacterBody2D
class_name Enemy

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal collided(last_collision, collision_count)
signal dead()
signal despawned()

# ------------------------------------------------------------------------------
# Constants and ENUMS
# ------------------------------------------------------------------------------
const DEATH_BURST : PackedScene = preload("res://objects/death_burst/death_burst.tscn")
const ATTACK_HIT_NODE : PackedScene = preload("res://objects/bullet_hit/bullet_hit.tscn")
const DIRECTIONAL_THRESHOLD : float = 0.1

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy")
@export var max_speed : float = 125.0
@export var max_health : int = 1500

@export var max_damage_per_attack : int = 30
@export_range(0.0, 1.0) var accuracy : float = 0.8

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _action : StringName = &"idle"

var _facing : Vector2 = Vector2.DOWN
var _direction : Vector2 = Vector2.ZERO

var _speed_multiplier : float = 1.0

var _body : AnimatedSprite2D = null
var _sprite_frames : SpriteFrames = null

var _health : int = 0


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_health = max_health
	_UpdateViz()


func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint(): return
	_Process_Start(delta)
	_Process_Velocity(delta)
	_Process_Move(delta)
	_Process_End(delta)

# ------------------------------------------------------------------------------
# Private Overrideable Methods
# ------------------------------------------------------------------------------
func _Process_Start(_delta : float) -> void:
	pass

func _Process_Velocity(delta : float) -> void:
	if _direction.length_squared() > DIRECTIONAL_THRESHOLD:
		#var weight : float = 1.0 if not _face_direction else _CalculateFacing(delta)
		var weight : float = _CalculateFacing(delta)
		velocity = _direction * max_speed * weight * _speed_multiplier
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.7)

func _Process_Move(_delta : float) -> void:
	if move_and_slide():
		collided.emit(get_last_slide_collision(), get_slide_collision_count())

func _Process_End(_delta : float) -> void:
	_action = &"move" if velocity.length() > 0.1 else &"idle"
	_UpdateViz()

func _Despawn() -> void:
	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
		despawned.emit()
		queue_free()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

func _SetBodySprite(body_sprite : AnimatedSprite2D) -> void:
	if body_sprite != _body:
		_body = body_sprite

func _SetSpriteFrames(sf : SpriteFrames) -> void:
	_sprite_frames = sf

func _GetSpriteFrames() -> SpriteFrames:
	# TODO: Code section for swapping atlas texture!!
	
	return _sprite_frames

func _ShortAngleDist(from : float, to: float) -> float:
	var diff : float = fmod(to - from, PI * 2)
	return fmod(2 * diff, PI * 2) - diff

func _CalculateFacing(delta : float) -> float:
	var rps : float = deg_to_rad(360.0) * delta
	var d : float = abs(_ShortAngleDist(_facing.angle(), _direction.angle()))
	
	var weight : float = 1.0
	if d >= deg_to_rad(0.5):
		weight = min(1.0, rps / d)
	
	var nfacing : Vector2 = _direction
	if weight < 0.98:
		nfacing = Vector2.RIGHT.rotated(lerp(_facing.angle(), _direction.angle(), weight))
	_facing = nfacing
	return weight


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
	if _body == null: return
	var frames : SpriteFrames = _GetSpriteFrames()
	if frames != null:
		_body.sprite_frames = frames
		
	if Engine.is_editor_hint(): return
	var facing : StringName = _VecToFacingName(_facing)
	_body.play("%s_%s"%[_action, facing])

func _SpawnDeathBurst() -> void:
	var parent = get_parent()
	if parent == null: return
	var burst = DEATH_BURST.instantiate()
	burst.death_type = 1
	parent.add_child(burst)
	burst.global_position = global_position

func _CalculateAttackDamage() -> int:
	var variance : int = floor((1.0 - accuracy) * float(max_damage_per_attack))
	return max_damage_per_attack - randi_range(0, variance)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_facing(f : Vector2) -> void:
	_facing = f.normalized()

func get_facing() -> Vector2:
	return _facing

func set_speed_multiplier(sm : float) -> void:
	_speed_multiplier = max(0.0, min(1.0, sm))

func get_speed_multiplier() -> float:
	return _speed_multiplier

func set_direction(d : Vector2) -> void:
	_direction = d

func get_direction() -> Vector2:
	return _direction

func is_alive() -> bool:
	return _health > 0

func damage(amount : int) -> void:
	if _health <= 0: return
	_health -= amount
	if _health <= 0:
		_SpawnDeathBurst()
		Game.xeno_killed()
		dead.emit()
		_Despawn.call_deferred()


