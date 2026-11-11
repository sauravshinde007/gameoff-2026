extends Control
## Title screen: Start fades to black, then loads the motel.

const MAIN_SCENE: String = "res://scenes/main.tscn"

@export var ambience: StringName = &"day_ambience"
@export var fade_seconds: float = 1.2

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var fade: ColorRect = %Fade

var _starting: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%TitleLabel.add_theme_font_override("font", preload("res://assets/fonts/screen_font.tres"))
	%SubtitleLabel.add_theme_font_override("font", preload("res://assets/fonts/subtitle_font.tres"))
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	AudioManager.set_ambience(ambience)
	start_button.grab_focus()
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, fade_seconds)


func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	AudioManager.play_sfx(&"ui_click")
	var t: Tween = create_tween()
	t.tween_property(fade, "modulate:a", 1.0, fade_seconds)
	await t.finished
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(&"ui_click")
	get_tree().quit()
