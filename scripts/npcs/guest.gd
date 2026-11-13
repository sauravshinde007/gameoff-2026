class_name Guest
extends StaticBody3D
## Ordinary check-in guest. Talk -> player assigns a room on the computer -> player takes the key
## from the rack -> talk again to hand it over -> guest walks to the hallway and disappears.

signal checked_in(reservation_id: String)

@export var reservation_id: String = "#0001"
@export var dialogue_ask: DialogueData
@export var dialogue_remind_room: DialogueData
@export var dialogue_remind_key: DialogueData
@export var dialogue_handover: DialogueData
## World-space waypoints the guest walks through after check-in.
@export var leave_path: PackedVector3Array = PackedVector3Array([Vector3(3, 0, 1.5), Vector3(3, 0, 5.2)])
@export var walk_speed: float = 2.8
## Task completed when the key is handed over.
@export var check_in_task_id: StringName = &"check_in_guest"

@onready var interactable: Interactable = $Interactable
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var model: RetroModel = get_node_or_null(^"Model") as RetroModel

var _asked: bool = false
var _handing_over: bool = false
var _done: bool = false


func _ready() -> void:
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
	var tween: Tween = create_tween()
	for point: Vector3 in leave_path:
		tween.tween_callback(_face.bind(point))
		var dist: float = global_position.distance_to(point)
		tween.tween_property(self, "global_position", point, dist / walk_speed)
	tween.tween_callback(hide)


func _face(point: Vector3) -> void:
	var target: Vector3 = Vector3(point.x, global_position.y, point.z)
	if target.distance_to(global_position) > 0.01:
		look_at(target)
