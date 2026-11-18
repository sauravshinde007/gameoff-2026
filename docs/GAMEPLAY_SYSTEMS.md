# ROOM 13 --- GAMEPLAY SYSTEMS

## Motel Simulator V1 Implementation Specification

**Project:** ROOM 13\
**Engine:** Godot 4.x\
**Language:** GDScript\
**Status:** Approved design direction; implementation must proceed
milestone by milestone.\
**Related documents:** `GDD.md`, `CLAUDE.md`, `ENVIRONMENT_STATUS.md`

------------------------------------------------------------------------

# 1. Purpose and Scope

This document translates the approved Motel Simulator V1 design into an
implementation plan for Claude Code.

ROOM 13 is a first-person motel job simulator. The player runs
day-to-day operations at a small roadside motel through guest
interactions, room management, physical errands, simple finances,
supplies and shift responsibilities.

The simulator is story-independent. Do not implement horror incidents,
criminals, antagonists, survival mechanics, narrative clues or endings.

## 1.1 Locked design decisions

  -----------------------------------------------------------------------
  Area                                Decision
  ----------------------------------- -----------------------------------
  Gameplay identity                   Balanced motel job simulator

  Pressure                            Moderate

  Guest interaction                   Mixed physical and telephone/remote

  Physical guest target               3--5 active at a time

  Economy                             Hybrid; income and expenses matter,
                                      no bankruptcy game-over

  Responsibilities                    Hybrid; regular duties plus
                                      generated tasks

  Satisfaction                        Simple individual guest
                                      satisfaction

  Upgrades                            None in V1

  Story/horror                        Independent and excluded
  -----------------------------------------------------------------------

## 1.2 Core design rule

Every system should create or support a meaningful player activity in
the motel environment. Avoid features that add menus or data management
without creating an interesting interaction.

The computer handles administration, the telephone handles
communication, and the 3D environment is where physical work happens.

------------------------------------------------------------------------

# 2. Existing Project Audit --- Milestone 0

This is the first implementation task. Do not begin building new systems
until this audit is complete and the user approves the resulting plan.

Inspect the actual Godot project. Do not infer implementation from
documentation alone.

## 2.1 Inspect

-   Project folder and scene structure.
-   Autoloads and global managers.
-   RoomManager and all room states/assignment logic.
-   TaskManager and task UI.
-   ShiftManager, clock and shift lifecycle.
-   Guest/NPC scenes, scripts, navigation and spawn points.
-   Reception computer UI and functionality.
-   Telephone interactions and dialogue flow.
-   Guest register and key rack.
-   Interaction system and interaction prompts.
-   Existing service/cleaning/maintenance interactions, if any.
-   Existing economy, inventory or transaction logic, if any.
-   Main scene and Free Roam scene dependencies.

## 2.2 Audit output

Produce a concise report with: 1. Existing systems and their file paths.
2. What already works. 3. What is partially implemented. 4. What is
missing. 5. Which existing systems should be extended. 6. Potential
conflicts or migration risks. 7. Proposed files/scenes for Milestone 1.
8. Validation status and any current errors.

Do not rewrite or refactor systems during the audit unless the user
separately approves it.

------------------------------------------------------------------------

# 3. Overall System Map

The following are logical responsibilities. They do not all need to be
separate autoloads or even separate scripts. Reuse existing
architecture.

  System             Responsibility
  ------------------ --------------------------------------------
  RoomManager        Room state, availability and assignments
  EconomyManager     Balance and transaction records
  GuestManager       Guest records and physical guest lifecycle
  ServiceManager     Guest service request lifecycle
  InventoryManager   Shared motel stock and carried quantities
  TaskManager        Regular and generated tasks
  ShiftManager       Existing clock and shift lifecycle

## 3.1 Communication

Prefer signals and explicit method calls between decoupled systems.

Examples of events that may need to be communicated: - Guest checked
in. - Guest checked out. - Room state changed. - Payment received. -
Expense recorded. - Guest request created/completed. - Inventory
quantity changed. - Task created/completed. - Shift started/ended.

