class_name ReservationData
extends Resource

enum Status { PENDING, CHECKED_IN, CHECKED_OUT, CANCELLED }

@export var id: String = ""
@export var guest_name: String = ""
## 0 = no room assigned yet.
@export var room_id: int = 0
@export var status: Status = Status.PENDING
## Absolute shift minute a phone booking arrives at the desk. 0 = no scheduled arrival.
@export var arrival_minute: int = 0
