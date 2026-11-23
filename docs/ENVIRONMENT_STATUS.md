# ROOM 13 — Environment Milestone Status

Status: all seven environment tasks are built and headless-validated. Waiting for the user's in-editor review and approval. No other game systems should be started until that approval.

## What exists

- Single-storey L-shaped motel property, about 35 m x 37 m, built around the original reception (unchanged position and interactions).
- East wing (Rooms 01-03) and north wing (Rooms 04-06) with a covered walkway on the courtyard side.
- All six rooms (01-06) are furnished and enterable (02, 04, 06 added 2026-11-16, same room base with different colours/extras). Rooms 02, 04 and 06 keep closed curtains; 02 and 06 glow at night.
- Reception additions: larger windows, side window, porch, sofa, notice board, coffee station, door to the owner's office.
- Owner's office, laundry, storage, staff corridor and a rear service yard. All furnished with decorative props only.
- Courtyard with parking bays, GGBot parked cars, street lamps, motel sign, vending and ice machines, fences, entrance gate, PSX trees, highway backdrop with random passing cars.
- Day and night use the same geometry. Presets: `data/lighting/day.tres` and `night.tres` (distance fog, sun/moon, ambient, grade, light scales).
- Timed day/night cycle (`scripts/environment/day_night_cycle.gd`, added 2026-11-19): blends night -> sunset (`sunset.tres`, PSX Sky Sampler Sunset_Orange) -> day -> sunset -> night by hour, cross-fades the sky panoramas (`assets/shaders/sky_blend.gdshader`) and moves the sun/moon on an arc. Main game follows the shift clock (6 AM-10 PM); Free Roam runs its own looping clock (N skips 2 hours).
- Free Roam mode (title screen) for reviewing the environment: time of day loops, N skips 2 hours, ESC opens the pause menu.

## Where things live

- Root scene: `scenes/environment/motel_property.tscn` (used by `scenes/main.tscn` and `scenes/free_roam.tscn`).
- Modules: `scenes/environment/modules/` (window unit, door frame, walkway pillar, fence run, highway).
- Rooms: `scenes/environment/guest_rooms/` (shell + furnished base). Service rooms: `scenes/environment/service/`.
- Props: `scenes/props/exterior/`, `scenes/props/vehicles/` (including `ggbot/`), `scenes/environment/trees/`.
- The scenes are the source of truth and can be edited in the editor. They were produced by throw-away generator scripts that are not kept in the repo.
- Old MVP environment scenes (`motel.tscn`, `hallway.tscn`, `exterior.tscn`) are unused fallbacks.

## Known gaps

- Audio: only `day_ambience` and `night_ambience` exist. There are no highway, wind, insect or electrical-hum recordings, so none were added. `end_sting` has no file.
- `CREDITS.md`: the tree pack and car pack licences still need confirming on their itch.io pages.
- Visual review is outstanding: nothing has been inspected in the editor by the assistant.

## Review checklist (Free Roam)

1. Layout and scale: walk reception, both walkways, courtyard, driveway, laundry, storage, office, rear yard.
2. Rooms: enter all six rooms (01-06). Check furniture, bathroom, door swing.
3. Collision: walk the whole fence line, the gate and the corners. Nothing should let you leave or get stuck.
4. Sightlines: from the reception desk, check the front window (courtyard and cars), side window (walkway) and the entrance approach.
5. Doors and interactions: entrance, room, office, laundry, storage and service doors open. Computer, phone, key rack, register, CCTV (3 cameras) still work in the main game.
6. Day: contrast, colour, fog fade, shadows.
7. Night (press N): parking lot readable but spooky, lamp pools, lit windows, headlight sweeps from highway cars, fog fade, nothing frustratingly dark.
8. Main game: start, read note, check in the guest (she opens the door and walks along the walkway), run to 6 AM.
9. Performance: frame rate with sun shadows, trees and lights.
