class_name Telephone
extends Node3D
## Reception phone. IDLE -> ring(call) -> RINGING -> player answers -> IN_CALL -> IDLE.
## Also used to place an outgoing wake-up call when GuestManager reports one is due.

signal call_answered(call_id: StringName)
signal call_ended(call_id: StringName, choice: int)
## The ringing stopped because nobody picked up.
signal call_missed(call_id: StringName)

enum State { IDLE, RINGING, IN_CALL }

## Testing aid. Phase 3's EventManager rings the phone instead (set delay to 0 then).
@export var debug_call: DialogueData
@export var debug_ring_delay: float = 0.0
## Task completed when a call ends.
@export var complete_task_id: StringName = &"answer_phone"
@export var blink_interval: float = 0.4
@export var light_energy: float = 1.5
## Silence between rings (the ring sound plays to its end first).
@export var ring_interval: float = 1.0

@onready var interactable: Interactable = $Interactable
@onready var ring_light: OmniLight3D = $RingLight
@onready var lamp: CSGBox3D = $Lamp

var state: State = State.IDLE
var _call: DialogueData = null
var _blink_tween: Tween
var _ring_id: int = 0
var _ring_player: Node = null
var _loop_handle: Node = null
var _wakeup: ServiceRequest = null


func _ready() -> void:
	add_to_group(&"telephone")
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	GuestManager.requests_changed.connect(_update_interactable)
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
	_ring_sound_loop()


## Stop an unanswered ring (the caller gave up).
func stop_ringing() -> void:
	if state != State.RINGING:
		return
	var id: StringName = _call.id if _call != null else &""
	state = State.IDLE
	_call = null
	_ring_id += 1
	if is_instance_valid(_ring_player):
		_ring_player.queue_free()
	_stop_blink()
	_update_interactable()
	call_missed.emit(id)


func _ring_sound_loop() -> void:
	_ring_id += 1
	var my_id: int = _ring_id
	while state == State.RINGING and my_id == _ring_id:
		_ring_player = AudioManager.play_sfx(&"phone_ring", global_position)
		var ring_length: float = 0.0
		if _ring_player != null:
			ring_length = (_ring_player as Node).get("stream").get_length()
		await get_tree().create_timer(ring_length + ring_interval).timeout


func _on_interacted(_by: Node) -> void:
	if state == State.IDLE:
		_place_wakeup_call()
		return
	if state != State.RINGING:
		return
	state = State.IN_CALL
	_ring_id += 1
	if is_instance_valid(_ring_player):
		_ring_player.queue_free()
	_stop_blink()
	_update_interactable()
	if _call.loop_sfx != &"":
		_loop_handle = AudioManager.play_loop(_call.loop_sfx, self)
	call_answered.emit(_call.id)
	DialogueManager.start(_call)


func _place_wakeup_call() -> void:
	var req: ServiceRequest = GuestManager.get_due_wakeup()
	if req == null:
		return
	var rec: GuestRecord = GuestManager.get_guest(req.guest_id)
	var who: String = rec.display_name if rec != null else "Guest"
	var room: RoomData = RoomManager.get_room(req.room_id)
	var data: DialogueData = DialogueData.new()
	data.id = StringName("wakeup_" + req.id)
	data.lines = [
		_line("You", "Good morning, %s. This is your wake-up call." % (room.display_name if room != null else "Room")),
		_line(who, "Thanks. I'm up."),
	]
	_wakeup = req
	_call = data
	state = State.IN_CALL
	_update_interactable()
	DialogueManager.start(data)


func _line(speaker: String, text: String) -> DialogueLine:
	var l: DialogueLine = DialogueLine.new()
	l.speaker = speaker
	l.text = text
	return l


func _on_dialogue_finished(id: StringName, choice: int) -> void:
	if state != State.IN_CALL or _call == null or id != _call.id:
		return
	if _wakeup != null:
		GuestManager.complete_request(_wakeup.id)
		_wakeup = null
	state = State.IDLE
	_call = null
	AudioManager.stop_loop(_loop_handle)
	_loop_handle = null
	AudioManager.play_sfx(&"phone_hangup", global_position)
	_update_interactable()
	if not String(id).begins_with("wakeup_"):
		TaskManager.complete_task(complete_task_id)
	call_ended.emit(id, choice)


func _update_interactable() -> void:
	var wakeup_due: bool = state == State.IDLE and GuestManager.get_due_wakeup() != null
	interactable.enabled = state == State.RINGING or wakeup_due
	interactable.prompt_text = "Place wake-up call" if wakeup_due else "Answer phone"


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