Avoid circular dependencies. A system should not directly manipulate
another system's internal data when a clear method or signal can be
used.

## 3.2 Data/configuration

Keep tunable values configurable through resources or exported
variables: - Starting balance. - Room prices. - Service prices. -
Operating expense amounts and intervals. - Initial supply quantities. -
Carry limits. - Task generation frequency. - Request deadlines. -
Satisfaction changes. - Generator fuel threshold.

Do not invent final economy numbers. Propose sensible defaults for user
review before balancing.

------------------------------------------------------------------------

# 4. Room Management Integration

## 4.1 Preserve existing implementation

RoomManager already exists in some form. Inspect it before changing
anything. Preserve working booking, occupancy and room assignment logic.

Map current room states to these intended concepts without blindly
replacing the current enum:

-   Available.
-   Reserved.
-   Occupied.
-   Needs Cleaning.
-   Maintenance.
-   Out of Service.

## 4.2 Guest lifecycle

Expected high-level flow:

``` text
Reservation / Walk-in
        |
Check room availability
        |
Assign room
        |
Collect payment / apply existing payment rules
        |
Check in
        |
Occupied
        |
Check out
        |
Needs cleaning
        |
Clean and restock
        |
Available
```

Do not decide payment timing, deposits or cancellation penalties without
checking existing behaviour and getting approval where needed.

## 4.3 Physical room access constraint

All six numbered rooms (01-06) have accessible interiors (revised
2026-11-16).

-   Physical cleaning, restocking and maintenance tasks may use any room.

------------------------------------------------------------------------

# 5. Economy System --- Milestone 1

## 5.1 Goals

-   Maintain one authoritative motel balance.
-   Record all income and expenses.
-   Integrate room payments and eligible service charges.
-   Deduct purchases and operating costs.
-   Expose a simple financial summary.
-   Prevent invalid or duplicate transactions.

## 5.2 Income categories

Initial candidates: - Room booking/stay payment. - Walk-in payment. -
Optional paid guest services. - Other explicitly approved motel charges.

## 5.3 Expense categories

Initial candidates: - Cleaning supplies. - Bathroom supplies. - Laundry
supplies. - Generator fuel. - Replacement materials and maintenance. -
Configured operating expenses.

Do not add loans, taxes, investments, payroll, dynamic pricing or
upgrades.

## 5.4 Transaction data

Each transaction should contain enough information for a simple
ledger: - Unique or stable transaction identifier if required by
existing architecture. - Amount. - Type: income or expense. -
Category. - Description. - Optional guest/room/task reference. - In-game
time or day/shift reference.

Use a consistent sign convention. For example, store amount as a
positive magnitude and use transaction type to determine whether it
increases or decreases the balance, or choose another consistent
representation and document it.

## 5.5 Economy rules

-   Only valid transactions can change the balance.
-   A payment must not be applied twice.
-   An expense must not silently create a negative balance unless that
    behaviour is explicitly approved.
-   Low funds may prevent optional purchases or selected operations.
-   Low funds must not trigger bankruptcy or game-over in V1.
-   Financial UI should show current balance, income, expenses, net
    result and recent transactions.

## 5.6 Acceptance tests

-   A valid guest payment increases balance once.
-   A valid purchase decreases balance once.
-   Failed/invalid transactions do not change balance.
-   Insufficient funds are handled clearly.
-   Transaction history matches balance changes.
-   Shift/day summary totals match the transaction ledger.

------------------------------------------------------------------------

# 6. Guest Operations --- Milestone 2

## 6.1 Physical guest target

Target 3--5 active physical guests at a time. This is a balancing
target, not a hard-coded requirement to keep the motel populated.

Use a small number of reusable guest behaviours: - Walk-in guest. -
Guest arriving for a reservation. - Existing guest. - Guest checking
out. - Guest approaching reception for service.

## 6.2 NPC behaviour

V1 behaviour should include: - Spawn/arrival at an appropriate entry
point. - Basic navigation to reception or assigned room area. - Simple
waiting/interaction state. - Check-in/check-out interaction. - Limited
movement between predefined locations. - Departure.

