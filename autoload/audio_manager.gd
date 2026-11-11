extends Node
## Sound playback by name. Streams come from data/audio/sound_bank.tres.
## Names with no file on disk are ignored (silent), so audio can be added at any time.

const AUDIO_EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]

@export var bank: SoundBank = preload("res://data/audio/sound_bank.tres")

var sfx: Dictionary[StringName, AudioStream] = {}
var loops: Dictionary[StringName, AudioStream] = {}
var ambience: Dictionary[StringName, AudioStream] = {}

var _ambience_player: AudioStreamPlayer
var _loop_players: Array[Node] = []


func _ready() -> void:
	_ambience_player = AudioStreamPlayer.new()
	add_child(_ambience_player)
	_load_bank()


func _load_bank() -> void:
	for sfx_name: StringName in bank.sfx:
		var stream: AudioStream = _load_stream(bank.sfx[sfx_name], false)
		if stream != null:
			sfx[sfx_name] = stream
	for loop_name: StringName in bank.loops:
		var stream: AudioStream = _load_stream(bank.loops[loop_name], true)
		if stream != null:
			loops[loop_name] = stream
			ambience[loop_name] = stream


func _load_stream(path: String, looped: bool) -> AudioStream:
	var found: String = ""
	if ResourceLoader.exists(path):
		found = path
	else:
		for ext: String in AUDIO_EXTENSIONS:
			if ResourceLoader.exists(path + "." + ext):
				found = path + "." + ext
				break
	if found.is_empty():
		return null
	var stream: AudioStream = load(found) as AudioStream
	if stream != null and looped:
		stream = stream.duplicate() as AudioStream
		if stream is AudioStreamWAV:
			var wav: AudioStreamWAV = stream
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			if wav.loop_end <= wav.loop_begin:
				# Imported files have no loop points: loop the whole clip.
				wav.loop_end = int(wav.get_length() * wav.mix_rate)
		elif "loop" in stream:
			stream.set("loop", true)
	return stream


## pos = Vector3.INF plays non-positional. Returns the player (null if the sound has no file).
func play_sfx(sfx_name: StringName, pos: Vector3 = Vector3.INF) -> Node:
	var stream: AudioStream = sfx.get(sfx_name)
	if stream == null:
		return null
	var db: float = bank.volume_db.get(sfx_name, 0.0)
	if pos == Vector3.INF:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = db
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
		return p
	else:
		var p3: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = db
		add_child(p3)
		p3.global_position = pos
		p3.finished.connect(p3.queue_free)
		p3.play()
		return p3


## Starts a looping sound. Non-positional by default; pass a Node3D to attach it as a 3D source.
## Returns a handle for stop_loop(), or null if the sound has no file.
func play_loop(loop_name: StringName, at: Node3D = null) -> Node:
	var stream: AudioStream = loops.get(loop_name)
	if stream == null:
		return null
	var db: float = bank.volume_db.get(loop_name, 0.0)
	var player: Node
	if at == null:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = db
		add_child(p)
		p.play()
		player = p
	else:
		var p3: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = db
		p3.unit_size = 3.0
		p3.max_distance = 14.0
		at.add_child(p3)
		p3.play()
		player = p3
	_loop_players.append(player)
	return player


func stop_loop(handle: Node) -> void:
	if handle == null:
		return
	_loop_players.erase(handle)
	if is_instance_valid(handle):
		handle.queue_free()


func set_ambience(ambience_name: StringName) -> void:
	var stream: AudioStream = ambience.get(ambience_name)
	if stream == null:
		_ambience_player.stop()
		return
	if _ambience_player.stream == stream and _ambience_player.playing:
		return
	_ambience_player.stream = stream
	_ambience_player.volume_db = bank.volume_db.get(ambience_name, 0.0)
	_ambience_player.play()


## Used on restart: stops ambience, every loop and every one-shot still playing.
func stop_all() -> void:
	_ambience_player.stop()
	for handle: Node in _loop_players:
		if is_instance_valid(handle):
			handle.queue_free()
	_loop_players.clear()
	for child: Node in get_children():
		if child != _ambience_player:
			child.queue_free()
