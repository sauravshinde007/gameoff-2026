class_name Guest
extends StaticBody3D
## Physical guest. Spawned by GuestSpawner. Two jobs:
##   CHECK_IN : walk to the desk -> talk -> player assigns a room on the computer -> player takes the
##              key from the rack -> talk again to hand it over (room paid once) -> walk to the room.
##   CHECK_OUT: walk from the room to the desk -> talk -> key returned, room needs cleaning -> leave.
## Dialogue exports left empty are built from the guest's name (only Ms. Carter uses the .tres files).

signal checked_in(reservation_id: String)
## Emitted just before the node frees itself.
signal departed(guest: Guest)

enum Mode { CHECK_IN, CHECK_OUT }

@export var reservation_id: String = "#0001"
@export var dialogue_ask: DialogueData
@export var dialogue_remind_room: DialogueData
@export var dialogue_remind_key: DialogueData
@export var dialogue_handover: DialogueData
@export var dialogue_checkout: DialogueData
## The door opens when the guest comes within this distance (metres, horizontal)...
@export var door_open_distance: float = 1.8
## ...and closes again once they are further than this on the other side.
@export var door_close_distance: float = 2.4
@export var walk_speed: float = 2.8
## How fast the guest turns to face where they are walking (higher = snappier).
@export var walk_turn_speed: float = 10.0
## Direction a guest faces while waiting at the desk: toward the counter and the window behind it.
@export var counter_direction: Vector3 = Vector3(0.0, 0.0, -1.0)
## Task completed when the key is handed over. Only the scripted first guest has one.
@export var check_in_task_id: StringName = &"check_in_guest"

@onready var interactable: Interactable = $Interactable
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var model: RetroModel = get_node_or_null(^"Model") as RetroModel

var record: GuestRecord
var mode: Mode = Mode.CHECK_IN
var spawner: GuestSpawner
## Gives up waiting at the desk (generated guests only).
var has_patience: bool = false

var _walk_in: bool = false
var _asked: bool = false
var _handing_over: bool = false
var _checking_out: bool = false
var _done: bool = false
var _tween: Tween
## Any "turn to face" tween (player, counter). Killed when walking starts so it cannot
## drag the guest back toward the reception while they walk away.
var _turn_tween: Tween
var _walking: bool = false
var _last_pos: Vector3 = Vector3.ZERO
var _doors: Array[Node3D] = []
## door -> 0 closed and waiting, 1 opened by this guest, 2 finished.
var _door_state: Dictionary[Node3D, int] = {}


func _ready() -> void:
	set_process(false)
	interactable.enabled = false
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)


## Called by the spawner right after instancing, before the guest enters the tree.
func setup(p_record: GuestRecord, p_mode: Mode, p_spawner: GuestSpawner, p_walk_in: bool) -> void:
	record = p_record
	mode = p_mode
	spawner = p_spawner
	_walk_in = p_walk_in
	reservation_id = p_record.reservation_id
	_build_missing_dialogues()


## Starts at the desk slot already (the day-intro guest).
func begin_at_desk() -> void:
	_arrived_at_desk()


## Walks `points` (world space, ending at the desk slot), then waits at the desk.
func begin_walk_to_desk(points: PackedVector3Array, doors: Array[Node3D]) -> void:
	_walk(points, doors, _arrived_at_desk)


func _arrived_at_desk() -> void:
	face_toward(global_position + counter_direction)
	if model != null:
		model.play(&"idle")
	body_shape.set_deferred("disabled", false)
	interactable.enabled = true
	if mode == Mode.CHECK_IN:
		GuestManager.set_state(record, GuestRecord.State.AT_DESK)
		if _walk_in and reservation_id.is_empty():
			_create_walk_in_reservation()
		if has_patience:
			_wait_for_patience()
	else:
		GuestManager.set_state(record, GuestRecord.State.CHECKING_OUT)
		interactable.prompt_text = "Check out guest"


