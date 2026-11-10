extends Node
## Sound playback by name. Stub until Phase 4: names with no stream registered are ignored.

## Register streams here (name -> stream). Filled in Phase 4.
var sfx: Dictionary[StringName, AudioStream] = {}
var ambience: Dictionary[StringName, AudioStream] = {}

var _ambience_player: AudioStreamPlayer


func _ready() -> void:
	_ambience_player = AudioStreamPlayer.new()
	add_child(_ambience_player)


## pos = Vector3.INF plays non-positional.
func play_sfx(sfx_name: StringName, pos: Vector3 = Vector3.INF) -> void:
	var stream: AudioStream = sfx.get(sfx_name)
	if stream == null:
		return
	if pos == Vector3.INF:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = stream
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
	else:
		var p3: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p3.stream = stream
		add_child(p3)
		p3.global_position = pos
		p3.finished.connect(p3.queue_free)
		p3.play()


func set_ambience(ambience_name: StringName) -> void:
	var stream: AudioStream = ambience.get(ambience_name)
	if stream == null:
		_ambience_player.stop()
		return
	_ambience_player.stream = stream
	_ambience_player.play()
