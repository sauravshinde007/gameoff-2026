# ROOM 13

## Game Design Document (GDD)

**Project:** ROOM 13\
**Game Jam:** Game Off 2026\
**Theme:** SHIFT\
**Engine:** Godot 4.x\
**Language:** GDScript\
**Genre:** First-Person Motel Job Simulator / Psychological Horror
(future narrative layer not currently specified)\
**Perspective:** First-Person 3D\
**Platform:** Windows / Linux\
**Players:** Single-player

> **Document status:** The original MVP and expanded motel environment
> have been implemented. This document now defines the approved
> direction for **Motel Simulator V1**. The simulator is designed to be
> story-independent. The final story, antagonist, horror incidents,
> survival mechanics, scoring and endings remain undecided and must not
> be invented or implemented as part of Simulator V1.

------------------------------------------------------------------------

# 1. Game Overview

ROOM 13 is a first-person game set at an isolated roadside motel. The
player works at the motel and is responsible for its day-to-day
operations.

The game combines: - Front-desk work and room management. - Guest
interactions through physical NPCs and telephone calls. - Simple motel
finances and supply management. - Physical errands across the motel
property. - Cleaning and basic maintenance. - Shift responsibilities and
an end-of-shift report.

The intended experience is a **balanced first-person motel job
simulator**, not a full business-management spreadsheet simulator. The
player should spend most of their time interacting with the motel and
its guests in the 3D environment. Computers and menus support the work;
they should not replace the physical gameplay.

The simulator must be functional and enjoyable independently of any
future horror or narrative content.

## 1.1 Core experience

The player starts a shift, reviews the motel's condition and outstanding
work, handles guests and bookings, completes physical errands, manages
basic supplies and money, and reviews the shift at the end.

The work should feel purposeful but manageable. The target pressure is
moderate: there can be competing responsibilities, but the game should
not become a constant countdown or punishing time-management challenge.

## 1.2 Design principles

1.  **Physical-first gameplay:** Use the motel environment for
    meaningful interactions.
2.  **Simple systems:** Prefer short, readable interactions over
    detailed simulations.
3.  **Connected mechanics:** A guest request should lead to a physical
    activity, use a location or resource, and update the relevant
    task/guest/economy state.
4.  **Moderate workload:** The player should have choices about task
    priority and enough time to move around.
5.  **Incremental implementation:** Extend existing systems rather than
    replacing them.
6.  **Story independence:** No story, horror, antagonist or survival
    assumptions in Simulator V1.

------------------------------------------------------------------------

# 2. Core Gameplay Identity

## 2.1 Approved V1 direction

  -----------------------------------------------------------------------
  Design area                         Decision
  ----------------------------------- -----------------------------------
  Gameplay identity                   Balanced motel job simulator

  Work pressure                       Moderate

  Guest interaction                   Mixed: physical guests and
                                      remote/telephone guests

  Active physical guests              Target of 3--5 at a time

  Economy                             Hybrid: income and expenses matter,
                                      but no bankruptcy game-over

  Daily responsibilities              Hybrid: regular duties plus
                                      generated tasks

  Guest satisfaction                  Simple individual guest
                                      satisfaction

  Motel upgrades                      Excluded from V1

  Story and horror                    Independent; not part of simulator
                                      implementation
  -----------------------------------------------------------------------

The 3--5 physical guest target is a balancing goal, not a requirement to
have that many NPCs present at every moment. Avoid unnecessary NPC
complexity.

## 2.2 Gameplay pillars

### A. Front-desk and guest management

-   Check-in and checkout.
-   Room assignment and availability.
-   Reservations and cancellations.
-   Guest payments.
-   Telephone calls and enquiries.
-   Basic guest records.

### B. Guest services

-   Receive service requests.
-   Collect and deliver requested items.
-   Handle basic complaints.
-   Schedule wake-up calls.
-   Track simple guest satisfaction.

### C. Motel operations

-   Clean rooms after checkout.
-   Restock rooms.
-   Collect and manage laundry.
-   Collect supplies from storage.
-   Perform simple maintenance.
-   Check the generator and fuel.
-   Handle occasional property chores.

### D. Economy and resources

-   Track motel balance.
-   Record income and expenses.
-   Purchase supplies.
-   Track a small set of essential stock.
-   Review financial summaries.

