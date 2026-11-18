# ROOM 13 --- Claude Code Instructions

First-person 3D motel job simulator for Game Off 2026 (theme: SHIFT),
built with Godot 4.x and GDScript.

## 1. Source documents and authority

-   `docs/GDD.md` --- high-level game vision, approved environment and
    Simulator V1 scope.
-   `docs/ENVIRONMENT.md` --- detailed environment construction
    specification, if present.
-   `docs/ENVIRONMENT_STATUS.md` --- implemented environment status,
    file map and known gaps.
-   `docs/GAMEPLAY_SYSTEMS.md` --- detailed mechanics and implementation
    plan for Motel Simulator V1.

Authority: - GDD is the high-level source of truth. - ENVIRONMENT.md
governs environment construction details. - GAMEPLAY_SYSTEMS.md governs
Simulator V1 mechanics and milestone implementation. -
ENVIRONMENT_STATUS.md describes what has actually been built; inspect
the project to confirm current state. - If documents or the project
conflict, stop and explain the conflict instead of silently choosing an
interpretation.

## 2. Current project status

The original MVP is complete. It includes a title screen, day
introduction, first-person movement and interaction, reception, room
management foundation, telephone/computer and other reception
interactions, day/night transition, ending, restart and pause
functionality.

The expanded motel environment has been implemented and
headless-validated. See `docs/ENVIRONMENT_STATUS.md` for its layout,
file map and known gaps. The user has reviewed/accepted the environment
for the purpose of moving into simulator design; still perform visual
checks when modifying environment scenes.

The environment includes: - Single-storey L-shaped roadside motel. - Six
numbered guest rooms. - Six accessible interiors (Rooms 01-06; Rooms 02, 04 and
06 added 2026-11-16). - Central courtyard and parking. - Expanded reception. - Laundry,
storage and owner's office. - Staff corridor and rear service area. -
Motel sign, vehicles, vending/ice machines and highway backdrop. -
Day/night lighting presets.

Free Roam remains separate: - Title screen → Free Roam. -
`scenes/free_roam.tscn`, `scripts/free_roam.gd`. - Loads the motel
environment without simulator tasks, economy, guest events, shift clock
or story. - N toggles day/night; ESC opens pause menu. - Keep Free Roam
independent when adding simulator systems.

## 3. Approved next phase: Motel Simulator V1

The approved design direction is: - Balanced first-person motel job
simulator. - Moderate work pressure. - Mixed guest interactions:
physical guests and telephone/remote interactions. - Target 3--5 active
physical guests at a time. - Hybrid economy: income and expenses matter,
but no bankruptcy game-over. - Hybrid responsibilities: regular duties
plus generated tasks. - Simple individual guest satisfaction. - No motel
upgrades in V1. - Simulator remains independent of story and horror.

Read `docs/GAMEPLAY_SYSTEMS.md` fully before implementing gameplay
systems.

### Included in V1

-   Preserve and integrate existing room management.
-   Motel balance, income, expenses and transaction history.
-   Guest check-in/out, room assignment and reservations.
-   Lightweight physical guest NPC behaviours.
-   Telephone reservations, enquiries and service requests.
-   Guest service requests and simple individual satisfaction.
-   Room cleaning and restocking.
-   Small shared inventory and limited carry quantities.
-   Laundry and supply collection.
-   Basic maintenance and generator fuel.
-   Regular and generated tasks.
-   End-of-shift financial/task/guest summary.

### Explicitly excluded

-   Motel upgrades or property expansion.
-   Employees and staff management.
-   Loans, bankruptcy, taxes, investments or complex accounting.
-   Advanced NPC personalities, autonomous schedules or elaborate
    dialogue trees.
-   RPG inventory grids, crafting, weight simulation or complex
    logistics.
-   Vehicle driving.
-   Detailed cleaning physics.
-   Complex reputation/review systems.
-   Story, antagonist, criminal AI, horror incidents or survival
    mechanics.
-   Scoring, grades, endings and win/loss conditions.

Do not add excluded systems unless the user explicitly approves a
revised scope.

## 4. Development workflow

Work in small, reviewable increments.

One milestone at a time: 0. Existing systems audit. 1. Economy
foundation. 2. Guest operations. 3. Physical operations. 4. Maintenance.
5. Shift integration.

Before coding each milestone: 1. Inspect the existing project structure
and relevant scenes/scripts/resources. 2. Identify existing
functionality and dependencies. 3. State which files/scenes you expect
to modify. 4. Explain the implementation plan briefly. 5. Identify
design conflicts or missing decisions. 6. Ask before substantial
architectural changes.

Do not implement all milestones in one large change. Keep the project
runnable after each change. Preserve the existing playable MVP as a
fallback.

After each milestone: - Run the validation commands below. - Summarize
changed files and behaviour. - Explain how to inspect the changes
in-editor. - Report warnings and errors accurately. - Commit after a
working milestone if the project uses Git.

## 5. Existing systems preservation

The project already has a gameplay foundation. Inspect before creating
replacements.

