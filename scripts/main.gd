extends Node3D

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

@export var intro_message: String = "Your shift starts at 6 AM. Read the shift notes on the desk."
@export var intro_message_seconds: float = 7.0
@export var night_caption: String = "6:00 AM"
## false = morning shift (day lighting). true = night shift (night lighting).
@export var night_shift: bool = false
@export var fade_out_seconds: float = 1.2
@export var caption_hold_seconds: float = 1.6
@export var fade_in_seconds: float = 1.5
@export var boot_fade_seconds: float = 1.0
@export var end_fade_seconds: float = 2.5

@onready var interactor: Interactor = $Player/Head/Camera3D/Interactor
@onready var hud: CanvasLayer = $HUD
@onready var day_night: DayNight = $DayNight
@onready var screen_fade: ScreenFade = $ScreenFade
@onready var end_screen: EndScreen = $EndScreen
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	interactor.focus_changed.connect(hud.set_prompt)
	EventManager.flag_set.connect(_on_flag_set)
	ShiftManager.shift_ended.connect(_on_shift_ended)
	end_screen.restart_requested.connect(restart)
	pause_menu.restart_requested.connect(restart)
	pause_menu.title_requested.connect(quit_to_title)
	screen_fade.set_black()
	screen_fade.fade_in(boot_fade_seconds)
	get_tree().call_group("hud", "show_message", intro_message, intro_message_seconds)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _on_flag_set(flag: StringName) -> void:
	if flag == &"note_read":
		_begin_night()


## End of shift (2 PM): controls off, operating costs charged, fade to black, then the shift report screen.
func _on_shift_ended() -> void:
	get_tree().call_group("player", "set_controls_enabled", false)
	var director: ShiftDirector = get_tree().get_first_node_in_group(&"shift_director") as ShiftDirector
	var report: Dictionary = director.finish_shift() if director != null else {}
	AudioManager.play_sfx(&"end_sting")
	await screen_fade.fade_out(end_fade_seconds)
	AudioManager.set_ambience(&"")
	end_screen.show_screen(report)


## Fresh run: reset every global system, then reload the scene (back to the day intro).
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


## Fade to black with the start time -> shift lighting (day or night) -> fade in -> the clock starts.
func _begin_night() -> void:
	get_tree().call_group("player", "set_controls_enabled", false)
	await screen_fade.fade_out(fade_out_seconds, night_caption)
	day_night.apply(day_night.night_preset if night_shift else day_night.day_preset)
	await get_tree().create_timer(caption_hold_seconds).timeout
	TaskManager.activate()
	await screen_fade.fade_in(fade_in_seconds)
	get_tree().call_group("player", "set_controls_enabled", true)
	ShiftManager.start()
