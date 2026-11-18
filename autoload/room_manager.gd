extends Node
## Room availability and reservations. Emits signals; never references scene nodes.

signal room_status_changed(room_id: int, status: int)
signal reservations_changed()
signal key_state_changed()

@export var database: RoomDatabase = preload("res://data/rooms/rooms.tres")

## Room id of the key the player is currently holding (0 = none).
var issued_key_room_id: int = 0

var _rooms: Array[RoomData] = []
var _reservations: Array[ReservationData] = []


func _ready() -> void:
	reset()


## Reload starting state from the database (copies, so the .tres is never mutated).
func reset() -> void:
	_rooms.clear()
	_reservations.clear()
	issued_key_room_id = 0
	for r: RoomData in database.rooms:
		_rooms.append(r.duplicate() as RoomData)
	for res: ReservationData in database.reservations:
		_reservations.append(res.duplicate() as ReservationData)
	for r: RoomData in _rooms:
		room_status_changed.emit(r.id, r.status)
	reservations_changed.emit()
	key_state_changed.emit()


func get_rooms() -> Array[RoomData]:
	return _rooms


func get_room(room_id: int) -> RoomData:
	for r: RoomData in _rooms:
		if r.id == room_id:
			return r
	return null


## Returns RoomData.Status, or -1 if the room does not exist.
func get_status(room_id: int) -> int:
	var r: RoomData = get_room(room_id)
	return r.status if r != null else -1


func get_reservations() -> Array[ReservationData]:
	return _reservations


func get_reservation(reservation_id: String) -> ReservationData:
	for res: ReservationData in _reservations:
		if res.id == reservation_id:
			return res
	return null


func add_reservation(res: ReservationData) -> void:
	_reservations.append(res)
	reservations_changed.emit()


## A pending reservation that will not be used (no-show, walked out, phone cancellation).
func cancel_reservation(reservation_id: String) -> bool:
	var res: ReservationData = get_reservation(reservation_id)
	if res == null or res.status != ReservationData.Status.PENDING:
		return false
	res.status = ReservationData.Status.CANCELLED
	reservations_changed.emit()
	return true


## Assign an AVAILABLE room to a reservation. Returns false if refused.
func assign_room(room_id: int, reservation_id: String) -> bool:
	var r: RoomData = get_room(room_id)
	var res: ReservationData = get_reservation(reservation_id)
	if r == null or res == null or r.status != RoomData.Status.AVAILABLE:
		return false
	r.status = RoomData.Status.OCCUPIED
	r.guest_name = res.guest_name
	r.key_issued = false
	res.room_id = room_id
	res.status = ReservationData.Status.CHECKED_IN
	room_status_changed.emit(room_id, r.status)
	reservations_changed.emit()
	key_state_changed.emit()
	return true


func check_out(room_id: int) -> bool:
	var r: RoomData = get_room(room_id)
	if r == null or r.status != RoomData.Status.OCCUPIED:
		return false
	for res: ReservationData in _reservations:
		if res.room_id == room_id and res.status == ReservationData.Status.CHECKED_IN:
			res.status = ReservationData.Status.CHECKED_OUT
	r.status = RoomData.Status.NEEDS_CLEANING
	r.guest_name = ""
	r.key_issued = false
	if issued_key_room_id == room_id:
		issued_key_room_id = 0
	room_status_changed.emit(room_id, r.status)
	reservations_changed.emit()
	key_state_changed.emit()
	return true


## Needs Cleaning -> Available. Refused for any other state.
func mark_clean(room_id: int) -> bool:
	var r: RoomData = get_room(room_id)
	if r == null or r.status != RoomData.Status.NEEDS_CLEANING:
		return false
	r.status = RoomData.Status.AVAILABLE
	room_status_changed.emit(room_id, r.status)
	return true


## true: Available/Needs Cleaning room -> Maintenance. false: Maintenance -> Available.
func set_maintenance(room_id: int, broken: bool) -> bool:
	var r: RoomData = get_room(room_id)
	if r == null:
		return false
	if broken:
		if r.status != RoomData.Status.AVAILABLE and r.status != RoomData.Status.NEEDS_CLEANING:
			return false
		r.status = RoomData.Status.MAINTENANCE
	else:
		if r.status != RoomData.Status.MAINTENANCE:
			return false
		r.status = RoomData.Status.AVAILABLE
	room_status_changed.emit(room_id, r.status)
	return true


## Display text for a room status.
func status_text(status: int) -> String:
	match status:
		RoomData.Status.AVAILABLE:
			return "AVAILABLE"
		RoomData.Status.OCCUPIED:
			return "OCCUPIED"
		RoomData.Status.RESERVED:
			return "RESERVED"
		RoomData.Status.NEEDS_CLEANING:
			return "NEEDS CLEANING"
		RoomData.Status.MAINTENANCE:
			return "MAINTENANCE"
	return "OUT OF SERVICE"


## A key can be taken for an assigned room whose guest has no key yet, if the player's hands are free.
func can_take_key(room_id: int) -> bool:
	var r: RoomData = get_room(room_id)
	return r != null and r.status == RoomData.Status.OCCUPIED and not r.key_issued \
			and issued_key_room_id == 0


func take_key(room_id: int) -> bool:
	if not can_take_key(room_id):
		return false
	issued_key_room_id = room_id
	key_state_changed.emit()
	return true


## Give the held key to the guest of that room.
func hand_over_key(room_id: int) -> bool:
	var r: RoomData = get_room(room_id)
	if r == null or issued_key_room_id != room_id:
		return false
	r.key_issued = true
	issued_key_room_id = 0
	key_state_changed.emit()
	return true