func _create_walk_in_reservation() -> void:
	var res: ReservationData = ReservationData.new()
	res.id = GuestManager.next_reservation_id()
	res.guest_name = record.display_name
	RoomManager.add_reservation(res)
	reservation_id = res.id
	record.reservation_id = res.id


func _on_interacted(by: Node) -> void:
	if _done or DialogueManager.is_active():
		return
	_kill_turn()
	_turn_tween = NpcFacing.face(self, by as Node3D)
	if mode == Mode.CHECK_OUT:
		_checking_out = true
		DialogueManager.start(dialogue_checkout)
		return
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
	if _handing_over and id == dialogue_handover.id:
		_handing_over = false
		_complete_check_in()
	elif _checking_out and id == dialogue_checkout.id:
		_checking_out = false
		_complete_check_out()
	# Only turn back to the counter if the guest is staying at the desk (not walking off).
	if not _done and not _walking and _owns_dialogue(id):
		_turn_to_counter()


func _owns_dialogue(id: StringName) -> bool:
	for d: DialogueData in [dialogue_ask, dialogue_remind_room, dialogue_remind_key,
			dialogue_handover, dialogue_checkout]:
		if d != null and d.id == id:
			return true
	return false


## After talking to the player, go back to facing the counter.
func _turn_to_counter() -> void:
	if not is_inside_tree():
		return
	var yaw: float = atan2(-counter_direction.x, -counter_direction.z)
	_kill_turn()
	_turn_tween = create_tween()
	_turn_tween.tween_property(self, "global_rotation:y", lerp_angle(global_rotation.y, yaw, 1.0), 0.3)


func _kill_turn() -> void:
	if _turn_tween != null:
		_turn_tween.kill()
		_turn_tween = null


func _complete_check_in() -> void:
	var res: ReservationData = RoomManager.get_reservation(reservation_id)
	if res == null or not RoomManager.hand_over_key(res.room_id):
		return
	_done = true
	EconomyManager.record_income(EconomyManager.config.room_price, &"room",
			"Room %02d - %s" % [res.room_id, res.guest_name], "stay:" + res.id, res.room_id)
	GuestManager.check_in(record, res.room_id)
	if check_in_task_id != &"":
		TaskManager.complete_task(check_in_task_id)
	checked_in.emit(res.id)
	_release_desk()
	_walk(spawner.route_to_room(res.room_id), spawner.doors_for_room(res.room_id), _depart)


func _complete_check_out() -> void:
	_done = true
	RoomManager.check_out(record.room_id)
	GuestManager.mark_gone(record)
	_release_desk()
	_walk(spawner.route_to_exit(), spawner.doors_for_exit(), _depart)


## Generated guests give up on check-in if nobody serves them. (A Timer child, so it dies with the guest.)
func _wait_for_patience() -> void:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = spawner.tuning.desk_patience_seconds
	timer.timeout.connect(_on_patience_timeout.bind(timer))
	add_child(timer)
	timer.start()


func _on_patience_timeout(timer: Timer) -> void:
	var res: ReservationData = RoomManager.get_reservation(reservation_id)
	if _done or res == null or res.status != ReservationData.Status.PENDING:
		return
	if DialogueManager.is_active():
		timer.start(2.0)
		return
	_give_up()


func _give_up() -> void:
	_done = true
	GuestManager.apply_outcome(record, &"waited_too_long")
	RoomManager.cancel_reservation(reservation_id)
	GuestManager.mark_gone(record)
	get_tree().call_group("hud", "show_message", "%s got tired of waiting and left." % record.display_name)
	_release_desk()
	_walk(spawner.route_to_exit(), spawner.doors_for_exit(), _depart)


func _release_desk() -> void:
	interactable.enabled = false
	spawner.release_slot(self)


func _depart() -> void:
	departed.emit(self)
	queue_free()


