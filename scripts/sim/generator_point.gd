class_name GeneratorPoint
extends Node3D
## The motel generator in the rear yard. Fuel drains with shift time. At the low level a refuel
## task appears (one at a time). At the critical level the ice machine and coffee maker stop
## working until the player pours in a carried fuel can.

signal fuel_changed(percent: float)
## Emitted when the critical (no ice / coffee) state flips.
signal power_changed()

const FUEL_ITEM: StringName = &"fuel"

@export var tuning: SimTuning = preload("res://data/sim/sim_tuning.tres")
@export var point_size: Vector3 = Vector3(2.0, 1.4, 2.0)
## Regular duty completed the first time the player checks the generator.
@export var check_task_id: StringName = &"check_generator"

@onready var interactable: Interactable = $Interactable
@onready var shape: CollisionShape3D = $Interactable/CollisionShape3D

var _fuel: float = 100.0
var _last_minute: int = 0
var _task_id: StringName = &""
var _task_count: int = 0
var _was_critical: bool = false


func _ready() -> void:
	add_to_group(&"generator")
	var box: BoxShape3D = BoxShape3D.new()
	box.size = point_size
	shape.shape = box
	shape.position = Vector3(0.0, point_size.y * 0.5, 0.0)
	_fuel = tuning.generator_start_fuel
	_last_minute = ShiftManager.get_minute()
	ShiftManager.time_changed.connect(_on_time_changed)
	InventoryManager.carry_changed.connect(_refresh_prompt)
	interactable.interacted.connect(_on_interacted)
	_refresh_prompt()


func get_fuel() -> float:
	return _fuel


func is_low() -> bool:
	return _fuel <= tuning.generator_low_fuel


func is_critical() -> bool:
	return _fuel <= tuning.generator_critical_fuel


func _on_time_changed(minute: int) -> void:
	var elapsed: int = minute - _last_minute
	_last_minute = minute
	if elapsed <= 0 or not ShiftManager.running:
		return
	_set_fuel(_fuel - tuning.generator_drain_per_hour * float(elapsed) / 60.0)


func _set_fuel(value: float) -> void:
	var was_low: bool = is_low()
	_fuel = clampf(value, 0.0, 100.0)
	fuel_changed.emit(_fuel)
	_refresh_prompt()
	if is_low() and not was_low:
		_say("The generator is running low on fuel.")
	_update_task()
	var critical: bool = is_critical()
	if critical != _was_critical:
		_was_critical = critical
		if critical:
			_say("The generator is almost empty. Ice and coffee are off.")
		power_changed.emit()


## One open task while low; it completes once fuel is back above the low level.
func _update_task() -> void:
	if is_low():
		if _task_id == &"" or not TaskManager.is_open(_task_id):
			_task_count += 1
			_task_id = StringName("refuel_generator_%d" % _task_count)
			var task: TaskData = TaskData.new()
			task.id = _task_id
			task.text = "Refuel the generator"
			task.category = &"maintenance"
			task.priority = TaskData.Priority.URGENT
			TaskManager.add_task(task)
	elif _task_id != &"":
		TaskManager.complete_task(_task_id)
		_task_id = &""


func _refresh_prompt() -> void:
	var text: String = "Generator (fuel %d%%)" % int(round(_fuel))
	if InventoryManager.has_carried(FUEL_ITEM):
		text = "Refuel generator (fuel %d%%)" % int(round(_fuel))
	interactable.prompt_text = text


func _say(text: String) -> void:
	get_tree().call_group("hud", "show_message", text)


func _on_interacted(_by: Node) -> void:
	TaskManager.complete_task(check_task_id)
	if _fuel >= 100.0:
		_say("The generator is full.")
		return
	if not InventoryManager.has_carried(FUEL_ITEM):
		_say("Generator fuel: %d%%. Need a fuel can from storage." % int(round(_fuel)))
		return
	if not InventoryManager.consume_carried({FUEL_ITEM: 1}):
		return
	_set_fuel(_fuel + tuning.generator_fuel_per_can)
	AudioManager.play_sfx(&"door_close", global_position)
	_say("Generator refuelled: %d%%." % int(round(_fuel)))
