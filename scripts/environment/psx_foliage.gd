class_name PsxFoliage
extends Node3D
## Wraps an imported PSX tree/bush model: applies the alpha-cut leaf texture with a retro look,
## skips shadows (cheap) and optionally adds a trunk collider. Scale the node uniformly.

@export var texture: Texture2D
## Darkens/colours the whole plant (used for distant trees that should read as silhouettes).
@export var tint: Color = Color.WHITE
## Model-space trunk radius. 0 = no collision (outside the fence).
@export var trunk_radius: float = 0.0

static var _materials: Dictionary = {}


func _ready() -> void:
	var mat: StandardMaterial3D = _get_material()
	_apply(self, mat)
	if trunk_radius > 0.0:
		var body: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cyl: CylinderShape3D = CylinderShape3D.new()
		cyl.radius = trunk_radius
		cyl.height = 4.0
		shape.shape = cyl
		shape.position = Vector3(0.0, 2.0, 0.0)
		body.add_child(shape)
		add_child(body)


func _get_material() -> StandardMaterial3D:
	var key: String = "%s|%s" % [texture.resource_path, tint]
	if _materials.has(key):
		return _materials[key]
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	_materials[key] = mat
	return mat


func _apply(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		var mesh_node: MeshInstance3D = node
		mesh_node.material_override = mat
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_apply(child, mat)
