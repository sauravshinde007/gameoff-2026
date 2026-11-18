class_name RepairPoint
extends Node3D
## Toolbox inside a guest room. Usable only while the room has a fault (Maintenance).
## A bulb fault needs one carried bulb. The repair takes a few seconds.

@export var room_id: int = 0
@export var point_size: Vector3 = Vector3(0.7, 0.8, 0.7)

@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _busy: bool = false
var _system: MaintenanceSystem = null


func _ready() -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = point_size
	shape.shape = box
	shape.position = Vector3(0.0, point_size.y * 0.5, 0.0)
	interactable.interacted.connect(_on_interacted)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	_find_system.call_deferred()
	_refresh()


func _find_system() -> void:
	_system = get_tree().get_first_node_in_group(&"maintenance_system") as MaintenanceSystem
	if _system != null:
		_system.faults_changed.connect(_refresh)
	_refresh()


func _on_room_status_changed(changed_id: int, _status: int) -> void:
	if changed_id == room_id:
		_refresh()


func _refresh() -> void:
	var broken: bool = _system != null and _system.has_fault(room_id)
	interactable.enabled = broken and not _busy
	if broken:
		interactable.prompt_text = "Replace bulb (Room %02d)" % room_id \
				if _system.get_fault(room_id) == MaintenanceSystem.Fault.BULB \
				else "Repair Room %02d" % room_id


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)


func _on_interacted(_by: Node) -> void:
	if _system == null or not _system.has_fault(room_id):
		return
	var needs: Dictionary = _system.needs(room_id)
	if not InventoryManager.has_carried_all(needs):
		_say("Need: %s." % ", ".join(InventoryManager.missing_names(needs)))
		return
	_busy = true
	_refresh()
	var caption: String = "Replacing the bulb in Room %02d..." % room_id \
			if _system.get_fault(room_id) == MaintenanceSystem.Fault.BULB \
			else "Repairing Room %02d..." % room_id
	WorkTransition.run(get_tree(), caption, _system.fix_seconds(), _finish_repair)


func _finish_repair() -> void:
	_busy = false
	if not _system.has_fault(room_id):
		_refresh()
		return
	if not InventoryManager.consume_carried(_system.needs(room_id)):
		_say("You no longer have what is needed.")
		_refresh()
		return
	_system.resolve(room_id)
	_say("Room %02d is fixed." % room_id)
