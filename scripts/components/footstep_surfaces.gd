class_name FootstepSurfaces
extends RefCounted
## Finds which surface (wood, stone, dirt...) is under a point, for footstep sounds.
##
## The motel floors are flat CSG boxes, and many of them (asphalt, paths, rugs, bathroom tiles)
## are thin overlays with no collision lying on a bigger collider (ground, room floor). So instead
## of asking physics, every flat CSGBox3D with a known surface is collected once into a list;
## a query returns the highest floor whose top face is just under the feet.
##
## A box counts if it has `footstep_surface` metadata, or its material is listed in the bank.

## Boxes thicker than this are not floors (walls, furniture), unless tagged with metadata.
const MAX_FLOOR_THICKNESS: float = 0.35
## How far the feet may be above / below a floor's top face and still be standing on it.
const ABOVE_TOLERANCE: float = 0.35
const BELOW_TOLERANCE: float = 0.25

class Floor:
	var inverse: Transform3D
	var half: Vector3
	var top_y: float
	var surface: StringName

static var _floors: Array[Floor] = []
## Floor boxes whose CSG nodes were baked away (CsgBaker): {xform, size, material_path, meta}.
static var _baked: Array[Dictionary] = []
static var _scanned_scene_id: int = 0


## Surface id under `feet` (world position of the feet), or the bank's default.
static func query(tree: SceneTree, bank: FootstepBank, feet: Vector3) -> StringName:
	_ensure_scanned(tree, bank)
	var best: StringName = bank.default_surface
	var best_top: float = -INF
	for f: Floor in _floors:
		var local: Vector3 = f.inverse * feet
		if absf(local.x) > f.half.x or absf(local.z) > f.half.z:
			continue
		if local.y > f.half.y + ABOVE_TOLERANCE or local.y < f.half.y - BELOW_TOLERANCE:
			continue
		if f.top_y > best_top:
			best_top = f.top_y
			best = f.surface
	return best


## Forces a rescan on the next query (call after building or moving floors at runtime).
static func invalidate() -> void:
	_scanned_scene_id = 0


## Called by CsgBaker for each CSGBox3D it is about to remove, so its surface is still found.
static func register_baked(xform: Transform3D, size: Vector3, material_path: String, meta_surface: StringName) -> void:
	_baked.append({"xform": xform, "size": size, "material_path": material_path, "meta": meta_surface})
	invalidate()


static func clear_baked() -> void:
	_baked.clear()
	invalidate()


static func _ensure_scanned(tree: SceneTree, bank: FootstepBank) -> void:
	var scene: Node = tree.current_scene
	var scene_id: int = scene.get_instance_id() if scene != null else -1
	if scene_id == _scanned_scene_id and not _floors.is_empty():
		return
	_scanned_scene_id = scene_id
	_floors.clear()
	for node: Node in tree.root.find_children("*", "CSGBox3D", true, false):
		var box: CSGBox3D = node as CSGBox3D
		if not box.is_visible_in_tree():
			continue
		var surface: StringName = _surface_of(box, bank)
		if surface == &"":
			continue
		var f: Floor = Floor.new()
		f.inverse = box.global_transform.affine_inverse()
		f.half = box.size * 0.5
		f.top_y = (box.global_transform * Vector3(0.0, f.half.y, 0.0)).y
		f.surface = surface
		_floors.append(f)
	for entry: Dictionary in _baked:
		var size: Vector3 = entry.size
		var surface: StringName = entry.meta
		if surface == &"":
			if size.y > MAX_FLOOR_THICKNESS or entry.material_path == "":
				continue
			surface = bank.material_surfaces.get(entry.material_path, &"")
			if surface == &"":
				continue
		var xform: Transform3D = entry.xform
		var f: Floor = Floor.new()
		f.inverse = xform.affine_inverse()
		f.half = size * 0.5
		f.top_y = (xform * Vector3(0.0, f.half.y, 0.0)).y
		f.surface = surface
		_floors.append(f)


static func _surface_of(box: CSGBox3D, bank: FootstepBank) -> StringName:
	if box.has_meta(&"footstep_surface"):
		return StringName(box.get_meta(&"footstep_surface"))
	if box.size.y > MAX_FLOOR_THICKNESS or box.material == null:
		return &""
	return bank.material_surfaces.get(box.material.resource_path, &"")
