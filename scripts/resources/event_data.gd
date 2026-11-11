class_name EventData
extends Resource
## One timed event. EventManager fires it once the clock reaches trigger_minute AND its
## conditions hold; until then the shift clock is held.

@export var id: StringName = &""
## Absolute minute (see ShiftData). 12:15 AM = 24 * 60 + 15.
@export var trigger_minute: int = 0
## Tasks that must be completed before the event fires.
@export var required_tasks: Array[StringName] = []
## Wait until no dialogue is active and the player is not in a UI screen.
@export var wait_for_idle: bool = true
## If set, the telephone rings with this call when the event fires.
@export var phone_call: DialogueData
