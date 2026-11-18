# ROOM 13: MVP Status Report

> **Update 2026-11-14: Room 13 incident removed.** The scripted incident (section 3 step 5, the Stranger's reservation, CAM 04, the phone calls, the Room 2 hallway scare, the rush to dawn) was prototype content and has been deleted: `scenes/events/room13_incident.tscn`, `scripts/events/room13_incident.gd`, `data/events/room13_reservation.tres`, `data/tasks/investigate_hallway.tres`, `data/dialogue/room13_call_*.tres`, the `room13` event and the "Room 13 unavailable" rule. The night now runs 10 PM to 6 AM with ordinary tasks only. New encounters will be designed fresh. The `MysteriousGuest` NPC scene and model remain as a reusable character only. Sections below describing the incident are historical.
>
> Also changed in the environment phase: 6 rooms (01–06) in `data/rooms/rooms.tres`, 6-hook key rack, and the entrance door now opens (`Door.openable`).

Companion to `docs/GDD.md` (design source of truth) and `CLAUDE.md` (workflow rules). This file describes what is actually built as of 2026-11-13. Hand all three to any AI that helps decide next steps.

## 1. Project facts

- Title: ROOM 13. Game Off 2026 jam entry, theme SHIFT.
- Genre: first-person psychological horror, workplace sim. Single player. Windows/Linux.
- Engine: Godot 4.x (project.godot targets 4.7, Forward Plus, Jolt Physics). GDScript only, static typing.
- Look: PS1/PSX retro. Low-res post-process filter (240p-style, dither, vignette, tint), low-poly models, pixel font (VCR OSD Mono), PSX skies.
- Premise: you are the new night receptionist at an isolated roadside motel with three rooms. A guest asks for a Room 13 that does not exist.
- Milestone: MVP complete (GDD phases 1-4). Remaining work is polish and playtest bug fixes only. No new features without approval (GDD section 12 lists the banned-for-now ideas).
- Length: about 5-10 minutes, start to finish, with restart.

## 2. Documents in the repo

| File | Purpose |
|---|---|
| `docs/GDD.md` | Full design: vision, setting, mechanics, MVP scope, Room 13 incident script, phase plan, future-expansion list, AI rules. Wins over CLAUDE.md on conflict. |
| `CLAUDE.md` | Workflow rules for the coding AI: small increments, validation commands, Godot conventions, scope limits, project layout. |
| `CREDITS.md` | Third-party assets. Several entries still say TODO (author/URL/licence for the PSX body mesh, AI face tool, prop models). Fix before release. |
| `docs/art inspiration/` | Reference screenshots. |
| `docs/MVP_STATUS.md` | This file. |

## 3. Player flow (what the game does end to end)

1. **Title screen.** START (fades to black, loads motel), NPC VIEWER (dev tool for previewing character models), QUIT.
2. **Day intro.** Warm daylight lighting. HUD message tells the player to read the manager's note. The player can walk the reception and hallway, and try the computer, phone, key rack, register, CCTV and doors. The task list is hidden.
3. **Read the manager's note.** Closing it the first time sets flag `note_read`. Screen fades to black with caption "10:00 PM", lighting swaps to the night preset, the task list appears, the clock starts.
4. **Night, 10 PM to about 12:15 AM.** Normal work:
   - 11:30 PM: phone rings. Mr. Doyle (Room 2) asks for towels. Answering completes the "answer the telephone" task.
   - The ordinary guest Ms. Carter checks in. This is a chain: talk to her, find her reservation on the computer, assign a free room, take the matching key from the rack, talk again to hand it over, and she walks down the hallway and vanishes from view. Handing over the key completes `check_in_guest`.
5. **Room 13 incident** fires at 12:15 AM (minute 1455), but only after `check_in_guest` is done and no dialogue is open.
   1. Entrance bell. The Stranger appears at the desk: "I have a reservation for Room 13."
   2. Impossible reservation `#0013`, guest "Unknown", room 13, status Check-in Pending, appears in the computer and register.
   3. Player checks the computer, then refuses (dialogue: "we don't have a Room 13" / "I stayed here yesterday").
   4. Reception lights flicker, cut out, return. The guest is gone. Entrance door stays locked.
   5. Phone rings: silence, static, line goes dead. HUD: "Something is wrong. Check the cameras."
   6. CCTV shows a figure at the end of the hallway on a fifth, phantom camera labelled ROOM 13 - CAMERA 04 (the camera is hidden until the story flag is set; viewing it sets `viewed_cam_04`).
   7. Second call: "You forgot to give me my key." ... "I'm already inside." A door-open sound plays at Room 2's door position.
   8. Footsteps. New task: "Investigate the hallway. Return to reception before 6:00 AM." Entering the hallway trigger flickers hallway lights, then Room 2's door handle slowly turns and returns.
   9. Walking back to reception completes the task and sets `room13_done`.
6. **Rush to dawn.** HUD: "The rest of the night passes quietly..." Clock speeds up to 3 s per game hour.
7. **6:00 AM.** Controls lock, end sting plays (file missing, see section 8), fade to black, "Shift complete" screen with Restart and Quit. The shift cannot end while the incident is still running (end is blocked until `room13_done`).
8. **Restart / pause.** ESC pauses (Resume, Restart, back to Title). Restart resets all autoloads and reloads the scene back to the day intro. F11 toggles fullscreen (action `toggle_fullscreen`).

Controls: WASD move, mouse look, E interact, ESC pause, mouse click for UI. No jump, run, crouch or inventory.

## 4. Gameplay systems and what they offer

**Player.** CharacterBody3D first-person controller. A visible body model (idle/walk animations; look down to see yourself; CCTV sees the full-body copy). `set_controls_enabled()` lets UI screens freeze movement and free the cursor.

**Interaction.** `Interactor` RayCast3D on the camera calls `interact()` and `get_prompt()` on any `Interactable` (component script in `scripts/components/interactable.gd`). Prompt shown in HUD. Adding a new interactable never needs player edits.

**Interactables built:**
- Entrance door (always locked) and 3 guest-room doors (show Available/Occupied; Room 2's handle can animate for the scare).
- Reception computer (zoom into monitor, old-terminal UI): room availability, reservations, guest info, assign a room to a reservation, shows the impossible #0013.
- Telephone: states IDLE, RINGING, IN_CALL. Plays ring, answer plays dialogue, then hang-up. Completes a task when a call ends.
- CCTV monitor: zoom in, cycle fixed cameras through a SubViewport sharing the 3D world; cameras can be gated by story flags and can set a flag when viewed.
- Key rack: one hook per room. Take the key for an assigned room, then hand it to the guest. Only one key held at a time.
- Guest register: lists rooms and tonight's reservations; reading it can complete a task.
- Manager's note: shows the instruction list; first close starts the night.
- Wall clock: reads out shift time.

**Rooms and reservations (RoomManager).** 3 rooms, Available/Occupied, guest name, key-issued state, reservations (Pending/Checked in/Checked out), assign, check-out, key take and hand-over. Start state from `data/rooms/rooms.tres`: Room 1 and 3 free, Room 2 occupied by Mr. Hale, one pending reservation (Ms. Carter, `#0001`).

**Shift clock (ShiftManager).** 10 PM to 6 AM (minutes 1320 to 1800). 60 real seconds per game hour normally (about 8 min total), 3 s per hour after the incident. Supports `hold()` (pause), `block_end()` (cannot finish) and a fast mode. Config in `data/shift/night_shift.tres`.

**Events (EventManager).** Data-driven timed events from `data/events/night_events.tres`: trigger minute, required completed tasks, wait-for-idle, optional phone call. Also holds story flags (`set_flag`/`has_flag`, `flag_set` signal). Current events: `towel_call` at 11:30 PM, `room13` at 12:15 AM. The incident itself is a scripted scene (`scenes/events/room13_incident.tscn`, `scripts/events/room13_incident.gd`) that listens for the event and runs the sequence above with await chains; all delays are exported vars.

**Tasks (TaskManager).** Data-driven list from `data/tasks/night_tasks.tres`. Tasks vs rules: rules (`is_rule`) are shown but never completable. Current list: Keep reception lights on (rule), Answer the telephone, Do not assign occupied rooms (rule), Room 13 is unavailable (rule), Never open the door after midnight unless recognised (rule), Check in the guest at the desk, Check the guest register. "Investigate the hallway" is added at runtime. Hidden until the note is read.

**Dialogue (DialogueManager + DialogueBox).** Line-by-line dialogue from `.tres` resources (`DialogueData`, `DialogueLine`), optional choices, typed text with blip sound. All text lives in `data/dialogue/` (guest check-in x4, Room 13 arrive/prompt/refusal/remind, two phone calls, towels call).

**Lighting and day/night.** `DayNight` applies a `LightingPreset` (`data/lighting/day.tres`, `night.tres`): environment, sky, ambient, tint and vignette for the retro filter, and light groups (`reception_lights`, `hallway_lights`, `exterior_lights`, `desk_lamp`). `FlickerLight` supports stutter, hard off, hum loop and random unprompted flicker.

**Audio (AudioManager).** Named sound bank (`data/audio/sound_bank.tres`): one-shots (positional or not), loops, ambience. Missing files are silent instead of crashing. Present: day and night ambience, phone ring/hang-up, bell, light buzz/off, door open/close/locked/handle, footsteps, key pickup/drop, computer beep, UI click, typing blip, call static.

**Presentation.** Title screen, HUD (prompt, timed messages, clock, task list), note panel, dialogue box, screen fade with caption, end screen, pause menu, PS1 retro filter, in-world screens that raise render resolution so text stays readable.

**Characters.** Ms. Carter (ordinary guest, walks to hallway after check-in) and the Stranger (Room 13 guest, appears and vanishes), both PSX-style models with projected face textures and facing helper (`npc_facing.gd`). The hallway Figure is shown on the phantom camera.

**Environment.** Reception, hallway with 3 doors, exterior visible through windows (parking lot, props such as car and vending machine, PSX sky, night moon). Assembled in `scenes/environment/motel.tscn`, composed by `scenes/main.tscn`.

## 5. Architecture summary

Autoloads (match CLAUDE.md): ShiftManager, TaskManager, RoomManager, EventManager, DialogueManager, AudioManager. Systems talk via signals and call_group (`hud`, `player`, `telephone`, `reception_lights`, `hallway_lights`). Content and tuning live in `.tres` resources and exported vars, with resource classes in `scripts/resources/`. `main.gd` owns scene flow: intro, night start, shift end, restart, quit-to-title, fullscreen.

Layout: `autoload/`, `scenes/{environment,events,npcs,player,props,ui}`, `scripts/` (mirrors scenes plus `components/`, `resources/`), `data/{audio,dialogue,events,lighting,rooms,shift,tasks}`, `assets/{audio,fonts,models,textures}`, `tools/blender/` (character and prop conversion scripts).

## 6. MVP checklist against GDD section 9

Done: reception, hallway, 3 doors, exterior, day and night lighting; first-person movement, mouse look, collision, interaction raycast and prompts; room management, computer, telephone, task system, accelerated clock; the mysterious guest, impossible reservation, CCTV anomaly, supernatural call, final scare; night completion ending, restart, pause, title.

Differences from GDD wording worth knowing:
- Only one ending (complete the shift). There is no failure condition.
- Player cannot accept the Room 13 reservation; refusal is the only path (as GDD allows for MVP).
- Rule tasks (lights, occupied rooms, Room 13, entrance door) are displayed but not enforced by code. Nothing happens if the player breaks them. The entrance door cannot be opened at all.
- Guest-room interiors are not explorable (as GDD allows).
- Final scare ends with the handle turning and a walk back to reception, then fast-forward to 6 AM, not a hard cut.
- Added beyond GDD: towels phone call event, Ms. Carter check-in chain, title screen NPC Viewer, pause menu, fullscreen toggle, visible player body.

## 7. How to run and validate

- Run: open in Godot and press F5 (main scene is `scenes/ui/title_screen.tscn`).
- Parse check: `godot --headless --path . --check-only --quit`
- Smoke test: `godot --headless --path . --quit-after 120`
- Fast testing: shorten `seconds_per_hour` in `data/shift/night_shift.tres`, or the `trigger_minute` of `room13` in `data/events/night_events.tres`.

## 8. Known gaps and risks (verify before relying on them)

- `end_sting` sound has no file in `assets/audio/sfx/` (plays silent).
- CREDITS.md has TODO entries; some third-party prop and character assets need their author and licence confirmed. The PSX Sky Sampler licence forbids redistributing the sky images themselves, so check how the exported build and public repo handle `assets/textures/sky/`.
- `assets/models/PSX_Sky_Sampler_v1.1.zip` and prop `.zip` files sit in the repo; consider removing them from version control.
- Working tree has many uncommitted changes (player model, props, sky, lighting, NPC scripts). The user handles all commits.
- Rule tasks are cosmetic. Whether to make them matter is a design decision for the user.
- No automated tests. Everything is verified by running the game.

## 9. Open design questions to put to the deciding AI

1. Polish only for the jam deadline, or approve a feature (second incident, accept-Room-13 branch, failure state, enforced rules)?
2. If features: which GDD section 12 item has the best payoff for the least risk to a stable build?
3. Should the manager's rules gain consequences (for example, opening the door after midnight), since the GDD's core idea is "instructions are not a complete solution"?
4. Is the 5-10 minute length right, or does the quiet stretch before 12:15 AM need more beats?
5. Release checklist: asset licences, export presets for Windows and Linux, itch.io page, screenshots.
