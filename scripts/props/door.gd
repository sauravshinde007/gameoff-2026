class_name Door
extends Node3D
## Static guest-room / entrance door. Never opens; shows room status on interact.
## room_id > 0 = guest room (status from RoomManager). room_id <= 0 = entrance (always locked).

@export var room_id: int = 0
@export var door_size: Vector3 = Vector3(0.9, 2.1, 0.1)
@export var handle_turn_degrees: float = 45.0
@export var handle_turn_seconds: float = 0.6

@onready var hinge: Node3D = $Hinge
@onready var leaf: CSGBox3D = $Hinge/Leaf
@onready var label: Label3D = $Hinge/Leaf/Label
@onready var handle: Node3D = $Hinge/Leaf/Handle
@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _handle_tween: Tween


func _ready() -> void:
	_apply_size()
	label.text = str(room_id)
	label.visible = room_id > 0
	interactable.interacted.connect(_on_interacted)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	_refresh_prompt()


## Phase 3 calls this (e.g. Room 2's handle slowly turning). seconds < 0 = use handle_turn_seconds.
func turn_handle(seconds: float = -1.0) -> void:
	if seconds < 0.0:
		seconds = handle_turn_seconds
	if _handle_tween != null:
		_handle_tween.kill()
	AudioManager.play_sfx(&"door_handle", global_position)
	_handle_tween = create_tween()
	var angle: float = -deg_to_rad(handle_turn_degrees)
	_handle_tween.tween_property(handle, "rotation:z", angle, seconds)
	_handle_tween.tween_interval(0.4)
	_handle_tween.tween_property(handle, "rotation:z", 0.0, seconds)


func _apply_size() -> void:
	var w: float = door_size.x
	hinge.position = Vector3(-w * 0.5, 0.0, 0.0)
	leaf.size = door_size
	leaf.position = Vector3(w * 0.5, 0.0, 0.0)
	label.position = Vector3(0.0, door_size.y * 0.31, door_size.z * 0.5 + 0.01)
	handle.position = Vector3(w * 0.5 - 0.1, -0.05, door_size.z * 0.5 + 0.04)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(w, door_size.y, 0.4)
	shape.shape = box


func _status_text() -> String:
	if room_id <= 0:
		return "Entrance – Locked"
	var room_name: String = "Room %d" % room_id
	match RoomManager.get_status(room_id):
		RoomData.Status.AVAILABLE:
			return "%s – Vacant" % room_name
		RoomData.Status.OCCUPIED:
			return "%s – Occupied" % room_name
		RoomData.Status.OUT_OF_ORDER:
			return "%s – Out of order" % room_name
	return "%s – Locked" % room_name


func _refresh_prompt() -> void:
	interactable.prompt_text = _status_text()


func _on_room_status_changed(changed_id: int, _status: int) -> void:
	if changed_id == room_id:
		_refresh_prompt()


func _on_interacted(_by: Node) -> void:
	var msg: String
	if room_id <= 0:
		if EventManager.has_flag(&"guest_vanished"):
			msg = "*The entrance door is still locked.*"
		else:
			msg = "The entrance door is locked."
	else:
		match RoomManager.get_status(room_id):
			RoomData.Status.AVAILABLE:
				msg = "Room %d is vacant. The door is locked." % room_id
			RoomData.Status.OCCUPIED:
				msg = "Room %d is occupied. Better not disturb them." % room_id
			_:
				msg = "Room %d is closed." % room_id
	AudioManager.play_sfx(&"door_locked", global_position)
	get_tree().call_group("hud", "show_message", msg)
