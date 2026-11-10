# ROOM 13

First-person psychological horror, Godot 4.x + GDScript, for Game Off 2026 (theme: SHIFT).
Full design: @docs/GDD.md — the GDD is the source of truth. If this file and the GDD disagree, the GDD wins.

## Workflow rules
- Work in small increments. The project must run (F5) after every change.
- One feature per task. Follow the GDD phase order (Phase 1 -> 4). Do not jump ahead.
- Before coding: inspect the existing project, state the plan in a few lines, then implement.
- Do NOT add mechanics, rooms, enemies or "future expansion" features (GDD section 12) without explicit approval.
- If a design decision is unclear, ask. Don't make big architecture or gameplay changes silently.
- After each task: run the validation command below, then summarize what changed and how to test it in-editor.
- Commit after each working milestone with a clear message.

## Validation (run after every change)
- Parse/lint check: `godot --headless --path . --check-only --quit` (adjust binary name if needed, e.g. `godot4`)
- Smoke test: `godot --headless --path . --quit-after 120` and confirm no errors in output
- Report any script errors or warnings; never claim something works without running these.
- You cannot see the game. For visual/feel changes, tell me exactly what to look at in the editor.

## Godot conventions
- GDScript only. Static typing everywhere (`var x: int`, `func f() -> void`).
- Scripts: snake_case.gd. Scenes: snake_case.tscn. Nodes: PascalCase. Constants: UPPER_SNAKE.
- Communicate through signals; keep systems decoupled. Prefer composition (small reusable scenes/components) over big scripts.
- Autoloads only for global systems: ShiftManager, TaskManager, RoomManager, EventManager, DialogueManager, AudioManager.
- Interaction: a single reusable `Interactable` base (script/component) with `interact()` and `get_prompt()`. The player raycasts and calls it — the player script must never need editing to add a new interactable.
- Event timings, dialogue text and room data go in data files or exported vars/resources, not hardcoded in unrelated scripts.
- Use exported variables for tuning values (speeds, durations, light energy).
- Avoid unnecessary abstraction. This is a jam project.

## Scene / file editing safety
- .tscn/.tres are text but fragile. Prefer small edits; never rewrite whole scene files blindly.
- Prefer building simple geometry/UI via scenes with primitive meshes (greybox) first. No external art needed until Phase 4.
- Never edit `.godot/` or `*.import` files. Keep `.godot/` in .gitignore.
- Don't rename/move files without updating all references.

## Project layout
```
res://
  docs/GDD.md
  scenes/   (player, environment, ui, props, npcs)
  scripts/  (matching subfolders)
  autoload/
  data/     (events, dialogue, rooms)
  assets/   (audio, textures, models)
```

## Current milestone
Phase 3: Horror sequence (see GDD section 11). Phase 1 (greybox + player) and Phase 2 (motel functionality, tasks 1-7) complete. Update this line as phases complete.

## Scope reminder
MVP = one 5-10 minute night shift with one scripted incident (The Room 13 Reservation), playable start to finish, with a restart. Polished and small beats big and broken.