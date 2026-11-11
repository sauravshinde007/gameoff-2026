class_name ScreenFade
extends CanvasLayer
## Full-screen black fade with an optional centered caption. Both calls can be awaited.

@onready var rect: ColorRect = %Rect
@onready var caption: Label = %Caption

var _tween: Tween


func _ready() -> void:
	add_to_group(&"screen_fade")
	caption.add_theme_font_override("font", preload("res://assets/fonts/screen_font.tres"))
	rect.modulate.a = 0.0
	caption.modulate.a = 0.0


## Cuts straight to black (use fade_in afterwards).
func set_black() -> void:
	if _tween != null:
		_tween.kill()
	rect.modulate.a = 1.0
	caption.modulate.a = 0.0


## Fades to black. If text is given, it fades in with the black.
func fade_out(seconds: float, text: String = "") -> void:
	caption.text = text
	_fade_to(1.0, 1.0 if not text.is_empty() else 0.0, seconds)
	await _tween.finished


func fade_in(seconds: float) -> void:
	_fade_to(0.0, 0.0, seconds)
	await _tween.finished


func _fade_to(rect_alpha: float, caption_alpha: float, seconds: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(rect, "modulate:a", rect_alpha, seconds)
	_tween.tween_property(caption, "modulate:a", caption_alpha, seconds)
