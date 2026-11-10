class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue panel. Draws whatever DialogueManager emits.
## E or left click advances (or finishes the typing first). Choices are buttons.

@export var chars_per_second: float = 45.0

@onready var panel: PanelContainer = %Panel
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var hint_label: Label = %HintLabel

var _typing: bool = false
var _choosing: bool = false
var _type_tween: Tween


func _ready() -> void:
	visible = false
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.05, 0.88)
	sb.border_color = Color(0.6, 0.6, 0.65, 0.8)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	DialogueManager.dialogue_started.connect(_on_started)
	DialogueManager.line_shown.connect(_on_line)
	DialogueManager.choices_shown.connect(_on_choices)
	DialogueManager.dialogue_finished.connect(_on_finished)


func _input(event: InputEvent) -> void:
	if not visible or _choosing:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("interact") or is_click:
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
		else:
			DialogueManager.advance()


func _on_started(_id: StringName) -> void:
	_clear_choices()
	visible = true
	get_tree().call_group("player", "set_controls_enabled", false)


func _on_line(speaker: String, text: String) -> void:
	_choosing = false
	_clear_choices()
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	text_label.text = text
	hint_label.visible = true
	_start_typing()


func _on_choices(options: PackedStringArray) -> void:
	_choosing = true
	hint_label.visible = false
	for i: int in options.size():
		var b: Button = Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(DialogueManager.choose.bind(i))
		choices_box.add_child(b)
	(choices_box.get_child(0) as Button).grab_focus()


func _on_finished(_id: StringName, _choice: int) -> void:
	_choosing = false
	_clear_choices()
	visible = false
	get_tree().call_group("player", "set_controls_enabled", true)


func _start_typing() -> void:
	if _type_tween != null:
		_type_tween.kill()
	var count: int = text_label.text.length()
	text_label.visible_characters = 0
	_typing = true
	_type_tween = create_tween()
	_type_tween.tween_property(text_label, "visible_characters", count, count / chars_per_second)
	_type_tween.tween_callback(_finish_typing)


func _finish_typing() -> void:
	if _type_tween != null:
		_type_tween.kill()
	text_label.visible_characters = -1
	_typing = false


func _clear_choices() -> void:
	for c: Node in choices_box.get_children():
		choices_box.remove_child(c)
		c.queue_free()
