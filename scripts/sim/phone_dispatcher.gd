class_name PhoneDispatcher
extends Node
## Builds short phone calls at runtime, rings the reception telephone, and applies the player's
## answer: bookings, enquiries, cancellations and guest service requests.
## Calls come from queue_call() (ShiftDirector). An unanswered call stops ringing after a while.

signal call_resolved(kind: StringName, accepted: bool)

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")
## Calls waiting for the phone to be free: {kind, type}.
var _queue: Array[Dictionary] = []
## The call that is ringing or being answered: {kind, type, guest_id, res_id, name, accepting}.
var _current: Dictionary = {}
var _ring_token: int = 0
var _answered: int = 0
var _missed: int = 0
var _call_number: int = 0
var _phone: Telephone = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_to_group(&"phone_dispatcher")
	_connect_phone.call_deferred()


func _connect_phone() -> void:
	_phone = get_tree().get_first_node_in_group(&"telephone") as Telephone
	if _phone != null:
		_phone.call_ended.connect(_on_call_ended)
		_phone.call_missed.connect(_on_call_missed)


## kind: &"reservation", &"enquiry", &"cancellation" or &"service" (then `type` names the request).
func queue_call(kind: StringName, type: StringName = &"") -> void:
	_queue.append({"kind": kind, "type": type})


func queue_size() -> int:
	return _queue.size() + (0 if _current.is_empty() else 1)


## true if such a call would make sense right now (a suitable guest / reservation exists).
func is_feasible(kind: StringName, type: StringName = &"") -> bool:
	return not _prepare(kind, type).is_empty()


func get_answered_count() -> int:
	return _answered


func get_missed_count() -> int:
	return _missed


func _process(_delta: float) -> void:
	if _queue.is_empty() or not _current.is_empty() or _phone == null:
		return
	if _phone.state != Telephone.State.IDLE or DialogueManager.is_active() \
			or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var entry: Dictionary = _queue.pop_front()
	var ctx: Dictionary = _prepare(entry["kind"], entry["type"])
	if ctx.is_empty():
		return  # nothing sensible to say right now (no guest, no reservation): drop it
	_current = ctx
	_phone.ring(ctx["dialogue"])
	_watch_ring(_ring_token)


## Gives up on an unanswered ring after tuning.call_timeout_seconds.
func _watch_ring(token: int) -> void:
	await get_tree().create_timer(tuning.call_timeout_seconds).timeout
	if token == _ring_token and _phone != null and _phone.state == Telephone.State.RINGING:
		_phone.stop_ringing()


# --- Building calls ---------------------------------------------------------------------------

## Returns {} if the call makes no sense in the current state. Otherwise the context + "dialogue".
func _prepare(kind: StringName, type: StringName) -> Dictionary:
	match kind:
		&"reservation":
			return _prepare_reservation()
		&"enquiry":
			return _prepare_enquiry()
		&"cancellation":
			return _prepare_cancellation()
		&"service":
			return _prepare_service(type)
	return {}


func _new_dialogue(kind: StringName) -> DialogueData:
	_call_number += 1
	var d: DialogueData = DialogueData.new()
	d.id = StringName("phone_%s_%d" % [kind, _call_number])
	return d


func _line(speaker: String, text: String) -> DialogueLine:
	var l: DialogueLine = DialogueLine.new()
	l.speaker = speaker
	l.text = text
	return l


## Rooms that are or will be bookable, minus bookings already promised.
func _free_capacity() -> int:
	var rooms: int = 0
	for r: RoomData in RoomManager.get_rooms():
		if r.status == RoomData.Status.AVAILABLE or r.status == RoomData.Status.NEEDS_CLEANING:
			rooms += 1
	var promised: int = 0
	for res: ReservationData in RoomManager.get_reservations():
		if res.status == ReservationData.Status.PENDING and GuestManager.find_by_reservation(res.id) == null:
			promised += 1
	return rooms - promised


func _unused_name() -> String:
	var spawner: GuestSpawner = get_tree().get_first_node_in_group(&"guest_spawner") as GuestSpawner
	var taken: Dictionary[String, bool] = {}
	for res: ReservationData in RoomManager.get_reservations():
		taken[res.guest_name] = true
	for _i: int in 10:
		var n: String = spawner.pick_name() if spawner != null else "Caller"
		if not taken.has(n):
			return n
	return "Caller %d" % (RoomManager.get_reservations().size() + 1)


func _prepare_reservation() -> Dictionary:
	var caller: String = _unused_name()
	var accepting: bool = _free_capacity() > 0
	var d: DialogueData = _new_dialogue(&"reservation")
	d.lines = [
		_line(caller, "Hello, front desk? Do you have a room for tonight?"),
		_line(caller, "I'd get in around %s. The name is %s." % [
			ShiftManager.format_minute(ShiftManager.get_minute() + tuning.booking_arrival_delay_minutes),
			caller]),
	]
	d.choices = PackedStringArray(["Yes, I'll book it for you.", "Sorry, we're full tonight."]) \
			if accepting else PackedStringArray(["Sorry, we're full tonight."])
	return {"kind": &"reservation", "name": caller, "accepting": accepting, "dialogue": d}


