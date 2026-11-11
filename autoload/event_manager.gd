extends Node
## Fires timed events from data and stores story flags. Scenes listen to event_triggered.

signal event_triggered(id: StringName)
signal flag_set(flag: StringName)

@export var database: EventDatabase = preload("res://data/events/night_events.tres")

var _pending: Array[EventData] = []
var _fired: Dictionary[StringName, bool] = {}
var _flags: Dictionary[StringName, bool] = {}


func _ready() -> void:
	ShiftManager.time_changed.connect(_on_time_changed)
	reset()


func reset() -> void:
	for e: EventData in _pending:
		ShiftManager.release(e.id)
	_pending.clear()
	_fired.clear()
	_flags.clear()
	_collect_due(ShiftManager.get_minute())


func set_flag(flag: StringName) -> void:
	if _flags.get(flag, false):
		return
	_flags[flag] = true
	flag_set.emit(flag)


func has_flag(flag: StringName) -> bool:
	return _flags.get(flag, false)


func _process(_delta: float) -> void:
	for e: EventData in _pending.duplicate():
		if _can_fire(e):
			_fire(e)
		else:
			ShiftManager.hold(e.id)


func _on_time_changed(minute: int) -> void:
	_collect_due(minute)


func _collect_due(minute: int) -> void:
	for e: EventData in database.events:
		if minute >= e.trigger_minute and not _fired.has(e.id) and not _pending.has(e):
			_pending.append(e)


func _can_fire(e: EventData) -> bool:
	for task_id: StringName in e.required_tasks:
		if not TaskManager.is_completed(task_id):
			return false
	if e.wait_for_idle:
		if DialogueManager.is_active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return false
	if e.phone_call != null:
		var phone: Telephone = get_tree().get_first_node_in_group(&"telephone") as Telephone
		if phone == null or phone.state != Telephone.State.IDLE:
			return false
	return true


func _fire(e: EventData) -> void:
	_pending.erase(e)
	_fired[e.id] = true
	ShiftManager.release(e.id)
	if e.phone_call != null:
		get_tree().call_group(&"telephone", &"ring", e.phone_call)
	event_triggered.emit(e.id)
