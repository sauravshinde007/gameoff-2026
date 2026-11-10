class_name TaskDatabase
extends Resource
## Starting task list plus the manager's note text. Edit data/tasks/night_tasks.tres.

@export var tasks: Array[TaskData] = []
@export var note_title: String = ""
@export_multiline var note_text: String = ""