Use existing navigation and interaction systems where possible. Avoid
sophisticated autonomous schedules, complex personalities and large
crowds.

## 6.3 Guest records

A guest record may need: - Guest identifier. - Display name. - Assigned
room, if any. - Stay/reservation state. - Payment state if relevant. -
Satisfaction value. - Active request references.

Keep data minimal. Do not create elaborate biographies or personality
attributes.

## 6.4 Reservations and telephone

Support basic flows: - Availability enquiry. - Reservation request. -
Cancellation if current design supports it. - Guest service request. -
General motel enquiry.

Use short dialogue choices. Avoid branching dialogue trees.

Telephone guests do not need to spawn physically unless the flow
explicitly becomes a walk-in/arrival.

## 6.5 Guest satisfaction

Use simple individual satisfaction, suggested internal range 0--100.
Keep changes configurable.

Possible outcomes: - Completing a request: increase. - Resolving a
complaint: increase. - Ignoring a request: decrease. - Missing an
explicitly communicated deadline: decrease. - Normal check-in: neutral
or small positive.

Do not implement an overall motel reputation or reviews system.

## 6.6 Acceptance tests

-   A physical guest can arrive and interact with reception.
-   Existing room logic determines availability.
-   Guest can be assigned a valid room.
-   Check-in/out updates room and guest states consistently.
-   Telephone request creates a service/task record.
-   Satisfaction changes only from defined outcomes.
-   NPC count remains within intended tuning targets under normal play.

------------------------------------------------------------------------

# 7. Guest Service System --- Milestone 2

## 7.1 Initial service catalogue

  -----------------------------------------------------------------------
  Service                 Player activity         Payment
  ----------------------- ----------------------- -----------------------
  Extra towels            Collect from laundry    Included
                          and deliver             

  Extra pillows           Collect from storage    Included
                          and deliver             

  Ice                     Use courtyard ice       Optional charge;
                          machine and deliver     configure

  Coffee                  Prepare/collect at      Optional charge;
                          reception and deliver   configure

  Wake-up call            Schedule through        Included
                          telephone               

  Room cleaning           Clean accessible guest  Included
                          room                    

  Maintenance request     Visit and perform       Included
                          simple repair           
  -----------------------------------------------------------------------

Prices and policies remain configurable and must not be invented as
final values.

## 7.2 Request state

A request should have a clear lifecycle: - Created. - Active/accepted. -
Completed. - Cancelled or failed, if needed.

Potential data: - Request ID. - Request type. - Guest and room
reference. - Description. - Priority. - Optional deadline. - Optional
payment. - Status. - Completion outcome.

Avoid duplicate task records for the same request. Decide whether a
service request owns a task or references a TaskManager task; do not
implement two competing sources of truth.

## 7.3 Completion

Completing a request may: - Consume inventory. - Change guest
satisfaction. - Create income if it is a paid service. - Mark the linked
task complete.

All changes should happen once and in a predictable order. Failed
delivery due to missing stock must leave the request active and
communicate the problem.

------------------------------------------------------------------------

# 8. Inventory System --- Milestone 3

## 8.1 Initial stock

Track only: - Clean towels. - Pillows. - Soap. - Cleaning supplies. -
Fuel/fuel containers. - Replacement bulbs.

Quantities are tunable values. Do not hardcode balancing values across
many scripts.

## 8.2 Shared stock and carry inventory

Use: - Shared motel stock located in the appropriate storage/laundry
context. - A small player carry inventory with limited quantities.

Do not build an RPG grid inventory, weight simulation, crafting or
complex logistics.

## 8.3 Physical interactions

-   Player interacts with a shelf or collection point.
-   Selects or collects a supported quantity.
-   Carry quantity increases.
-   Shared stock decreases.
-   Delivery/usage consumes carried items.
-   Invalid quantities and negative stock are prevented.

The interaction should be quick and readable. Do not require many
repetitive clicks.

## 8.4 Purchasing

Purchases happen through the reception computer: - Select an item. -
Select quantity. - Show cost. - Confirm purchase. - Validate funds. -
Record transaction. - Add stock immediately in V1.

