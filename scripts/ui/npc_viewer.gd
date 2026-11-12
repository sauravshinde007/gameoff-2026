extends Node3D
## Dev tool: shows every NPC scene on a turntable, so models can be checked without playing
## through the shift. Opened from the title screen (debug builds) or run directly (F6).
## Drag with the left mouse button to orbit, scroll to zoom, Left/Right to switch NPC.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

## NPC scenes to show. Add new NPCs here.
@export var npc_scenes: Array[PackedScene] = []
@export var orbit_sensitivity: float = 0.008
@export var zoom_step: float = 0.15
@export var min_distance: float = 0.5
@export var max_distance: float = 5.0
## Camera presets: (target height, distance).
@export var face_view: Vector2 = Vector2(1.62, 0.75)
@export var body_view: Vector2 = Vector2(1.0, 3.0)
@export var day_color: Color = Color(1.0, 0.88, 0.72)
@export var night_color: Color = Color(0.7, 0.82, 1.0)

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D
@onready var stage: Node3D = $Stage
@onready var key_light: SpotLight3D = $KeyLight
@onready var npc_list: ItemList = %NpcList
@onready var anim_option: OptionButton = %AnimOption
@onready var speed_slider: HSlider = %SpeedSlider
@onready var speed_label: Label = %SpeedLabel
@onready var face_button: Button = %FaceButton
@onready var body_button: Button = %BodyButton
@onready var light_button: Button = %LightButton
@onready var spin_check: CheckBox = %SpinCheck
@onready var back_button: Button = %BackButton
@onready var info_label: Label = %InfoLabel

var _current: Node3D
var _model: RetroModel
var _dragging: bool = false
var _distance: float = 3.0
var _night: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for scene: PackedScene in npc_scenes:
		npc_list.add_item(scene.resource_path.get_file().get_basename().capitalize())
	npc_list.item_selected.connect(_show_npc)
	anim_option.item_selected.connect(_on_anim_selected)
	speed_slider.value_changed.connect(_on_speed_changed)
	face_button.pressed.connect(_set_view.bind(face_view))
	body_button.pressed.connect(_set_view.bind(body_view))
	light_button.pressed.connect(_toggle_light)
	back_button.pressed.connect(_on_back_pressed)
	_set_view(body_view)
	_apply_light()
	if not npc_scenes.is_empty():
		npc_list.select(0)
		_show_npc(0)


func _process(delta: float) -> void:
	if spin_check.button_pressed and _current != null:
		_current.rotate_y(delta * 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_distance(_distance - zoom_step)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_distance(_distance + zoom_step)
	elif event is InputEventMouseMotion and _dragging:
		var mm: InputEventMouseMotion = event
		pivot.rotation.y -= mm.relative.x * orbit_sensitivity
		pivot.rotation.x = clampf(pivot.rotation.x - mm.relative.y * orbit_sensitivity, -1.2, 1.2)
	elif event.is_action_pressed(&"ui_left"):
		_step_npc(-1)
	elif event.is_action_pressed(&"ui_right"):
		_step_npc(1)
	elif event.is_action_pressed(&"ui_cancel"):
		_on_back_pressed()


func _step_npc(dir: int) -> void:
	if npc_scenes.is_empty():
		return
	var selected: PackedInt32Array = npc_list.get_selected_items()
	var idx: int = selected[0] if not selected.is_empty() else 0
	idx = wrapi(idx + dir, 0, npc_scenes.size())
	npc_list.select(idx)
	_show_npc(idx)


func _show_npc(index: int) -> void:
	if _current != null:
		_current.queue_free()
	_current = npc_scenes[index].instantiate() as Node3D
	stage.add_child(_current)
	# Some NPCs start hidden until their event (e.g. the Room 13 guest).
	_current.visible = true
	_model = _find_model(_current)
	anim_option.clear()
	if _model != null:
		for anim: String in _model.get_animation_names():
			anim_option.add_item(anim)
		var start: int = _index_of_anim(String(_model.autoplay_anim))
		if start >= 0:
			anim_option.select(start)
		speed_slider.set_value_no_signal(_model.anim_speed)
	_update_speed_label()
	info_label.text = "%s\n%s" % [npc_list.get_item_text(index), npc_scenes[index].resource_path]


func _find_model(node: Node) -> RetroModel:
	for child: Node in node.get_children():
		if child is RetroModel:
			return child
		var found: RetroModel = _find_model(child)
		if found != null:
			return found
	return null


func _index_of_anim(anim_name: String) -> int:
	for i: int in anim_option.item_count:
		if anim_option.get_item_text(i) == anim_name:
			return i
	return -1


func _on_anim_selected(index: int) -> void:
	if _model != null:
		_model.play(StringName(anim_option.get_item_text(index)))


func _on_speed_changed(value: float) -> void:
	if _model != null:
		_model.set_anim_speed(value)
	_update_speed_label()


func _update_speed_label() -> void:
	speed_label.text = "Speed %.2f" % speed_slider.value


func _set_view(view: Vector2) -> void:
	pivot.position.y = view.x
	pivot.rotation = Vector3.ZERO
	_set_distance(view.y)


func _set_distance(d: float) -> void:
	_distance = clampf(d, min_distance, max_distance)
	camera.position = Vector3(0.0, 0.0, _distance)


func _toggle_light() -> void:
	_night = not _night
	_apply_light()


func _apply_light() -> void:
	key_light.light_color = night_color if _night else day_color
	key_light.light_energy = 2.0 if _night else 4.0
	light_button.text = "Light: Night" if _night else "Light: Day"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