func _prepare_enquiry() -> Dictionary:
	var free: bool = _free_capacity() > 0
	var d: DialogueData = _new_dialogue(&"enquiry")
	d.lines = [
		_line("Caller", "Hi, do you have any vacancies tonight? And what is the rate?"),
		_line("You", "Yes, we have rooms. It is $%d a night." % EconomyManager.config.room_price \
				if free else "I'm sorry, we're full tonight."),
		_line("Caller", "Thanks, I'll think about it." if free else "Okay. Thanks anyway."),
	]
	return {"kind": &"enquiry", "dialogue": d}


func _prepare_cancellation() -> Dictionary:
	var target: ReservationData = null
	for res: ReservationData in RoomManager.get_reservations():
		if res.status == ReservationData.Status.PENDING and res.arrival_minute > 0 \
				and GuestManager.find_by_reservation(res.id) == null:
			target = res
			break
	if target == null:
		return {}
	var d: DialogueData = _new_dialogue(&"cancellation")
	d.lines = [
		_line(target.guest_name, "Hello? I booked a room for tonight under %s." % target.guest_name),
		_line(target.guest_name, "Something came up. I need to cancel, I'm sorry."),
	]
	d.choices = PackedStringArray(["Cancel the reservation.", "Sorry, it cannot be cancelled."])
	return {"kind": &"cancellation", "res_id": target.id, "name": target.guest_name, "dialogue": d}


func _prepare_service(type: StringName) -> Dictionary:
	if not GuestManager.REQUEST_INFO.has(type):
		return {}
	var candidates: Array[GuestRecord] = []
	for g: GuestRecord in GuestManager.get_guests():
		if g.state == GuestRecord.State.STAYING and g.room_id > 0 \
				and GuestManager.find_open_request(type, g.id) == null:
			candidates.append(g)
	if candidates.is_empty():
		return {}
	var rec: GuestRecord = candidates[_rng.randi() % candidates.size()]
	var room: RoomData = RoomManager.get_room(rec.room_id)
	var info: Dictionary = GuestManager.REQUEST_INFO[type]
	var d: DialogueData = _new_dialogue(&"service")
	d.lines = [
		_line(rec.display_name, "Hello, front desk? This is %s." % room.display_name),
		_line(rec.display_name, info["call"]),
	]
	var yes: String = "I'll schedule your wake-up call." if type == &"wakeup" else "Of course, I'll take care of it."
	d.choices = PackedStringArray([yes, "Sorry, I can't help with that right now."])
	return {"kind": &"service", "type": type, "guest_id": rec.id, "dialogue": d}


# --- Applying answers -------------------------------------------------------------------------

func _on_call_ended(id: StringName, choice: int) -> void:
	if _current.is_empty() or _current["dialogue"].id != id:
		return  # not one of ours (e.g. an old scripted call)
	var ctx: Dictionary = _current
	_current = {}
	_ring_token += 1
	_answered += 1
	var accepted: bool = false
	match ctx["kind"]:
		&"reservation":
			accepted = ctx["accepting"] and choice == 0
			if accepted:
				_book(ctx["name"])
		&"cancellation":
			accepted = choice == 0 and RoomManager.cancel_reservation(ctx["res_id"])
		&"service":
			accepted = choice == 0 and _accept_service(ctx["type"], ctx["guest_id"])
			if choice == 1:
				GuestManager.apply_outcome(GuestManager.get_guest(ctx["guest_id"]), &"request_ignored")
	call_resolved.emit(ctx["kind"], accepted)


func _book(guest_name: String) -> void:
	var res: ReservationData = ReservationData.new()
	res.id = GuestManager.next_reservation_id()
	res.guest_name = guest_name
	res.arrival_minute = ShiftManager.get_minute() + tuning.booking_arrival_delay_minutes
	RoomManager.add_reservation(res)


func _accept_service(type: StringName, guest_id: int) -> bool:
	var rec: GuestRecord = GuestManager.get_guest(guest_id)
	var start: int = 0
	if type == &"wakeup":
		start = ShiftManager.get_minute() + tuning.wakeup_delay_minutes
	return GuestManager.create_request(type, rec, start) != null


## Nobody answered. A booking is lost; a guest who asked for something counts as ignored.
func _on_call_missed(id: StringName) -> void:
	if _current.is_empty() or _current["dialogue"].id != id:
		return
	var ctx: Dictionary = _current
	_current = {}
	_ring_token += 1
	_missed += 1
	if ctx["kind"] == &"service":
		GuestManager.apply_outcome(GuestManager.get_guest(ctx["guest_id"]), &"request_ignored")
	call_resolved.emit(ctx["kind"], false)
