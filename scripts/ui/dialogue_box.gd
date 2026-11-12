class_name DialogueBox
extends CanvasLayer
## Subtitle-style dialogue. Draws whatever DialogueManager emits.
## Text types out character by character. E or left click skips the typing, then advances.
## Choices are flat text buttons. The player's lines sit lower than everyone else's.

@export var chars_per_second: float = 38.0
## Extra pause after sentence-ending punctuation (seconds).
@export var punctuation_pause: float = 0.22
## Name of the talk sound. It plays only while text is typing and stops at pauses and line end.
@export var talk_sfx: StringName = &"type_blip"
@export var player_speaker: String = "You"
## Vertical position of a line (fraction of screen height).
@export var npc_line_y: float = 0.74
@export var player_line_y: float = 0.85
@export var npc_font_size: int = 30
@export var player_font_size: int = 26
@export var npc_color: Color = Color(1, 1, 1)
@export var player_color: Color = Color(0.8, 0.88, 1.0)
## Speaker name drawn above NPC lines (not shown for the player).
@export var name_color: Color = Color(1, 0.85, 0.4)
@export var name_gap: float = 0.05

const SUBTITLE_FONT: Font = preload("res://assets/fonts/subtitle_font.tres")

@onready var text_label: Label = %TextLabel
@onready var name_label: Label = %NameLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var hint_label: Label = %HintLabel

var _typing: bool = false
var _choosing: bool = false
var _progress: float = 0.0
var _pause_left: float = 0.0
var _talk_player: AudioStreamPlayer


func _ready() -> void:
	visible = false
	set_process(false)
	_talk_player = AudioStreamPlayer.new()
	add_child(_talk_player)
	_setup_talk_sound()
	text_label.add_theme_font_override("font", SUBTITLE_FONT)
	hint_label.add_theme_font_override("font", SUBTITLE_FONT)
	name_label.add_theme_font_override("font", SUBTITLE_FONT)
	name_label.add_theme_color_override("font_color", name_color)
	DialogueManager.dialogue_started.connect(_on_started)
	DialogueManager.line_shown.connect(_on_line)
	DialogueManager.choices_shown.connect(_on_choices)
	DialogueManager.dialogue_finished.connect(_on_finished)


func _process(delta: float) -> void:
	if not _typing:
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_talk_player.stream_paused = false
		return
	_progress += chars_per_second * delta
	var total: int = text_label.text.length()
	var target: int = mini(int(_progress), total)
	var shown: int = text_label.visible_characters
	while shown < target:
		var ch: String = text_label.text[shown]
		shown += 1
		var next: String = text_label.text[shown] if shown < total else ""
		if ch in ".!?" and not next in ".!?":
			_pause_left = punctuation_pause
			_talk_player.stream_paused = true
			break
		if ch == "," and next == " ":
			_pause_left = punctuation_pause * 0.5
			_talk_player.stream_paused = true
			break
	text_label.visible_characters = shown
	_progress = maxf(_progress, float(shown))
	if shown >= total:
		_finish_typing()


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
	var is_player: bool = speaker == player_speaker
	var y: float = player_line_y if is_player else npc_line_y
	text_label.anchor_top = y
	text_label.anchor_bottom = y + 0.1
	text_label.offset_top = 0.0
	text_label.offset_bottom = 0.0
	text_label.add_theme_font_size_override("font_size", player_font_size if is_player else npc_font_size)
	text_label.add_theme_color_override("font_color", player_color if is_player else npc_color)
	text_label.text = text
	var show_name: bool = not is_player and speaker != ""
	name_label.visible = show_name
	name_label.text = speaker
	name_label.anchor_bottom = y
	name_label.anchor_top = y - name_gap
	_start_typing()


func _on_choices(options: PackedStringArray) -> void:
	_choosing = true
	hint_label.visible = false
	for i: int in options.size():
		choices_box.add_child(_make_choice_button(options[i], i))
	(choices_box.get_child(0) as Button).grab_focus()


func _on_finished(_id: StringName, _choice: int) -> void:
	_choosing = false
	_typing = false
	_talk_player.stop()
	set_process(false)
	_clear_choices()
	name_label.visible = false
	visible = false
	get_tree().call_group("player", "set_controls_enabled", true)


func _start_typing() -> void:
	text_label.visible_characters = 0
	_progress = 0.0
	_pause_left = 0.0
	_typing = true
	hint_label.visible = false
	set_process(true)
	_start_talk_sound()


func _finish_typing() -> void:
	text_label.visible_characters = -1
	_typing = false
	_talk_player.stop()
	set_process(false)
	hint_label.visible = not _choosing


## One looping player instead of a new sound per character: the long recording would overlap itself.
func _setup_talk_sound() -> void:
	var stream: AudioStream = AudioManager.sfx.get(talk_sfx)
	if stream == null:
		return
	stream = stream.duplicate() as AudioStream
	if "loop" in stream:
		stream.set("loop", true)
	_talk_player.stream = stream
	_talk_player.volume_db = AudioManager.bank.volume_db.get(talk_sfx, 0.0)


func _start_talk_sound() -> void:
	if _talk_player.stream == null:
		return
	_talk_player.stream_paused = false
	var length: float = _talk_player.stream.get_length()
	_talk_player.play(randf_range(0.0, maxf(0.0, length - 3.0)))


func _make_choice_button(text: String, index: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", SUBTITLE_FONT)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_color_override("font_outline_color", Color.BLACK)
	b.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	for c: String in ["font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var lit: StyleBoxFlat = StyleBoxFlat.new()
	lit.bg_color = Color(0, 0, 0, 0.35)
	lit.border_color = Color.WHITE
	lit.border_width_bottom = 2
	lit.set_content_margin_all(6)
	for state: String in ["hover", "focus", "pressed"]:
		b.add_theme_stylebox_override(state, lit)
	b.pressed.connect(DialogueManager.choose.bind(index))
	return b


func _clear_choices() -> void:
	for c: Node in choices_box.get_children():
		choices_box.remove_child(c)
		c.queue_free()
