class_name Footsteps
extends Node3D
## Footstep sounds for anything that walks (player, guests). Add as a child at the feet.
## Plays one step every `stride` metres the parent moves horizontally, with the sound of the
## surface under it (see FootstepSurfaces). Works for physics movement and tweened NPCs alike.

@export var bank: FootstepBank = preload("res://data/audio/footsteps.tres")
## Metres walked between two steps.
@export var stride: float = 0.75
## Added to the surface's volume (e.g. quieter NPCs).
@export var volume_offset_db: float = 0.0
## Distance (metres) at which the step sound is at full volume before fading.
@export var unit_size: float = 3.0
@export var max_distance: float = 25.0
## Moves larger than this in one frame are teleports, not steps.
@export var teleport_distance: float = 1.0
## For CharacterBody3D parents: no steps while airborne.
@export var require_floor: bool = true

var _body: Node3D
var _last_pos: Vector3
var _travelled: float = 0.0
var _player: AudioStreamPlayer3D
var _last_index: int = -1


func _ready() -> void:
	_body = get_parent() as Node3D
	_player = AudioStreamPlayer3D.new()
	_player.unit_size = unit_size
	_player.max_distance = max_distance
	add_child(_player)
	_last_pos = _body.global_position if _body != null else Vector3.ZERO
	# Half a stride in: the first step comes soon after starting to walk.
	_travelled = stride * 0.5


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var pos: Vector3 = _body.global_position
	var moved: Vector3 = pos - _last_pos
	moved.y = 0.0
	_last_pos = pos
	var dist: float = moved.length()
	if dist > teleport_distance:
		return
	if require_floor and _body is CharacterBody3D and not (_body as CharacterBody3D).is_on_floor():
		return
	if dist < 0.0005:
		# Standing still: the next walk starts with a quick first step.
		_travelled = maxf(_travelled, stride * 0.5)
		return
	_travelled += dist
	if _travelled >= stride:
		_travelled = fmod(_travelled, stride)
		step()


## Plays one footstep for the surface under the feet now.
func step() -> void:
	if bank == null or not is_inside_tree():
		return
	var id: StringName = FootstepSurfaces.query(get_tree(), bank, _body.global_position)
	var surface: FootstepSurface = bank.get_surface(id)
	if surface == null or surface.streams.is_empty():
		return
	var index: int = randi() % surface.streams.size()
	if surface.streams.size() > 1 and index == _last_index:
		index = (index + 1) % surface.streams.size()
	_last_index = index
	_player.stream = surface.streams[index]
	_player.volume_db = surface.volume_db + volume_offset_db
	_player.pitch_scale = randf_range(surface.pitch_min, surface.pitch_max)
	_player.play()


## Surface id under the feet now (for debugging / UI).
func current_surface() -> StringName:
	if bank == null or _body == null:
		return &""
	return FootstepSurfaces.query(get_tree(), bank, _body.global_position)
