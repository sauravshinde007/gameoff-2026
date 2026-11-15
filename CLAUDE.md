# ROOM 13 — Claude Code Instructions

First-person 3D game for Game Off 2026 (theme: SHIFT), built with Godot 4.x and GDScript.

## Source documents and authority

- `docs/GDD.md` — high-level game design and approved project direction.
- `docs/ENVIRONMENT.md` — detailed specification for the current motel environment expansion milestone.
- The GDD is the high-level source of truth. For the environment milestone, follow the more detailed spatial and construction requirements in `docs/ENVIRONMENT.md`.
- If documents conflict, stop and explain the conflict instead of silently choosing an interpretation.

The final story, antagonist, full gameplay loop, economy, scoring, endings and survival mechanics are not finalized. Do not invent or implement them.

## Workflow rules

- Work in small, reviewable increments.
- The project must remain runnable after every change.
- One milestone/task at a time. The current approved milestone is the environment expansion described in `docs/ENVIRONMENT.md`.
- Before coding: inspect the existing project, identify relevant scenes/scripts/resources, state the plan briefly, then implement.
- Preserve the completed MVP as a working fallback. Do not delete or overwrite the original playable scene before the expanded environment has been tested.
- Preserve existing player controls, interactions, reception functionality, UI and gameplay systems unless a change is explicitly required and approved.
- Do not implement economy, advanced room management, guest personality systems, new story events, criminal AI, survival systems, scoring or endings during the environment milestone.
- If a design decision is unclear or the current project structure conflicts with the environment specification, ask before making a substantial change.
- After each task, run the validation commands below and summarize what changed and how to inspect it in-editor.
- Commit after each working milestone with a clear commit message if the project uses Git.

## Current project status

The MVP is complete. It includes a title screen, day introduction, first-person movement and interaction, reception, short hallway with three guest-room doors, receptionist tasks, day/night transition, ending, restart and pause menu. The prototype Room 13 incident was removed on 2026-11-14 (see Scope discipline).

Environment milestone: all seven tasks are built and headless-validated. See `docs/ENVIRONMENT_STATUS.md` for the layout, file map, known gaps and the review checklist. Waiting for the user's in-editor approval before any other work.

Free Roam mode (title screen → Free Roam, `scenes/free_roam.tscn`, `scripts/free_roam.gd`) loads the environment with no tasks, shift clock, events or story. N toggles day/night, ESC opens the pause menu. Use it to review the environment. Keep it separate from the main game: future narrative and mechanics go in `main.tscn`, not Free Roam. When the environment root scene changes, update both `main.tscn` and `free_roam.tscn`.

The current MVP screenshots establish the visual style:
- PS1/PSX-inspired low-poly 3D.
- Low-resolution/pixelated retro post-processing.
- Dither, vignette and retro colour treatment.
- Pixel-style UI typography.
- Wooden-panel reception walls and tiled floor.
- CRT-era computer props.
- Warm daytime lighting and dark blue nighttime lighting.

Keep the MVP working while expanding the environment.

## Current milestone: Environment expansion

Read `docs/ENVIRONMENT.md` fully before implementation.

Approved environment decisions:
- Single-storey L-shaped roadside motel.
- Wooden-panel architecture matching the existing MVP.
- Six numbered guest rooms.
- Three fully accessible guest-room interiors.
- Central parking courtyard.
- Expanded reception, preserving existing interactions.
- Laundry room.
- Storage room.
- Owner's office.
- Small rear service area.
- Limited exploration of the motel property only.
- Highway and surrounding world are background scenery, not explorable.
- Reuse the same environment for day and night; vary lighting, ambience and activity.

The environment milestone should be delivered as one coherent level-design phase, but implemented in safe substeps:
1. Inspect existing project and map current reception coordinates/node structure.
2. Create a greybox of the full property and validate proportions/navigation.
3. Expand building wings and add six room doors.
4. Add the three accessible guest-room interiors and reusable room structure.
5. Add laundry, storage, owner's office and rear service area.
6. Add central courtyard, parking, vehicles, sign, boundary and background.
7. Add day/night environmental lighting and ambience.
8. Run validation and provide a clear in-editor review checklist.

Do not skip the greybox review. Do not add detailed props before the overall layout is navigable.

## Godot conventions

- GDScript only.
- Use static typing (`var x: int`, `func f() -> void`).
- Scripts: `snake_case.gd`.
- Scenes: `snake_case.tscn`.
- Nodes: PascalCase.
- Constants: UPPER_SNAKE_CASE.
- Communicate through signals; keep systems decoupled.
- Prefer composition and small reusable scenes over large scripts.
- Autoloads only for genuinely global systems.
- Keep interaction reusable. The player raycasts and calls an interactable's `interact()` / `get_prompt()`; avoid editing the player script for each new object.
- Put tunable values in exported variables or resources.
- Avoid unnecessary abstraction. This is a game jam project.

## Scene and file editing safety

- `.tscn` and `.tres` are text but fragile. Make small, deliberate edits; do not rewrite entire scene files blindly.
- Inspect existing scene hierarchy, node paths, scripts, signals and resource references before modifying them.
- Prefer modular scenes for repeated room modules, doors, windows, wall sections, lights, vehicles and props.
- Reuse existing materials and assets where practical.
- Preserve the existing wooden-panel and PS1/PSX visual identity.
- Do not edit `.godot/` or `*.import` files.
- Keep `.godot/` in `.gitignore`.
- Do not rename or move files without updating every reference.
- Keep the existing MVP scene available as a fallback until the expanded level is validated.

## Project layout

Follow the existing repository structure. The expected documentation locations are:

```text
res://
  docs/
    GDD.md
    ENVIRONMENT.md
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

Do not reorganize the project merely to match this example. Inspect the actual project first.

## Validation (run after changes)

Parse/lint check:

```bash
godot --headless --path . --check-only --quit
```

Use the installed binary name if different (for example `godot4`).

Smoke test:

```bash
godot --headless --path . --quit-after 120
```

- Confirm there are no script/scene loading errors.
- Report warnings and errors; do not claim a test passed unless it was run.
- Headless validation does not replace visual inspection.
- For visual changes, tell the user exactly what to inspect in the Godot editor: navigation, collisions, proportions, sightlines, doors, lighting and interaction preservation.

## Scope discipline

The current task is environment construction only.

Do not implement:
- Full motel economy or money system.
- Advanced room booking/occupancy simulation.
- Guest personality or branching dialogue systems.
- New customer roster or character AI.
- Final story or antagonist.
- Criminal/stalker AI or combat.
- Survival mechanics.
- Scoring, grades or performance reports.
- New endings or win/loss states.
- New story encounters or scripted events (encounters will be designed fresh in a later phase).

The MVP Room 13 incident (and its Room 2 hallway scare) has been retired and removed from the project (2026-11-14). It is not canon and must not be preserved, restored or worked around. New encounters and story structure will be designed fresh in a later phase. Current goal: build the full game environment.

When the environment milestone is complete, stop and report the result. Wait for the user's review and approval before moving to the next game-development phase.
