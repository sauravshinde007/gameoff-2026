class_name TaskList
extends CanvasLayer
## Top-left task list. Standing rules (is_rule) are not shown here; they live in the manager's note.
## A completed task turns green, then slides out to the left and the rows below move up.

const BULLET: String = "• "

@export var row_width: float = 560.0
@export var font_size: int = 26
@export var done_color: Color = Color(0.56, 0.83, 0.56)
## How long the green "done" row stays before sliding out.
@export var done_hold_seconds: float = 0.7
@export var failed_color: Color = Color(0.9, 0.35, 0.3)
@export var urgent_color: Color = Color(1.0, 0.8, 0.35)
@export var slide_seconds: float = 0.45
@export var collapse_seconds: float = 0.25

@onready var panel: PanelContainer = %Panel
@onready var box: VBoxContainer = %Box
@onready var header: Label = %Header

## task id -> row wrapper (a plain Control, so its label can be moved freely inside the list).
var _rows: Dictionary[StringName, Control] = {}


func _ready() -> void:
	# No box: text sits straight on the scene with an outline, objective-HUD style.
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	TaskManager.tasks_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	panel.visible = TaskManager.is_active()
	for t: TaskData in TaskManager.get_tasks():
		if t.is_rule:
			continue
		if TaskManager.is_completed(t.id) or TaskManager.is_failed(t.id):
			if _rows.has(t.id):
				_slide_out(t.id, TaskManager.is_failed(t.id))
		elif not _rows.has(t.id):
			_add_row(t)
	# Tasks removed from the manager (e.g. guest left) lose their row without the done animation.
	for id: StringName in _rows.keys():
		if TaskManager.get_task(id) == null:
			_remove_row(_rows[id])
			_rows.erase(id)
	_update_header()


func _add_row(task: TaskData) -> void:
	var wrapper: Control = Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.custom_minimum_size = Vector2(row_width, font_size + 10)
	var label: Label = Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = row_width
	label.text = "%s%s" % [BULLET, _row_text(task)]
	if task.priority == TaskData.Priority.URGENT:
		label.add_theme_color_override("font_color", urgent_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	wrapper.add_child(label)
	box.add_child(wrapper)
	_rows[task.id] = wrapper
	# Wait a frame so the wrapped text has its real height.
	await get_tree().process_frame
	if is_instance_valid(wrapper) and is_instance_valid(label):
		wrapper.custom_minimum_size.y = label.get_combined_minimum_size().y


func _row_text(task: TaskData) -> String:
	var text: String = task.text
	if task.priority == TaskData.Priority.URGENT:
		text = "! " + text
	if task.deadline_minute > 0:
		text += " (by %s)" % ShiftManager.format_minute(task.deadline_minute)
	return text


func _slide_out(id: StringName, failed: bool = false) -> void:
	var wrapper: Control = _rows[id]
	_rows.erase(id)
	var label: Label = wrapper.get_node("Label")
	label.add_theme_color_override("font_color", failed_color if failed else done_color)
	var tween: Tween = create_tween()
	tween.tween_interval(done_hold_seconds)
	tween.set_parallel(true)
	tween.tween_property(label, "position:x", -(row_width + 80.0), slide_seconds) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, slide_seconds)
	tween.chain().tween_property(wrapper, "custom_minimum_size:y", 0.0, collapse_seconds)
	tween.chain().tween_callback(_remove_row.bind(wrapper))


func _remove_row(wrapper: Control) -> void:
	box.remove_child(wrapper)
	wrapper.queue_free()
	_update_header()


## Header only shows while at least one row (including one that is leaving) is in the list.
func _update_header() -> void:
	header.visible = box.get_child_count() > 1
