class_name GuestSpawner
extends Node3D
## Spawns and routes physical guests. Waypoints are world space (the motel sits at the origin).
## Guests walk set paths (tweens, no navmesh): gate -> reception entrance -> desk slot -> room door.
## The arrival scheduler here is simple and timer based; Task 7's shift director may take it over.

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")
@export var guest_scene: PackedScene = preload("res://scenes/npcs/guest.tscn")
## Where guests stand to be served. Index 0 is the scripted guest's spot.
@export var desk_slots: PackedVector3Array = PackedVector3Array([
	Vector3(-0.4, 0.0, -0.3), Vector3(-1.5, 0.0, -0.3), Vector3(0.8, 0.0, -0.3)])
@export var gate_point: Vector3 = Vector3(-14.0, 0.0, 8.5)
## Inside the entrance door, on the way to the desk row.
@export var entrance_inside: Vector3 = Vector3(2.5, 0.0, -0.3)
## Outside the entrance door, then the route to the gate (arrival is this reversed).
@export var exit_points: PackedVector3Array = PackedVector3Array([
	Vector3(2.5, 0.0, -4.6), Vector3(-6.0, 0.0, -5.0), Vector3(-14.0, 0.0, -2.0)])
## Walkway waypoints from the entrance to the start of the east walkway.
@export var walkway_start: PackedVector3Array = PackedVector3Array([
	Vector3(2.5, 0.0, -4.3), Vector3(4.6, 0.0, -4.0), Vector3(5.1, 0.0, -5.5)])
## Corner between the east and north walkways (rooms 04-06 are past it).
@export var walkway_corner: Vector3 = Vector3(5.1, 0.0, -17.6)
## The first guest of the shift: already at the desk from the day intro (the original MVP flow).
@export var scripted_guest_name: String = "Ms. Carter"
@export var scripted_reservation_id: String = "#0001"
@export var guest_names: PackedStringArray = PackedStringArray([
	"Mr. Okafor", "Ms. Lindqvist", "Mr. Tanaka", "Ms. Alvarez", "Mr. Brennan",
	"Ms. Novak", "Mr. Haddad", "Ms. Whitaker", "Mr. Petrov", "Ms. Osei"])
@export var guest_tints: Array[Color] = [
	Color(1.0, 1.0, 1.0), Color(0.85, 0.9, 1.0), Color(1.0, 0.9, 0.85),
	Color(0.9, 1.0, 0.9), Color(0.95, 0.85, 1.0)]

var _slots: Array[Guest] = []
var _active: Array[Guest] = []
var _next_check_minute: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"guest_spawner")
	_rng.randomize()
	_slots.resize(desk_slots.size())
	ShiftManager.time_changed.connect(_on_time_changed)
	_spawn_scripted.call_deferred()


func get_active_count() -> int:
	return _active.size()


# --- Spawning ---------------------------------------------------------------------------------

func _spawn_scripted() -> void:
	if RoomManager.get_reservation(scripted_reservation_id) == null:
		return
	var rec: GuestRecord = GuestManager.create_guest(scripted_guest_name, scripted_reservation_id)
	var guest: Guest = _make_guest(rec, Guest.Mode.CHECK_IN, false, false)
	guest.global_position = desk_slots[0]
	_claim_slot(guest, 0)
	guest.begin_at_desk()


## A new guest arrives from the gate. `walk_in` = no reservation yet.
func spawn_arrival(walk_in: bool) -> Guest:
	var slot: int = _free_slot()
	if slot < 0:
		return null
	var rec: GuestRecord = GuestManager.create_guest(pick_name())
	var guest: Guest = _make_guest(rec, Guest.Mode.CHECK_IN, walk_in, true)
	guest.global_position = gate_point
	_claim_slot(guest, slot)
	guest.begin_walk_to_desk(_arrival_points(desk_slots[slot]), doors_for_exit())
	return guest


