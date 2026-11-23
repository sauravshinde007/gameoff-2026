class_name RetroModel
extends Node3D
## Put on an instanced character model (.glb). Gives its materials the same retro look as the
## environment (blocky nearest-filtered textures, matte surface) and plays a looping animation.

@export var autoplay_anim: StringName = &"idle"
## Animation speed. Very low values give an unnaturally still, "wrong" idle.
@export var anim_speed: float = 1.0
## Nearest gives the chunky PS1 look; LINEAR_WITH_MIPMAPS is softer and keeps faces smoother.
@export var texture_filter: BaseMaterial3D.TextureFilter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
## Replaces the albedo texture on every surface. Lets several NPCs share one body mesh
## and differ only by their painted texture (clothes, face, hair). Empty = keep the model's own.
@export var skin_texture: Texture2D
## Multiplies every surface's colour (e.g. to paint the same car model in different colours).
@export var tint: Color = Color.WHITE
## Render layers for every mesh (e.g. 2 = only CCTV cameras see it).
@export_flags_3d_render var render_layers: int = 1
@export var cast_shadows: bool = true
## The model's animation stops while it is hidden or further than this from the camera (it would
## not be seen, and skinned animation is not free). 0 = always animate.
@export var anim_cull_distance: float = 40.0

## Retro copies of imported materials, shared by every model using the same source/skin/tint.
static var _material_cache: Dictionary = {}

var _anim: AnimationPlayer
var _cull_timer: float = 0.0


func _ready() -> void:
	_retro_materials(self)
	_anim = _find_anim_player(self)
	if _anim != null:
		_anim.speed_scale = anim_speed
		if autoplay_anim != &"":
			play(autoplay_anim)
	set_process(_anim != null and anim_cull_distance > 0.0)


func _process(delta: float) -> void:
	_cull_timer += delta
	if _cull_timer < 0.5:
		return
	_cull_timer = 0.0
	var cam: Camera3D = get_viewport().get_camera_3d()
	var near: bool = true
	if cam != null:
		near = cam.global_position.distance_to(global_position) <= anim_cull_distance
	var should_run: bool = is_visible_in_tree() and near
	if _anim.active != should_run:
		_anim.active = should_run


## Plays a looping animation by name. Ignored if the model has no such animation.
## blend: cross-fade time in seconds from the current animation (-1 = AnimationPlayer default).
func play(anim: StringName, blend: float = -1.0) -> void:
	if _anim == null or not _anim.has_animation(anim):
		return
	_anim.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	_anim.play(anim, blend)


## Names of every animation the model has (empty if it has no AnimationPlayer).
func get_animation_names() -> PackedStringArray:
	if _anim == null:
		return PackedStringArray()
	return _anim.get_animation_list()


func set_anim_speed(speed: float) -> void:
	anim_speed = speed
	if _anim != null:
		_anim.speed_scale = speed


func _retro_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node: MeshInstance3D = node
		mesh_node.layers = render_layers
		mesh_node.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		if mesh_node.mesh != null:
			for i: int in mesh_node.mesh.get_surface_count():
				var mat: BaseMaterial3D = mesh_node.mesh.surface_get_material(i) as BaseMaterial3D
				if mat == null:
					continue
				mesh_node.set_surface_override_material(i, _retro_copy(mat))
	for child: Node in node.get_children():
		_retro_materials(child)


func _retro_copy(mat: BaseMaterial3D) -> BaseMaterial3D:
	var key: String = "%d|%d|%s|%s" % [mat.get_instance_id(), texture_filter,
			skin_texture.resource_path if skin_texture != null else "", tint]
	if skin_texture != null and skin_texture.resource_path == "":
		key += "|%d" % skin_texture.get_instance_id()
	if _material_cache.has(key):
		return _material_cache[key]
	var copy: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
	copy.texture_filter = texture_filter
	if skin_texture != null:
		copy.albedo_texture = skin_texture
	copy.albedo_color = copy.albedo_color * tint
	copy.roughness = 1.0
	copy.metallic_specular = 0.1
	_material_cache[key] = copy
	return copy


func _find_anim_player(node: Node) -> AnimationPlayer:
	for child: Node in node.get_children():
		if child is AnimationPlayer:
			return child
		var found: AnimationPlayer = _find_anim_player(child)
		if found != null:
			return found
	return null
