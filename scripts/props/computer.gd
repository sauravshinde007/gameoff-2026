class_name Computer
extends Node3D
## Reception computer. Interact zooms the camera to the screen and opens the terminal UI.

@onready var interactable: Interactable = $Interactable
@onready var screen: WorldScreen = $WorldScreen


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	screen.open()
