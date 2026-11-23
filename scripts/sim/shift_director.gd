class_name ShiftDirector
extends Node
## Generates the shift's occasional work: phone calls (bookings, enquiries, requests) and room
## faults. Every event respects caps from SimTuning, so work never piles up endlessly.
## At the end of the shift it charges the operating cost and builds the report.

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")

var _next_minute: int = -1
var _finished: bool = false
var _report: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_to_group(&"shift_director")
	ShiftManager.time_changed.connect(_on_time_changed)


func _on_time_changed(minute: int) -> void:
	if not ShiftManager.running or _finished:
		return
	if _next_minute < 0:
		_next_minute = minute + tuning.director_first_event_minutes
	if minute < _next_minute:
		return
	_next_minute = minute + tuning.director_interval_minutes
	_generate()


## Try a few weighted picks; the first one that is allowed and makes sense happens.
func _generate() -> void:
	var keys: Array = tuning.director_weights.keys()
	for _attempt: int in 6:
		var key: String = _pick(keys)
		if key.is_empty():
			return
		if _try_event(key):
			return


func _pick(keys: Array) -> String:
	var total: int = 0
	for k: String in keys:
		total += int(tuning.director_weights[k])
	if total <= 0:
		return ""
	var roll: int = _rng.randi() % total
	for k: String in keys:
		roll -= int(tuning.director_weights[k])
		if roll < 0:
			return k
	return ""


func _try_event(key: String) -> bool:
	var parts: PackedStringArray = key.split(":")
	var kind: StringName = StringName(parts[0])
	var type: StringName = StringName(parts[1]) if parts.size() > 1 else &""
	if kind == &"fault":
		return _try_fault(type)
	var dispatcher: PhoneDispatcher = get_tree().get_first_node_in_group(&"phone_dispatcher") as PhoneDispatcher
	if dispatcher == null or dispatcher.queue_size() >= tuning.director_max_pending_calls:
		return false
	if kind == &"service":
		if type == &"wakeup":
			if TaskManager.count_open(true) >= tuning.director_max_mandatory:
				return false
		elif TaskManager.count_open(false) + dispatcher.queue_size() >= tuning.director_max_optional:
			return false
		if type == &"maintenance" and TaskManager.count_open_urgent() >= tuning.director_max_urgent:
			return false
	if not dispatcher.is_feasible(kind, type):
		return false
	dispatcher.queue_call(kind, type)
	return true


func _try_fault(type: StringName) -> bool:
	var maintenance: MaintenanceSystem = get_tree().get_first_node_in_group(&"maintenance_system") as MaintenanceSystem
	if maintenance == null or maintenance.fault_count() >= tuning.director_max_faults:
		return false
	if TaskManager.count_open(false) >= tuning.director_max_optional:
		return false
	return maintenance.create_fault(
			MaintenanceSystem.Fault.BULB if type == &"bulb" else MaintenanceSystem.Fault.REPAIR)


## Called once when the clock reaches the end. Charges operating costs (never more than the
## balance, so no debt), then returns the final report. Safe to call again.
func finish_shift() -> Dictionary:
	if _finished:
		return _report
	_finished = true
	# Cash still lying on the desk is banked before closing the books.
	get_tree().call_group(&"cash_stash", &"collect_all", true)
	var cost: int = EconomyManager.config.operating_cost
	var pay: int = mini(cost, EconomyManager.get_balance())
	if pay > 0:
		EconomyManager.record_expense(pay, &"operating", "Operating costs", "operating:shift")
	_report = ShiftReport.build(get_tree())
	return _report
