class_name Interactable
extends Area3D
## Attach to an Area3D (with a CollisionShape3D child). The player's Interactor
## finds it by raycast and calls interact(). Parent props listen to `interacted`.

signal interacted(by: Node)
## Emitted when prompt_text changes so a focused prompt can refresh.
signal prompt_changed()

@export var prompt_text: String = "Interact":
	set(value):
		prompt_text = value
		prompt_changed.emit()
@export var enabled: bool = true


func _ready() -> void:
	collision_layer = 4  # layer 3: interactable
	collision_mask = 0


func interact(by: Node) -> void:
	if enabled:
		interacted.emit(by)


func get_prompt() -> String:
	return prompt_text
