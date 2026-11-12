class_name RetroFilter
extends CanvasLayer
## Full-screen PS1-style look (low-res pixels, 15-bit colour + dither, tint, vignette, fringing).
## Sits just below the default canvas layer, so HUD and menus stay sharp. DayNight drives the
## tint and vignette per preset through set_look().

const SHADER: Shader = preload("res://assets/shaders/retro_screen.gdshader")

@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready():
			_rect.visible = enabled
			_update_scaling()
## Height of the low-resolution picture in pixels. 240 is the PS1's usual.
@export_range(120, 1080) var lines: int = 240:
	set(value):
		lines = value
		_apply(&"lines", float(value))
		if is_node_ready():
			_update_scaling()
@export var dither: bool = true:
	set(value):
		dither = value
		_apply(&"dither", value)
@export_range(1, 8) var color_bits: int = 5:
	set(value):
		color_bits = value
		_apply(&"color_bits", value)
@export_range(0.0, 1.0) var softness: float = 0.35:
	set(value):
		softness = value
		_apply(&"softness", value)
@export_range(0.0, 0.02) var fringe: float = 0.004:
	set(value):
		fringe = value
		_apply(&"fringe", value)
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_apply(&"tint", value)
@export_range(0.0, 1.0) var vignette: float = 0.4:
	set(value):
		vignette = value
		_apply(&"vignette", value)
## The 3D is rendered at this multiple of the low-res size and smoothed, so thin geometry does
## not sparkle when the picture is snapped to the pixel grid. 0 renders it at full resolution.
@export_range(0.0, 4.0) var supersample: float = 2.0

var _rect: ColorRect
var _mat: ShaderMaterial


func _init() -> void:
	layer = -1
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)


func _ready() -> void:
	add_to_group(&"retro_filter")
	for prop: StringName in [&"lines", &"dither", &"color_bits", &"softness", &"fringe", &"tint", &"vignette"]:
		_apply(prop, get(prop))
	_rect.visible = enabled
	get_viewport().size_changed.connect(_update_scaling)
	_update_scaling()


func _exit_tree() -> void:
	get_viewport().scaling_3d_scale = 1.0


func set_look(new_tint: Color, new_vignette: float) -> void:
	tint = new_tint
	vignette = new_vignette


func _apply(param: StringName, value: Variant) -> void:
	if _mat != null:
		_mat.set_shader_parameter(param, value)


func _update_scaling() -> void:
	var vp: Viewport = get_viewport()
	if not enabled or supersample <= 0.0:
		vp.scaling_3d_scale = 1.0
		return
	var window_height: float = float(get_window().size.y)
	vp.scaling_3d_scale = clampf(lines * supersample / maxf(window_height, 1.0), 0.25, 1.0)
