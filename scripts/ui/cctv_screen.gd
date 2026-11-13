class_name CctvScreen
extends CanvasLayer
## Security monitor UI (shown on the monitor by WorldScreen, which owns player controls). Renders the selected CctvCamera through a SubViewport that shares the main
## 3D world. The viewport only updates while the screen is open.

signal closed

@export var rec_blink_seconds: float = 0.8

@onready var panel: PanelContainer = %Panel
@onready var viewport: SubViewport = %Viewport
@onready var feed_camera: Camera3D = %FeedCamera
@onready var feed: TextureRect = %Feed
@onready var cam_label: Label = %CamLabel
@onready var rec_label: Label = %RecLabel
@onready var time_label: Label = %TimeLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var close_button: Button = %CloseButton

var _cams: Array[CctvCamera] = []
var _index: int = 0


func _ready() -> void:
	visible = false
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.03, 0.95)
	sb.border_color = Color(0.45, 0.5, 0.45, 0.9)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	viewport.world_3d = get_viewport().find_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	feed.texture = viewport.get_texture()
	prev_button.pressed.connect(_cycle.bind(-1))
	next_button.pressed.connect(_cycle.bind(1))
	close_button.pressed.connect(close)


func open() -> void:
	if visible:
		return
	_collect_cameras()
	visible = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_index = clampi(_index, 0, maxi(_cams.size() - 1, 0))
	_show_current()


func close() -> void:
	if not visible:
		return
	visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	closed.emit()


func _process(_delta: float) -> void:
	if not visible or _cams.is_empty():
		return
	var cam: CctvCamera = _cams[_index]
	feed_camera.global_transform = cam.global_transform
	feed_camera.fov = cam.fov
	feed_camera.cull_mask = cam.cull_mask & ~WorldScreen.LAYER_MASK & ~PlayerBody.FP_LAYER_MASK
	time_label.text = ShiftManager.get_time_text()
	var phase: float = fmod(Time.get_ticks_msec() / 1000.0, rec_blink_seconds * 2.0)
	rec_label.modulate.a = 1.0 if phase < rec_blink_seconds else 0.0


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("move_left"):
		_cycle(-1)
	elif event.is_action_pressed("move_right"):
		_cycle(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _collect_cameras() -> void:
	var current: CctvCamera = _cams[_index] if _index < _cams.size() else null
	_cams.clear()
	for node: Node in get_tree().get_nodes_in_group(&"cctv_camera"):
		var cam: CctvCamera = node as CctvCamera
		if cam != null and cam.is_available():
			_cams.append(cam)
	_cams.sort_custom(func(a: CctvCamera, b: CctvCamera) -> bool: return a.sort_order < b.sort_order)
	if current != null and _cams.has(current):
		_index = _cams.find(current)


func _cycle(step: int) -> void:
	if _cams.size() < 2:
		return
	_index = posmod(_index + step, _cams.size())
	_show_current()


func _show_current() -> void:
	if _cams.is_empty():
		cam_label.text = "NO SIGNAL"
		return
	var cam: CctvCamera = _cams[_index]
	cam_label.text = cam.label
	if cam.viewed_flag != &"":
		EventManager.set_flag(cam.viewed_flag)
