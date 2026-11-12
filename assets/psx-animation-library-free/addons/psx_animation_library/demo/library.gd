extends "res://addons/psx_animation_library/demo/gallery.gd"
## The pack's gallery, opening on the library: a mannequin turning slowly and, left of it, every
## clip under its group (props.json's "group") to play on it, the man or the woman, at full, half
## or quarter speed; a clip that plays once plays again after a pause, to be watched again.
## In the gallery a mannequin's bar has only the way back here, its clips being too many for it.

const AGAIN := 0.8  # seconds before a once-played clip plays again

var panel := CanvasLayer.new()
var playing := Label.new()
var current := "idle"
var again := -1.0
var browsing := false
var speed := 1.0


func _ready() -> void:
	super._ready()
	_panel()
	if start and not still:
		show_library(0)


func _mannequins() -> Array:
	return range(props.size()).filter(func(i): return props[i]["anims"].any(func(a): return a.has("group")))


## The mannequin at `i` in the library, playing the clip it was on.
func show_library(i: int) -> void:
	show_prop(i)
	browsing = true
	ui.hide()
	panel.show()
	cam.h_offset = -0.45  # the mannequin right of the panel
	look(target, dist * 1.2, 0.6, -0.12)
	play_clip(current)


func play_clip(anim: String) -> void:
	current = anim
	again = -1.0
	var player := _player()
	if not player or not player.has_animation(anim):
		return
	player.speed_scale = speed
	player.stop()
	player.play(anim)
	var a: Dictionary = props[index]["anims"].filter(func(x): return x["name"] == anim)[0]
	playing.text = "%s  |  %s  |  %.1f s, %s" % [a["name"], a["group"], a["seconds"], "loops" if a["loop"] else "once"]


func _player() -> AnimationPlayer:
	return shown.get_child(0).find_child("AnimationPlayer", true, false) as AnimationPlayer if shown.get_child_count() else null


func show_prop(i: int) -> void:
	super.show_prop(i)
	if index in _mannequins():
		_clear_anims()
		_anim_button("Library", func() -> void: show_library(index))


func _clear() -> void:
	super._clear()
	if browsing:
		browsing = false
		panel.hide()
		ui.visible = not still
		cam.h_offset = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if not browsing:
		return
	var player := _player()
	if player and not player.is_playing() and current != "":
		if again < 0.0:
			again = AGAIN
		again -= delta
		if again <= 0.0:
			play_clip(current)


func _panel() -> void:
	add_child(panel)
	panel.hide()
	var box := PanelContainer.new()
	box.position = Vector2(12, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.04, 0.72)
	bg.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", bg)
	panel.add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	box.add_child(col)
	var head := Label.new()
	head.text = "Animation Library"
	head.add_theme_font_size_override("font_size", 20)
	col.add_child(head)
	var bodies := HBoxContainer.new()
	col.add_child(bodies)
	for i in _mannequins():
		_button(bodies, props[i]["title"].get_slice(", ", 1), func() -> void: show_library(i))
	for k in [1.0, 0.5, 0.25]:
		_button(bodies, "%sx" % ("1" if k == 1.0 else "1/%d" % int(1.0 / k)), func() -> void:
			speed = k
			play_clip(current))
	var tools := HBoxContainer.new()
	col.add_child(tools)
	if psx_screen:
		_button(tools, "PSX Look", func() -> void: set_psx(not psx_on))
	_button(tools, "Gallery", func() -> void: show_prop(index))
	playing.add_theme_font_size_override("font_size", 13)
	playing.modulate = Color(0.85, 0.82, 0.75)
	col.add_child(playing)
	col.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var all := _mannequins()
	if all.is_empty():
		return
	var flow: HFlowContainer
	var group := ""
	for a in props[all[0]]["anims"]:
		if a["group"] != group:
			group = a["group"]
			var l := Label.new()
			l.text = group
			l.modulate = Color(1, 0.85, 0.45)
			list.add_child(l)
			flow = HFlowContainer.new()
			flow.custom_minimum_size.x = 340
			list.add_child(flow)
		var b := _button(flow, a["name"].replace("_", " "), func() -> void: play_clip(a["name"]))
		b.add_theme_font_size_override("font_size", 12)