## A guest with a phone booking arrives from the gate for their existing reservation.
func spawn_reservation_arrival(res: ReservationData) -> Guest:
	var slot: int = _free_slot()
	if slot < 0:
		return null
	var rec: GuestRecord = GuestManager.create_guest(res.guest_name, res.id)
	var guest: Guest = _make_guest(rec, Guest.Mode.CHECK_IN, false, true)
	guest.global_position = gate_point
	_claim_slot(guest, slot)
	guest.begin_walk_to_desk(_arrival_points(desk_slots[slot]), doors_for_exit())
	return guest


## A staying guest walks from their room to the desk to check out.
func spawn_checkout(rec: GuestRecord) -> Guest:
	var slot: int = _free_slot()
	var door: Node3D = _room_door(rec.room_id)
	if slot < 0 or door == null:
		return null
	var guest: Guest = _make_guest(rec, Guest.Mode.CHECK_OUT, false, false)
	var to_room: PackedVector3Array = route_to_room(rec.room_id)
	var points: PackedVector3Array = PackedVector3Array()
	for i: int in range(to_room.size() - 1, -1, -1):
		points.append(to_room[i])
	points.append(desk_slots[slot])
	guest.global_position = points[0]
	points.remove_at(0)
	GuestManager.set_state(rec, GuestRecord.State.CHECKING_OUT)
	_claim_slot(guest, slot)
	var doors: Array[Node3D] = doors_for_room(rec.room_id)
	guest.begin_walk_to_desk(points, doors)
	return guest


func _make_guest(rec: GuestRecord, mode: Guest.Mode, walk_in: bool, generated: bool) -> Guest:
	var guest: Guest = guest_scene.instantiate() as Guest
	if generated:
		# The .tres dialogues and the check-in task belong to the scripted guest only.
		guest.dialogue_ask = null
		guest.dialogue_remind_room = null
		guest.dialogue_remind_key = null
		guest.dialogue_handover = null
		guest.check_in_task_id = &""
		guest.has_patience = mode == Guest.Mode.CHECK_IN
		var model: RetroModel = guest.get_node("Model") as RetroModel
		model.tint = guest_tints[_rng.randi() % guest_tints.size()]
	elif mode == Guest.Mode.CHECK_OUT:
		guest.dialogue_ask = null
		guest.dialogue_remind_room = null
		guest.dialogue_remind_key = null
		guest.dialogue_handover = null
		guest.check_in_task_id = &""
	guest.setup(rec, mode, self, walk_in)
	guest.departed.connect(_on_guest_departed)
	add_child(guest)
	_active.append(guest)
	return guest


func _on_guest_departed(guest: Guest) -> void:
	_active.erase(guest)


func pick_name() -> String:
	var used: Dictionary[String, bool] = {}
	for g: GuestRecord in GuestManager.get_guests():
		if g.state != GuestRecord.State.GONE:
			used[g.display_name] = true
	var pool: Array[String] = []
	for n: String in guest_names:
		if not used.has(n):
			pool.append(n)
	if pool.is_empty():
		return "Guest %d" % (GuestManager.get_guests().size() + 1)
	return pool[_rng.randi() % pool.size()]


# --- Desk slots -------------------------------------------------------------------------------

func _free_slot() -> int:
	for i: int in _slots.size():
		if _slots[i] == null:
			return i
	return -1


func _claim_slot(guest: Guest, index: int) -> void:
	_slots[index] = guest


func release_slot(guest: Guest) -> void:
	var i: int = _slots.find(guest)
	if i >= 0:
		_slots[i] = null


# --- Routes -----------------------------------------------------------------------------------

