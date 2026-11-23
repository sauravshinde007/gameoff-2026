class_name GuestRoomInterior
extends Node3D
## Furniture set for a guest room, placed as a child of a GuestRoomShell (same local frame).
## One reusable layout; rooms differ by mirroring, colours and optional extra props.

## Flips the whole layout left/right (bathroom and bed swap sides).
@export var mirrored: bool = false
@export var bedspread_color: Color = Color(0.55, 0.2, 0.2, 1.0)
@export var rug_color: Color = Color(0.22, 0.28, 0.35, 1.0)
## Optional extras that make rooms feel individual.
@export var suitcase: bool = false
@export var armchair: bool = false
## Furniture further than this from the camera is not drawn (renderer visibility range, so no CSG
## rebuild and no collision change). 0 disables. Hides far rooms' contents and their shadow passes.
@export var cull_distance: float = 10.0

@onready var furniture: Node3D = $Furniture


func _ready() -> void:
	if not suitcase:
		$Furniture/Suitcase.queue_free()
	if not armchair:
		$Furniture/Armchair.queue_free()
	if cull_distance > 0.0:
		_set_visibility_range(furniture)
	_tint($Furniture/Bed/Bedspread, bedspread_color)
	_tint($Furniture/Rug/Mat, rug_color)
	if mirrored:
		for item: Node in furniture.get_children():
			if item is Node3D and not item.is_queued_for_deletion():
				var node: Node3D = item
				node.position.x = -node.position.x
				node.rotation.y = -node.rotation.y


## Every instance gets its own material so colours don't leak between rooms.
func _tint(box: CSGBox3D, color: Color) -> void:
	var mat: StandardMaterial3D = (box.material as StandardMaterial3D).duplicate()
	mat.albedo_color = color
	box.material = mat


func _set_visibility_range(node: Node) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is GeometryInstance3D:
			var geo: GeometryInstance3D = child
			geo.visibility_range_end = cull_distance
			geo.visibility_range_end_margin = 1.0
			geo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		_set_visibility_range(child)
