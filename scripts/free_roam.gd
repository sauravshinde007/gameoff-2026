extends Node3D
## Free Roam: walk the motel environment with no tasks, shift clock, events or story.
## For environment review. Time of day loops on its own (DayNightCycle); N skips ahead,
## ESC opens the pause menu.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

@export var help_text: String = "FREE ROAM   [N] Skip 2 hours   [F] Hold: timelapse   [ESC] Menu"
@export var skip_hours: float = 2.0
## Holding F speeds the clock up by this factor (a timelapse of the scene).
@export var timelapse_scale: float = 40.0
@export var toggle_message_seconds: float = 1.5

@onready var interactor: Interactor = $Player/Head/Camera3D/Interactor
@onready var hud: CanvasLayer = $HUD
@onready var cycle: DayNightCycle = $DayNightCycle
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var help_label: Label = %HelpLabel


func _ready() -> void:
	interactor.focus_changed.connect(hud.set_prompt)
	pause_menu.restart_requested.connect(restart)
	pause_menu.title_requested.connect(quit_to_title)
	help_label.add_theme_font_override("font", preload("res://assets/fonts/pixel_font.tres"))
	help_label.text = help_text


func _process(_delta: float) -> void:
	var lapse: bool = Input.is_action_pressed("time_lapse") and not get_tree().paused
	cycle.time_scale = timelapse_scale if lapse else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("toggle_day_night"):
		cycle.skip_hours(skip_hours)
		get_tree().call_group("hud", "show_message", cycle.get_time_text(), toggle_message_seconds)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


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
	EconomyManager.reset()
	GuestManager.reset()
	InventoryManager.reset()
	DialogueManager.reset()
	AudioManager.stop_all()
	get_tree().paused = false
