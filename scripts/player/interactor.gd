class_name Interactor
extends RayCast3D
## Child of the player camera. Looks for an Interactable and calls interact() on E.

signal focus_changed(prompt: String)

var _focused: Interactable = null


func _physics_process(_delta: float) -> void:
	if _focused != null and not is_instance_valid(_focused):
		_focused = null
	var target: Interactable = null
	var hit: Object = get_collider() if is_colliding() else null
	if hit is Interactable and (hit as Interactable).enabled:
		target = hit
	if target != _focused:
		if _focused != null:
			_focused.prompt_changed.disconnect(_on_prompt_changed)
			_focused.set_highlighted(false)
		_focused = target
		if _focused != null:
			_focused.prompt_changed.connect(_on_prompt_changed)
			_focused.set_highlighted(true)
		focus_changed.emit(target.get_prompt() if target != null else "")


func _on_prompt_changed() -> void:
	if _focused != null:
		focus_changed.emit(_focused.get_prompt())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focused != null:
		_focused.interact(owner)


## Off = no focus, no prompt, E ignored (used while a UI screen is open).
func set_active(active: bool) -> void:
	set_physics_process(active)
	set_process_unhandled_input(active)
	if not active and _focused != null:
		if is_instance_valid(_focused):
			_focused.prompt_changed.disconnect(_on_prompt_changed)
			_focused.set_highlighted(false)
		_focused = null
		focus_changed.emit("")
