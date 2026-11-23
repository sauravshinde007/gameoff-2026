class_name DayNight
extends Node
## Applies a LightingPreset to the world environment and the light groups
## (reception_lights, hallway_lights, exterior_lights), plus the desk_lamp group. Starts in the day look.
## blend() mixes two presets (used by DayNightCycle for the timed day/night transition).

const SKY_SHADER: Shader = preload("res://assets/shaders/sky_blend.gdshader")

@export var day_preset: LightingPreset
@export var night_preset: LightingPreset
@export var start_with_day: bool = true
## Screen-space ambient occlusion is a costly full-screen pass. Off by default for performance;
## presets keep their ssao_* values, so turning this on restores the old look.
@export var use_ssao: bool = false

## The preset applied last (other systems read it, e.g. highway traffic headlights).
var current: LightingPreset

## Reused by _lerp_preset so a blend does not allocate a new resource every refresh.
var _blend_preset: LightingPreset
## Names of LightingPreset's script variables, read once.
var _preset_props: Array[StringName] = []


func _ready() -> void:
	add_to_group(&"day_night")
	apply(day_preset if start_with_day else night_preset)


## Mix of two presets, t = 0 -> a, 1 -> b. The sky panoramas cross-fade.
func blend(a: LightingPreset, b: LightingPreset, t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	if t <= 0.0 or a == b:
		apply(a)
		return
	if t >= 1.0:
		apply(b)
		return
	apply(_lerp_preset(a, b, t), b.sky_panorama, t)


## sky_b / sky_t: optional second panorama cross-faded over preset.sky_panorama.
func apply(preset: LightingPreset, sky_b: Texture2D = null, sky_t: float = 0.0) -> void:
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
	env.ssao_enabled = use_ssao and preset.ssao_intensity > 0.0
	env.ssao_intensity = preset.ssao_intensity
	env.ssao_radius = preset.ssao_radius
	_apply_sky(env, preset, sky_b, sky_t)
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


## The scene's PanoramaSkyMaterial is swapped once for the blend shader (same look, two textures).
func _apply_sky(env: Environment, preset: LightingPreset, sky_b: Texture2D, sky_t: float) -> void:
	if env.sky == null:
		return
	var mat: ShaderMaterial = env.sky.sky_material as ShaderMaterial
	if mat == null or mat.shader != SKY_SHADER:
		var old: PanoramaSkyMaterial = env.sky.sky_material as PanoramaSkyMaterial
		mat = ShaderMaterial.new()
		mat.shader = SKY_SHADER
		if old != null and old.panorama != null:
			mat.set_shader_parameter(&"sky_a", old.panorama)
			mat.set_shader_parameter(&"sky_b", old.panorama)
		env.sky.sky_material = mat
	if preset.sky_panorama != null:
		mat.set_shader_parameter(&"sky_a", preset.sky_panorama)
	mat.set_shader_parameter(&"sky_b", sky_b if sky_b != null else preset.sky_panorama)
	mat.set_shader_parameter(&"blend", sky_t if sky_b != null else 0.0)
	mat.set_shader_parameter(&"energy", preset.sky_energy)


func _lerp_preset(a: LightingPreset, b: LightingPreset, t: float) -> LightingPreset:
	if _blend_preset == null:
		_blend_preset = LightingPreset.new()
		for prop: Dictionary in _blend_preset.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				_preset_props.append(prop.name)
	var p: LightingPreset = _blend_preset
	for key: StringName in _preset_props:
		var va: Variant = a.get(key)
		var vb: Variant = b.get(key)
		match typeof(va):
			TYPE_FLOAT:
				p.set(key, lerpf(va, vb, t))
			TYPE_COLOR:
				p.set(key, (va as Color).lerp(vb, t))
			_:
				# bool / texture / name: take whichever preset dominates.
				p.set(key, va if t < 0.5 else vb)
	p.sky_panorama = a.sky_panorama
	return p


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
