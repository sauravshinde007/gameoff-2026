class_name CsgBaker
extends Node
## Replaces static CSG level geometry with plain meshes plus one trimesh collider per chunk.
##
## CSG roots are authored one node per box, so the motel is hundreds of separate meshes and draw
## calls. A few frames after the scene starts, this bakes every eligible CSG root (Godot 4.4+
## bake_static_mesh / bake_collision_shape) and merges the results per instanced scene and
## material into one MeshInstance3D + one StaticBody3D. The source scenes stay editable as CSG.
##
## Only CSG that belongs to a scene in `bake_scenes` is touched, and never:
##   - CSG with a script, in group "no_bake", or with a collision layer/mask other than 1;
##   - CSG under a physics body (moving props);
##   - CSG an Interactable's meshless highlight would pick (supply shelves etc.).
## CSGBox3D floors are handed to FootstepSurfaces first so footstep sounds keep working.

signal finished(stats: Dictionary)

## Scenes whose own CSG is static architecture. Anything else (doors, windows, props that
## script their materials) keeps its CSG.
@export var bake_scenes: PackedStringArray = PackedStringArray([
	"res://scenes/environment/motel_property.tscn",
	"res://scenes/environment/exterior.tscn",
	"res://scenes/environment/hallway.tscn",
	"res://scenes/environment/reception.tscn",
	"res://scenes/environment/guest_rooms/guest_room_shell.tscn",
	"res://scenes/environment/guest_rooms/guest_room_base.tscn",
	"res://scenes/environment/service/storage_room.tscn",
	"res://scenes/environment/service/laundry_room.tscn",
	"res://scenes/environment/service/owners_office.tscn",
	"res://scenes/environment/service/staff_corridor.tscn",
	"res://scenes/environment/modules/highway.tscn",
	"res://scenes/environment/modules/walkway_pillar.tscn",
	"res://scenes/environment/modules/door_frame.tscn",
	"res://scenes/props/exterior/street_lamp.tscn",
])
@export var enabled: bool = true
## Frames to wait so CSG has built its meshes and room scripts have finished _ready.
@export var wait_frames: int = 3
## Chunks baked per frame (spreads the one-off cost).
@export var chunks_per_frame: int = 2
@export var verbose: bool = false

class Chunk:
	var root: Node3D
	var layers: int
	var cast_shadow: int
	var vis_end: float
	var shapes: Array[CSGShape3D] = []


func _ready() -> void:
	if enabled:
		_run.call_deferred()


func _exit_tree() -> void:
	FootstepSurfaces.clear_baked()


func _run() -> void:
	for i: int in wait_frames:
		await get_tree().process_frame
	var scan_root: Node = get_parent()
	var csg_roots: Array[CSGShape3D] = []
	var protect: Array[AABB] = []
	_collect(scan_root, csg_roots, protect)
	var chunks: Dictionary[String, Chunk] = {}
	var skipped: int = 0
	for shape: CSGShape3D in csg_roots:
		var chunk_root: Node3D = _chunk_root_of(shape)
		if chunk_root == null or not _eligible(shape, chunk_root, protect):
			skipped += 1
			continue
		var key: String = "%d|%d|%d|%s" % [chunk_root.get_instance_id(), shape.layers,
				shape.cast_shadow, str(shape.visibility_range_end)]
		if not chunks.has(key):
			var c: Chunk = Chunk.new()
			c.root = chunk_root
			c.layers = shape.layers
			c.cast_shadow = shape.cast_shadow
			c.vis_end = shape.visibility_range_end
			chunks[key] = c
		chunks[key].shapes.append(shape)
	var stats: Dictionary = {"roots_found": csg_roots.size(), "roots_skipped": skipped,
			"roots_baked": 0, "chunks": 0, "surfaces": 0, "bodies": 0, "faces": 0}
	var done: int = 0
	for chunk: Chunk in chunks.values():
		if not is_instance_valid(chunk.root):
			continue
		_bake_chunk(chunk, stats)
		done += 1
		if done % maxi(chunks_per_frame, 1) == 0:
			await get_tree().process_frame
	FootstepSurfaces.invalidate()
	if verbose:
		print("[CsgBaker] ", stats)
	finished.emit(stats)


func _collect(node: Node, out_roots: Array[CSGShape3D], protect: Array[AABB]) -> void:
	if node is CSGShape3D:
		var csg: CSGShape3D = node
		if csg.is_root_shape():
			out_roots.append(csg)
		return  # CSG children belong to their root.
	if node is Interactable:
		_add_protect_boxes(node as Interactable, protect)
	for child: Node in node.get_children():
		_collect(child, out_roots, protect)


