class_name ManagerNote
extends Node3D
## Shift notes board on the reception wall. Read-only: the instructions are drawn on the board
## itself (TaskManager.database note_title / note_text). The shift starts by unlocking the
## reception front door (see main.gd), not here.

@onready var title_label: Label3D = $Title
@onready var body_label: Label3D = $Body


func _ready() -> void:
	var db: TaskDatabase = TaskManager.database
	if db != null:
		title_label.text = db.note_title
		body_label.text = db.note_text
