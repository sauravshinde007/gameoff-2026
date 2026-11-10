class_name ReservationData
extends Resource

enum Status { PENDING, CHECKED_IN, CHECKED_OUT }

@export var id: String = ""
@export var guest_name: String = ""
## 0 = no room assigned yet.
@export var room_id: int = 0
@export var status: Status = Status.PENDING
