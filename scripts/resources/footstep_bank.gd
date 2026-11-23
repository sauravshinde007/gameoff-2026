class_name FootstepBank
extends Resource
## Footstep sounds per surface, and which floor materials count as which surface.
## A floor node can also name its surface directly with the metadata `footstep_surface`
## (e.g. for inline materials); that wins over the material mapping.

@export var surfaces: Array[FootstepSurface] = []
## Material resource path -> surface id.
@export var material_surfaces: Dictionary[String, StringName] = {}
## Used when nothing walkable is found under the feet.
@export var default_surface: StringName = &"stone"


func get_surface(id: StringName) -> FootstepSurface:
	for s: FootstepSurface in surfaces:
		if s.id == id:
			return s
	for s: FootstepSurface in surfaces:
		if s.id == default_surface:
			return s
	return null
