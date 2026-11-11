extends Node
## Accelerated shift clock. Minutes are absolute (see ShiftData). Systems can pause it with hold().

signal time_changed(minute: int)
signal shift_ended()

@export var data: ShiftData = preload("res://data/shift/night_shift.tres")

var running: bool = false
var _elapsed_minutes: float = 0.0
var _minute: int = 0
var _holds: Dictionary[StringName, bool] = {}
var _end_blocks: Dictionary[StringName, bool] = {}
var _fast: bool = false


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if not running or not _holds.is_empty():
		return
	var pace: float = data.fast_seconds_per_hour if _fast else data.seconds_per_hour
	_elapsed_minutes += delta * 60.0 / pace
	var new_minute: int = data.start_minute + int(_elapsed_minutes)
	if new_minute >= data.end_minute:
		if _end_blocks.is_empty():
			new_minute = data.end_minute
			running = false
		else:
			# Something (an incident) is still running: wait one minute short of the end.
			new_minute = data.end_minute - 1
	if new_minute != _minute:
		_minute = new_minute
		time_changed.emit(_minute)
	if not running:
		shift_ended.emit()


## Begin the clock. No-op if already running or finished.
func start() -> void:
	if running or _minute >= data.end_minute:
		return
	running = true


func reset() -> void:
	running = false
	_elapsed_minutes = 0.0
	_holds.clear()
	_end_blocks.clear()
	_fast = false
	_minute = data.start_minute
	time_changed.emit(_minute)


func get_minute() -> int:
	return _minute


## Pause the clock until every hold is released.
func hold(reason: StringName) -> void:
	_holds[reason] = true


func release(reason: StringName) -> void:
	_holds.erase(reason)


## The shift cannot end while any block is active. The clock waits at the last minute instead.
func block_end(reason: StringName) -> void:
	_end_blocks[reason] = true


func unblock_end(reason: StringName) -> void:
	_end_blocks.erase(reason)


## true = clock runs at data.fast_seconds_per_hour.
func set_fast(fast: bool) -> void:
	_fast = fast


func is_held() -> bool:
	return not _holds.is_empty()


func get_time_text() -> String:
	return format_minute(_minute)


static func format_minute(minute: int) -> String:
	var day_minute: int = minute % 1440
	var hour24: int = day_minute / 60
	var suffix: String = "AM" if hour24 < 12 else "PM"
	var hour12: int = hour24 % 12
	if hour12 == 0:
		hour12 = 12
	return "%d:%02d %s" % [hour12, day_minute % 60, suffix]
