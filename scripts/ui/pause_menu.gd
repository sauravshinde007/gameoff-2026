class_name PauseMenu
extends CanvasLayer
## ESC while the player is idle (no dialogue / screen / transition) pauses the game.

signal restart_requested
signal title_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var title_button: Button = %TitleButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var font: Font = preload("res://assets/fonts/screen_font.tres")
	%PausedLabel.add_theme_font_override("font", font)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(func() -> void: _click(); restart_requested.emit())
	title_button.pressed.connect(func() -> void: _click(); title_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		resume()
	elif _player_idle():
		_open()
	else:
		return
	get_viewport().set_input_as_handled()


func resume() -> void:
	if not visible:
		return
	_click()
	visible = false
	get_tree().paused = false
	get_tree().call_group("player", "set_controls_enabled", true)


func _open() -> void:
	visible = true
	get_tree().paused = true
	get_tree().call_group("player", "set_controls_enabled", false)
	resume_button.grab_focus()


func _player_idle() -> bool:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_controls_enabled()


## The click must play while the tree is paused.
func _click() -> void:
	var p: Node = AudioManager.play_sfx(&"ui_click")
	if p != null:
		p.process_mode = Node.PROCESS_MODE_ALWAYS
