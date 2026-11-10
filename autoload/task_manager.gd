extends Node
## The shift's task list. Hidden until the manager's note is read (activate()).
## Props complete tasks by id via exported ids; unknown ids are ignored.

signal task_added(id: StringName)
signal task_completed(id: StringName)
signal tasks_changed()

@export var database: TaskDatabase = preload("res://data/tasks/night_tasks.tres")

var _tasks: Array[TaskData] = []
var _done: Dictionary[StringName, bool] = {}
var _active: bool = false


func _ready() -> void:
	load_tasks(database)


func load_tasks(db: TaskDatabase) -> void:
	database = db
	_tasks.clear()
	_done.clear()
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


func add_task(task: TaskData) -> void:
	_tasks.append(task)
	task_added.emit(task.id)
	tasks_changed.emit()


func is_completed(id: StringName) -> bool:
	return _done.get(id, false)


func complete_task(id: StringName) -> void:
	if _done.get(id, false):
		return
	for t: TaskData in _tasks:
		if t.id == id and not t.is_rule:
			_done[id] = true
			task_completed.emit(id)
			tasks_changed.emit()
			return