In particular, audit: - RoomManager and room assignment/state logic. -
TaskManager and task UI. - ShiftManager and existing clock/shift flow. -
Reception computer. - Telephone. - Guest register and key rack. -
Interaction system and interactable objects. - Existing guest/NPC scenes
and movement. - UI and pause/menu flows. - Existing autoloads and signal
connections.

Extend or reuse existing systems where practical. Do not create
duplicate managers or parallel systems for functionality that already
exists.

Do not change the existing shift duration, clock speed, player controls,
interaction prompts or room behaviour without approval or a clear
technical necessity.

## 6. Gameplay design constraints

### Physical-first interaction

The computer is for administration; the telephone is for communication;
the physical motel is where the player executes work. Do not make the
simulator primarily a menu game.

### Guests

Target 3--5 active physical guests as a balancing goal, not a mandatory
constant NPC count. Use simple predefined behaviours and navigation.
Avoid complex personality simulation or autonomous schedules.

### Room access

All six rooms (01-06) have accessible interiors. Physical tasks
requiring room entry may use any of them.

### Economy

Use one source of truth for motel balance. All income/expense changes
should be recorded as transactions. Low funds may restrict purchases or
selected operations, but must not cause bankruptcy or game-over in V1.

### Inventory

Use a small shared stock and limited carry inventory. Prevent negative
quantities. No RPG grid, crafting, weight simulation or complex
logistics. Purchases may update stock immediately in V1.

### Tasks

Combine regular responsibilities with generated guest/maintenance tasks.
Initial tuning targets are 3--4 active optional tasks, 2--3 mandatory
tasks and 1--2 simultaneous urgent requests. Treat these as tunable
values, not hard architectural limits. Avoid endless task generation.

### Satisfaction

Use simple individual guest satisfaction. Do not introduce overall motel
reputation, reviews or progression unlocks.

### Story independence

Do not create story clues, suspicious guests, scripted scares,
criminals, ghosts, stalkers, survival mechanics or narrative events. The
old MVP Room 13 incident was retired and removed on 2026-11-14. It is
not canon and must not be restored.

## 7. Godot conventions

-   Godot 4.x.
-   GDScript only.
-   Use static typing (`var x: int`, `func f() -> void`).
-   Scripts: `snake_case.gd`.
-   Scenes: `snake_case.tscn`.
-   Nodes: PascalCase.
-   Constants: UPPER_SNAKE_CASE.
-   Communicate between decoupled systems through signals.
-   Prefer composition and small reusable scenes over large scripts.
-   Autoloads only for genuinely global systems.
-   Keep interactions reusable. The player raycasts and calls an
    interactable's `interact()` / `get_prompt()`; avoid editing the
    player script for each new object.
-   Put tunable values in exported variables or resources.
-   Avoid unnecessary abstraction. This is a game jam project.

Proposed logical responsibilities in GAMEPLAY_SYSTEMS.md are not a
mandate to create every manager as an autoload. Inspect existing
architecture first.

## 8. Scene and file editing safety

-   Inspect scene hierarchy, node paths, scripts, signals and resource
    references before modifying.
-   `.tscn` and `.tres` files are text but fragile. Make small,
    deliberate edits; do not rewrite entire scene files blindly.
-   Prefer modular scenes for repeated interactions and props.
-   Reuse existing materials and assets.
-   Preserve the PS1/PSX wooden motel identity.
-   Do not edit `.godot/` or `*.import` files.
-   Keep `.godot/` in `.gitignore`.
-   Do not rename or move files without updating every reference.
-   Keep Free Roam independent of simulator systems.
-   When changing the environment root scene, update both `main.tscn`
    and `free_roam.tscn` only if their environment references require
    it; do not attach simulator systems to Free Roam.

## 9. Expected project documentation locations

Follow the actual repository structure. Expected documentation
locations:

``` text
res://
  docs/
    GDD.md
    ENVIRONMENT.md
    ENVIRONMENT_STATUS.md
    GAMEPLAY_SYSTEMS.md
  scenes/
    player/
    environment/
    ui/
    props/
    npcs/
  scripts/
  autoload/
  data/
  assets/
```

Do not reorganize the project merely to match this example.

## 10. Validation

Run after changes:

Parse/lint check:

``` bash
godot --headless --path . --check-only --quit
```

Use installed binary name if different (for example `godot4`).

Smoke test:

``` bash
godot --headless --path . --quit-after 120
```

-   Confirm there are no script/scene loading errors.
-   Report warnings and errors; do not claim a test passed unless it was
    run.
-   Headless validation does not replace visual inspection.
-   For visual changes, provide an in-editor checklist covering
    navigation, collisions, proportions, doors, lighting and interaction
    preservation.
-   Test Free Roam separately after environment changes.

## 11. Scope discipline

The current approved milestone is **Milestone 0: Existing Systems
Audit**, unless the user explicitly approves a later milestone.

Do not begin coding Milestone 1 or beyond until: 1. The audit is
complete. 2. Existing systems and required changes are reported. 3. The
user approves the implementation plan.

Do not invent unresolved values such as starting balance, room prices,
service prices, operating expense amounts, shift duration or exact task
frequency. Make tunable values configurable and identify proposed
defaults for user review before balancing.

**The goal is to expand ROOM 13 incrementally, preserving a working
playable project throughout development.**
