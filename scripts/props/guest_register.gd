class_name GuestRegister
extends Node3D
## Guest register: lists rooms and tonight's reservations. Reading it can complete a task.

@export var read_task_id: StringName = &"read_register"

@onready var interactable: Interactable = $Interactable
@onready var note_panel: NotePanel = $NotePanel


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	note_panel.open("GUEST REGISTER", _build_text())
	TaskManager.complete_task(read_task_id)


func _build_text() -> String:
	var out: String = "ROOMS\n"
	for room: RoomData in RoomManager.get_rooms():
		var who: String = room.guest_name if room.status == RoomData.Status.OCCUPIED \
				else RoomManager.status_text(room.status).capitalize()
		out += "  %s: %s\n" % [room.display_name, who]
	out += "\nTONIGHT'S RESERVATIONS\n"
	for res: ReservationData in RoomManager.get_reservations():
		var where: String = "not assigned"
		var room: RoomData = RoomManager.get_room(res.room_id)
		if room != null:
			where = room.display_name
		out += "  %s  %s  (%s)\n" % [res.id, res.guest_name, where]
	return out
