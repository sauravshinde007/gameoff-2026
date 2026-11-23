class_name FoliageBatcher
extends Node
## Merges the scene's PsxFoliage trees and bushes into one MultiMeshInstance3D per mesh and
## material, so ~85 plants cost a handful of draw calls instead of one per mesh. Trunk colliders
## stay on the original nodes. Scans its parent's subtree a few frames after the scene starts.

@export var enabled: bool = true
## Frames to wait so every PsxFoliage has applied its material.
@export var wait_frames: int = 3
@export var verbose: bool = false


func _ready() -> void:
	if enabled:
		_run.call_deferred()


func _run() -> void:
	for i: int in wait_frames:
		await get_tree().process_frame
	var groups: Dictionary = {}  # "meshid|matid" -> {mesh, material, nodes}
	var stack: Array[Node] = [get_parent()]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is PsxFoliage:
			_collect_meshes(n, groups)
			continue
		stack.append_array(n.get_children())
	var plants: int = 0
	for g: Dictionary in groups.values():
		var nodes: Array = g.nodes
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g.mesh
		mm.instance_count = nodes.size()
		for i: int in nodes.size():
			var mesh_node: MeshInstance3D = nodes[i]
			mm.set_instance_transform(i, mesh_node.global_transform)
			mesh_node.queue_free()
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.name = "BatchedFoliage"
		instance.top_level = true
		instance.multimesh = mm
		instance.material_override = g.material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		plants += nodes.size()
	if verbose:
		print("[FoliageBatcher] meshes=", plants, " batches=", groups.size())


func _collect_meshes(node: Node, groups: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_node: MeshInstance3D = node
		if mesh_node.mesh != null and mesh_node.material_override != null and mesh_node.visible:
			var key: String = "%d|%d" % [mesh_node.mesh.get_instance_id(), mesh_node.material_override.get_instance_id()]
			if not groups.has(key):
				groups[key] = {"mesh": mesh_node.mesh, "material": mesh_node.material_override, "nodes": []}
			(groups[key].nodes as Array).append(mesh_node)
	for child: Node in node.get_children():
		_collect_meshes(child, groups)
