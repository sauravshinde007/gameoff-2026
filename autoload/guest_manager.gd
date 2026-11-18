extends Node
## Guest records and individual satisfaction. Physical guests are nodes owned by GuestSpawner;
## this is only their data. Satisfaction changes only through named outcomes (see SimTuning).

signal guest_created(guest_id: int)
signal guest_state_changed(guest_id: int, state: int)
signal satisfaction_changed(guest_id: int, value: int)
signal requests_changed()
signal request_state_changed(request_id: String, state: int)

## type -> what the guest says on the phone, the task text ("%s" = room name), urgency, mandatory.
const REQUEST_INFO: Dictionary = {
	&"towels": {"call": "Could you send up some extra towels?", "task": "Bring towels to %s",
			"urgent": false, "mandatory": false},
	&"pillows": {"call": "Could I get a couple of extra pillows?", "task": "Bring pillows to %s",
			"urgent": false, "mandatory": false},
	&"ice": {"call": "Could someone bring a bucket of ice?", "task": "Bring ice to %s",
			"urgent": false, "mandatory": false},
	&"coffee": {"call": "Could I get a pot of coffee sent over?", "task": "Bring coffee to %s",
			"urgent": false, "mandatory": false},
	&"cleaning": {"call": "The room needs a quick clean, please.", "task": "Clean %s",
			"urgent": false, "mandatory": false},
	&"maintenance": {"call": "Something in the room is broken. Can someone take a look?",
			"task": "Repair problem in %s", "urgent": true, "mandatory": false},
	&"wakeup": {"call": "Could you give me a wake-up call?", "task": "Place wake-up call for %s",
			"urgent": false, "mandatory": true},
}

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")

var _guests: Array[GuestRecord] = []
var _next_id: int = 1
var _next_reservation: int = 2
var _requests: Array[ServiceRequest] = []
var _next_request: int = 1


func _ready() -> void:
	ShiftManager.time_changed.connect(_on_time_changed)
	reset()


## Fresh start. Guests already occupying rooms in RoomManager get a record that has "stayed a while".
func reset() -> void:
	_guests.clear()
	_next_id = 1
	_next_reservation = 2
	_requests.clear()
	_next_request = 1
	for room: RoomData in RoomManager.get_rooms():
		if room.status != RoomData.Status.OCCUPIED:
			continue
		var rec: GuestRecord = create_guest(room.guest_name)
		rec.state = GuestRecord.State.STAYING
		rec.room_id = room.id
		rec.checkin_minute = ShiftManager.get_minute() - tuning.preexisting_stay_minutes


func get_guests() -> Array[GuestRecord]:
	return _guests


func get_guest(guest_id: int) -> GuestRecord:
	for g: GuestRecord in _guests:
		if g.id == guest_id:
			return g
	return null


func find_by_room(room_id: int) -> GuestRecord:
	for g: GuestRecord in _guests:
		if g.room_id == room_id and g.state != GuestRecord.State.GONE:
			return g
	return null


func find_by_reservation(reservation_id: String) -> GuestRecord:
	if reservation_id.is_empty():
		return null
	for g: GuestRecord in _guests:
		if g.reservation_id == reservation_id:
			return g
	return null


func create_guest(display_name: String, reservation_id: String = "") -> GuestRecord:
	var rec: GuestRecord = GuestRecord.new()
	rec.id = _next_id
	_next_id += 1
	rec.display_name = display_name
	rec.reservation_id = reservation_id
	rec.satisfaction = tuning.start_satisfaction
	_guests.append(rec)
	guest_created.emit(rec.id)
	return rec


## "#0002", "#0003", ... for walk-ins and generated reservations.
func next_reservation_id() -> String:
	var id: String = "#%04d" % _next_reservation
	_next_reservation += 1
	return id


func set_state(rec: GuestRecord, state: GuestRecord.State) -> void:
	if rec == null or rec.state == state:
		return
	rec.state = state
	guest_state_changed.emit(rec.id, state)


## The guest got their key. Call once, after RoomManager.hand_over_key succeeded.
func check_in(rec: GuestRecord, room_id: int) -> void:
	if rec == null:
		return
	rec.room_id = room_id
	rec.checkin_minute = ShiftManager.get_minute()
	set_state(rec, GuestRecord.State.STAYING)
	apply_outcome(rec, &"check_in")


## The guest left for good. Call after RoomManager.check_out (or when giving up without a room).
func mark_gone(rec: GuestRecord) -> void:
	if rec != null:
		for req: ServiceRequest in _requests:
			if req.guest_id == rec.id:
				cancel_request(req.id)
	set_state(rec, GuestRecord.State.GONE)


func apply_outcome(rec: GuestRecord, outcome: StringName) -> void:
	if rec == null:
		return
	var delta: int = tuning.get_satisfaction_delta(outcome)
	if delta == 0:
		return
	rec.satisfaction = clampi(rec.satisfaction + delta, 0, 100)
	satisfaction_changed.emit(rec.id, rec.satisfaction)


## Staying guests who have stayed long enough, whose room is really theirs (occupied, key given).
func get_checkout_candidates(minute: int, min_stay_minutes: int) -> Array[GuestRecord]:
	var out: Array[GuestRecord] = []
	for g: GuestRecord in _guests:
		if g.state != GuestRecord.State.STAYING or minute - g.checkin_minute < min_stay_minutes:
			continue
		var room: RoomData = RoomManager.get_room(g.room_id)
		if room != null and room.status == RoomData.Status.OCCUPIED and room.key_issued:
			out.append(g)
	return out


