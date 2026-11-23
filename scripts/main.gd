extends Node3D

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

## Day flow: spawn at the entrance gate -> "DAY n" caption -> walk to reception and unlock the
## front door -> start-time caption, shift starts -> shift ends -> lock the front door from outside
## -> walk out through the gate -> shift report.
@export var day_number: int = 1
@export var day_caption_format: String = "DAY %d"
@export var intro_message: String = "Walk up to the reception and unlock the front door to open the motel."
@export var intro_message_seconds: float = 7.0
@export var night_caption: String = "6:00 AM"
@export var closing_message: String = "Shift's over. Lock the reception's front door from outside, then leave through the gate."
@export var closing_message_seconds: float = 7.0
@export var service_door_path: NodePath = ^"Motel/Service/Doors/ServiceDoor"
@export var lock_from_inside_message: String = "Step outside first, then lock the door."
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
@onready var gate_exit: Area3D = $GateExit
## Other ways into the reception/staff area. They stay locked until the front door is unlocked.
@onready var back_doors: Array[Door] = _find_back_doors()

var _entrance: Door
var _report: Dictionary = {}
var _day_over: bool = false


func _ready() -> void:
	interactor.focus_changed.connect(hud.set_prompt)
	EventManager.flag_set.connect(_on_flag_set)
	ShiftManager.shift_ended.connect(_on_shift_ended)
	end_screen.restart_requested.connect(restart)
	pause_menu.restart_requested.connect(restart)
	pause_menu.title_requested.connect(quit_to_title)
	gate_exit.body_entered.connect(_on_gate_exit_entered)
	_entrance = get_tree().get_first_node_in_group(&"entrance_doors") as Door
	if _entrance != null:
		_entrance.key_requested.connect(_on_entrance_key)
		_entrance.set_key_locked(true)
		_entrance.set_key_action("Unlock")
	_set_back_doors_locked(true)
	_begin_day()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _on_flag_set(flag: StringName) -> void:
	if flag == &"shift_started":
		_begin_night()


## Black screen with the "DAY n" caption (same fade as the shift-start time caption), then the
## player is standing at the entrance gate.
func _begin_day() -> void:
	get_tree().call_group("player", "set_controls_enabled", false)
	screen_fade.set_black()
	await screen_fade.fade_out(boot_fade_seconds, day_caption_format % day_number)
	await get_tree().create_timer(caption_hold_seconds).timeout
	await screen_fade.fade_in(fade_in_seconds)
	get_tree().call_group("player", "set_controls_enabled", true)
	get_tree().call_group("hud", "show_message", intro_message, intro_message_seconds)


## Front door key actions: "Unlock" opens the motel (starts the shift), "Lock" closes up after it.
func _on_entrance_key(action: String, by: Node) -> void:
	if action == "Unlock":
		_entrance.set_key_action("")
		_entrance.set_key_locked(false)
		AudioManager.play_sfx(&"door_handle", _entrance.global_position)
		_entrance.set_open(true, by as Node3D)
		_set_back_doors_locked(false)
		EventManager.set_flag(&"shift_started")
	elif action == "Lock":
		if _is_inside_reception(by as Node3D):
			get_tree().call_group("hud", "show_message", lock_from_inside_message)
			return
		_entrance.set_key_action("")
		_entrance.set_key_locked(true)
		_set_back_doors_locked(true)
		AudioManager.play_sfx(&"door_handle", _entrance.global_position)
		TaskManager.complete_task(&"lock_up")
		gate_exit.monitoring = true


func _find_back_doors() -> Array[Door]:
	var found: Array[Door] = []
	var door: Door = get_node_or_null(service_door_path) as Door
	if door != null:
		found.append(door)
	return found


func _set_back_doors_locked(locked: bool) -> void:
	for d: Door in back_doors:
		d.set_key_locked(locked)


## The reception (the door's parent scene) is on the inside; compare sides along the door normal.
func _is_inside_reception(node: Node3D) -> bool:
	if node == null:
		return false
	var room: Node3D = _entrance.get_parent() as Node3D
	var normal: Vector3 = _entrance.global_basis.z
	var inside_sign: float = signf((room.global_position - _entrance.global_position).dot(normal))
	return signf((node.global_position - _entrance.global_position).dot(normal)) == inside_sign


## End of shift (10 PM): operating costs charged and the report built now (so the closing tasks
## don't count in it); then the player locks up and walks out through the gate.
func _on_shift_ended() -> void:
	var director: ShiftDirector = get_tree().get_first_node_in_group(&"shift_director") as ShiftDirector
	_report = director.finish_shift() if director != null else {}
	AudioManager.play_sfx(&"end_sting")
	_add_closing_task(&"lock_up", "Lock the reception's front door.")
	_add_closing_task(&"leave_gate", "Leave through the entrance gate.")
	if _entrance != null:
		_entrance.set_key_action("Lock")
	else:
		gate_exit.monitoring = true
	get_tree().call_group("hud", "show_message", closing_message, closing_message_seconds)


func _add_closing_task(id: StringName, text: String) -> void:
	var t: TaskData = TaskData.new()
	t.id = id
	t.text = text
	t.category = &"closing"
	t.mandatory = true
	TaskManager.add_task(t)


func _on_gate_exit_entered(body: Node3D) -> void:
	if _day_over or not body.is_in_group(&"player"):
		return
	_day_over = true
	TaskManager.complete_task(&"leave_gate")
	_end_day()


## Controls off, fade to black, then the shift report screen.
func _end_day() -> void:
	get_tree().call_group("player", "set_controls_enabled", false)
	await screen_fade.fade_out(end_fade_seconds)
	AudioManager.set_ambience(&"")
	end_screen.show_screen(_report)


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


## Fade to black with the start time -> fade in -> the clock starts. Lighting follows the clock
## through DayNightCycle (dawn at 6 AM, day, sunset, night by the 10 PM end).
func _begin_night() -> void:
	get_tree().call_group("player", "set_controls_enabled", false)
	await screen_fade.fade_out(fade_out_seconds, night_caption)
	await get_tree().create_timer(caption_hold_seconds).timeout
	TaskManager.activate()
	await screen_fade.fade_in(fade_in_seconds)
	get_tree().call_group("player", "set_controls_enabled", true)
	ShiftManager.start()
