class_name MaintenanceSystem
extends Node
## Room faults: a burnt-out bulb or a broken fitting in a vacant room. The room goes to
## Maintenance (so it cannot be assigned), its door unlocks, and one task is created. The fix
## happens at the room's RepairPoint. At most one fault per room, so no duplicate tasks.
## ShiftDirector decides when faults happen.

signal faults_changed()

enum Fault { BULB, REPAIR }

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")

var _faults: Dictionary[int, int] = {}
var _lights: Dictionary[int, float] = {}
var _task_ids: Dictionary[int, StringName] = {}
var _task_count: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_to_group(&"maintenance_system")


func fault_count() -> int:
	return _faults.size()


func has_fault(room_id: int) -> bool:
	return _faults.has(room_id)


## Fault enum value, or -1.
func get_fault(room_id: int) -> int:
	return _faults.get(room_id, -1)


## Carried items the fix needs.
func needs(room_id: int) -> Dictionary:
	return {&"bulbs": 1} if get_fault(room_id) == Fault.BULB else {}


func fix_seconds() -> float:
	return tuning.repair_seconds


func fault_text(room_id: int) -> String:
	return "Replace the bulb in Room %02d" % room_id if get_fault(room_id) == Fault.BULB \
			else "Repair Room %02d" % room_id


## Break something in `room_id` (0 = a random vacant, working room). false if not possible.
func create_fault(kind: Fault, room_id: int = 0) -> bool:
	if room_id == 0:
		room_id = _pick_room()
	if room_id == 0 or _faults.has(room_id):
		return false
	if not RoomManager.set_maintenance(room_id, true):
		return false
	_faults[room_id] = kind
	if kind == Fault.BULB:
		var light: OmniLight3D = _find_light(room_id)
		if light != null:
			_lights[room_id] = light.light_energy
			light.light_energy = 0.0
	_task_count += 1
	_task_ids[room_id] = StringName("fault_room_%d_%d" % [room_id, _task_count])
	var task: TaskData = TaskData.new()
	task.id = _task_ids[room_id]
	task.text = fault_text(room_id)
	task.category = &"maintenance"
	task.room_id = room_id
	TaskManager.add_task(task)
	faults_changed.emit()
	return true


## The physical repair succeeded. Restores the room, completes the task.
func resolve(room_id: int) -> bool:
	if not _faults.has(room_id):
		return false
	if _lights.has(room_id):
		var light: OmniLight3D = _find_light(room_id)
		if light != null:
			light.light_energy = _lights[room_id]
		_lights.erase(room_id)
	_faults.erase(room_id)
	RoomManager.set_maintenance(room_id, false)
	TaskManager.complete_task(_task_ids[room_id])
	_task_ids.erase(room_id)
	faults_changed.emit()
	return true


func _pick_room() -> int:
	var candidates: Array[int] = []
	for r: RoomData in RoomManager.get_rooms():
		if r.status == RoomData.Status.AVAILABLE and not _faults.has(r.id):
			candidates.append(r.id)
	return candidates[_rng.randi() % candidates.size()] if not candidates.is_empty() else 0


func _find_light(room_id: int) -> OmniLight3D:
	for node: Node in get_tree().get_nodes_in_group(&"room_doors"):
		var door: Door = node as Door
		if door.room_id == room_id and door.get_parent() != null:
			return door.get_parent().get_node_or_null("Light") as OmniLight3D
	return null
