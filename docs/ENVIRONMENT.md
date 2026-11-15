# ROOM 13 — Environment Design & Implementation Specification

**Document:** Environment milestone specification  
**Project:** ROOM 13  
**Engine:** Godot 4.x  
**Implementation language:** GDScript  
**Status:** Approved environment scope; ready for project inspection and greybox implementation  
**Target:** Game Off 2026  
**Important:** This document specifies the motel environment only. It does not finalize the story, antagonist, gameplay loop, economy, scoring, survival mechanics or endings.

---

# 1. Purpose

Expand the completed MVP environment into a believable, compact, explorable roadside motel.

The MVP currently contains a reception area, a short hallway with three guest-room doors, a limited exterior view, a first-person controller and working MVP interactions. The existing scene is the foundation and must be inspected and preserved where practical.

The expanded environment must feel like a real motel property with a central parking courtyard and useful work areas. It must remain small enough to build and polish within the Game Off schedule.

**Primary implementation rule:** Preserve the existing reception and its working interactions. Expand around it. Do not blindly replace the current scene.

# 2. Locked Design Decisions

| Property | Specification |
|---|---|
| Building | Single-storey L-shaped motel |
| Setting | Isolated roadside highway |
| Architecture | Wooden-panel style throughout |
| Visual style | Existing PS1/PSX low-poly retro style |
| Guest rooms | 6 numbered rooms |
| Accessible guest-room interiors | 3 |
| Parking | Central courtyard |
| Reception | Existing reception expanded, not discarded |
| Additional interiors | Laundry, storage, owner's office |
| Additional exterior | Small rear service area |
| Player boundary | Motel property only |
| Highway | Background scenery only; not explorable |
| Day/night | Same geometry, different lighting/ambience/activity |
| Access | Mixed; some rooms/areas may be restricted depending on shift/task |

Do not change these decisions without asking the user.

# 3. Art Direction and Existing MVP Continuity

Use the user's current MVP screenshots as the visual reference.

Preserve:
- PS1/PSX-inspired low-poly geometry.
- Low-resolution/pixelated retro presentation.
- Existing dither, vignette and colour treatment.
- Pixel-style UI typography.
- Wooden-panel walls.
- Existing tiled floor treatment in reception.
- CRT monitor and old desktop computer props.
- Existing warm daytime and dark blue nighttime lighting language.

Do not redesign the game into a photorealistic motel or introduce a radically different architecture.

Wooden-panel architecture should be used across the motel. Small variations in wood colour, trim, floor material and prop materials are welcome, but the building should read as one coherent property.

Reuse existing materials, meshes, props and scripts where practical. Do not add expensive external art dependencies during the greybox stage.

# 4. Site Plan and Coordinate Convention

## 4.1 Coordinate Convention

Use Godot's 3D axes:
- X: east/west.
- Y: vertical.
- Z: north/south.
- North is negative Z.
- South is positive Z.
- West is negative X.
- East is positive X.

One Godot world unit is treated as approximately one metre for blockout planning.

The coordinates below are a **proposed starting grid**, not measurements of the current MVP. Before construction, inspect the existing reception scene and its dimensions. Preserve its functional geometry and adapt the new footprint to it if necessary.

## 4.2 Approximate Property Bounds

Initial blockout bounds:
- X: -20 to +20.
- Z: -17 to +17.

This gives a property footprint of approximately 40m × 34m.

The property boundary is a gameplay/level-design boundary, not necessarily a continuous tall wall. Use fencing, roadside barriers, terrain, trees and visual blockers to prevent leaving the motel property.

## 4.3 L-Shaped Building Arrangement

The building should form an L around the central courtyard.

The intended spatial relationships are more important than the exact first-pass coordinates:

1. Guest Wing A forms the northern/rear arm of the L.
2. Guest Wing B forms the eastern arm of the L.
3. Reception occupies the southern elbow/junction of the L, with a clear view toward the courtyard.
4. The courtyard occupies the open inside of the L.
5. Laundry and storage are near the rear/service side and connected by a practical staff route.
6. The owner's office is a small enclosed room connected to reception.
7. The rear service area sits behind/alongside the building and remains compact.

### Suggested blockout zones