### E. Shift and task management

-   Review shift instructions.
-   Track regular responsibilities.
-   Receive guest and maintenance tasks.
-   Prioritize tasks.
-   Complete the shift and review results.

------------------------------------------------------------------------

# 3. Setting and Environment

## 3.1 Overall setting

The game takes place at a small, isolated, single-storey roadside motel
beside a highway.

The motel property is the primary playable location. The highway and
wider surrounding world are background scenery only.

## 3.2 Approved environment

  -----------------------------------------------------------------------
  Property                            Decision
  ----------------------------------- -----------------------------------
  Building layout                     L-shaped, single-storey motel

  Geographic setting                  Isolated roadside highway

  Guest rooms                         6 numbered rooms

  Fully accessible guest-room         3
  interiors                           

  Parking                             Central courtyard

  Architecture                        Wooden-panel motel

  Visual style                        PS1/PSX-inspired low-poly

  Exterior exploration                Limited to motel property

  Day/night                           Same geometry with different
                                      lighting, ambience and activity

  Access                              Mixed; some areas may be restricted
                                      by shift or task
  -----------------------------------------------------------------------

The reception is at the junction/elbow of the L-shaped building. Guest
wings extend around the central courtyard.

## 3.3 Environment spaces and intended gameplay use

  -----------------------------------------------------------------------
  Location                            Simulator V1 purpose
  ----------------------------------- -----------------------------------
  Reception                           Check-in/out, reservations,
                                      payments, telephone, computer,
                                      guest register and coffee

  Guest rooms                         Cleaning, restocking, deliveries
                                      and basic maintenance

  Laundry                             Collect clean towels/linen and
                                      perform a simple laundry
                                      interaction

  Storage                             Collect supplies, check stock and
                                      access replacement materials

  Owner's office                      Financial ledger, shift reports and
                                      management instructions

  Central courtyard                   Ice machine, vending, garbage
                                      collection and occasional parking
                                      inspection

  Rear service area                   Generator fuel and basic equipment
                                      checks

  Staff corridor                      Navigation between operational
                                      spaces
  -----------------------------------------------------------------------

All six guest rooms (01-06) have accessible interiors (revised
2026-11-16). Physical room tasks may use any of them.

## 3.4 Reception

Preserve existing reception interactions and visual identity: -
Wooden-panel walls and tiled floor. - Reception counter. - CRT
computer. - Telephone. - Guest register. - Room-key rack. - Wall clock
and manager's notes. - Existing interaction points.

The computer is the administration interface. The telephone is the
communication interface. Physical work is performed in the 3D
environment.

## 3.5 Guest accommodation

The motel has six numbered guest rooms. All six interiors are accessible
in the current environment. Room modules and room identifiers should
remain reusable and consistent.

## 3.6 Central parking courtyard

The courtyard includes parking bays, vehicles, exterior lights, motel
signage, vending and/or ice machines, fences and the entrance gate.
Vehicles are scenery and must not become drivable in Simulator V1.

## 3.7 Laundry room

Contains washing machines, laundry baskets, clean-towel shelves and
cleaning equipment. Simulator V1 may add simple interactions for
collecting clean linen and updating stock. Do not build a detailed
washing physics or timing simulation.

## 3.8 Storage room

Contains shelves, boxes, tools, replacement bulbs and cleaning supplies.
Use it as the physical location for collecting available supplies.

## 3.9 Owner's office

Contains a desk, computer/CRT, filing cabinet, papers and ledger. Use it
for financial records, shift reports and management instructions. Do not
add story clues or secrets.

## 3.10 Rear service area

Contains the generator, garbage bins, service entrance and maintenance
access. Use it for simple generator-fuel and occasional maintenance
tasks.

## 3.11 Day and night

Reuse the same geometry. Day/night presentation is controlled by
lighting, ambience and activity. Shift scheduling and the final story
are not locked by this document.

## 3.12 Visual identity

Preserve: - PS1/PSX-inspired low-poly 3D. - Low-resolution/pixelated
presentation. - Dither, vignette and retro colour treatment. -
Pixel-style UI typography. - Wooden-panel architecture. - Warm daytime
lighting and darker blue nighttime lighting.

