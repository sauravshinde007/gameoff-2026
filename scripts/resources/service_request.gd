class_name ServiceRequest
extends Resource
## One guest request (towels, ice, wake-up call...). State lives here and in GuestManager;
## `task_id` points at the single TaskManager task that shows it to the player.

enum State { CREATED, ACTIVE, COMPLETED, FAILED, CANCELLED }

@export var id: String = ""
@export var type: StringName = &""
@export var guest_id: int = 0
@export var room_id: int = 0
@export var state: State = State.CREATED
## Absolute shift minute the request becomes active (wake-up calls start later). 0 = at once.
@export var start_minute: int = 0
## Absolute shift minute after which the request counts as missed. 0 = none.
@export var deadline_minute: int = 0
@export var task_id: StringName = &""