# --- Service requests -------------------------------------------------------------------------

func get_requests() -> Array[ServiceRequest]:
	return _requests


func get_request(request_id: String) -> ServiceRequest:
	for r: ServiceRequest in _requests:
		if r.id == request_id:
			return r
	return null


## Created or active request of this type for this guest (null if none).
func find_open_request(type: StringName, guest_id: int) -> ServiceRequest:
	for r: ServiceRequest in _requests:
		if r.type == type and r.guest_id == guest_id and _is_open(r):
			return r
	return null


func count_open_requests() -> int:
	var n: int = 0
	for r: ServiceRequest in _requests:
		if _is_open(r):
			n += 1
	return n


## Active wake-up request whose time has come (the player can place the call now), or null.
func get_due_wakeup() -> ServiceRequest:
	for r: ServiceRequest in _requests:
		if r.type == &"wakeup" and r.state == ServiceRequest.State.ACTIVE:
			return r
	return null


## New request for a staying guest. start_minute 0 = active at once (task appears now).
## Returns null if the guest is not staying, the type is unknown or the same request is already open.
func create_request(type: StringName, rec: GuestRecord, start_minute: int = 0) -> ServiceRequest:
	if rec == null or rec.state != GuestRecord.State.STAYING or not REQUEST_INFO.has(type):
		return null
	if find_open_request(type, rec.id) != null:
		return null
	var req: ServiceRequest = ServiceRequest.new()
	req.id = "R%04d" % _next_request
	_next_request += 1
	req.type = type
	req.guest_id = rec.id
	req.room_id = rec.room_id
	req.start_minute = start_minute
	req.task_id = StringName("req_" + req.id)
	_requests.append(req)
	rec.request_ids.append(req.id)
	if start_minute <= ShiftManager.get_minute():
		_activate(req)
	else:
		requests_changed.emit()
	return req


func complete_request(request_id: String) -> bool:
	var req: ServiceRequest = get_request(request_id)
	if req == null or req.state != ServiceRequest.State.ACTIVE:
		return false
	req.state = ServiceRequest.State.COMPLETED
	TaskManager.complete_task(req.task_id)
	apply_outcome(get_guest(req.guest_id), &"request_completed")
	request_state_changed.emit(req.id, req.state)
	requests_changed.emit()
	return true


## The request was not met in time. `outcome` is the satisfaction outcome applied to the guest.
func fail_request(request_id: String, outcome: StringName = &"deadline_missed") -> bool:
	var req: ServiceRequest = get_request(request_id)
	if req == null or req.state != ServiceRequest.State.ACTIVE:
		return false
	req.state = ServiceRequest.State.FAILED
	TaskManager.fail_task(req.task_id)
	apply_outcome(get_guest(req.guest_id), outcome)
	request_state_changed.emit(req.id, req.state)
	requests_changed.emit()
	return true


## Withdrawn without blame (guest left). Removes its task, no satisfaction change.
func cancel_request(request_id: String) -> bool:
	var req: ServiceRequest = get_request(request_id)
	if req == null or not _is_open(req):
		return false
	req.state = ServiceRequest.State.CANCELLED
	TaskManager.remove_task(req.task_id)
	request_state_changed.emit(req.id, req.state)
	requests_changed.emit()
	return true


func _is_open(req: ServiceRequest) -> bool:
	return req.state == ServiceRequest.State.CREATED or req.state == ServiceRequest.State.ACTIVE


func _activate(req: ServiceRequest) -> void:
	var info: Dictionary = REQUEST_INFO[req.type]
	var urgent: bool = info["urgent"]
	var room: RoomData = RoomManager.get_room(req.room_id)
	var room_name: String = room.display_name if room != null else "Room %02d" % req.room_id
	var now: int = ShiftManager.get_minute()
	if req.type == &"wakeup":
		req.deadline_minute = now + tuning.wakeup_grace_minutes
	else:
		req.deadline_minute = now + (tuning.urgent_request_deadline_minutes if urgent \
				else tuning.request_deadline_minutes)
	req.state = ServiceRequest.State.ACTIVE
	var task: TaskData = TaskData.new()
	task.id = req.task_id
	task.text = info["task"] % room_name
	task.category = &"guest"
	task.priority = TaskData.Priority.URGENT if urgent else TaskData.Priority.NORMAL
	task.mandatory = info["mandatory"]
	task.deadline_minute = req.deadline_minute
	task.room_id = req.room_id
	task.guest_id = req.guest_id
	task.request_id = req.id
	TaskManager.add_task(task)
	request_state_changed.emit(req.id, req.state)
	requests_changed.emit()


func _on_time_changed(minute: int) -> void:
	# Copy: activating/failing does not change the array, but keep it safe against later additions.
	for req: ServiceRequest in _requests.duplicate():
		if req.state == ServiceRequest.State.CREATED and minute >= req.start_minute:
			_activate(req)
		elif req.state == ServiceRequest.State.ACTIVE and req.deadline_minute > 0 \
				and minute > req.deadline_minute:
			fail_request(req.id)


static func satisfaction_label(value: int) -> String:
	if value >= 80:
		return "Delighted"
	if value >= 60:
		return "Content"
	if value >= 40:
		return "Neutral"
	if value >= 20:
		return "Unhappy"
	return "Angry"
