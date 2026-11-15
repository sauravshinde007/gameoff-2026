extends Node3D
## Free Roam: walk the motel environment with no tasks, shift clock, events or story.
## For environment review. N toggles day/night, ESC opens the pause menu.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

@export var help_text: String = "FREE ROAM   [N] Day/Night   [ESC] Menu"
@export var toggle_message_seconds: float = 1.5

@onready var interactor: Interactor = $Player/Head/Camera3D/Interactor
@onready var hud: CanvasLayer = $HUD
@onready var day_night: DayNight = $DayNight
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var help_label: Label = %HelpLabel

var _is_night: bool = false


func _ready() -> void:
	interactor.focus_changed.connect(hud.set_prompt)
	pause_menu.restart_requested.connect(restart)
	pause_menu.title_requested.connect(quit_to_title)
	help_label.add_theme_font_override("font", preload("res://assets/fonts/pixel_font.tres"))
	help_label.text = help_text
	_is_night = not day_night.start_with_day


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("toggle_day_night"):
		set_night(not _is_night)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func set_night(night: bool) -> void:
	_is_night = night
	day_night.apply(day_night.night_preset if night else day_night.day_preset)
	get_tree().call_group("hud", "show_message", "Night" if night else "Day", toggle_message_seconds)


func restart() -> void:
	_reset_all()
	get_tree().reload_current_scene()


func quit_to_title() -> void:
	_reset_all()
	get_tree().change_scene_to_file(TITLE_SCENE)


func _reset_all() -> void:
	ShiftManager.reset()
	EventManager.reset()
	TaskManager.reset()
	RoomManager.reset()
	DialogueManager.reset()
	AudioManager.stop_all()
	get_tree().paused = false
