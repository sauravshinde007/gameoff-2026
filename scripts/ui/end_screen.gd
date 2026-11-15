class_name EndScreen
extends CanvasLayer
## "Shift complete" screen. Shown by main.gd when the clock reaches 6 AM.

signal restart_requested

@export var time_text: String = "6:00 AM"
@export var title_text: String = "SHIFT COMPLETE"
@export_multiline var closing_text: String = "You made it to morning."
@export var fade_seconds: float = 1.5

@onready var content: Control = %Content
@onready var time_label: Label = %TimeLabel
@onready var title_label: Label = %TitleLabel
@onready var closing_label: Label = %ClosingLabel
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	var screen_font: Font = preload("res://assets/fonts/screen_font.tres")
	var text_font: Font = preload("res://assets/fonts/subtitle_font.tres")
	time_label.add_theme_font_override("font", screen_font)
	title_label.add_theme_font_override("font", screen_font)
	closing_label.add_theme_font_override("font", text_font)
	time_label.text = time_text
	title_label.text = title_text
	closing_label.text = closing_text
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func show_screen() -> void:
	visible = true
	content.modulate.a = 0.0
	create_tween().tween_property(content, "modulate:a", 1.0, fade_seconds)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	AudioManager.play_sfx(&"ui_click")
	restart_requested.emit()


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(&"ui_click")
	get_tree().quit()
