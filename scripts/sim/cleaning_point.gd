class_name CleaningPoint
extends Node3D
## Cleaning bucket inside a guest room. Only usable while the room Needs Cleaning.
## Uses up the carried supplies listed in SupplyCatalog.clean_cost, takes a few seconds,
## then the room becomes Available.

@export var room_id: int = 0
@export var point_size: Vector3 = Vector3(0.7, 0.8, 0.7)

@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _busy: bool = false


func _ready() -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = point_size
	shape.shape = box
	shape.position = Vector3(0.0, point_size.y * 0.5, 0.0)
	interactable.prompt_text = "Clean Room %02d" % room_id
	interactable.interacted.connect(_on_interacted)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	_refresh()


func _on_room_status_changed(changed_id: int, _status: int) -> void:
	if changed_id == room_id:
		_refresh()


func _refresh() -> void:
	var dirty: bool = RoomManager.get_status(room_id) == RoomData.Status.NEEDS_CLEANING
	interactable.enabled = dirty and not _busy


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)


func _on_interacted(_by: Node) -> void:
	var cost: Dictionary = InventoryManager.catalog.clean_cost
	if not InventoryManager.has_carried_all(cost):
		_say("Need: %s." % ", ".join(InventoryManager.missing_names(cost)))
		return
	_busy = true
	_refresh()
	WorkTransition.run(get_tree(), "Cleaning Room %02d..." % room_id,
			InventoryManager.catalog.clean_seconds, _finish_cleaning)


func _finish_cleaning() -> void:
	_busy = false
	var cost: Dictionary = InventoryManager.catalog.clean_cost
	if RoomManager.get_status(room_id) != RoomData.Status.NEEDS_CLEANING:
		_refresh()
		return
	if not InventoryManager.consume_carried(cost):
		_say("You no longer have the supplies.")
		_refresh()
		return
	RoomManager.mark_clean(room_id)
	_refresh()
	_say("Room %02d is clean." % room_id)
