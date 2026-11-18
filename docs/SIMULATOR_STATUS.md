# ROOM 13 — Motel Simulator V1 Status

All seven simulator tasks are implemented and headless-validated. In-editor review is outstanding.

## Systems and files

| System | Files |
|---|---|
| Rooms (Available, Occupied, Reserved, Needs Cleaning, Maintenance) | `autoload/room_manager.gd`, `scripts/resources/room_data.gd` |
| Economy (one balance, ledger, no negative balance) | `autoload/economy_manager.gd`, `data/sim/economy_config.tres` |
| Guests, satisfaction, service requests | `autoload/guest_manager.gd`, `scripts/resources/guest_record.gd`, `service_request.gd`, `scripts/sim/guest_spawner.gd` |
| Tasks (priority, mandatory, deadline, fail/remove) | `autoload/task_manager.gd`, `scripts/resources/task_data.gd`, `data/tasks/night_tasks.tres` |
| Telephone calls | `scripts/props/telephone.gd`, `scripts/sim/phone_dispatcher.gd` |
| Inventory and carrying | `autoload/inventory_manager.gd`, `data/sim/supply_catalog.tres`, `scripts/sim/supply_point.gd` |
| Room service, cleaning, repair | `scripts/sim/room_service_point.gd`, `cleaning_point.gd`, `repair_point.gd`, `room_point_spawner.gd` |
| Generator and room faults | `scripts/sim/generator_point.gd`, `maintenance_system.gd` |
| Event generation and shift end | `scripts/sim/shift_director.gd`, `shift_report.gd` |

Everything simulator-specific lives under the `Simulator` node in `scenes/main.tscn`. Free Roam does not load it.

## Tuning (first balance pass, 2026-11-18)

Values live in `data/sim/economy_config.tres`, `sim_tuning.tres`, `supply_catalog.tres` and `data/shift/night_shift.tres`.

- Shift: 90 real seconds per game hour, so the 6 AM to 2 PM morning shift is 12 real minutes. `main.gd` `night_shift` switches back to night lighting; `data/shift/night_shift.tres` holds the start/end minutes. One game minute is 1.5 real seconds.
- Economy: start $300, room $45, ice $2, coffee $3, operating costs $120 per shift. A decent shift ends around +$100 to +$200.
- Stock: towels 8, pillows 4, soap 8, cleaning 5, fuel 2, bulbs 3. Cleaning a room uses 1 cleaning, 1 soap, 1 towel, so supplies need restocking about once a shift. Purchases up to 10 at a time.
- Requests: 50 game minutes to deliver (75 s real), urgent 30. Wake-up calls are requested 90 minutes ahead and may be placed up to 15 minutes late.
- Phone: rings 40 s before the caller gives up. Phone bookings arrive 60 minutes later.
- Generator: starts at 70%, drains 12% per hour. Low (30%) around 9:20 AM, critical (10%) around 11 AM if ignored. One can adds 50%. Expect 1 to 2 refuels.
- Director: first event 15 minutes in, then one every 30 game minutes (45 s real). Caps: 4 optional, 4 mandatory, 2 urgent, 2 calls waiting, 1 room fault.
- Room jobs (cleaning, repairs) fade to black with a caption while they run (`scripts/sim/work_transition.gd`).
- Guests: up to 5 on the grounds, first arrival check 25 minutes in, then every 45. Guests stay at least 150 minutes. They wait 120 s at the desk before leaving.
- Satisfaction: start 60, check-in +5, request done +10, ignored -15, missed deadline -10, left waiting -20.

## Known gaps

- The MVP duties (answer phone, check register) count toward the optional-task cap until done.
- Guest arrivals are still timed by `GuestSpawner`, not the director.
- Phone bookings do not set a room to Reserved.