------------------------------------------------------------------------

# 4. Simulator V1 --- Core Gameplay Loop

1.  Begin a shift.
2.  Review manager instructions, room status, supplies and outstanding
    tasks.
3.  Handle physical guests, reservations and telephone calls.
4.  Assign rooms, check guests in/out and process payments.
5.  Receive and complete guest service requests.
6.  Perform physical motel work: cleaning, laundry, restocking and
    maintenance.
7.  Purchase supplies and monitor motel finances.
8.  Complete regular responsibilities and prioritize generated tasks.
9.  End the shift and review finances, guest outcomes and outstanding
    work.

The loop should create variety through different guests and tasks, not
through a large number of complicated systems.

------------------------------------------------------------------------

# 5. Room and Guest Management

## 5.1 Existing system

The project already has a basic room/reception foundation. Inspect the
current RoomManager and related scenes/scripts before making changes.
Preserve working functionality and extend it only where needed.

## 5.2 Room states

The intended expanded room lifecycle is: - **Available:** Clean,
maintained and ready. - **Reserved:** Assigned to an upcoming booking. -
**Occupied:** A guest is currently staying. - **Needs Cleaning:** Guest
has checked out and the room requires cleaning. - **Maintenance:** A
repair is required. - **Out of Service:** The room cannot currently be
booked.

Do not force this exact enum or rewrite existing state handling without
first auditing the implementation. Map existing states to these design
concepts and explain any migration required.

## 5.3 Guest lifecycle

-   Reservation or walk-in enquiry.
-   Room availability check.
-   Room assignment.
-   Payment and key issue.
-   Occupied stay.
-   Service requests where applicable.
-   Checkout and payment settlement.
-   Room becomes dirty/needs cleaning.
-   Cleaning/restocking.
-   Room becomes available again.

Room payment timing and any deposit policy should be configurable; do
not hardcode unapproved business rules.

## 5.4 Physical guest behaviour

Target 3--5 active physical guests at a time. Use a small set of
reusable behaviours: - Walk-in guest. - Existing guest. - Checking-out
guest. - Guest approaching reception for a service. - Guest arriving for
a reservation.

V1 NPC behaviour should be simple: - Basic movement between predefined
locations. - Reception interaction. - Room assignment. - Check-in and
checkout. - Short dialogue choices. - Request generation. -
Arrival/departure behaviour.

Use existing navigation and interaction foundations where possible. Do
not build advanced personality simulation, complex schedules, elaborate
dialogue trees or sophisticated autonomous AI.

Guests may occupy rooms whose interiors are not physically accessible to
the player, provided the existing room system supports this. Tasks
requiring physical room entry must be restricted to accessible
interiors.

------------------------------------------------------------------------

# 6. Guest Services and Satisfaction

## 6.1 Initial service catalogue

  -----------------------------------------------------------------------
  Service                 Player activity         Initial payment policy
  ----------------------- ----------------------- -----------------------
  Extra towels            Collect from laundry    Included
                          and deliver             

  Extra pillows           Collect from storage    Included
                          and deliver             

  Ice request             Use courtyard ice       Optional charge;
                          machine and deliver     configure

  Coffee request          Prepare/collect at      Optional charge;
                          reception and deliver   configure

  Wake-up call            Schedule through        Included
                          telephone               

  Room cleaning           Visit and clean room    Included

  Maintenance request     Visit and repair        Included
  -----------------------------------------------------------------------

These are the initial V1 service candidates. Exact prices and final
policies are balancing/configuration decisions, not fixed values in this
document.

## 6.2 Request lifecycle

1.  Request arrives by telephone or physical guest interaction.
2.  Create a task/request record with guest or room reference.
3.  Add it to the active task list.
4.  Player completes the required physical or reception interaction.
5.  Mark request complete.
6.  Update guest satisfaction and economy only where appropriate.

Each request should support: - Guest/room reference. - Request type and
description. - Priority. - Status. - Optional deadline. - Optional
payment. - Completion outcome.

Do not create a complex branching dialogue system.

## 6.3 Guest satisfaction

Use simple individual satisfaction, with a configurable value such as
0--100. It may be stored internally as a number while UI communicates it
through readable labels.

