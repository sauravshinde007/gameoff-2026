extends Node
## The shift's task list. Hidden until the manager's note is read (activate()).
## Props complete tasks by id via exported ids; unknown ids are ignored.

signal task_added(id: StringName)
signal task_completed(id: StringName)
signal task_failed(id: StringName)
signal task_removed(id: StringName)
signal tasks_changed()

@export var database: TaskDatabase = preload("res://data/tasks/night_tasks.tres")

var _tasks: Array[TaskData] = []
var _done: Dictionary[StringName, bool] = {}
var _failed: Dictionary[StringName, bool] = {}
var _active: bool = false


func _ready() -> void:
	load_tasks(database)


func load_tasks(db: TaskDatabase) -> void:
	database = db
	_tasks.clear()
	_done.clear()
	_failed.clear()
	for t: TaskData in db.tasks:
		_tasks.append(t)
	tasks_changed.emit()


func reset() -> void:
	_active = false
	load_tasks(database)


## Show the list. Completions recorded before this still count.
func activate() -> void:
	if _active:
		return
	_active = true
	tasks_changed.emit()


func is_active() -> bool:
	return _active


func get_tasks() -> Array[TaskData]:
	return _tasks


func get_task(id: StringName) -> TaskData:
	for t: TaskData in _tasks:
		if t.id == id:
			return t
	return null


## Ignored if a task with this id already exists (no duplicate tasks).
func add_task(task: TaskData) -> void:
	if get_task(task.id) != null:
		return
	_tasks.append(task)
	task_added.emit(task.id)
	tasks_changed.emit()


func is_completed(id: StringName) -> bool:
	return _done.get(id, false)


func is_failed(id: StringName) -> bool:
	return _failed.get(id, false)


## Not completed, not failed, not a rule.
func is_open(id: StringName) -> bool:
	var t: TaskData = get_task(id)
	return t != null and not t.is_rule and not is_completed(id) and not is_failed(id)


## Open (not done, not failed) tasks that are not rules. mandatory: true/false filters by that flag.
func count_open(mandatory: bool) -> int:
	var n: int = 0
	for t: TaskData in _tasks:
		if t.mandatory == mandatory and is_open(t.id):
			n += 1
	return n


## Non-rule tasks completed so far.
func count_completed() -> int:
	var n: int = 0
	for t: TaskData in _tasks:
		if not t.is_rule and is_completed(t.id):
			n += 1
	return n


func count_failed() -> int:
	var n: int = 0
	for t: TaskData in _tasks:
		if not t.is_rule and is_failed(t.id):
			n += 1
	return n


func count_open_urgent() -> int:
	var n: int = 0
	for t: TaskData in _tasks:
		if t.priority == TaskData.Priority.URGENT and is_open(t.id):
			n += 1
	return n


## Marks an open task failed (missed deadline, cancelled by the system). Rules cannot fail.
func fail_task(id: StringName) -> void:
	if not is_open(id):
		return
	_failed[id] = true
	task_failed.emit(id)
	tasks_changed.emit()


## Drops a task without counting it as done or failed (e.g. its guest left).
func remove_task(id: StringName) -> void:
	var t: TaskData = get_task(id)
	if t == null:
		return
	_tasks.erase(t)
	_done.erase(id)
	_failed.erase(id)
	task_removed.emit(id)
	tasks_changed.emit()


func complete_task(id: StringName) -> void:
	if _done.get(id, false) or _failed.get(id, false):
		return
	for t: TaskData in _tasks:
		if t.id == id and not t.is_rule:
			_done[id] = true
			task_completed.emit(id)
			tasks_changed.emit()
			return
