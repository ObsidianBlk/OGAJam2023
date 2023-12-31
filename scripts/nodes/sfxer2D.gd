extends Node2D
class_name sfxer2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal finished()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("SFXer 2D")
@export_subgroup("Audio Stream Player Config")
@export var bus : StringName = &"Master":						set = set_bus
@export var max_distance : float = 2000.0:						set = set_max_distance
@export_subgroup("Samples and Groups")
@export var sample_names : Array[StringName] = []
@export var sample_streams : Array[AudioStream] = []
@export var sample_groups : Array[String] = []:					set = set_sample_groups

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _groups : Dictionary = {}

var _audio1 : AudioStreamPlayer2D = null
var _audio2 : AudioStreamPlayer2D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_bus(bus_name : StringName) -> void:
	bus = bus_name
	if _audio1 != null:
		_audio1.bus = bus
	if _audio2 != null:
		_audio2.bus = bus

func set_max_distance(d : float) -> void:
	if d <= 0.0: return
	max_distance = d
	if _audio1 != null:
		_audio1.max_distance = max_distance
	if _audio2 != null:
		_audio2.max_distance = max_distance

func set_sample_groups(sg : Array[String]) -> void:
	sample_groups = sg
	var group_names : Array = []
	for group in sample_groups:
		var group_name : StringName = _AddSampleGroup(group)
		if group_name != &"":
			group_names.append(group_name)
	_ClearMissingSampleGroups(group_names)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_audio1 = AudioStreamPlayer2D.new()
	_audio2 = AudioStreamPlayer2D.new()
	add_child(_audio1)
	add_child(_audio2)
	set_bus(bus)
	set_max_distance(max_distance)
	
	_audio1.finished.connect(_on_audio_finished.bind(_audio1))
	_audio2.finished.connect(_on_audio_finished.bind(_audio2))
	set_sample_groups(sample_groups)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearMissingSampleGroups(groups : Array) -> void:
	var keys : Array = _groups.keys()
	for key in keys:
		if groups.find(key) < 0:
			_groups.erase(key)


func _AddSampleGroup(group_def : String) -> StringName:
	var ginfo : Array = group_def.split(",")
	for i in range(ginfo.size()):
		ginfo[i] = ginfo[i].strip_edges()
	var group_name : StringName = &""
	if ginfo.size() > 2 and ginfo[0] != "":
		group_name = StringName(ginfo[0])
		_groups[group_name] = ginfo.slice(1, ginfo.size())
	return group_name

func _GetAvailableStream() -> AudioStreamPlayer2D:
	for stream in [_audio1, _audio2]:
		if not stream.playing:
			return stream
	return null

func _GetStreamName(audio : AudioStreamPlayer2D) -> StringName:
	if audio.stream != null:
		var idx : int = sample_streams.find(audio.stream)
		if idx >= 0:
			return sample_names[idx]
	return &""

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func stop() -> void:
	_audio1.stop()
	_audio1.stream = null
	_audio2.stop()
	_audio2.stream = null

func play(stream_name : StringName, force : bool = false, id : int = -1) -> void:
	var idx : int = sample_names.find(stream_name)
	if not (idx >= 0 and idx < sample_streams.size()):
		return
	
	var audio : AudioStreamPlayer2D = null
	if force:
		if not (id >= 0 and id < 2):
			id = randi_range(0, 1)
		audio = _audio1 if id == 0 else _audio2
	else:
		audio = _GetAvailableStream()
	if audio != null:
		audio.stop()
		audio.stream = sample_streams[idx]
		audio.play()

func is_stream_playing(stream_name : StringName) -> bool:
	for audio in [_audio1, _audio2]:
		if audio.playing and stream_name == _GetStreamName(audio):
			return true
	return false

func play_group(group_name : StringName, force : bool = false, id : int = -1) -> void:
	if group_name in _groups:
		var idx : int = randi_range(0, _groups[group_name].size() - 1)
		play(_groups[group_name][idx], force, id)

func is_group_playing(group_name : StringName) -> bool:
	for audio in [_audio1, _audio2]:
		var stream_name : StringName = _GetStreamName(audio)
		if stream_name in _groups:
			return true
	return false

func get_playing_streams() -> PackedStringArray:
	var streams : Array = []
	for audio in [_audio1, _audio2]:
		var sname : StringName = _GetStreamName(audio)
		if sname != &"":
			streams.append(sname)
	return PackedStringArray(streams)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_finished(_audio : AudioStreamPlayer2D) -> void:
	finished.emit()


