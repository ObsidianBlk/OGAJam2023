extends Node2D
class_name GameLevel


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal temprature_changed(temp)
signal cooling_source_changed(source_name, absorbed_temp, max_absorption)
signal cooling_source_removed(source_name)

signal player_health_changed(percentage)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Game Level")
@export_node_path("CanvasModulate") var canvas_modulate_node_path : NodePath = ^""
@export var color : Color = Color.WHITE
@export var initial_temprature : float = 55.0
@export var temprature_dps : float = 1.0
@export var player_respawn_delay : float = 3.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _temprature : float = 0.0
var _cooling_source : Dictionary = {}

var _player : WeakRef = weakref(null)

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
	_temprature += temprature_dps * delta
	
	var source_keys : Array = _cooling_source.keys()
	for source in source_keys:
		var cool = _cooling_source[source]
		if cool.current >= cool.max:
			_cooling_source.erase(source)
			cooling_source_removed.emit(source)
			continue
		
		var cdps : float = (1.0 - (cool.current / cool.max)) * cool.dps
		if cdps > 0.01:
			cool.current += cdps * delta
			_temprature -= cdps * delta
		else:
			var diff : float = cool.max - cool.current
			cool.current = cool.max
			_temprature -= diff
		cooling_source_changed.emit(source, cool.current, cool.max)
	
	temprature_changed.emit(_temprature)

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


func add_cooling_source(source_name : String, absorption_dps : float, max_absorption : float) -> void:
	if source_name in _cooling_source: return
	_cooling_source[source_name] = {
		"dps": absorption_dps,
		"max": max_absorption,
		"current": 0.0
	}


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


