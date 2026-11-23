class_name Player
extends CharacterBody3D

@export var move_speed: float = 4.5
@export var mouse_sensitivity: float = 0.0025
@export var max_pitch_degrees: float = 85.0
@export var gravity: float = 20.0
## How fast the camera turns to centre the NPC being talked to (higher = snappier).
@export var dialogue_focus_speed: float = 6.0

@onready var head: Node3D = $Head
@onready var interactor: Interactor = $Head/Camera3D/Interactor

var _controls_enabled: bool = true


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## UI screens (computer, dialogue, notes) call this via call_group("player", ...).
## false = freeze movement/look/interaction and free the cursor.
func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	interactor.set_active(enabled)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE


func is_controls_enabled() -> bool:
	return _controls_enabled


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		rotate_y(-motion.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(
			head.rotation.x - motion.relative.y * mouse_sensitivity,
			-deg_to_rad(max_pitch_degrees),
			deg_to_rad(max_pitch_degrees))
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_update_dialogue_focus(delta)


## While talking to an NPC, keep them in the middle of the screen (body turns, head pitches).
func _update_dialogue_focus(delta: float) -> void:
	var target: Node3D = DialogueManager.focus_target
	if not DialogueManager.is_active() or not is_instance_valid(target) or not target.is_inside_tree():
		return
	var point: Vector3 = (target.call(&"get_focus_point") as Vector3) if target.has_method(&"get_focus_point") \
			else target.global_position + Vector3(0.0, 1.5, 0.0)
	var eye: Vector3 = head.global_position
	var offset: Vector3 = point - eye
	var flat: float = Vector2(offset.x, offset.z).length()
	if flat < 0.05:
		return
	var weight: float = 1.0 - exp(-dialogue_focus_speed * delta)
	var yaw: float = atan2(-offset.x, -offset.z)
	rotation.y = lerp_angle(rotation.y, yaw, weight)
	var pitch: float = clampf(atan2(offset.y, flat), -deg_to_rad(max_pitch_degrees), deg_to_rad(max_pitch_degrees))
	head.rotation.x = lerpf(head.rotation.x, pitch, weight)


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	if _controls_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
