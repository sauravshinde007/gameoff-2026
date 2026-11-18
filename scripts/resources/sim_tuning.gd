class_name SimTuning
extends Resource
## Simulator tuning values. Placeholder defaults, to be reviewed before balancing.

@export_group("Satisfaction")
@export_range(0, 100) var start_satisfaction: int = 60
@export var delta_check_in: int = 5
@export var delta_request_completed: int = 10
@export var delta_complaint_resolved: int = 10
@export var delta_request_ignored: int = -15
@export var delta_deadline_missed: int = -10
@export var delta_waited_too_long: int = -20

@export_group("Service requests")
## Shift minutes a normal guest request may stay open before it counts as missed.
@export var request_deadline_minutes: int = 50
## Same for urgent requests (maintenance).
@export var urgent_request_deadline_minutes: int = 30
## Wake-up calls: shift minutes from the phone call to the requested wake-up time.
@export var wakeup_delay_minutes: int = 90
## Wake-up calls may be placed this many minutes after the requested time.
@export var wakeup_grace_minutes: int = 15

@export_group("Maintenance")
## Generator fuel in percent. Drains with shift time.
@export_range(0.0, 100.0) var generator_start_fuel: float = 70.0
@export var generator_drain_per_hour: float = 12.0
## At or below this a refuel task appears.
@export var generator_low_fuel: float = 30.0
## At or below this the ice machine and coffee maker stop working until refuelled.
@export var generator_critical_fuel: float = 10.0
## Percent added by one carried fuel can.
@export var generator_fuel_per_can: float = 50.0
## Real seconds a repair takes (bulb swap, fixing a broken fitting).
@export var repair_seconds: float = 4.0

@export_group("Phone")
## Real seconds a phone rings before the caller gives up.
@export var call_timeout_seconds: float = 40.0
## Shift minutes between a booking call and the guest arriving.
@export var booking_arrival_delay_minutes: int = 60

@export_group("Shift director")
## Shift minutes after the shift starts before the first generated event.
@export var director_first_event_minutes: int = 15
## Shift minutes between generated events (calls, faults).
@export var director_interval_minutes: int = 30
## No new event while this many optional tasks (plus queued calls) are open.
@export var director_max_optional: int = 4
## No new mandatory event (wake-up call) while this many mandatory tasks are open.
@export var director_max_mandatory: int = 4
## No new urgent request (maintenance) while this many urgent tasks are open.
@export var director_max_urgent: int = 2
## No new call while this many are waiting or ringing.
@export var director_max_pending_calls: int = 2
## No new room fault while this many rooms are faulty.
@export var director_max_faults: int = 1
## Event weights: "reservation", "enquiry", "cancellation", "service:<type>", "fault:bulb", "fault:repair".
@export var director_weights: Dictionary = {
	"reservation": 3, "enquiry": 1, "cancellation": 1,
	"service:towels": 3, "service:pillows": 2, "service:ice": 2, "service:coffee": 2,
	"service:cleaning": 1, "service:wakeup": 2, "service:maintenance": 1,
	"fault:bulb": 1, "fault:repair": 1,
}

@export_group("Physical guests")
## Upper bound on guests physically in the motel grounds at once (target is 3-5).
@export var max_active_guests: int = 5
## Shift minutes after the shift starts before the first generated arrival check.
@export var first_spawn_delay_minutes: int = 25
## Shift minutes between arrival checks (Task 7 may replace this with the shift director).
@export var spawn_interval_minutes: int = 45
## Shift minutes a guest must have stayed before they can come to check out.
@export var min_stay_minutes: int = 150
## Guests already in rooms at shift start count as having stayed this long.
@export var preexisting_stay_minutes: int = 600
## Real seconds a generated guest waits at the desk before giving up on check-in.
@export var desk_patience_seconds: float = 120.0


## Named outcomes are the only way satisfaction changes. Unknown names change nothing.
func get_satisfaction_delta(outcome: StringName) -> int:
	match outcome:
		&"check_in":
			return delta_check_in
		&"request_completed":
			return delta_request_completed
		&"complaint_resolved":
			return delta_complaint_resolved
		&"request_ignored":
			return delta_request_ignored
		&"deadline_missed":
			return delta_deadline_missed
		&"waited_too_long":
			return delta_waited_too_long
	return 0