func _walk(points: PackedVector3Array, doors: Array[Node3D], on_done: Callable) -> void:
	if _tween != null:
		_tween.kill()
	interactable.enabled = false
	body_shape.set_deferred("disabled", true)
	_doors = doors
	_door_state.clear()
	for d: Node3D in doors:
		_door_state[d] = 0
	if model != null:
		model.play(&"walk")
	_kill_turn()
	_walking = true
	_last_pos = global_position
	set_process(true)
	if not points.is_empty():
		face_toward(points[0])
	_tween = create_tween()
	var from: Vector3 = global_position
	for point: Vector3 in points:
		_tween.tween_property(self, "global_position", point, maxf(from.distance_to(point), 0.01) / walk_speed)
		from = point
	_tween.tween_callback(_finish_walk.bind(on_done))


## While walking: face the direction of travel, and open each door as the guest approaches it
## (closing it once they are through).
func _process(delta: float) -> void:
	if _walking:
		var moved: Vector3 = global_position - _last_pos
		moved.y = 0.0
		_last_pos = global_position
		if moved.length() > 0.0005:
			var yaw: float = atan2(-moved.x, -moved.z)
			global_rotation.y = lerp_angle(global_rotation.y, yaw, clampf(walk_turn_speed * delta, 0.0, 1.0))
	for d: Node3D in _doors:
		if not is_instance_valid(d) or not d.has_method("set_open"):
			continue
		var to_door: Vector3 = d.global_position - global_position
		to_door.y = 0.0
		var dist: float = to_door.length()
		var state: int = _door_state[d]
		if state == 0 and dist < door_open_distance:
			_door_state[d] = 1
			d.call("set_open", true, self)
			if d.is_in_group(&"entrance_doors"):
				AudioManager.play_sfx(&"entrance_bell", d.global_position)
		elif state == 1 and dist > door_close_distance:
			_door_state[d] = 2
			d.call("set_open", false)


func _finish_walk(on_done: Callable) -> void:
	for d: Node3D in _doors:
		if is_instance_valid(d) and _door_state.get(d, 0) == 1:
			d.call("set_open", false)
	_doors.clear()
	_walking = false
	set_process(false)
	on_done.call()


func face_toward(point: Vector3) -> void:
	var target: Vector3 = Vector3(point.x, global_position.y, point.z)
	if target.distance_to(global_position) > 0.01:
		look_at(target)


func _build_missing_dialogues() -> void:
	var who: String = record.display_name
	if dialogue_ask == null:
		var opener: String = "Good morning. Do you have a room for tonight?" if _walk_in \
				else "Good morning. I have a reservation under %s." % who
		dialogue_ask = _dialogue(&"ask", [[who, opener], [who, "I would like to check in, please."],
				["You", "Of course. Let me find you on the computer."]])
	if dialogue_remind_room == null:
		dialogue_remind_room = _dialogue(&"remind_room", [[who, "Is my room ready yet?"],
				["You", "Almost. I need to assign it on the computer."]])
	if dialogue_remind_key == null:
		dialogue_remind_key = _dialogue(&"remind_key", [[who, "Do you have my key?"],
				["You", "One moment. I will get it from the rack."]])
	if dialogue_handover == null:
		dialogue_handover = _dialogue(&"handover", [["You", "Here is your key. Enjoy your stay."],
				[who, "Thank you. Goodnight."]])
	if dialogue_checkout == null:
		dialogue_checkout = _dialogue(&"checkout", [[who, "I would like to check out, please."],
				[who, "Here is the key."], ["You", "Thank you for staying with us. Goodbye."]])


func _dialogue(suffix: StringName, lines: Array) -> DialogueData:
	var data: DialogueData = DialogueData.new()
	data.id = StringName("guest_%d_%s" % [record.id, suffix])
	for pair: Array in lines:
		var line: DialogueLine = DialogueLine.new()
		line.speaker = pair[0]
		line.text = pair[1]
		data.lines.append(line)
	return data
