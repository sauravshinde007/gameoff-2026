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
## Render layers for every mesh (e.g. 2 = only CCTV cameras see it).
@export_flags_3d_render var render_layers: int = 1
@export var cast_shadows: bool = true

var _anim: AnimationPlayer


func _ready() -> void:
	_retro_materials(self)
	_anim = _find_anim_player(self)
	if _anim != null:
		_anim.speed_scale = anim_speed
		if autoplay_anim != &"":
			play(autoplay_anim)


## Plays a looping animation by name. Ignored if the model has no such animation.
func play(anim: StringName) -> void:
	if _anim == null or not _anim.has_animation(anim):
		return
	_anim.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	_anim.play(anim)


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
				var copy: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
				copy.texture_filter = texture_filter
				if skin_texture != null:
					copy.albedo_texture = skin_texture
				copy.roughness = 1.0
				copy.metallic_specular = 0.1
				mesh_node.set_surface_override_material(i, copy)
	for child: Node in node.get_children():
		_retro_materials(child)


func _find_anim_player(node: Node) -> AnimationPlayer:
	for child: Node in node.get_children():
		if child is AnimationPlayer:
			return child
		var found: AnimationPlayer = _find_anim_player(child)
		if found != null:
			return found
	return null
