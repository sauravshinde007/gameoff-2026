class_name MysteriousGuest
extends StaticBody3D
## A reusable standing character (used by the NPC viewer). No story, no dialogue.
## Hidden until appear().

@onready var interactable: Interactable = $Interactable
@onready var body_shape: CollisionShape3D = $CollisionShape3D
@onready var area_shape: CollisionShape3D = $Interactable/CollisionShape3D


func _ready() -> void:
	_set_present(false)


func appear() -> void:
	_set_present(true)


func vanish() -> void:
	_set_present(false)


func _set_present(present: bool) -> void:
	visible = present
	interactable.enabled = false
	body_shape.set_deferred("disabled", not present)
	area_shape.set_deferred("disabled", true)
