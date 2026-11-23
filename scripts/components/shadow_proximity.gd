class_name ShadowProximity
extends OmniLight3D
## Omni shadows cost six extra scene renders each. This keeps the light's shadow on only while the
## active camera is near enough to see its effect, and drops it otherwise. The light itself stays on.

## Extra distance beyond the light's range at which its shadow is still kept.
@export var margin: float = 1.5
## Seconds between distance checks.
@export var check_interval: float = 0.25

var _wanted: bool = false
var _since: float = 0.0


func _ready() -> void:
	_wanted = shadow_enabled
	_since = randf() * check_interval
	if not _wanted:
		set_process(false)


func _process(delta: float) -> void:
	_since += delta
	if _since < check_interval:
		return
	_since = 0.0
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var near: bool = cam.global_position.distance_to(global_position) <= omni_range + margin
	if near != shadow_enabled:
		shadow_enabled = near
