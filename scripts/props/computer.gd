class_name Computer
extends Node3D
## Reception computer. Interact opens the management terminal UI.

@onready var interactable: Interactable = $Interactable
@onready var screen: ComputerScreen = $ComputerScreen


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	screen.open()
