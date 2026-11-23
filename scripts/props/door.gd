class_name Door
extends Node3D
## Guest-room / entrance door. Static (locked, shows room status) unless `openable` is set.
## room_id > 0 = guest room (status from RoomManager). room_id <= 0 = entrance.

## Emitted when the player uses the key action (see set_key_action). The shift scene decides
## what happens (e.g. unlock at the start of the day, lock up at the end).
signal key_requested(action: String, by: Node)

@export var room_id: int = 0
## Prompt/message name for non-guest-room doors (office, laundry...). Empty = "Entrance" or "Room NN".
@export var door_name: String = ""
@export var door_size: Vector3 = Vector3(0.9, 2.1, 0.1)
@export var handle_turn_degrees: float = 45.0
@export var handle_turn_seconds: float = 0.6
## Door model from assets/models/props/doors (door_01 .. door_15). 0 = plain wooden box leaf.
## The model is stretched to door_size; the box leaf stays as the (invisible) collider.
@export_range(0, 15) var model_variant: int = 0
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
## Under the leaf, so the interaction box swings with the door (it can be closed while open).
@onready var interactable: Interactable = $Hinge/Leaf/Interactable
@onready var shape: CollisionShape3D = $Hinge/Leaf/Interactable/CollisionShape3D

const DOOR_MODEL_PATH: String = "res://assets/models/props/doors/door_%02d.glb"
## Variants whose knob is modelled on the left: turned 180 degrees so it sits on the handle side.
const KNOB_LEFT_VARIANTS: Array[int] = [1, 2, 3, 4]

var _handle_tween: Tween
var _swing_tween: Tween
var _is_open: bool = false
## +1 = swings away from the labelled (front) face, -1 = away from the back face.
var _swing_sign: float = 1.0
## Key lock set by the shift scene (reception front door). Locked doors never open for the player.
var _key_locked: bool = false
## Key action offered to the player ("Unlock", "Lock"); empty = none. Overrides the open/close prompt.
var _key_action: String = ""


func _ready() -> void:
	_apply_size()
	_apply_model()
	if room_id > 0:
		add_to_group(&"room_doors")
	elif room_id == -1:
		add_to_group(&"entrance_doors")
	label.text = "%02d" % room_id
	# Model doors carry no painted number (the room's wall plate shows it).
	label.visible = room_id > 0 and model_variant <= 0
	interactable.interacted.connect(_on_interacted)
	RoomManager.room_status_changed.connect(_on_room_status_changed)
	EventManager.flag_set.connect(_on_flag_set)
	_refresh_prompt()


func is_locked() -> bool:
	if _key_locked:
		return true
	if not openable:
		return true
	# A guest's room stays locked while they have it. Guests open their own door through set_open().
	if room_id > 0 and RoomManager.get_status(room_id) == RoomData.Status.OCCUPIED:
		return true
	return lock_flag != &"" and EventManager.has_flag(lock_flag)


## `opener` (player or guest) decides the swing direction: the door always swings away from them,
## so it opens from both sides. Closing swings back along the same arc.
func set_open(open: bool, opener: Node3D = null) -> void:
	if open == _is_open:
		return
	_is_open = open
	if open and opener != null:
		var offset: Vector3 = opener.global_position - global_position
		_swing_sign = 1.0 if offset.dot(global_basis.z) >= 0.0 else -1.0
	if _swing_tween != null:
		_swing_tween.kill()
	AudioManager.play_sfx(&"door_open" if open else &"door_close", global_position)
	var target: float = deg_to_rad(open_degrees) * _swing_sign if open else 0.0
	_swing_tween = create_tween()
	_swing_tween.tween_property(hinge, "rotation:y", target, open_seconds)
	_refresh_prompt()


func set_key_locked(locked: bool) -> void:
	_key_locked = locked
	if locked:
		set_open(false)
	_refresh_prompt()


## Offer a key action to the player instead of open/close. Interacting emits key_requested.
func set_key_action(action: String) -> void:
	_key_action = action
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


func _apply_model() -> void:
	if model_variant <= 0:
		return
	var scene: PackedScene = load(DOOR_MODEL_PATH % model_variant) as PackedScene
	if scene == null:
		push_warning("Door: missing model variant %d" % model_variant)
		return
	var model: Node3D = scene.instantiate() as Node3D
	model.name = "Model"
	model.set_script(RetroModel)
	leaf.add_child(model)
	var box: AABB = _mesh_aabb(model)
	if box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
		return
	var fit: Basis = Basis.from_scale(door_size / box.size)
	if model_variant in KNOB_LEFT_VARIANTS:
		fit = Basis(Vector3.UP, PI) * fit
	# Model origin is its bottom centre; the leaf origin is the door's centre.
	model.transform = Transform3D(fit, Vector3(0.0, -door_size.y * 0.5, 0.0))
	# Hide the plain box (and its knob) but keep its collision.
	leaf.layers = 0
	leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Bounds of every mesh under `root`, in root's local space.
func _mesh_aabb(root: Node3D) -> AABB:
	var out: AABB = AABB()
	var first: bool = true
	var to_root: Transform3D = root.global_transform.affine_inverse()
	for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi as MeshInstance3D
		var b: AABB = (to_root * m.global_transform) * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


func _status_text() -> String:
	if _key_action != "":
		return "%s – %s" % [_display_name(), _key_action]
	if not is_locked():
		return "%s – %s" % [_display_name(), "Close" if _is_open else "Open"]
	if room_id <= 0:
		return "%s – Locked" % _display_name()
	var room_name: String = "Room %02d" % room_id
	match RoomManager.get_status(room_id):
		RoomData.Status.AVAILABLE, RoomData.Status.RESERVED:
			return "%s – Vacant" % room_name
		RoomData.Status.OCCUPIED:
			return "%s – Occupied" % room_name
		RoomData.Status.NEEDS_CLEANING:
			return "%s – Needs cleaning" % room_name
		RoomData.Status.MAINTENANCE:
			return "%s – Maintenance" % room_name
		RoomData.Status.OUT_OF_ORDER:
			return "%s – Out of service" % room_name
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


func _on_interacted(by: Node) -> void:
	if _key_action != "":
		key_requested.emit(_key_action, by)
		return
	if not is_locked():
		set_open(not _is_open, by as Node3D)
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
