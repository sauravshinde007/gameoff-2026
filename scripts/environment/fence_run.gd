class_name FenceRun
extends Node3D
## A straight run of fence or barrier along local X, centred on the node. Builds its own meshes and
## one collision box at runtime. Used for the property boundary and the small interior seals.

enum Style { WOOD, BARRIER }

@export var length: float = 4.0
@export var height: float = 2.2
@export var style: Style = Style.WOOD
@export var post_spacing: float = 2.5
## Collision is taller than the visible fence so nothing can be climbed or jumped.
@export var collision_height: float = 2.4

const WOOD_MAT: Material = preload("res://assets/materials/wood.tres")
const CONCRETE_MAT: Material = preload("res://assets/materials/concrete.tres")
const THICKNESS: float = 0.3


func _ready() -> void:
	if style == Style.BARRIER:
		_add_box("Barrier", Vector3(length, height, 0.4), Vector3(0.0, height * 0.5, 0.0), CONCRETE_MAT)
	else:
		_add_box("Boards", Vector3(length, height * 0.85, 0.08), Vector3(0.0, height * 0.45, 0.0), WOOD_MAT)
		_add_box("TopRail", Vector3(length, 0.1, 0.14), Vector3(0.0, height, 0.0), WOOD_MAT)
		var posts: int = maxi(2, int(ceil(length / post_spacing)) + 1)
		var step: float = length / float(posts - 1)
		for i: int in posts:
			_add_box("Post%d" % i, Vector3(0.14, height + 0.1, 0.14), Vector3(-length * 0.5 + step * i, height * 0.5, 0.0), WOOD_MAT)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Collision"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(length, collision_height, THICKNESS)
	shape.shape = box
	shape.position = Vector3(0.0, collision_height * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)


func _add_box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mesh_node.mesh = mesh
	mesh_node.position = pos
	add_child(mesh_node)
