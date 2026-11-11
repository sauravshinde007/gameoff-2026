class_name CctvMonitor
extends Node3D
## Reception CCTV monitor. Interact zooms the camera to the screen and opens the camera feed UI.

@onready var interactable: Interactable = $Interactable
@onready var screen: WorldScreen = $WorldScreen


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	screen.open()
