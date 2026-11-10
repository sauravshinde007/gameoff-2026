class_name ManagerNote
extends Node3D
## The manager's note. Reading it shows the task list.

@onready var interactable: Interactable = $Interactable
@onready var note_panel: NotePanel = $NotePanel


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	note_panel.open(TaskManager.database.note_title, TaskManager.database.note_text)
	TaskManager.activate()
