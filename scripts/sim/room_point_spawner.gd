class_name RoomPointSpawner
extends Node
## Places one service tray (outside), one cleaning bucket and one toolbox (inside) at every guest room door.
## Positions come from the door transforms, so they follow the rooms if the layout moves.

@export var service_scene: PackedScene = preload("res://scenes/props/sim/room_service_point.tscn")
@export var cleaning_scene: PackedScene = preload("res://scenes/props/sim/cleaning_point.tscn")
## Door-local offsets: x = sideways along the wall, y = world height, z = outward (walkway side).
@export var service_offset: Vector3 = Vector3(0.85, 0.95, 0.15)
## Rooms are 6 m deep with the door 3 m in front of the room centre, so z = -3 is the middle.
@export var cleaning_offset: Vector3 = Vector3(-0.4, 0.0, -3.0)
@export var repair_scene: PackedScene = preload("res://scenes/props/sim/repair_point.tscn")
@export var repair_offset: Vector3 = Vector3(0.4, 0.0, -3.0)


func _ready() -> void:
	_spawn.call_deferred()


func _spawn() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"room_doors"):
		var door: Door = node as Door
		_place(service_scene, door, service_offset)
		_place(cleaning_scene, door, cleaning_offset)
		_place(repair_scene, door, repair_offset)


func _place(scene: PackedScene, door: Door, offset: Vector3) -> void:
	var point: Node3D = scene.instantiate() as Node3D
	point.set("room_id", door.room_id)
	add_child(point)
	var basis: Basis = door.global_basis.orthonormalized()
	var pos: Vector3 = door.global_position + basis * Vector3(offset.x, 0.0, offset.z)
	pos.y = offset.y
	point.global_transform = Transform3D(basis, pos)
