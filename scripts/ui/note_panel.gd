class_name NotePanel
extends CanvasLayer
## Generic read-only paper panel: open(title, body). Esc, E or the button closes it.

signal closed

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.9, 0.87, 0.72)
	sb.border_color = Color(0.32, 0.18, 0.1)
	sb.set_border_width_all(12)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	var ink: Color = Color(0.12, 0.1, 0.08)
	title_label.add_theme_font_override("font", preload("res://assets/fonts/screen_font.tres"))
	body_label.add_theme_font_override("font", preload("res://assets/fonts/subtitle_font.tres"))
	title_label.add_theme_color_override("font_color", ink)
	body_label.add_theme_color_override("font_color", ink)
	close_button.pressed.connect(close)


func open(title: String, body: String) -> void:
	if visible:
		return
	title_label.text = title
	body_label.text = body
	visible = true
	get_tree().call_group("player", "set_controls_enabled", false)


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().call_group("player", "set_controls_enabled", true)
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("interact")):
		close()
		get_viewport().set_input_as_handled()
