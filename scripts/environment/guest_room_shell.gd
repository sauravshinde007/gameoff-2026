@tool
class_name GuestRoomShell
extends Node3D
## Reusable guest-room building shell (walls, door frame, window, number plate).
## Local +Z = door side (faces the walkway). Furniture is added by variants later.

@export var room_number: int = 1:
	set(value):
		room_number = value
		_apply()
## Rooms the player cannot enter get closed curtains so they read as occupied/finished.
@export var curtains_closed: bool = false:
	set(value):
		curtains_closed = value
		_apply()

## Room light is on: the window glows at night (occupied-looking rooms).
@export var window_lit: bool = false:
	set(value):
		window_lit = value
		_apply()

@onready var plate_label: Label3D = $NumberPlate/Label
@onready var window_unit: WindowUnit = $Window


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	plate_label.text = "%02d" % room_number
	window_unit.curtains_closed = curtains_closed
	window_unit.lit = window_lit
