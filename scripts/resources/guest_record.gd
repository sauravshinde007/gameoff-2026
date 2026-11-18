class_name GuestRecord
extends Resource
## Minimal guest data kept by GuestManager. No personality, no biography.

enum State { ARRIVING, AT_DESK, STAYING, CHECKING_OUT, GONE }

@export var id: int = 0
@export var display_name: String = ""
## "" until the guest has a reservation (walk-ins get one at the desk).
@export var reservation_id: String = ""
## 0 = no room yet.
@export var room_id: int = 0
@export var state: State = State.ARRIVING
@export_range(0, 100) var satisfaction: int = 60
## Service request ids (Task 4).
@export var request_ids: Array[String] = []
## Absolute shift minute of check-in.
@export var checkin_minute: int = 0
