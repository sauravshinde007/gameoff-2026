class_name Telephone
extends Node3D
## Reception phone. IDLE -> ring(call) -> RINGING -> player answers -> IN_CALL -> IDLE.

signal call_answered(call_id: StringName)
signal call_ended(call_id: StringName, choice: int)

enum State { IDLE, RINGING, IN_CALL }

## Testing aid. Phase 3's EventManager rings the phone instead (set delay to 0 then).
@export var debug_call: DialogueData
@export var debug_ring_delay: float = 0.0
## Task completed when a call ends.
@export var complete_task_id: StringName = &"answer_phone"
@export var blink_interval: float = 0.4
@export var light_energy: float = 1.5

@onready var interactable: Interactable = $Interactable
@onready var ring_light: OmniLight3D = $RingLight
@onready var lamp: CSGBox3D = $Lamp

var state: State = State.IDLE
var _call: DialogueData = null
var _blink_tween: Tween


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_set_blink(false)
	_update_interactable()
	if debug_ring_delay > 0.0 and debug_call != null:
		await get_tree().create_timer(debug_ring_delay).timeout
		ring(debug_call)


func ring(call: DialogueData) -> void:
	if state != State.IDLE or call == null:
		return
	_call = call
	state = State.RINGING
	_update_interactable()
	_start_blink()
	AudioManager.play_sfx(&"phone_ring", global_position)


func _on_interacted(_by: Node) -> void:
	if state != State.RINGING:
		return
	state = State.IN_CALL
	_stop_blink()
	_update_interactable()
	call_answered.emit(_call.id)
	DialogueManager.start(_call)


func _on_dialogue_finished(id: StringName, choice: int) -> void:
	if state != State.IN_CALL or _call == null or id != _call.id:
		return
	state = State.IDLE
	_call = null
	_update_interactable()
	TaskManager.complete_task(complete_task_id)
	call_ended.emit(id, choice)


func _update_interactable() -> void:
	interactable.enabled = state == State.RINGING
	interactable.prompt_text = "Answer phone"


func _start_blink() -> void:
	_stop_blink()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(_set_blink.bind(true))
	_blink_tween.tween_interval(blink_interval)
	_blink_tween.tween_callback(_set_blink.bind(false))
	_blink_tween.tween_interval(blink_interval)


func _stop_blink() -> void:
	if _blink_tween != null:
		_blink_tween.kill()
	_set_blink(false)


func _set_blink(on: bool) -> void:
	ring_light.light_energy = light_energy if on else 0.0
	lamp.visible = on
