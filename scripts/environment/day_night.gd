class_name DayNight
extends Node
## Applies a LightingPreset to the world environment and the light groups
## (reception_lights, hallway_lights, exterior_lights), plus the desk_lamp group. Starts in the day look.

@export var day_preset: LightingPreset
@export var night_preset: LightingPreset
@export var start_with_day: bool = true

## The preset applied last (other systems read it, e.g. highway traffic headlights).
var current: LightingPreset


func _ready() -> void:
	add_to_group(&"day_night")
	apply(day_preset if start_with_day else night_preset)


func apply(preset: LightingPreset) -> void:
	current = preset
	var env: Environment = get_viewport().world_3d.environment
	env.background_color = preset.background_color
	env.ambient_light_color = preset.ambient_color
	env.ambient_light_energy = preset.ambient_energy
	env.fog_light_color = preset.fog_color
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = preset.fog_density
	env.fog_depth_begin = preset.fog_depth_begin
	env.fog_depth_end = preset.fog_depth_end
	env.fog_depth_curve = preset.fog_depth_curve
	env.fog_height_density = 0.0
	env.fog_sky_affect = preset.sky_fog_affect
	_apply_sky(env, preset)
	for sun: Node in get_tree().get_nodes_in_group(&"sun"):
		(sun as DirectionalLight3D).light_color = preset.sun_color
		(sun as DirectionalLight3D).light_energy = preset.sun_energy
	env.adjustment_enabled = true
	env.adjustment_brightness = preset.grade_brightness
	env.adjustment_contrast = preset.grade_contrast
	env.adjustment_saturation = preset.grade_saturation
	for filter: Node in get_tree().get_nodes_in_group(&"retro_filter"):
		(filter as RetroFilter).set_look(preset.retro_tint, preset.retro_vignette)
	for light: Node in get_tree().get_nodes_in_group(&"reception_lights"):
		if not light.is_in_group(&"desk_lamp"):
			(light as Light3D).light_color = preset.reception_light_color
	_scale_group(&"reception_lights", preset.reception_light_scale)
	_scale_group(&"hallway_lights", preset.hallway_light_scale)
	_scale_group(&"exterior_lights", preset.exterior_light_scale)
	get_tree().call_group(&"lit_windows", "set_glow", preset.exterior_light_scale)
	for lamp: Node in get_tree().get_nodes_in_group(&"desk_lamp"):
		(lamp as FlickerLight).set_energy_scale(1.0 if preset.desk_lamp else 0.0)
	AudioManager.set_ambience(preset.ambience)


func _apply_sky(env: Environment, preset: LightingPreset) -> void:
	if env.sky == null or not env.sky.sky_material is PanoramaSkyMaterial:
		return
	var mat: PanoramaSkyMaterial = env.sky.sky_material
	if preset.sky_panorama != null:
		mat.panorama = preset.sky_panorama
	mat.energy_multiplier = preset.sky_energy


func _scale_group(group: StringName, scale: float) -> void:
	for node: Node in get_tree().get_nodes_in_group(group):
		if node.is_in_group(&"desk_lamp"):
			continue
		if node is FlickerLight:
			(node as FlickerLight).set_energy_scale(scale)
		elif node is Light3D:
			var light: Light3D = node
			if not light.has_meta(&"authored_energy"):
				light.set_meta(&"authored_energy", light.light_energy)
			light.light_energy = float(light.get_meta(&"authored_energy")) * scale
