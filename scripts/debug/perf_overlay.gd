extends CanvasLayer
## Debug performance overlay. F3 toggles it, F4 appends a snapshot line to
## user://perf_log.txt (and prints it) so benchmark spots can be compared.

const LOG_PATH: String = "user://perf_log.txt"
const REFRESH_SECONDS: float = 0.5

## Starts hidden so it never shows up in normal play.
@export var start_visible: bool = false

var _label: Label
var _elapsed: float = 0.0
var _frames: int = 0
var _worst_ms: float = 0.0
var _avg_fps: float = 0.0
var _avg_ms: float = 0.0
var _snapshot_index: int = 0
## Diagnostic toggles (keys 1-6 while the overlay is open): name -> currently switched off.
var _off: Dictionary = {"1 sun shadow": false, "2 omni shadows": false, "3 mirrors": false,
		"4 foliage": false, "5 traffic": false, "6 baked level": false}
var _saved: Dictionary = {}


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(8.0, 8.0)
	_label.add_theme_font_size_override(&"font_size", 14)
	_label.add_theme_color_override(&"font_color", Color(0.7, 1.0, 0.7))
	_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0))
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = start_visible
	set_process(start_visible)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F3:
		visible = not visible
		set_process(visible)
		get_viewport().set_input_as_handled()
	elif visible and key.keycode >= KEY_1 and key.keycode <= KEY_6:
		_toggle(_off.keys()[key.keycode - KEY_1])
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F4:
		_write_snapshot()
		get_viewport().set_input_as_handled()


## Switches one feature off/on so its share of the draw calls shows in the counter.
func _toggle(name: String) -> void:
	var off: bool = not _off[name]
	_off[name] = off
	var root: Node = get_tree().current_scene
	match name:
		"1 sun shadow":
			for n: Node in get_tree().get_nodes_in_group(&"sun"):
				(n as Light3D).shadow_enabled = not off
		"2 omni shadows":
			for n: Node in _all(root):
				if n is ShadowProximity:
					n.set_process(not off)
				if n is OmniLight3D or n is SpotLight3D:
					var l: Light3D = n
					if off:
						_saved[l] = l.shadow_enabled
						l.shadow_enabled = false
					elif _saved.has(l):
						l.shadow_enabled = _saved[l]
		"3 mirrors":
			for n: Node in _all(root):
				if n is Mirror:
					if off:
						_saved[n] = n.max_distance
						n.max_distance = 0.0
					elif _saved.has(n):
						n.max_distance = _saved[n]
		"4 foliage":
			for n: Node in _all(root):
				if n is PsxFoliage or n.name == &"BatchedFoliage":
					(n as Node3D).visible = not off
		"5 traffic":
			for n: Node in _all(root):
				if n is HighwayTraffic:
					(n as Node3D).visible = not off
		"6 baked level":
			for n: Node in _all(root):
				if n.name == &"BakedCSG":
					(n as Node3D).visible = not off


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		stack.append_array(n.get_children())
	return out


func _process(delta: float) -> void:
	_elapsed += delta
	_frames += 1
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	if _elapsed < REFRESH_SECONDS:
		return
	_avg_fps = float(_frames) / _elapsed
	_avg_ms = _elapsed * 1000.0 / float(_frames)
	_label.text = _build_text()
	_elapsed = 0.0
	_frames = 0
	_worst_ms = 0.0


func _build_text() -> String:
	var vp: Viewport = get_viewport()
	var off_names: PackedStringArray = PackedStringArray()
	for k: String in _off:
		if _off[k]:
			off_names.append(k)
	var toggles: String = "\nOFF: %s\n[1-6] toggle: sun shadow, omni shadows, mirrors, foliage, traffic, baked level" % (", ".join(off_names) if not off_names.is_empty() else "none")
	return "FPS %.0f  (%.2f ms avg, %.1f ms worst)\nDraw calls %d\nObjects %d\nPrimitives %d\nCPU process %.2f ms  physics %.2f ms\nVRAM %.0f MB  tex %.0f MB\n3D scale %.2f  window %s" % [
		_avg_fps, _avg_ms, _worst_ms,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		vp.scaling_3d_scale, str(get_window().size)] + toggles


func _write_snapshot() -> void:
	_snapshot_index += 1
	var scene: Node = get_tree().current_scene
	var line: String = "#%d scene=%s fps=%.0f ms=%.2f worst=%.1f draws=%d objs=%d prims=%d scale=%.2f vram=%.0fMB" % [
		_snapshot_index, scene.name if scene != null else "?",
		_avg_fps, _avg_ms, _worst_ms,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		get_viewport().scaling_3d_scale,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0]
	print("[perf] ", line)
	var f: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE) if FileAccess.file_exists(LOG_PATH) else FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(line)
		f.close()