| Zone | Approximate planning bounds | Notes |
|---|---|---|
| Property | X -20..+20, Z -17..+17 | Entire playable property |
| Guest Wing A | North/rear arm, approx. 26m × 8m | Rooms 01–03 |
| Guest Wing B | East arm, approx. 8m × 20m | Rooms 04–06 |
| Reception elbow | At the junction of the two wings | Preserve existing reception layout |
| Owner's office | Approx. 3.5m × 3m within/adjacent to reception | Enclosed, compact |
| Laundry | Approx. 4m × 4m | Staff/service access |
| Storage | Approx. 3m × 4m | Adjacent to laundry |
| Rear service area | Approx. 10m × 5m | Generator, bins, service access |
| Central courtyard | Remaining open inner area | Parking and pedestrian circulation |

The exact partitions must be resolved in the greybox after inspecting the current reception. Do not use overlapping bounding boxes as literal final wall geometry.

# 5. Area-by-Area Specification

## 5.1 Reception — Existing Area to Preserve and Expand

This is the primary workplace and the most important existing interior.

Retain existing functional objects and interactions wherever possible:
- Reception desk.
- Existing desktop/CRT computer.
- Telephone.
- Guest register.
- Room-key rack.
- Manager's note/instructions.
- Existing clock/UI interactions.
- Existing player entry and navigation.

Add only environment elements that fit without breaking the existing layout:
- Main entrance door.
- Guest seating area.
- Notice board.
- Small coffee machine or decorative reception props.
- Larger or better-framed windows overlooking the parking courtyard.
- Internal door to owner's office, if practical.

Requirements:
- The player must be able to move around the reception without collision problems.
- The front desk remains a clear focal point.
- The player should be able to see a useful portion of the parking courtyard through the windows.
- Preserve the current visual identity and interaction positions where possible.
- Do not rewrite existing gameplay UI or computer/telephone systems during this milestone.

## 5.2 Guest Accommodation — Six Rooms

Create six numbered guest-room doors: **Room 01, Room 02, Room 03, Room 04, Room 05 and Room 06**.

Three room interiors must be fully explorable in this milestone. The other three must have visible, convincing doors and room numbers but may remain inaccessible.

Suggested room size: approximately 4.5m × 6m per room, adjusted to fit the building.

Each accessible room should include a reusable base layout:
- Bed.
- Bedside table.
- Lamp.
- Small desk or table.
- Chair.
- Television or simple wall-mounted prop.
- Curtains and window.
- Basic wall/floor details.
- Door and collision.

Use one reusable guest-room scene or modular kit. Create small variations through prop placement, colour/material variation and furnishing differences rather than building three unrelated rooms.

The room doors should:
- Be consistently sized and positioned.
- Have readable room numbers.
- Have collision.
- Open/close only if the existing door system supports it or a simple reusable door is explicitly needed for the environment.
- Not require new booking or occupancy logic in this phase.

Do not build all six room interiors. Do not make inaccessible rooms look like obvious unfinished greybox holes.

## 5.3 Central Parking Courtyard

The courtyard is the open centre of the L-shaped motel and must be fully explorable.

Include:
- Four to six marked parking bays.
- Two or three vehicle models/instances.
- Clear pedestrian walking paths.
- Driveable-looking vehicle access geometry, but no vehicle-driving mechanics.
- Exterior lamps.
- Motel sign visible from the property entrance.
- Vending machine and/or ice machine if time permits.
- Windows and guest-room doors facing or relating to the courtyard.

Vehicle models can be reused with different colours/placements. Parked vehicles should not block all navigation paths or completely obscure the reception view.

The courtyard should feel open enough to navigate but not like a huge empty plaza.

## 5.4 Laundry Room

Suggested dimensions: approximately 4m × 4m.

Visual contents:
- Two washing machines.
- Laundry baskets.
- Shelving.
- Folded towels.
- Cleaning equipment.
- Basic utility details.

The room should have a clear doorway and collision. It should connect naturally to a staff/service path.

No laundry simulation, timers, inventory, resource economy or cleaning task logic is required in this phase.

## 5.5 Storage Room

Suggested dimensions: approximately 3m × 4m.

Visual contents:
- Shelves.
- Boxes.
- Basic tools.
- Spare bulbs.
- Cleaning supplies.
- Maintenance props.

Keep it compact and believable. It may share a wall or service connection with the laundry room.

No inventory or item-management mechanics are required.

## 5.6 Owner's Office

Suggested dimensions: approximately 3.5m × 3m.

