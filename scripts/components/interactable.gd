class_name Interactable
extends Area3D
## Attach to an Area3D (with a CollisionShape3D child). The player's Interactor
## finds it by raycast and calls interact(). Parent props listen to `interacted`.
## While focused, the prop's meshes get a white outline (set_highlighted).

signal interacted(by: Node)
## Emitted when prompt_text changes so a focused prompt can refresh.
signal prompt_changed()

const OUTLINE_SHADER: Shader = preload("res://assets/shaders/interact_outline.gdshader")

@export var prompt_text: String = "Interact":
	set(value):
		prompt_text = value
		prompt_changed.emit()
@export var enabled: bool = true
@export_group("Highlight")
@export var highlight_enabled: bool = true
## Node whose meshes get outlined. Empty = this Interactable's parent.
## If that node has no meshes (e.g. an invisible supply point over a shelf), meshes whose
## centre lies inside the collision shape are outlined instead.
@export var highlight_root: NodePath
@export var outline_color: Color = Color.WHITE
@export_range(0.0, 10.0) var outline_width: float = 3.0

static var _outline_materials: Dictionary[Color, ShaderMaterial] = {}

var _targets: Array[GeometryInstance3D] = []
var _targets_found: bool = false


func _ready() -> void:
	collision_layer = 4  # layer 3: interactable
	collision_mask = 0


func interact(by: Node) -> void:
	if enabled:
		interacted.emit(by)


func get_prompt() -> String:
	return prompt_text


## Called by the Interactor when the player starts/stops looking at this.
func set_highlighted(on: bool) -> void:
	# Headless (dummy renderer) can't resolve shader materials and logs an error per overlay.
	if not highlight_enabled or DisplayServer.get_name() == "headless":
		return
	if not _targets_found:
		_find_targets()
	var mat: ShaderMaterial = _get_outline_material() if on else null
	for g: GeometryInstance3D in _targets:
		if is_instance_valid(g):
			g.material_overlay = mat


func _get_outline_material() -> ShaderMaterial:
	var key: Color = Color(outline_color.r, outline_color.g, outline_color.b, outline_width)
	if not _outline_materials.has(key):
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = OUTLINE_SHADER
		mat.set_shader_parameter(&"outline_color", outline_color)
		mat.set_shader_parameter(&"outline_width", outline_width)
		_outline_materials[key] = mat
	return _outline_materials[key]


func _find_targets() -> void:
	_targets_found = true
	_targets.clear()
	var root: Node = get_node_or_null(highlight_root) if not highlight_root.is_empty() else get_parent()
	if root != null:
		_collect(root)
	if _targets.is_empty():
		_collect_overlapping()


func _collect(node: Node) -> void:
	if node != self and node is Interactable:
		return  # another interactable's prop (e.g. a separate hook on the key rack)
	if _is_outline_target(node):
		_targets.append(node as GeometryInstance3D)
	for c: Node in node.get_children():
		_collect(c)


func _is_outline_target(node: Node) -> bool:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).visible
	if node is CSGShape3D:
		return (node as CSGShape3D).is_root_shape() and (node as CSGShape3D).visible
	return false


## Fallback for meshless points: outline scene meshes whose centre is inside our collision box.
func _collect_overlapping() -> void:
	var box: AABB = _local_shape_aabb()
	if box.size == Vector3.ZERO:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var inv: Transform3D = global_transform.affine_inverse()
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Interactable or n.is_in_group(&"player"):
			continue
		if _is_outline_target(n):
			var g: GeometryInstance3D = n as GeometryInstance3D
			var world_box: AABB = g.global_transform * g.get_aabb()
			var centre: Vector3 = inv * world_box.get_center()
			var local_size: Vector3 = (inv.basis * world_box.size).abs()
			if box.has_point(centre) and local_size.x <= box.size.x * 2.0 \
					and local_size.y <= box.size.y * 2.0 and local_size.z <= box.size.z * 2.0:
				_targets.append(g)
		for c: Node in n.get_children():
			stack.append(c)


func _local_shape_aabb() -> AABB:
	for c: Node in get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape != null:
			var cs: CollisionShape3D = c
			return cs.transform * cs.shape.get_debug_mesh().get_aabb()
	return AABB()
