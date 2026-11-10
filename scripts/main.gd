extends Node3D

@onready var interactor: Interactor = $Player/Head/Camera3D/Interactor
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	interactor.focus_changed.connect(hud.set_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
