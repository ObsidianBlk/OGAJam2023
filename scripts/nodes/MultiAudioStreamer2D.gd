extends Node2D
class_name MultiAudioStreamer2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal finished()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Multi-Audio Streamer 2D")
@export_subgroup("Audio Stream Player Config")
@export var bus : StringName = &"Master":						set = set_bus
@export var max_distance : float = 2000.0:						set = set_max_distance
@export_subgroup("Samples")
@export var sample_names : Array[StringName] = []
@export var sample_streams : Array[AudioStream] = []
@export_subgroup("Variations")
@export_range(-80.0, 24.0) var default_volume_db : float = 0.0
@export_range(-80.0, 24.0) var min_volume_db : float = 0.0:		set = set_min_volume_db
@export_range(-80.0, 24.0) var max_volume_db : float = 0.0:		set = set_max_volume_db
@export_range(0.01, 4.0) var default_pitch_scale : float = 1.0
@export_range(0.01, 4.0) var min_pitch_scale : float = 1.0:		set = set_min_pitch_scale
@export_range(0.01, 4.0) var max_pitch_scale : float = 1.0:		set = set_max_pitch_scale

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _audio1 : AudioStreamPlayer2D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_bus(bus_name : StringName) -> void:
	bus = bus_name
	if _audio1 != null:
		_audio1.bus = bus

func set_max_distance(d : float) -> void:
	if d <= 0.0: return
	max_distance = d
	if _audio1 != null:
		_audio1.max_distance = max_distance

func set_min_pitch_scale(s : float) -> void:
	if s >= 0.01 and s <= 4.0:
		min_pitch_scale = s
		if max_pitch_scale < min_pitch_scale:
			max_pitch_scale = min_pitch_scale

func set_max_pitch_scale(s : float) -> void:
	if s >= 0.01 and s <= 4.0:
		max_pitch_scale = s
		if max_pitch_scale < min_pitch_scale:
			min_pitch_scale = max_pitch_scale

func set_min_volume_db(v : float) -> void:
	if v >= -80.0 and v <= 24.0:
		min_volume_db = v
		if min_volume_db > max_volume_db:
			max_volume_db = min_volume_db

func set_max_volume_db(v : float) -> void:
	if v >= -80.0 and v <= 24.0:
		max_volume_db = v
		if max_volume_db < min_volume_db:
			min_volume_db = max_volume_db

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_audio1 = AudioStreamPlayer2D.new()
	add_child(_audio1)
	set_bus(bus)
	set_max_distance(max_distance)
	
	_audio1.finished.connect(_on_audio_finished.bind(_audio1))


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetStreamName() -> StringName:
	if _audio1 == null: return &""
	if _audio1.stream != null:
		var idx : int = sample_streams.find(_audio1.stream)
		if idx >= 0:
			return sample_names[idx]
	return &""

func _GetVolumeVariance() -> float:
	if min_volume_db == max_volume_db: return min_volume_db
	return randf_range(min_volume_db, max_volume_db)

func _GetPitchVariance() -> float:
	if min_pitch_scale == max_pitch_scale: return min_pitch_scale
	return randf_range(min_pitch_scale, max_pitch_scale)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func stop() -> void:
	_audio1.stop()
	_audio1.stream = null

func play(stream_name : StringName = &"", force : bool = false, variation: bool = true) -> void:
	if sample_names.size() <= 0 or sample_streams.size() <= 0: return
	
	if stream_name == &"":
		stream_name = sample_names[randi_range(0, sample_names.size() - 1)]
	
	var idx : int = sample_names.find(stream_name)
	if not (idx >= 0 and idx < sample_streams.size()):
		return
	
	if _audio1.playing and not force: return
	
	if _audio1 != null:
		if variation:
			_audio1.volume_db = _GetVolumeVariance()
			_audio1.pitch_scale = _GetPitchVariance()
		else:
			_audio1.volume_db = default_volume_db
			_audio1.pitch_scale = default_pitch_scale
		_audio1.stop()
		_audio1.stream = sample_streams[idx]
		_audio1.play()

func is_stream_playing(stream_name : StringName) -> bool:
	return stream_name == _GetStreamName()

func is_playing() -> bool:
	if _audio1 == null: return false
	return _audio1.playing

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_finished(_audio : AudioStreamPlayer2D) -> void:
	finished.emit()