Potential influences: - Completing a request: positive. - Resolving a
complaint: positive. - Ignoring a request: negative. - Missing an agreed
deadline: negative. - Successful check-in: neutral or small positive.

Do not add an overall motel reputation, review platform, progression
unlocks or complex guest mood simulation in V1. Satisfaction may
influence simple guest feedback and modest configured outcomes, but
should not become a separate management game.

------------------------------------------------------------------------

# 7. Economy and Money

## 7.1 Economy direction

Use a hybrid economy: - The motel has a starting balance. - Room
bookings and eligible services generate income. - Purchases and
operating costs create expenses. - Transactions are recorded. - Low
funds can restrict purchases or selected operations. - Low funds must
not cause bankruptcy or an immediate game-over in V1.

## 7.2 Income sources

-   Room bookings and walk-in stays.
-   Eligible additional guest services.
-   Other explicitly configured motel charges.

## 7.3 Expenses

-   Cleaning and bathroom supplies.
-   Laundry supplies.
-   Generator fuel.
-   Replacement materials and maintenance.
-   Configured operating expenses.

Do not invent complex taxes, loans, investments, interest, payroll,
dynamic pricing or business upgrades.

## 7.4 Transactions and reports

Record each transaction with: - Amount. - Income/expense category. -
Description. - Related room/guest/task when applicable. - In-game
timestamp or shift/day reference.

The player should be able to review: - Current balance. - Income for the
shift/day. - Expenses for the shift/day. - Net result. - Recent
transaction history.

Use one source of truth for the balance. Avoid multiple systems
independently changing money.

------------------------------------------------------------------------

# 8. Inventory and Supplies

## 8.1 Design

Use a small shared motel inventory and a limited carry inventory. Do not
build an RPG-style grid inventory, crafting system, weight simulation or
complex logistics.

Initial resources: - Clean towels. - Pillows. - Soap. - Cleaning
supplies. - Fuel containers/fuel. - Replacement bulbs.

Exact starting quantities are balancing values and should be
configurable.

## 8.2 Interactions

-   Collect supplies physically from shelves.
-   Track quantities in the player's carry inventory.
-   Deliver items to guests or rooms.
-   Consume resources during cleaning and maintenance.
-   Decrease storage stock when items are collected.
-   Purchase replenishment through the reception computer.
-   For V1, purchased supplies may be added immediately; no delivery
    truck or supplier NPC is required.

Prevent negative stock and clearly communicate when a required item is
unavailable.

------------------------------------------------------------------------

# 9. Physical Motel Operations

## 9.1 Room cleaning

Keep room cleaning to a short, readable interaction: 1. Enter an
accessible room requiring cleaning. 2. Interact with the cleaning point.
3. Complete a short animation or interaction. 4. Handle dirty linen if
the task requires it. 5. Restock required supplies. 6. Mark the room
ready.

No detailed dirt simulation, movable furniture, mop physics or repeated
tiny cleaning actions.

## 9.2 Laundry

V1 laundry interactions should support: - Collecting clean
towels/linen. - Updating stock. - Optionally a simple start/complete
washing interaction if useful.

Do not build a detailed washing-machine simulation or long wait loop.

## 9.3 Maintenance

Initial maintenance activities: - Replace a burnt-out bulb. - Refill
generator fuel. - Perform a simple equipment repair. - Occasional
courtyard garbage collection or inspection.

These should be occasional tasks, not constant chores.

## 9.4 Generator

The generator interaction should be simple: - Receive a low-fuel
task/notification. - Visit the rear service area. - Use available
fuel. - Update fuel state. - Resolve the task.

Do not simulate electrical engineering, power distribution networks or
detailed generator mechanics. Any effect on motel functions should be
limited and clearly communicated.

------------------------------------------------------------------------

# 10. Telephone and Computer

## 10.1 Telephone --- communication

The telephone handles: - Reservations. - Guest service requests. -
General enquiries. - Cancellations. - Manager instructions. - Supplier
calls only if required for a specific task.

Use concise dialogue and limited choices. Do not implement elaborate
branching dialogue trees.

## 10.2 Reception computer --- administration

The computer may provide: - Room status and guest records. - Reservation
handling. - Financial overview and transaction history. - Supply
ordering. - Active task list. - Daily/shift report.

