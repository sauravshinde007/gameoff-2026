class_name WorldScreen
extends Node3D
## Puts a 2D UI scene on a screen in the 3D world. Interact -> open(): the player camera zooms in
## to the screen, the cursor is freed and mouse/keyboard are forwarded into the UI.
## Esc (or the UI closing itself) zooms back out to the normal view.
## The UI scene root must have open(), close() and a `closed` signal (ComputerScreen, CctvScreen).

signal opened
signal closed

## Render layer of the live screen quad. CCTV feeds hide it so a monitor can never film itself.
const LAYER_MASK: int = 1 << 19
const NO_HIT: Vector2 = Vector2(-1.0, -1.0)

@export var ui_scene: PackedScene
## Physical size of the screen face in meters. Its aspect should match viewport_size.
@export var screen_size: Vector2 = Vector2(0.42, 0.3)
## Resolution the UI is laid out and rendered at.
@export var viewport_size: Vector2i = Vector2i(1260, 900)
## Camera distance from the screen when zoomed in (meters).
@export var view_distance: float = 0.55
## Extra room around the screen when it is fitted to the view (1.0 = edge to edge).
@export var fit_margin: float = 1.12
@export var zoom_seconds: float = 0.45
@export var leave_hint: String = "Press Esc to step back."
@export var hint_seconds: float = 2.5

var _viewport: SubViewport
var _quad: MeshInstance3D
var _ui: Node
var _camera: Camera3D
var _saved_local: Transform3D
var _saved_fov: float = 75.0
var _tween: Tween
var _active: bool = false
var _leaving: bool = false


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = viewport_size
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_ui = ui_scene.instantiate()
	_viewport.add_child(_ui)
	_ui.connect(&"closed", _on_ui_closed)

	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = screen_size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _viewport.get_texture()
	mat.disable_fog = true
	_quad = MeshInstance3D.new()
	_quad.mesh = mesh
	_quad.material_override = mat
	_quad.layers = LAYER_MASK
	_quad.visible = false
	add_child(_quad)


func open() -> void:
	if _active or _leaving:
		return
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	_active = true
	_saved_local = _camera.transform
	_saved_fov = _camera.fov
	get_tree().call_group("player", "set_controls_enabled", false)
	_quad.visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_ui.call(&"open")
	get_tree().call_group("hud", "show_message", leave_hint, hint_seconds)
	_zoom_to(_focus_transform(), _focus_fov())
	opened.emit()


func _on_ui_closed() -> void:
	if not _active or _leaving:
		return
	_leaving = true
	# Stop updating now: the last rendered frame (UI still visible) stays on screen while zooming out.
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var back: Transform3D = _camera.get_parent_node_3d().global_transform * _saved_local
	await _zoom_to(back, _saved_fov)
	_camera.transform = _saved_local
	_camera.fov = _saved_fov
	_quad.visible = false
	_active = false
	_leaving = false
	get_tree().call_group("player", "set_controls_enabled", true)
	closed.emit()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if _leaving:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		_ui.call(&"close")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse:
		var mouse: InputEventMouse = event.duplicate()
		var pixel: Vector2 = _screen_pixel(mouse.position)
		if pixel != NO_HIT:
			mouse.position = pixel
			mouse.global_position = pixel
			_viewport.push_input(mouse, true)
		elif event is InputEventMouseMotion:
			# Pointer left the screen: park it off-screen so hover highlights clear.
			mouse.position = Vector2(-10000.0, -10000.0)
			mouse.global_position = mouse.position
			_viewport.push_input(mouse, true)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.is_action("toggle_fullscreen"):
		_viewport.push_input(event)
		get_viewport().set_input_as_handled()


## Window mouse position -> pixel in the UI viewport, or NO_HIT if the pointer is off the screen.
func _screen_pixel(mouse_pos: Vector2) -> Vector2:
	var origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var dir: Vector3 = _camera.project_ray_normal(mouse_pos)
	var inv: Transform3D = _quad.global_transform.affine_inverse()
	var o: Vector3 = inv * origin
	var d: Vector3 = inv.basis * dir
	if absf(d.z) < 0.00001:
		return NO_HIT
	var t: float = -o.z / d.z
	if t < 0.0:
		return NO_HIT
	var p: Vector3 = o + d * t
	var uv: Vector2 = Vector2(p.x / screen_size.x + 0.5, 0.5 - p.y / screen_size.y)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return NO_HIT
	return uv * Vector2(viewport_size)


## Camera pose facing the screen straight on, view_distance away.
func _focus_transform() -> Transform3D:
	var g: Transform3D = _quad.global_transform
	var basis: Basis = g.basis.orthonormalized()
	return Transform3D(basis, g.origin + basis.z * view_distance)


## Vertical FOV that fits the whole screen (plus margin) at view_distance.
func _focus_fov() -> float:
	var win: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = win.x / maxf(win.y, 1.0)
	var extent: float = maxf(screen_size.y, screen_size.x / aspect) * fit_margin
	return rad_to_deg(2.0 * atan(extent * 0.5 / view_distance))


func _zoom_to(target: Transform3D, target_fov: float) -> void:
	if _tween != null:
		_tween.kill()
	var from: Transform3D = _camera.global_transform
	var from_fov: float = _camera.fov
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_blend_camera.bind(from, target, from_fov, target_fov), 0.0, 1.0, zoom_seconds)
	await _tween.finished


func _blend_camera(w: float, from: Transform3D, to: Transform3D, from_fov: float, to_fov: float) -> void:
	_camera.global_transform = from.interpolate_with(to, w)
	_camera.fov = lerpf(from_fov, to_fov, w)
