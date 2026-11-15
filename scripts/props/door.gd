class_name Door
extends Node3D
## Guest-room / entrance door. Static (locked, shows room status) unless `openable` is set.
## room_id > 0 = guest room (status from RoomManager). room_id <= 0 = entrance.

@export var room_id: int = 0
## Prompt/message name for non-guest-room doors (office, laundry...). Empty = "Entrance" or "Room NN".
@export var door_name: String = ""
@export var door_size: Vector3 = Vector3(0.9, 2.1, 0.1)
@export var handle_turn_degrees: float = 45.0
@export var handle_turn_seconds: float = 0.6
@export_group("Opening")
## When true, interacting swings the door open/closed instead of showing the locked message.
@export var openable: bool = false
## Once this EventManager flag is set the door closes and behaves as locked. Empty = never locks.
@export var lock_flag: StringName = &""
## Swing angle. Positive opens away from the labelled (front) face.
@export var open_degrees: float = 95.0
@export var open_seconds: float = 0.5

@onready var hinge: Node3D = $Hinge
@onready var leaf: CSGBox3D = $Hinge/Leaf
@onready var label: Label3D = $Hinge/Leaf/Label
@onready var handle: Node3D = $Hinge/Leaf/Handle
@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _handle_tween: Tween
var _swing_tween: Tween
var _is_open: bool = false


func _ready() -> void:
	_apply_size()
	label.text = "%02d" % room_id
	label.visible = room_id > 0
	interactable.interacted.connect(_on_interacted)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	EventManager.flag_set.connect(_on_flag_set)
	_refresh_prompt()


func is_locked() -> bool:
	if not openable:
		return true
	return lock_flag != &"" and EventManager.has_flag(lock_flag)


func set_open(open: bool) -> void:
	if open == _is_open:
		return
	_is_open = open
	if _swing_tween != null:
		_swing_tween.kill()
	AudioManager.play_sfx(&"door_open" if open else &"door_close", global_position)
	var target: float = deg_to_rad(open_degrees) if open else 0.0
	_swing_tween = create_tween()
	_swing_tween.tween_property(hinge, "rotation:y", target, open_seconds)
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
	if not is_locked():
		return "%s – %s" % [_display_name(), "Close" if _is_open else "Open"]
	if room_id <= 0:
		return "%s – Locked" % _display_name()
	var room_name: String = "Room %02d" % room_id
	match RoomManager.get_status(room_id):
		RoomData.Status.AVAILABLE:
			return "%s – Vacant" % room_name
		RoomData.Status.OCCUPIED:
			return "%s – Occupied" % room_name
		RoomData.Status.OUT_OF_ORDER:
			return "%s – Out of order" % room_name
	return "%s – Locked" % room_name


func _display_name() -> String:
	if door_name != "":
		return door_name
	return "Room %02d" % room_id if room_id > 0 else "Entrance"


func _refresh_prompt() -> void:
	interactable.prompt_text = _status_text()


func _on_room_status_changed(changed_id: int, _status: int) -> void:
	if changed_id == room_id:
		_refresh_prompt()


func _on_flag_set(flag: StringName) -> void:
	if openable and flag == lock_flag:
		set_open(false)
		_refresh_prompt()


func _on_interacted(_by: Node) -> void:
	if not is_locked():
		set_open(not _is_open)
		return
	var msg: String
	if room_id <= 0:
		msg = "The %s door is locked." % _display_name().to_lower()
	else:
		match RoomManager.get_status(room_id):
			RoomData.Status.AVAILABLE:
				msg = "Room %02d is vacant. The door is locked." % room_id
			RoomData.Status.OCCUPIED:
				msg = "Room %02d is occupied. Better not disturb them." % room_id
			_:
				msg = "Room %02d is closed." % room_id
	AudioManager.play_sfx(&"door_locked", global_position)
	get_tree().call_group("hud", "show_message", msg)