Keep the interface readable and consistent with the existing pixel-style
UI. Do not force the player to remain at the computer for most of the
shift.

## 10.3 Interaction principle

-   Telephone = communication.
-   Computer = administration.
-   Physical motel = execution.

Preserve existing computer and telephone behaviour where it already
works; extend rather than replace.

------------------------------------------------------------------------

# 11. Tasks, Responsibilities and Workload

## 11.1 Hybrid task model

Each shift combines:

**Regular responsibilities** - Review room availability. - Check
reception. - Review outstanding guest requests. - Check essential
supplies. - Review end-of-shift report.

**Generated responsibilities** - Walk-in guest arrives. - Guest requests
towels or another service. - Room needs cleaning. - Generator needs
fuel. - Maintenance issue occurs. - Telephone reservation arrives.

These are examples, not a requirement that every event occurs on every
shift.

## 11.2 Workload targets

Initial balancing targets: \| Parameter \| Target \| \|---\|---:\| \|
Active physical guests \| 3--5 \| \| Active optional tasks \| 3--4 \| \|
Mandatory tasks \| 2--3 \| \| Simultaneous urgent requests \| 1--2 \|

These are tunable targets, not hard-coded architectural limits. The
system should avoid generating an endless stream of tasks.

## 11.3 Priority and deadlines

Not every task needs a timer.

  Task               Suggested handling
  ------------------ ------------------------------------------------------
  Walk-in check-in   Immediate attention while guest is present
  Guest service      Flexible; deadline only when explicitly communicated
  Room cleaning      Before the room is assigned again
  Generator fuel     Complete before a configured critical threshold
  Supply ordering    Flexible
  Shift report       End-of-shift responsibility

The player should be able to prioritize tasks. Missed deadlines should
have understandable, proportionate consequences.

## 11.4 Neglected tasks

Possible gradual consequences: - Ignored guest request: satisfaction
decreases. - Dirty room: cannot be reassigned. - Low supplies: related
services become unavailable. - Low generator fuel: configured motel
functions may be affected. - Unresolved maintenance: room/equipment
remains unavailable. - Unanswered reservation: potential booking is
lost.

Do not add bankruptcy, sudden game-over or severe cascading penalties in
V1.

------------------------------------------------------------------------

# 12. Shift Management and Day Structure

The existing ShiftManager and clock must be inspected and preserved.
Simulator V1 may integrate task generation and shift reports with the
existing shift lifecycle.

The final campaign length, day count, exact shift schedule and story
progression are not defined here. Do not invent them.

A shift should: 1. Begin using the existing shift flow. 2. Present
instructions and current motel state. 3. Allow regular and generated
work. 4. Track completed and outstanding tasks. 5. End through the
existing shift/end-of-shift mechanism. 6. Present a summary of finances,
task outcomes and relevant guest outcomes.

Do not change shift duration or clock speed without approval.

------------------------------------------------------------------------

# 13. Simulator V1 Exclusions

Do not implement: - Motel upgrades or property expansion. - Employee
hiring/management. - Loans, bankruptcy or complex accounting. - Taxes,
investments or dynamic pricing. - Advanced NPC personalities or
autonomous schedules. - Complex dialogue trees. - Large inventory grids,
crafting or weight simulation. - Vehicle driving. - Detailed cleaning
physics. - Complex motel reputation/review systems. - Story progression
or narrative clues. - Horror incidents, criminals, stalkers, ghosts or
survival mechanics. - Scoring, grades, endings or win/loss conditions. -
Additional large locations.

------------------------------------------------------------------------

# 14. Technical Architecture Guidelines

Use Godot 4.x and GDScript. Follow the existing project structure and
conventions.

Proposed logical responsibilities: - **RoomManager:** Existing room
states, availability and assignments. - **EconomyManager:** Balance and
transaction records. - **GuestManager:** Guest records and physical
guest lifecycle. - **ServiceManager:** Guest service requests. -
**InventoryManager:** Stock and carried quantities. - **TaskManager:**
Regular and generated tasks. - **ShiftManager:** Existing clock and
shift lifecycle.

These are logical responsibilities, not instructions to create every
manager as a new autoload. Inspect existing scripts and autoloads first.
Reuse or extend existing systems where appropriate.