## World-space boxes of every interactable's collision shapes (the meshless-highlight zones).
func _add_protect_boxes(interactable: Interactable, protect: Array[AABB]) -> void:
	for child: Node in interactable.get_children():
		var cs: CollisionShape3D = child as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var local: AABB = cs.shape.get_debug_mesh().get_aabb()
		protect.append(cs.global_transform * local)


## Nearest instanced scene above the shape (its own scene file decides if it may be baked).
func _chunk_root_of(shape: CSGShape3D) -> Node3D:
	var n: Node = shape.get_parent()
	while n != null:
		if n.scene_file_path != "":
			return n as Node3D
		n = n.get_parent()
	return null


func _eligible(shape: CSGShape3D, chunk_root: Node3D, protect: Array[AABB]) -> bool:
	if not bake_scenes.has(chunk_root.scene_file_path):
		return false
	if not shape.is_visible_in_tree() or shape.is_in_group(&"no_bake") or shape.has_meta(&"no_bake"):
		return false
	if shape.use_collision and (shape.collision_layer != 1 or shape.collision_mask != 1):
		return false
	var n: Node = shape.get_parent()
	while n != null and n != chunk_root:
		if n is CollisionObject3D or n.is_in_group(&"no_bake"):
			return false
		n = n.get_parent()
	if _has_script(shape):
		return false
	var world: AABB = shape.global_transform * shape.get_aabb()
	for zone: AABB in protect:
		# Same test Interactable uses to pick meshes for a meshless point.
		if zone.has_point(world.get_center()) and world.size.x <= zone.size.x * 2.0 \
				and world.size.y <= zone.size.y * 2.0 and world.size.z <= zone.size.z * 2.0:
			return false
	return true


func _has_script(node: Node) -> bool:
	if node.get_script() != null:
		return true
	for child: Node in node.get_children():
		if _has_script(child):
			return true
	return false


func _bake_chunk(chunk: Chunk, stats: Dictionary) -> void:
	var to_chunk: Transform3D = chunk.root.global_transform.affine_inverse()
	var surfaces: Dictionary = {}  # Material (or null) -> SurfaceTool
	var faces: PackedVector3Array = PackedVector3Array()
	var baked: Array[CSGShape3D] = []
	for shape: CSGShape3D in chunk.shapes:
		if not is_instance_valid(shape):
			continue
		var mesh: ArrayMesh = shape.bake_static_mesh()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var xf: Transform3D = to_chunk * shape.global_transform
		for s: int in mesh.get_surface_count():
			var mat: Material = mesh.surface_get_material(s)
			if not surfaces.has(mat):
				var st: SurfaceTool = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				surfaces[mat] = st
			(surfaces[mat] as SurfaceTool).append_from(mesh, s, xf)
		if shape.use_collision:
			var collider: ConcavePolygonShape3D = shape.bake_collision_shape()
			if collider != null:
				for v: Vector3 in collider.get_faces():
					faces.append(xf * v)
		_register_footstep_floors(shape)
		baked.append(shape)
	if baked.is_empty():
		return
	var merged: ArrayMesh = ArrayMesh.new()
	for mat: Variant in surfaces.keys():
		var st: SurfaceTool = surfaces[mat]
		st.set_material(mat as Material)
		st.commit(merged)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "BakedCSG"
	instance.mesh = merged
	instance.layers = chunk.layers
	instance.cast_shadow = chunk.cast_shadow as GeometryInstance3D.ShadowCastingSetting
	if chunk.vis_end > 0.0:
		instance.visibility_range_end = chunk.vis_end
		instance.visibility_range_end_margin = 1.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	chunk.root.add_child(instance)
	if not faces.is_empty():
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "BakedCSGBody"
		var cs: CollisionShape3D = CollisionShape3D.new()
		var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		concave.set_faces(faces)
		cs.shape = concave
		body.add_child(cs)
		chunk.root.add_child(body)
		stats.bodies += 1
		stats.faces += faces.size() / 3
	for shape: CSGShape3D in baked:
		shape.queue_free()
	stats.roots_baked += baked.size()
	stats.chunks += 1
	stats.surfaces += merged.get_surface_count()


## Floors are found by scanning CSGBox3D nodes; hand them over before the nodes go away.
func _register_footstep_floors(shape: CSGShape3D) -> void:
	var boxes: Array[Node] = shape.find_children("*", "CSGBox3D", true, false)
	boxes.append(shape)
	for node: Node in boxes:
		var box: CSGBox3D = node as CSGBox3D
		if box == null or not box.is_visible_in_tree():
			continue
		var mat_path: String = box.material.resource_path if box.material != null else ""
		var meta: StringName = StringName(box.get_meta(&"footstep_surface")) if box.has_meta(&"footstep_surface") else &""
		FootstepSurfaces.register_baked(box.global_transform, box.size, mat_path, meta)
