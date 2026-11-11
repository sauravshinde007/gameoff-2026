class_name MysteriousGuest
extends StaticBody3D
## The Room 13 guest. Hidden until appear(). Talk -> check reservation on computer -> refuse.
## Emits talked(step): &"asked" after the first talk, &"refused" after the refusal exchange.

signal talked(step: StringName)

@export var dialogue_arrive: DialogueData
@export var dialogue_remind: DialogueData
@export var dialogue_prompt: DialogueData
@export var dialogue_refusal: DialogueData
## Story flag the computer sets once the player has looked at the Room 13 reservation.
@export var viewed_flag: StringName = &"viewed_res_0013"

@onready var interactable: Interactable = $Interactable
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var area_shape: CollisionShape3D = $Interactable/CollisionShape3D

var _asked: bool = false
var _current_id: StringName = &""


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_set_present(false)


func appear() -> void:
	_set_present(true)


func vanish() -> void:
	_set_present(false)


func _set_present(present: bool) -> void:
	visible = present
	interactable.enabled = present
	body_shape.set_deferred("disabled", not present)
	area_shape.set_deferred("disabled", not present)


func _on_interacted(_by: Node) -> void:
	if DialogueManager.is_active():
		return
	if not _asked:
		_start(dialogue_arrive)
	elif not EventManager.has_flag(viewed_flag):
		_start(dialogue_remind)
	else:
		_start(dialogue_prompt)


func _start(data: DialogueData) -> void:
	_current_id = data.id
	DialogueManager.start(data)


func _on_dialogue_finished(id: StringName, choice: int) -> void:
	if id != _current_id:
		return
	_current_id = &""
	if id == dialogue_arrive.id:
		_asked = true
		talked.emit(&"asked")
	elif id == dialogue_prompt.id and choice == 0:
		# Deferred: let the dialogue box finish closing before the next one opens.
		_start.call_deferred(dialogue_refusal)
	elif id == dialogue_refusal.id:
		interactable.enabled = false
		talked.emit(&"refused")