## Entrance (inside) -> room door -> just inside the room. Excludes the desk part.
func route_to_room(room_id: int) -> PackedVector3Array:
	var door: Node3D = _room_door(room_id)
	var points: PackedVector3Array = PackedVector3Array([entrance_inside])
	points.append_array(walkway_start)
	if door == null:
		return points
	var pos: Vector3 = Vector3(door.global_position.x, 0.0, door.global_position.z)
	var out_dir: Vector3 = door.global_basis.z
	out_dir.y = 0.0
	out_dir = out_dir.normalized()
	if pos.z < walkway_corner.z - 0.5:
		points.append(walkway_corner)
	points.append(pos + out_dir * 0.9)
	points.append(pos - out_dir * 0.8)
	return points


## Desk -> out of the entrance -> to the gate. Starts at the entrance (inside).
func route_to_exit() -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array([entrance_inside])
	points.append_array(exit_points)
	points.append(gate_point)
	return points


func doors_for_room(room_id: int) -> Array[Node3D]:
	var doors: Array[Node3D] = []
	var entrance: Node3D = _entrance_door()
	if entrance != null:
		doors.append(entrance)
	var door: Node3D = _room_door(room_id)
	if door != null:
		doors.append(door)
	return doors


func doors_for_exit() -> Array[Node3D]:
	var doors: Array[Node3D] = []
	var entrance: Node3D = _entrance_door()
	if entrance != null:
		doors.append(entrance)
	return doors


func _arrival_points(slot_pos: Vector3) -> PackedVector3Array:
	var exit_path: PackedVector3Array = route_to_exit()
	var points: PackedVector3Array = PackedVector3Array()
	for i: int in range(exit_path.size() - 2, -1, -1):
		points.append(exit_path[i])
	points.append(slot_pos)
	return points


func _room_door(room_id: int) -> Node3D:
	for d: Node in get_tree().get_nodes_in_group(&"room_doors"):
		if (d as Door).room_id == room_id:
			return d as Node3D
	return null


func _entrance_door() -> Node3D:
	return get_tree().get_first_node_in_group(&"entrance_doors") as Node3D


# --- Arrival scheduler ------------------------------------------------------------------------

func _on_time_changed(minute: int) -> void:
	if not ShiftManager.running:
		return
	_spawn_due_bookings(minute)
	if _next_check_minute < 0:
		_next_check_minute = minute + tuning.first_spawn_delay_minutes
	if minute < _next_check_minute:
		return
	_next_check_minute = minute + tuning.spawn_interval_minutes
	_try_spawn(minute)


## Phone bookings whose arrival time has come. A full desk or motel just delays them a minute.
func _spawn_due_bookings(minute: int) -> void:
	for res: ReservationData in RoomManager.get_reservations():
		if res.status != ReservationData.Status.PENDING or res.arrival_minute <= 0 \
				or res.arrival_minute > minute or GuestManager.find_by_reservation(res.id) != null:
			continue
		if _active.size() >= tuning.max_active_guests or _free_slot() < 0:
			return
		spawn_reservation_arrival(res)


func _try_spawn(minute: int) -> void:
	if _active.size() >= tuning.max_active_guests or _free_slot() < 0:
		return
	var checkouts: Array[GuestRecord] = GuestManager.get_checkout_candidates(minute, tuning.min_stay_minutes)
	var can_check_in: bool = _free_rooms() - _waiting_check_ins() > 0
	if can_check_in and not checkouts.is_empty():
		can_check_in = _rng.randf() < 0.5
	if can_check_in:
		spawn_arrival(true)
	elif not checkouts.is_empty():
		spawn_checkout(checkouts[_rng.randi() % checkouts.size()])


func _free_rooms() -> int:
	var count: int = 0
	for r: RoomData in RoomManager.get_rooms():
		if r.status == RoomData.Status.AVAILABLE:
			count += 1
	return count


## Check-in guests that will still need a room (not yet handed a key).
func _waiting_check_ins() -> int:
	var count: int = 0
	for g: Guest in _active:
		if g.mode == Guest.Mode.CHECK_IN and g.record.state != GuestRecord.State.STAYING:
			var res: ReservationData = RoomManager.get_reservation(g.reservation_id)
			if res == null or res.status == ReservationData.Status.PENDING:
				count += 1
	return count
