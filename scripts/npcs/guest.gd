class_name Guest
extends StaticBody3D
## Ordinary check-in guest. Talk -> player assigns a room on the computer -> player takes the key
## from the rack -> talk again to hand it over -> guest walks away along `leave_path` and disappears.

signal checked_in(reservation_id: String)

@export var reservation_id: String = "#0001"
@export var dialogue_ask: DialogueData
@export var dialogue_remind_room: DialogueData
@export var dialogue_remind_key: DialogueData
@export var dialogue_handover: DialogueData
## World-space waypoints the guest walks through after check-in.
@export var leave_path: PackedVector3Array = PackedVector3Array([Vector3(3, 0, 1.5), Vector3(3, 0, 5.2)])
## Optional door the guest opens on the way out (relative to this node). Empty = no door.
@export var exit_door_path: NodePath
## The door opens when the guest comes within this distance (metres, horizontal)...
@export var exit_door_open_distance: float = 1.8
## ...and closes again once she is further than this on the other side.
@export var exit_door_close_distance: float = 2.4
@export var walk_speed: float = 2.8
## Task completed when the key is handed over.
@export var check_in_task_id: StringName = &"check_in_guest"

@onready var interactable: Interactable = $Interactable
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var model: RetroModel = get_node_or_null(^"Model") as RetroModel

var _asked: bool = false
var _handing_over: bool = false
var _done: bool = false
var _exit_door: Node3D
var _door_opened: bool = false


func _ready() -> void:
	set_process(false)
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)


func _on_interacted(by: Node) -> void:
	if _done or DialogueManager.is_active():
		return
	NpcFacing.face(self, by as Node3D)
	var res: ReservationData = RoomManager.get_reservation(reservation_id)
	if res == null:
		return
	if res.status == ReservationData.Status.PENDING:
		if _asked:
			DialogueManager.start(dialogue_remind_room)
		else:
			_asked = true
			DialogueManager.start(dialogue_ask)
	elif res.status == ReservationData.Status.CHECKED_IN:
		if RoomManager.issued_key_room_id == res.room_id:
			_handing_over = true
			DialogueManager.start(dialogue_handover)
		else:
			DialogueManager.start(dialogue_remind_key)


func _on_dialogue_finished(id: StringName, _choice: int) -> void:
	if not _handing_over or id != dialogue_handover.id:
		return
	_handing_over = false
	var res: ReservationData = RoomManager.get_reservation(reservation_id)
	if res != null and RoomManager.hand_over_key(res.room_id):
		_done = true
		TaskManager.complete_task(check_in_task_id)
		checked_in.emit(reservation_id)
		_leave()


func _leave() -> void:
	interactable.enabled = false
	body_shape.set_deferred("disabled", true)
	if model != null:
		model.play(&"walk")
	if not exit_door_path.is_empty():
		_exit_door = get_node_or_null(exit_door_path) as Node3D
	set_process(_exit_door != null and _exit_door.has_method("set_open"))
	var tween: Tween = create_tween()
	var from: Vector3 = global_position
	for point: Vector3 in leave_path:
		tween.tween_callback(_face.bind(point))
		tween.tween_property(self, "global_position", point, from.distance_to(point) / walk_speed)
		from = point
	tween.tween_callback(_finish_leave)


## Opens the exit door as the guest approaches it and closes it once she is through.
func _process(_delta: float) -> void:
	var to_door: Vector3 = _exit_door.global_position - global_position
	to_door.y = 0.0
	var dist: float = to_door.length()
	if not _door_opened and dist < exit_door_open_distance:
		_door_opened = true
		_exit_door.call("set_open", true)
	elif _door_opened and dist > exit_door_close_distance:
		_door_opened = false
		_exit_door.call("set_open", false)
		set_process(false)


func _finish_leave() -> void:
	if _door_opened and _exit_door != null:
		_exit_door.call("set_open", false)
	set_process(false)
	hide()


func _face(point: Vector3) -> void:
	var target: Vector3 = Vector3(point.x, global_position.y, point.z)
	if target.distance_to(global_position) > 0.01:
		look_at(target)
