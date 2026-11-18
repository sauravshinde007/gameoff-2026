extends CanvasLayer

@export var default_message_seconds: float = 2.5

@onready var prompt_label: Label = $PromptLabel
@onready var message_label: Label = $MessageLabel
@onready var carry_label: Label = $CarryLabel

var _message_tween: Tween


func _ready() -> void:
	add_to_group("hud")
	set_prompt("")
	message_label.visible = false
	InventoryManager.carry_changed.connect(_refresh_carry)
	_refresh_carry()


func set_prompt(text: String) -> void:
	prompt_label.visible = not text.is_empty()
	prompt_label.text = "[E] " + text


## Props call this via get_tree().call_group("hud", "show_message", text).
func show_message(text: String, seconds: float = -1.0) -> void:
	if seconds < 0.0:
		seconds = default_message_seconds
	if _message_tween != null:
		_message_tween.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	message_label.visible = true
	_message_tween = create_tween()
	_message_tween.tween_interval(seconds)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	_message_tween.tween_callback(message_label.hide)


func _refresh_carry() -> void:
	var text: String = InventoryManager.carry_text()
	carry_label.visible = not text.is_empty()
	carry_label.text = "Carrying: " + text
