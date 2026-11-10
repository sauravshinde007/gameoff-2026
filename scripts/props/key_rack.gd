class_name KeyRack
extends Node3D
## Wall rack with one key hook per room. Take the key of an assigned room, then give it to the guest.

@onready var hooks: Array[Node3D] = [$Hook1, $Hook2, $Hook3]


func _ready() -> void:
	for i: int in hooks.size():
		var inter: Interactable = hooks[i].get_node("Interactable")
		inter.interacted.connect(_on_hook_interacted.bind(i + 1))
		(hooks[i].get_node("Label") as Label3D).text = str(i + 1)
	RoomManager.key_state_changed.connect(_refresh)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	_refresh()


func _on_room_status_changed(_room_id: int, _status: int) -> void:
	_refresh()


func _key_on_hook(room_id: int) -> bool:
	if RoomManager.issued_key_room_id == room_id:
		return false
	var room: RoomData = RoomManager.get_room(room_id)
	return not (room != null and room.status == RoomData.Status.OCCUPIED and room.key_issued)


func _refresh() -> void:
	for i: int in hooks.size():
		var on_hook: bool = _key_on_hook(i + 1)
		(hooks[i].get_node("Key") as Node3D).visible = on_hook
		var inter: Interactable = hooks[i].get_node("Interactable")
		inter.enabled = on_hook
		inter.prompt_text = "Take key (Room %d)" % (i + 1)


func _on_hook_interacted(_by: Node, room_id: int) -> void:
	var msg: String
	if RoomManager.take_key(room_id):
		msg = "Took the key to Room %d." % room_id
	elif RoomManager.issued_key_room_id != 0:
		msg = "Already holding a key."
	else:
		msg = "Room %d has no guest waiting for a key." % room_id
	get_tree().call_group("hud", "show_message", msg)
