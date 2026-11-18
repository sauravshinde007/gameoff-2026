class_name RoomServicePoint
extends Node3D
## Tray beside a room door. Deliver what a guest asked for (towels, pillows, ice, coffee) or
## clean or repair an occupied room on request. Works from outside, so locked rooms are served too.

## Request type -> carried item delivered for it.
const DELIVERY_ITEMS: Dictionary = {
	&"towels": &"towels", &"pillows": &"pillows", &"ice": &"ice", &"coffee": &"coffee"}

@export var room_id: int = 0
@export var point_size: Vector3 = Vector3(0.6, 0.6, 0.5)

@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _busy: bool = false


func _ready() -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = point_size
	shape.shape = box
	interactable.interacted.connect(_on_interacted)
	GuestManager.requests_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var open: Array[ServiceRequest] = _open_requests()
	if open.is_empty():
		interactable.prompt_text = "Room %02d service tray" % room_id
	else:
		interactable.prompt_text = "Serve Room %02d (%s)" % [room_id, open[0].type]


func _open_requests() -> Array[ServiceRequest]:
	var out: Array[ServiceRequest] = []
	for r: ServiceRequest in GuestManager.get_requests():
		if r.room_id == room_id and r.state == ServiceRequest.State.ACTIVE \
				and (DELIVERY_ITEMS.has(r.type) or r.type == &"cleaning" or r.type == &"maintenance"):
			out.append(r)
	return out


func _needs(req: ServiceRequest) -> Dictionary:
	if req.type == &"cleaning":
		return InventoryManager.catalog.clean_cost
	if req.type == &"maintenance":
		return {}
	return {DELIVERY_ITEMS[req.type]: 1}


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)


func _on_interacted(_by: Node) -> void:
	if _busy:
		return
	var open: Array[ServiceRequest] = _open_requests()
	if open.is_empty():
		_say("No requests for Room %02d." % room_id)
		return
	for req: ServiceRequest in open:
		if InventoryManager.has_carried_all(_needs(req)):
			_serve(req)
			return
	var missing: PackedStringArray = InventoryManager.missing_names(_needs(open[0]))
	_say("Room %02d: %s. Missing: %s." % [room_id, open[0].type, ", ".join(missing)])


func _serve(req: ServiceRequest) -> void:
	if req.type != &"cleaning" and req.type != &"maintenance":
		_finish(req)
		return
	_busy = true
	interactable.enabled = false
	var seconds: float = InventoryManager.catalog.clean_seconds
	if req.type == &"maintenance":
		seconds = GuestManager.tuning.repair_seconds
	var caption: String = "%s Room %02d..." % [
			"Repairing" if req.type == &"maintenance" else "Cleaning", room_id]
	WorkTransition.run(get_tree(), caption, seconds, _finish_timed.bind(req))


func _finish_timed(req: ServiceRequest) -> void:
	_busy = false
	interactable.enabled = true
	_finish(req)


## Consume, pay (ice/coffee), then complete the request, in that order and once.
func _finish(req: ServiceRequest) -> void:
	if req.state != ServiceRequest.State.ACTIVE:
		_say("That request is no longer open.")
		return
	if not InventoryManager.consume_carried(_needs(req)):
		_say("You no longer have what is needed.")
		return
	var price: int = 0
	if req.type == &"ice":
		price = EconomyManager.config.ice_price
	elif req.type == &"coffee":
		price = EconomyManager.config.coffee_price
	if price > 0:
		EconomyManager.record_income(price, &"service", "%s, Room %02d" % [req.type, room_id],
				"req:" + req.id, room_id)
	GuestManager.complete_request(req.id)
	_say("Done: %s for Room %02d." % [req.type, room_id])
