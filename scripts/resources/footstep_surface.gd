class_name FootstepSurface
extends Resource
## One walkable surface type (wood, stone, dirt...) and how its footsteps sound.

@export var id: StringName = &"stone"
## A random clip is picked per step (never the same one twice in a row).
@export var streams: Array[AudioStream] = []
@export var volume_db: float = 0.0
@export var pitch_min: float = 0.92
@export var pitch_max: float = 1.08
