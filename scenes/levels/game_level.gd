extends Node2D
class_name GameLevel


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(request)
signal temprature_changed(temp)
signal exit_timer_changed(time_passed, interval)
signal player_health_changed(percentage)

# ------------------------------------------------------------------------------
# Constant
# ------------------------------------------------------------------------------
const MIN_TEMPERATURE : float = 80.0
const MAX_TEMPERATURE : float = 200.0
const DAMAGE_TEMPERATURE : float = 150.0
const HEAT_DAMAGE_INTERVAL : float = 2.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Game Level")
@export_node_path("CanvasModulate") var canvas_modulate_node_path : NodePath = ^""
@export var color : Color = Color.WHITE
@export_range(MIN_TEMPERATURE, MAX_TEMPERATURE) var initial_temprature : float = MIN_TEMPERATURE
@export var temprature_dps : float = 1.0
@export var player_respawn_delay : float = 3.0
@export_file var next_level : String = ""
@export var final_level : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _temprature : float = MIN_TEMPERATURE

var _player : WeakRef = weakref(null)
var _heat_damage_delay : float = 0.0

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.reset_xeno_count()
	_temprature = initial_temprature
	var cm = get_node_or_null(canvas_modulate_node_path)
	if is_instance_of(cm, CanvasModulate):
		cm.color = color
		#cm.visible = true

func _physics_process(delta : float) -> void:
	_temprature = min(_temprature + (temprature_dps * delta), MAX_TEMPERATURE)
	temprature_changed.emit(_temprature)
	if _temprature >= DAMAGE_TEMPERATURE:
		_heat_damage_delay += delta
		if _heat_damage_delay >= HEAT_DAMAGE_INTERVAL:
			_heat_damage_delay -= HEAT_DAMAGE_INTERVAL
			var player : CharacterBody2D = _player.get_ref()
			if player == null: return
			if player.has_method("damage"):
				player.damage(1)
	else:
		_heat_damage_delay = 0.0

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func initialize() -> void:
	if _player.get_ref() != null: return
	var plist : Array = get_tree().get_nodes_in_group(&"Player")
	for p in plist:
		if is_instance_of(p, CharacterBody2D):
			_player = weakref(p)
			if p.has_signal("health_changed"):
				if not p.health_changed.is_connected(_on_player_health_changed):
					p.health_changed.connect(_on_player_health_changed)
			p.revive()
			break
	
	if _player.get_ref() == null:
		printerr("Failed to find player node!!")

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_player_health_changed(current_health : int, max_health : int) -> void:
	var percent : float = max(0.0, min(1.0, float(current_health) / float(max_health)))
	player_health_changed.emit(percent)
	if current_health < 0:
		get_tree().create_timer(player_respawn_delay).timeout.connect(
			_on_player_respawn_delay_timeout, CONNECT_ONE_SHOT
		)

func _on_player_respawn_delay_timeout() -> void:
	var player : CharacterBody2D = _player.get_ref()
	if player == null: return
	var pos : Vector2 = player.global_position
	var pslist : Array = get_tree().get_nodes_in_group(&"PlayerStart")
	if pslist.size() > 0:
		var idx : int = 0
		if pslist.size() > 1:
			idx = randi_range(0, pslist.size() - 1)
		pos = pslist[idx].global_position
	player.global_position = pos
	player.revive()

func _on_coolant_discharged(amount : float) -> void:
	if amount > 0:
		_temprature = max(_temprature - amount, MIN_TEMPERATURE)

func _on_exit_timer_changed(time_passed : float, interval : float) -> void:
	exit_timer_changed.emit(time_passed, interval)

func _on_level_exited() -> void:
	if final_level:
		requested.emit({"action":&"game_won"})
	elif next_level != "":
		requested.emit({"action":&"load_level", "payload":next_level})
	else:
		printerr("Level Exit called but nothing to do.")