No delivery truck, supplier NPC or delayed logistics system is required.

## 8.5 Acceptance tests

-   Stock decreases when items are collected.
-   Carry quantity increases correctly.
-   Delivery consumes carried items.
-   Cleaning consumes configured supplies where applicable.
-   Stock cannot become negative.
-   Purchase deducts money and increases stock exactly once.
-   Failed purchase leaves money and stock unchanged.

------------------------------------------------------------------------

# 9. Physical Operations --- Milestone 3

## 9.1 Room cleaning

Simple sequence: 1. Player enters an accessible room in Needs Cleaning
state. 2. Interacts with the cleaning point. 3. Short animation or
progress interaction occurs. 4. Required linen/supplies are collected or
consumed as configured. 5. Room state becomes Available only when
required steps are complete.

Avoid dirt simulation, detailed mop physics or moving furniture.

## 9.2 Laundry

V1 should support: - Collecting clean towels/linen from shelves. -
Updating stock. - Optionally a simple start/complete washing interaction
if it creates useful gameplay.

Do not build a detailed washing simulation or long waiting loop.

## 9.3 Storage

-   Physical collection of supplies.
-   Replacement bulbs and cleaning materials.
-   Clear feedback when stock is unavailable.

## 9.4 Courtyard

Possible occasional tasks: - Use/refill ice machine. - Collect
garbage. - Inspect parking area.

Do not make all courtyard props interactive by default.

------------------------------------------------------------------------

# 10. Maintenance System --- Milestone 4

Initial maintenance interactions: - Replace a burnt-out bulb. - Refill
generator fuel. - Simple equipment repair. - Occasional garbage
collection or property inspection.

## 10.1 Generator

Simple flow: 1. Generator fuel reaches configured low threshold. 2.
Create one maintenance task/notification. 3. Player visits rear service
area. 4. Player uses carried fuel. 5. Fuel state updates. 6. Task
completes.

Avoid electrical engineering or power network simulation. If fuel
reaches a critical state, only a small set of clearly communicated motel
functions may be affected. Define those effects before implementing
them.

## 10.2 Maintenance tasks

-   Do not generate repeated duplicate tasks for the same unresolved
    issue.
-   Resolve the task when the physical interaction succeeds.
-   If the player lacks the required item, explain what is missing and
    keep the task active.
-   Keep maintenance occasional rather than constant.

------------------------------------------------------------------------

# 11. Task and Shift Integration --- Milestone 5

## 11.1 Task categories

**Regular responsibilities** - Review room availability. - Check
reception. - Review outstanding guest requests. - Check essential
supplies. - Review end-of-shift report.

**Generated tasks** - Walk-in guest arrives. - Guest requests an item. -
Room needs cleaning. - Generator needs fuel. - Maintenance issue
appears. - Telephone reservation arrives.

Not every task must appear in every shift.

## 11.2 Task model

Each task should minimally support: - Task identifier. -
Type/category. - Description. - Priority. - Status. - Optional
deadline. - Optional linked guest/room/request. - Completion outcome.

Reuse the existing TaskManager if it exists. Do not create a parallel
task system.

## 11.3 Workload targets

Initial balancing targets: \| Parameter \| Target \| \|---\|---:\| \|
Active physical guests \| 3--5 \| \| Active optional tasks \| 3--4 \| \|
Mandatory tasks \| 2--3 \| \| Simultaneous urgent requests \| 1--2 \|

These should be configurable and tuned through playtesting. Do not
generate an endless stream of tasks. Consider a cap, cooldown or queue.

## 11.4 Deadlines and consequences

  -----------------------------------------------------------------------
  Task                                Handling
  ----------------------------------- -----------------------------------
  Walk-in check-in                    Guest waits for service

  Guest service                       Flexible unless a deadline is
                                      explicitly communicated

  Room cleaning                       Before next assignment

  Generator fuel                      Before critical configured
                                      threshold

  Supply ordering                     Flexible

  Shift report                        End of shift
  -----------------------------------------------------------------------

