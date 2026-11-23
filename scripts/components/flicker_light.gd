class_name FlickerLight
extends OmniLight3D
## Light that can flicker or cut out on command. Joins group_name so events can address it
## via call_group (e.g. "reception_lights", "hallway_lights").

@export var group_name: StringName = &"reception_lights"
@export var min_interval: float = 0.04
@export var max_interval: float = 0.18
## Energy while flickering "off" (fraction of the normal energy).
@export_range(0.0, 1.0) var dim_fraction: float = 0.05

## Looping 3D sound attached to this light (AudioManager loop name). Stops while the light is off.
@export var hum_sfx: StringName = &""
## Occasional unprompted flicker (e.g. the motel sign). Gap and length are random per flicker.
@export var auto_flicker: bool = false
@export var auto_min_gap: float = 4.0
@export var auto_max_gap: float = 12.0
@export var auto_flicker_seconds: float = 0.5

var _authored_energy: float = 1.0
var _hum: Node = null
var _off: bool = false
var _base_energy: float = 1.0
var _tween: Tween
## Current fraction of _base_energy (0 = off, 1 = on); kept so an energy-scale change never fights a flicker or an off light.
var _level: float = 1.0


func _ready() -> void:
	_authored_energy = light_energy
	_base_energy = light_energy
	add_to_group(group_name)
	_start_hum()
	if auto_flicker:
		_auto_flicker_loop()


## Random on/off stutter for `seconds`, then back to normal.
func flicker(seconds: float) -> void:
	_kill_tween()
	_tween = create_tween()
	var t: float = 0.0
	var on: bool = false
	while t < seconds:
		var step: float = randf_range(min_interval, max_interval)
		_tween.tween_callback(_set_level.bind(1.0 if on else dim_fraction))
		_tween.tween_interval(step)
		on = not on
		t += step
	_tween.tween_callback(_set_level.bind(1.0))


## Scales the energy set in the scene (used by DayNight presets). 1.0 = as authored.
func set_energy_scale(energy_scale: float) -> void:
	_base_energy = _authored_energy * energy_scale
	light_energy = _base_energy * _level


## true = fully dark until set_off(false).
func set_off(off: bool) -> void:
	_kill_tween()
	_off = off
	_set_level(0.0 if off else 1.0)
	if off:
		AudioManager.stop_loop(_hum)
		_hum = null
	else:
		_start_hum()


func _set_level(fraction: float) -> void:
	_level = fraction
	light_energy = _base_energy * fraction


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()


func _start_hum() -> void:
	if hum_sfx != &"" and _hum == null:
		_hum = AudioManager.play_loop(hum_sfx, self)


func _auto_flicker_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(auto_min_gap, auto_max_gap)).timeout
		if is_inside_tree() and not _off and _base_energy > 0.0:
			flicker(auto_flicker_seconds)
