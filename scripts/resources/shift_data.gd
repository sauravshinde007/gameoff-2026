class_name ShiftData
extends Resource
## Shift clock tuning. Minutes are absolute since midnight of the day the shift starts,
## so 6 AM the next day is 30 * 60.

@export var start_minute: int = 22 * 60
@export var end_minute: int = 30 * 60
@export var seconds_per_hour: float = 60.0
## Pace after the incident is over: the rest of the night rushes by.
@export var fast_seconds_per_hour: float = 3.0
