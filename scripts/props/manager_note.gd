class_name ManagerNote
extends Node3D
## The manager's note. Closing it for the first time sets flag note_read, which starts the night (see main.gd).

@onready var interactable: Interactable = $Interactable
@onready var note_panel: NotePanel = $NotePanel


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	note_panel.closed.connect(_on_closed)


func _on_interacted(_by: Node) -> void:
	note_panel.open(TaskManager.database.note_title, TaskManager.database.note_text)


func _on_closed() -> void:
	EventManager.set_flag(&"note_read")