Architecture rules: - GDScript only. - Static typing. - Scripts use
`snake_case.gd`. - Scenes use `snake_case.tscn`. - Nodes use
PascalCase. - Constants use `UPPER_SNAKE_CASE`. - Use signals to
communicate between decoupled systems. - Prefer composition and small
reusable scenes. - Use autoloads only for genuinely global systems. -
Keep tunable values in exported variables or resources. - Avoid
unnecessary abstraction.

------------------------------------------------------------------------

# 15. Development Roadmap

Implement one milestone at a time. The project must remain runnable
after each milestone.

## Milestone 0 --- Existing systems audit

-   Inspect project structure and current scenes/scripts.
-   Identify RoomManager, TaskManager, ShiftManager, telephone,
    computer, interaction and guest systems.
-   Document what already exists and what must be extended.
-   Identify risks and conflicts before coding.
-   Do not rewrite systems during the audit.

## Milestone 1 --- Economy foundation

-   Balance and transaction model.
-   Guest room payment integration.
-   Expense and purchase integration.
-   Financial overview and transaction history.
-   Test positive, negative and insufficient-funds cases.

## Milestone 2 --- Guest operations

-   Guest records and simple NPC states.
-   Check-in/check-out integration.
-   Reservations and telephone interactions.
-   Guest service request lifecycle.
-   Simple individual satisfaction.
-   Keep NPC count and behaviour lightweight.

## Milestone 3 --- Physical operations

-   Cleaning and room readiness.
-   Laundry and towel stock.
-   Storage collection.
-   Carry inventory and deliveries.
-   Guest service completion in the environment.

## Milestone 4 --- Maintenance

-   Generator fuel.
-   Replacement bulbs.
-   Basic repairs.
-   Occasional property chores.
-   Supply consumption and task resolution.

## Milestone 5 --- Shift integration

-   Regular responsibilities.
-   Generated tasks and workload limits.
-   Priorities and selected deadlines.
-   End-of-shift financial/task/guest summary.
-   Full simulator playthrough and balancing.

Do not implement all milestones in one large change.

------------------------------------------------------------------------

# 16. Validation and Acceptance Criteria

After each milestone: - Run
`godot --headless --path . --check-only --quit` (or installed binary
equivalent). - Run `godot --headless --path . --quit-after 120` (or
equivalent smoke test). - Report actual warnings/errors; do not claim
tests passed unless run. - Visually inspect changed scenes in the Godot
editor. - Preserve the existing MVP as a working fallback. - Keep Free
Roam independent of simulator tasks, economy, guests and shift
progression.

Simulator V1 is ready for review when: - Existing movement and
interaction remain functional. - Existing room/reception functionality
is preserved. - Money changes only through valid transactions. - Guests
can be checked in/out using the room system. - Physical and telephone
requests can be received and completed. - Cleaning and supply tasks use
the existing accessible spaces. - Inventory quantities cannot become
negative. - Generated tasks remain within the intended workload. - The
shift can be completed and summarized. - No story or horror content has
been introduced.

Headless validation does not replace in-editor visual inspection.

------------------------------------------------------------------------

# 17. Story and Horror Independence

Simulator V1 is deliberately story-independent.

The current creative preference for a grounded human threat is not
authorization to implement any antagonist, criminal AI, suspicious
guest, scripted encounter or survival mechanic.

The previous MVP Room 13 incident was retired and removed on 2026-11-14.
It is not canon and must not be restored.

Build the motel simulator as a stable foundation. Future narrative and
horror systems will be designed separately and layered onto this
foundation only after explicit approval.

------------------------------------------------------------------------

# 18. Important Instructions for AI Development

Before coding: 1. Read this GDD, `CLAUDE.md` and `GAMEPLAY_SYSTEMS.md`.
2. Inspect the actual Godot project and relevant scripts/scenes. 3.
Compare the design with existing functionality. 4. Explain the proposed
milestone plan and files to be changed. 5. Ask about substantial
ambiguities or conflicts. 6. Implement only the currently approved
milestone. 7. Validate and report the result.

Do not independently expand scope, silently replace existing systems or
invent story content.

**The goal is a compact, atmospheric, playable motel job simulator with
meaningful physical interactions and simple connected management
systems.**