class_name WorkTransition
extends RefCounted
## Fade to black with a caption while the player does a room job (cleaning, repairs), like the
## shift-start "6:00 AM" caption. Controls are off while the screen is black. `on_done` runs
## while still black, then the screen fades back in.

const FADE_SECONDS: float = 0.6


static func run(tree: SceneTree, caption: String, hold_seconds: float, on_done: Callable) -> void:
	var fade: ScreenFade = tree.get_first_node_in_group(&"screen_fade") as ScreenFade
	tree.call_group("player", "set_controls_enabled", false)
	if fade != null:
		await fade.fade_out(FADE_SECONDS, caption)
	await tree.create_timer(hold_seconds, false).timeout
	on_done.call()
	# The shift may have ended meanwhile: main.gd owns the screen from then on.
	if ShiftManager.get_minute() >= ShiftManager.data.end_minute:
		return
	if fade != null:
		await fade.fade_in(FADE_SECONDS)
	tree.call_group("player", "set_controls_enabled", true)
