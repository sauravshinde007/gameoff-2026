class_name RoomData
extends Resource

## OUT_OF_ORDER = "Out of Service". New values are appended so saved .tres ints stay valid.
enum Status { AVAILABLE, OCCUPIED, OUT_OF_ORDER, RESERVED, NEEDS_CLEANING, MAINTENANCE }

@export var id: int = 0
@export var display_name: String = ""
@export var status: Status = Status.AVAILABLE
@export var guest_name: String = ""
## True once the guest in this room has been handed their key.
@export var key_issued: bool = false
