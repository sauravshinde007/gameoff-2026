class_name WallClock
extends Node3D
## Wall clock showing ShiftManager time. Interact to read it out.

@onready var interactable: Interactable = $Interactable
@onready var face: Label3D = $Face


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	ShiftManager.time_changed.connect(_on_time_changed)
	_on_time_changed(ShiftManager.get_minute())


func _on_time_changed(minute: int) -> void:
	face.text = ShiftManager.format_minute(minute)


func _on_interacted(_by: Node) -> void:
	get_tree().call_group("hud", "show_message", "It is %s." % ShiftManager.get_time_text())