Consequences should be gradual: - Ignored request: satisfaction
decreases. - Dirty room: cannot be assigned. - Low supplies: related
service unavailable. - Low fuel: configured functions may be affected. -
Maintenance unresolved: equipment/room remains unavailable. - Unanswered
reservation: potential booking lost.

No bankruptcy or game-over in V1.

## 11.5 End-of-shift report

Summarize: - Starting and ending balance. - Income. - Expenses. - Net
result. - Completed tasks. - Outstanding tasks. - Relevant guest
outcomes.

Do not introduce letter grades, scoring, rankings or endings.

------------------------------------------------------------------------

# 12. UI Responsibilities

Reuse existing UI where possible. Keep the retro pixel-style visual
identity.

## Reception computer

-   Room and guest overview.
-   Reservation handling.
-   Financial summary.
-   Transaction history.
-   Supply purchasing.
-   Active task list.
-   End-of-shift report.

## Telephone

-   Incoming call presentation.
-   Short dialogue choices.
-   Reservation and service request handling.
-   Manager instructions where required.

## In-world interaction

-   Clear prompts.
-   Short collection/delivery interactions.
-   Cleaning and maintenance interactions.
-   Feedback for missing stock, unavailable rooms or insufficient funds.

Do not move all gameplay into the computer. Physical actions should
happen in the environment.

------------------------------------------------------------------------

# 13. Milestone Order and Dependencies

  -----------------------------------------------------------------------
  Milestone               Deliverable             Depends on
  ----------------------- ----------------------- -----------------------
  0                       Existing systems audit  None

  1                       Economy foundation      Audit approval

  2                       Guest operations and    Room system audit;
                          service requests        economy interfaces
                                                  where needed

  3                       Cleaning, laundry,      Guest/service model
                          inventory and           
                          deliveries              

  4                       Generator and basic     Inventory and task
                          maintenance             model

  5                       Task generation, shift  Previous systems
                          integration and reports 
  -----------------------------------------------------------------------

Claude must stop after each milestone, validate, report and wait for
approval before starting the next milestone.

------------------------------------------------------------------------

# 14. Validation Checklist

Run after each milestone:

``` bash
godot --headless --path . --check-only --quit
godot --headless --path . --quit-after 120
```

Use the installed binary name if different.

Also: - Test relevant interactions in-editor. - Confirm no duplicate
transaction or task processing. - Confirm stock and balance cannot
become invalid. - Confirm room state changes are consistent. - Confirm
Free Roam has no simulator tasks, economy, guest spawning or shift
progression. - Confirm the original playable MVP remains available as a
fallback. - Report actual errors/warnings and do not claim tests passed
unless run.

Headless validation does not replace visual inspection.

------------------------------------------------------------------------

# 15. Explicit Non-Goals

Do not implement: - Motel upgrades. - Employee management. - Loans,
bankruptcy, taxes, investments or complex accounting. - Advanced guest
personalities or autonomous schedules. - Elaborate branching dialogue. -
RPG inventory, crafting or weight simulation. - Vehicle driving. -
Detailed cleaning physics. - Overall motel reputation/reviews. - Story,
horror, antagonist, criminal AI, ghosts or survival mechanics. -
Scoring, grades, endings or win/loss states. - New explorable locations.

------------------------------------------------------------------------

# 16. Instructions to Claude Code

Before each milestone: 1. Read `GDD.md`, `CLAUDE.md` and this document.
2. Inspect the actual project and relevant files. 3. Identify existing
functionality to reuse. 4. State the proposed changes and affected
files. 5. Identify unresolved design values or conflicts. 6. Ask before
substantial architecture changes. 7. Implement only the approved
milestone. 8. Run validation and report the actual result.

Do not invent final prices, starting balance, operating expense amounts,
exact task frequency, shift length or deadlines. Keep these configurable
and propose defaults for approval.

Preserve the playable project after every change. Keep Free Roam
independent. Do not implement story or horror content.

**Build a compact, atmospheric, first-person motel job simulator through
small, testable milestones.**
