extends Control
## Title screen: Start fades to black, then loads the motel.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const FREE_ROAM_SCENE: String = "res://scenes/free_roam.tscn"
const NPC_VIEWER_SCENE: String = "res://scenes/ui/npc_viewer.tscn"

@export var ambience: StringName = &"day_ambience"
@export var fade_seconds: float = 1.2

@onready var start_button: Button = %StartButton
@onready var free_roam_button: Button = %FreeRoamButton
@onready var quit_button: Button = %QuitButton
@onready var npc_viewer_button: Button = %NpcViewerButton
@onready var fade: ColorRect = %Fade

var _starting: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%TitleLabel.add_theme_font_override("font", preload("res://assets/fonts/screen_font.tres"))
	%SubtitleLabel.add_theme_font_override("font", preload("res://assets/fonts/subtitle_font.tres"))
	start_button.pressed.connect(_on_start_pressed)
	free_roam_button.pressed.connect(_on_free_roam_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# Dev tool: only in editor/debug builds, never in the exported game.
	npc_viewer_button.visible = OS.is_debug_build()
	npc_viewer_button.pressed.connect(_on_npc_viewer_pressed)
	AudioManager.set_ambience(ambience)
	start_button.grab_focus()
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, fade_seconds)


func _on_start_pressed() -> void:
	_fade_to(MAIN_SCENE)


## Free Roam: environment-only walk-around, no tasks/clock/story.
func _on_free_roam_pressed() -> void:
	_fade_to(FREE_ROAM_SCENE)


func _fade_to(scene_path: String) -> void:
	if _starting:
		return
	_starting = true
	AudioManager.play_sfx(&"ui_click")
	var t: Tween = create_tween()
	t.tween_property(fade, "modulate:a", 1.0, fade_seconds)
	await t.finished
	get_tree().change_scene_to_file(scene_path)


func _on_npc_viewer_pressed() -> void:
	AudioManager.play_sfx(&"ui_click")
	get_tree().change_scene_to_file(NPC_VIEWER_SCENE)


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(&"ui_click")
	get_tree().quit()