Visual contents:
- Desk and chair.
- Computer or CRT monitor.
- Filing cabinet.
- Papers/ledger.
- Calendar.
- Locked drawer/cabinet as a prop.

The office should be an enclosed room connected to or immediately adjacent to reception.

Do not add story-critical clues, secret documents, character backstory or plot reveals. The narrative is not finalized.

## 5.7 Rear Service Area

Suggested dimensions: approximately 10m × 5m, adjusted to fit.

Visual contents:
- Generator.
- Garbage bins.
- Service entrance.
- Maintenance access.
- Fence or boundary.
- A few practical outdoor props.

Keep this area small. It is not a separate level or large exploration zone.

# 6. Exterior Boundary and Background

The player can explore:
- The motel building.
- Central parking courtyard.
- The limited rear service area.
- The immediate motel entrance/driveway.

The player cannot explore:
- Highway lanes.
- Nearby town.
- Other buildings/businesses.
- A large forest.
- An open landscape beyond the motel.

Use natural boundary design:
- Fence sections.
- Roadside barriers.
- Low-poly trees and bushes.
- Terrain elevation or a shallow ditch.
- Distant tree silhouettes.
- Background highway plane/road section.
- Distant moving headlights if feasible.

The highway is a backdrop and audio source only. Do not implement traffic simulation or vehicle navigation.

# 7. Day/Night Presentation

Use the same environment geometry for both times of day.

## Daytime

- Warm natural daylight.
- Warm interior lights.
- Clear visibility of the courtyard and guest wings.
- Ordinary motel atmosphere.
- Distant highway traffic.
- Soft shadows.

## Nighttime

- Dark blue/green ambient environment.
- Warm reception lights as a visual anchor.
- Exterior lamps around the courtyard.
- Selected window and room lights.
- Distant vehicle headlights or subtle moving light sweeps if feasible.
- Wind, insects, distant highway traffic and electrical ambience.
- More limited visibility around the rear service area and building corners.

Do not make the entire scene so dark that navigation becomes frustrating. Maintain readable silhouettes and player navigation.

Do not create a separate nighttime level.

# 8. Player Navigation and Sightlines

The player must be able to navigate between the following areas without awkward dead ends:

### Route A — Reception to guest rooms
Reception → courtyard/walkway → guest-room doors.

### Route B — Reception to service areas
Reception → staff/service route → laundry → storage.

### Route C — Reception to parking
Reception/main entrance → courtyard → parking bays and vending/ice machine.

### Route D — Reception to owner's office
A short internal route from reception into the enclosed office.

Avoid forcing every trip through a narrow bottleneck. Ensure doors, corridors and walkways are wide enough for the existing player controller.

## Reception sightlines

Design three useful sightlines:
1. Front window: a meaningful portion of the parking courtyard and parked vehicles.
2. Side window: main entrance and guest walkway.
3. Reception entrance: the approach into the reception interior.

Do not expose every part of the property:
- Rear service area can be partially hidden.
- Some room doors can be obscured by building corners.
- Parked vehicles can create partial visual cover.
- Storage should not be visible from the main desk.

These are environmental layout choices only. Do not add scripted threats or scares.

# 9. Proposed Dimensions and Construction Guidance

These are starting dimensions. Adjust after inspecting the current MVP scale.

| Element | Starting dimension |
|---|---:|
| Property | 40m × 34m |
| Reception | 9m × 8m |
| Owner's office | 3.5m × 3m |
| Guest room | 4.5m × 6m |
| Guest wing depth | Approx. 8m |
| Laundry | 4m × 4m |
| Storage | 3m × 4m |
| Rear service area | 10m × 5m |
| Courtyard | Approx. 20m × 17m usable area |
| Parking bay | 2.8m × 5.5m |
| Exterior walkway | 1.8m–2m |
| Exterior wall height | Approx. 3.2m |
| Interior ceiling height | Approx. 2.8m |
| Door height | Approx. 2.1m |

Use consistent scale with the existing player controller and current reception. Do not resize the player or existing reception solely to match these approximate numbers.

# 10. Technical Scene Organization

Inspect the existing project before deciding exact file names or moving assets.

Prefer reusable environment scenes for:
- Main motel environment/root.
- Guest-room module.
- Reusable room door.
- Wall segment.
- Window segment.
- Exterior light.
- Vehicle.
- Vending/ice machine.
- Laundry room.
- Storage room.
- Owner's office.
- Rear service props.

