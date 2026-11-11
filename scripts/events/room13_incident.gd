class_name Room13Incident
extends Node3D
## Scripted incident: The Room 13 Reservation. Runs when EventManager fires event_id.

@export var event_id: StringName = &"room13"
## Impossible reservation added to the system after the guest first speaks.
@export var reservation: ReservationData
@export var appear_delay: float = 1.5
## Reception lights stutter this long after the refusal, then cut out briefly.
@export var flicker_seconds: float = 1.6
@export var blackout_seconds: float = 0.6
## Ambient light during the blackout (fraction of normal). 0 = pitch dark.
@export_range(0.0, 1.0) var blackout_ambient: float = 0.0
## Phone calls that follow the disappearance.
@export var call_silence: DialogueData
@export var call_key: DialogueData
@export var phone_delay: float = 3.0
## Pause between the player seeing Camera 04 and the second call.
@export var second_call_delay: float = 2.0
## Where the "door opens" cue plays (Room 2's door).
@export var door_cue_position: Vector3 = Vector3(4.0, 1.05, 7.1)
## Final scare: Room 2's door. Set in motel.tscn.
@export var door_room2_path: NodePath
@export var investigate_task: TaskData
@export var footsteps_delay: float = 1.5
@export var hallway_flicker_seconds: float = 1.2
@export var handle_turn_seconds: float = 2.5

@onready var guest: MysteriousGuest = $MysteriousGuest
@onready var figure: Node3D = $Figure
@onready var hallway_trigger: Area3D = $HallwayTrigger
@onready var reception_trigger: Area3D = $ReceptionTrigger


func _ready() -> void:
	EventManager.event_triggered.connect(_on_event_triggered)
	guest.talked.connect(_on_guest_talked)


func _on_event_triggered(id: StringName) -> void:
	if id != event_id:
		return
	ShiftManager.block_end(event_id)
	AudioManager.play_sfx(&"entrance_bell", guest.global_position)
	get_tree().call_group("hud", "show_message", "*A bell rings at the entrance.*")
	await get_tree().create_timer(appear_delay).timeout
	guest.appear()


func _on_guest_talked(step: StringName) -> void:
	if step == &"asked":
		RoomManager.add_reservation(reservation.duplicate() as ReservationData)
	elif step == &"refused":
		_vanish_guest()


## Lights flicker, cut out, and the guest is gone when they come back.
func _vanish_guest() -> void:
	AudioManager.play_sfx(&"light_buzz", guest.global_position)
	get_tree().call_group("reception_lights", "flicker", flicker_seconds)
	await get_tree().create_timer(flicker_seconds).timeout
	get_tree().call_group("reception_lights", "set_off", true)
	AudioManager.play_sfx(&"light_off", guest.global_position)
	var env: Environment = get_viewport().world_3d.environment
	var base_ambient: float = env.ambient_light_energy
	env.ambient_light_energy = base_ambient * blackout_ambient
	await get_tree().create_timer(blackout_seconds * 0.5).timeout
	guest.vanish()
	await get_tree().create_timer(blackout_seconds * 0.5).timeout
	get_tree().call_group("reception_lights", "set_off", false)
	env.ambient_light_energy = base_ambient
	EventManager.set_flag(&"guest_vanished")
	figure.visible = true
	await _run_phone_sequence()


## Silent call -> player checks Camera 04 -> "I'm already inside" -> door opens.
func _run_phone_sequence() -> void:
	await get_tree().create_timer(phone_delay).timeout
	await _ring_and_wait(call_silence)
	get_tree().call_group("hud", "show_message", "*Something is wrong. Check the cameras.*", 4.0)
	while not EventManager.has_flag(&"viewed_cam_04"):
		await EventManager.flag_set
	await get_tree().create_timer(second_call_delay).timeout
	await _wait_until_idle()
	await _ring_and_wait(call_key)
	figure.visible = false
	AudioManager.play_sfx(&"door_open", door_cue_position)
	get_tree().call_group("hud", "show_message", "*A door opens somewhere in the hallway.*", 4.0)
	await _final_scare()


## Footsteps -> player investigates the hallway -> Room 2's handle turns -> return to reception.
func _final_scare() -> void:
	await get_tree().create_timer(footsteps_delay).timeout
	AudioManager.play_sfx(&"footsteps", door_cue_position)
	get_tree().call_group("hud", "show_message", "*Footsteps in the hallway.*", 4.0)
	TaskManager.add_task(investigate_task)
	await _wait_for_player_in(hallway_trigger)
	get_tree().call_group("hallway_lights", "flicker", hallway_flicker_seconds)
	await get_tree().create_timer(hallway_flicker_seconds).timeout
	var door_room2: Door = get_node_or_null(door_room2_path) as Door
	if door_room2 != null:
		door_room2.turn_handle(handle_turn_seconds)
	else:
		push_warning("Room13Incident: door_room2_path does not point to a Door")
	await get_tree().create_timer(handle_turn_seconds * 2.0 + 0.4).timeout
	reception_trigger.monitoring = true
	await _wait_for_player_in(reception_trigger)
	TaskManager.complete_task(investigate_task.id)
	ShiftManager.unblock_end(event_id)
	EventManager.set_flag(&"room13_done")


func _wait_for_player_in(area: Area3D) -> void:
	while true:
		await get_tree().physics_frame
		for body: Node3D in area.get_overlapping_bodies():
			if body.is_in_group(&"player"):
				return


func _ring_and_wait(call: DialogueData) -> void:
	var phone: Telephone = get_tree().get_first_node_in_group(&"telephone") as Telephone
	if phone == null or call == null:
		return
	while phone.state != Telephone.State.IDLE:
		await get_tree().create_timer(0.5).timeout
	phone.ring(call)
	while true:
		var ended: Array = await phone.call_ended
		if ended[0] == call.id:
			return


func _wait_until_idle() -> void:
	while DialogueManager.is_active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		await get_tree().process_frame
