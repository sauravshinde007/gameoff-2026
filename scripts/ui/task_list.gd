class_name TaskList
extends CanvasLayer
## Top-left list of tasks and standing rules. Draws what TaskManager holds.

@onready var panel: PanelContainer = %Panel
@onready var text_label: RichTextLabel = %TextLabel


func _ready() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.05, 0.7)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	TaskManager.tasks_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	panel.visible = TaskManager.is_active()
	var tasks: Array[TaskData] = TaskManager.get_tasks()
	var out: String = "[b]TASKS[/b]\n"
	for t: TaskData in tasks:
		if t.is_rule:
			continue
		if TaskManager.is_completed(t.id):
			out += "[color=#77cc77][x] [s]%s[/s][/color]\n" % t.text
		else:
			out += "[ ] %s\n" % t.text
	out += "\n[b]RULES[/b]\n"
	for t: TaskData in tasks:
		if t.is_rule:
			out += "- %s\n" % t.text
	text_label.text = out