A possible structure, to adapt to the existing project:

```text
scenes/
  environment/
    motel_environment.tscn
    motel_exterior.tscn
    reception/
    guest_rooms/
      guest_room_base.tscn
      room_01.tscn
      room_02.tscn
      room_03.tscn
    service/
      laundry_room.tscn
      storage_room.tscn
      owners_office.tscn
      rear_service_area.tscn
  props/
    doors/
    vehicles/
    furniture/
    exterior/
```

Do not reorganize the project just to match this example. Preserve existing paths and references where possible.

Use modular scenes and instancing for repeated assets. Avoid copy-pasting large amounts of identical geometry.

# 11. Environment Implementation Plan

Deliver the environment as one coherent milestone, implemented in safe substeps.

## E0 — Inspect and protect the MVP
- Inspect the current project tree.
- Identify the current main scene and reception scene.
- Inspect player scale, collision, camera height and interaction ray.
- Identify existing materials, meshes, door scenes and scripts.
- Identify all node paths and signals used by reception interactions.
- Create a safe backup/branch or preserve the existing scene as a fallback.
- Report the proposed integration approach before substantial edits.

## E1 — Greybox the full property
- Build the L-shaped building footprint.
- Place reception at the L junction, preserving its working layout.
- Block out six guest rooms.
- Block out laundry, storage and owner's office.
- Block out central courtyard and rear service area.
- Establish property boundaries.
- Add basic collision.
- Confirm player navigation and scale.

Stop for user review after E1. Do not add detailed props until the user approves the layout.

## E2 — Building and room modules
- Expand the reception without breaking interactions.
- Build six consistent room doors and identifiers.
- Build three reusable/accessible guest-room interiors.
- Build laundry, storage and owner's office interiors.
- Add staff/service connections.

## E3 — Courtyard and exterior
- Add parking bays and pedestrian paths.
- Add two or three vehicle instances.
- Add motel sign and entrance.
- Add exterior lamps.
- Add vending/ice machine if practical.
- Add rear service props and boundary fencing.
- Add distant highway/background scenery.

## E4 — Lighting and environment polish
- Implement daytime lighting.
- Implement nighttime lighting using the same geometry.
- Add basic environmental audio/ambience if existing audio structure makes this straightforward.
- Ensure night visibility remains navigable.
- Polish materials and prop placement.

## E5 — Validation and handoff
- Run the project in-editor.
- Verify player can reach every intended accessible area.
- Verify inaccessible rooms are visually complete from outside.
- Verify no gaps in collision or accidental exits from property.
- Verify existing reception interactions still work.
- Verify day/night presentation.
- Run headless validation and report results.
- Provide the user with a precise visual review checklist.

# 12. Explicitly Out of Scope

Do not implement during this environment milestone:
- Money/economy.
- Guest satisfaction or reputation.
- Advanced reservations or room occupancy.
- Cleaning or laundry simulation.
- Inventory.
- Maintenance task logic.
- Guest personality/dialogue systems.
- New NPCs or character AI.
- Final story or narrative clues.
- Criminal/stalker AI.
- Combat or survival mechanics.
- Scoring, grades or daily performance reports.
- Win/loss conditions or endings.
- New story encounters or scripted events. (The MVP Room 13 incident has been removed; do not preserve or rebuild it. Encounters will be designed fresh later.)
- Highway exploration, town or additional buildings.
- Vehicle driving or traffic simulation.

The environment can include props that may support future mechanics, but props must remain decorative unless a later task explicitly adds functionality.

# 13. Definition of Done

The environment milestone is complete when:

- The player can explore a coherent L-shaped motel property.
- Reception remains functional and visually consistent with the MVP.
- Six numbered guest-room doors are present.
- Three guest-room interiors are fully accessible and furnished.
- The remaining three rooms look complete from the exterior and are intentionally inaccessible.
- Central parking courtyard is navigable and furnished.
- Laundry, storage and owner's office exist as coherent interiors.
- Rear service area exists and is bounded.
- Highway and surrounding environment are background only.
- Day and night use the same geometry and have distinct, readable atmospheres.
- Player collision and navigation work throughout the playable property.
- Existing MVP interactions still function.
- The project passes the available Godot validation checks.
- The user has inspected and approved the environment in-editor.

After the environment is complete, stop. Do not proceed to other game systems until the user reviews and approves this milestone.
