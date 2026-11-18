class_name TaskData
extends Resource

enum Priority { NORMAL, URGENT }

@export var id: StringName = &""
@export var text: String = ""
## Rules are standing instructions: listed, but never completed.
@export var is_rule: bool = false
## Free-form group: &"duty", &"guest", &"maintenance"... Empty for the original MVP tasks.
@export var category: StringName = &""
@export var priority: Priority = Priority.NORMAL
## Mandatory tasks are expected of the player; optional ones are extra work.
@export var mandatory: bool = false
## Absolute shift minute (see ShiftData). 0 = no deadline.
@export var deadline_minute: int = 0
## Optional links, 0 / "" = none. The owner of the state (e.g. GuestManager) keeps the real data.
@export var room_id: int = 0
@export var guest_id: int = 0
@export var request_id: String = ""
