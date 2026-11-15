# ROOM 13
## Game Design Document (GDD)

**Project:** ROOM 13  
**Game Jam:** Game Off 2026  
**Theme:** SHIFT  
**Engine:** Godot 4.x  
**Language:** GDScript  
**Genre:** Psychological Horror / Workplace Simulation (current broad direction; final gameplay and narrative direction are still being developed)  
**Perspective:** First-Person 3D  
**Platform:** Windows / Linux  
**Players:** Single-player

> **Document status:** The MVP described in this document has been completed. The project is now moving into an approved expansion phase. The environment decisions in Sections 3 and 9 are current. The final story, antagonist, management depth, scoring, win/loss conditions and complete gameplay loop are NOT finalized. Do not invent or implement those systems without explicit approval.

---

# 1. Game Overview

ROOM 13 is a first-person game set at an isolated roadside motel. The player works at the motel as a receptionist.

The completed MVP established the basic first-person experience, motel reception, a short guest-room hallway, day-to-night transition, receptionist tasks, a scripted Room 13 incident, an ending, restart and pause functionality.

The project is now being expanded into a fuller Game Off 2026 experience. The motel should become a believable, compact roadside property rather than remaining limited to the MVP reception and three-room hallway.

The current design direction is to establish ordinary motel work and interactions before introducing the game's main unsettling or threatening events. The exact story and nature of the threat remain under discussion. Do not assume that the MVP's supernatural Room 13 incident is the final plot twist or final explanation.

The central experience being explored is:

**The player works at an ordinary roadside motel, manages its day-to-day needs and interacts with different guests, while the familiar workplace gradually becomes unsettling.**

The game should prioritize atmosphere, believable interactions, readable objectives and a cohesive environment over unnecessary scale or complexity.

---

# 2. Core Vision

The intended experience should make the player feel:

- Familiar with the motel and its routines during ordinary work.
- Interested in the guests and their different personalities.
- Responsible for the motel's basic operations.
- Increasingly alert to unusual behaviour or events as the experience progresses.
- Vulnerable when the situation becomes dangerous.

The contrast between ordinary motel work and the later unsettling experience is an important design opportunity.

The motel should feel like a real, slightly outdated roadside business—not a luxury hotel, sprawling resort or open-world location.

The game should create atmosphere through:
- Environmental design and lighting.
- Guest behaviour and authored interactions.
- Sound and ambience.
- Environmental storytelling.
- Player observation and decisions.
- Carefully paced events.

Avoid relying entirely on jumpscares. The final horror approach is still being decided; do not assume supernatural explanations or paranormal mechanics are part of the final direction.

---

# 3. Setting and Environment

## 3.1 Overall Setting

The game takes place at a small, isolated, single-storey roadside motel beside a highway.

The motel is the primary playable location. The player may explore the motel property, including its parking courtyard and limited service exterior. The highway and wider surrounding world are background scenery only.

The agreed environment direction is:

| Property | Current decision |
|---|---|
| Building layout | L-shaped, single-storey motel |
| Geographic setting | Isolated roadside highway |
| Guest rooms | 6 numbered rooms |
| Fully accessible guest-room interiors | 3 |
| Parking | Central courtyard |
| Architectural style | Wooden-panel motel |
| Visual style | Existing PS1/PSX-inspired low-poly style |
| Exterior exploration | Limited to the motel property |
| Day/night | Reuse the same environment with different lighting, ambience and activity |
| Access | Mixed; some areas may be restricted depending on shift and task |

These decisions define the environment scope, not the final story or gameplay systems.

## 3.2 Architectural Layout

The motel uses an L-shaped footprint around a central parking courtyard.

The reception sits at the junction/elbow of the L and acts as the operational centre of the property. Guest wings extend from the reception around the courtyard. Guest-room doors and the exterior walkway should relate clearly to the central parking area.

The layout should provide:
- A readable route from reception to guest rooms.
- A practical connection between reception and staff/service areas.
- A central courtyard that can be seen from selected reception windows.
- Some intentionally blocked sightlines around parked vehicles, building corners and the rear service area.
- A compact footprint that is easy to navigate.

The exact wall positions and dimensions are specified in `ENVIRONMENT.md`. If a measured existing MVP scene conflicts with a proposed coordinate, preserve working existing interactions and adapt the blockout rather than blindly forcing dimensions.

## 3.3 Reception

The reception is the main operational space and should preserve the completed MVP's existing working interactions and visual identity.

Existing visual elements to retain where practical:
- Wooden-panel walls.
- Tiled floor.
- Reception counter.
- CRT monitor / old desktop computer.
- Telephone.
- Guest register.
- Room-key rack.
- Wall clock and manager's notes.
- Existing character placement and interaction points where compatible.

Environment expansion may add:
- Main entrance door.
- Guest seating.
- Notice board.
- Coffee machine or small reception props.
- Larger windows overlooking the courtyard.
- Internal access to the owner's office, if this can be added without disrupting the existing reception.

Do not discard or rebuild the existing reception interactions without inspecting the project and explaining the migration plan.

## 3.4 Guest Accommodation

The expanded motel contains six numbered guest rooms.

- Rooms 01–06 must have visible, readable room identifiers.
- All six doors should exist in the environment.
- Three rooms receive fully explorable interiors in this environment phase.
- The other three rooms may remain closed/inaccessible while still looking like real motel rooms from the exterior.
- Room interiors should use a reusable scene or modular construction approach.
- Variations in furniture placement, curtains, lighting and small props should make rooms feel less identical without requiring six unique builds.

The specific allocation of which three rooms are accessible can be selected during implementation, provided it is documented and consistent.

## 3.5 Central Parking Courtyard

The central courtyard is part of the playable motel property.

It should include:
- Four to six marked parking spaces.
- Two or three reusable vehicle models/instances.
- A clear vehicle circulation and pedestrian path.
- Exterior lights.
- Motel signage visible from the property entrance.
- A vending machine and/or ice machine if practical.
- Windows and room entrances that establish the relationship between the building and courtyard.

Vehicles can be reused with different colours and placements. Do not create a vehicle-driving system.

## 3.6 Laundry Room

A compact operational interior containing:
- Washing machines.
- Laundry baskets.
- Shelves for clean towels.
- Cleaning equipment and a small number of supplies.

This is an environmental space for future motel-work interactions. Do not implement laundry simulation or inventory mechanics as part of the environment-only phase.

## 3.7 Storage Room

A compact service interior containing:
- Shelves and boxes.
- Basic tools.
- Replacement bulbs.
- Cleaning and maintenance props.

Do not implement an inventory system or item economy during environment construction.

## 3.8 Owner's Office

A small enclosed office connected to or immediately adjacent to reception.

Suggested visual contents:
- Desk and chair.
- Computer or CRT monitor.
- Filing cabinet.
- Papers and ledger.
- Calendar.
- Locked drawer or cabinet as a visual prop.

Do not write story clues, secrets or narrative documents into the office yet. The final story is not decided.

## 3.9 Rear Service Area

A small exterior service area behind/alongside the building, containing:
- Generator.
- Garbage bins.
- Service entrance.
- Maintenance access.
- Property boundary fencing.

Keep this area compact. It is not a separate explorable level.

## 3.10 Property Boundary and Background

The player may explore the motel building, central courtyard, and limited rear service area.

The player must not be able to explore:
- The highway itself.
- A nearby town.
- Other businesses or buildings.
- A large forest or surrounding open landscape.

Use roadside barriers, fencing, vegetation, terrain and distant scenery to define the playable boundary naturally. The highway may be visible and audible as background scenery.

## 3.11 Day and Night Environment

Reuse the same geometry and environment for daytime and nighttime.

Daytime direction:
- Warm natural daylight.
- Warm interior lighting.
- Readable exterior and guest areas.
- Ordinary highway traffic and motel ambience.
- A welcoming but slightly dated workplace.

Nighttime direction:
- Darker blue/green ambient environment.
- Warm reception lighting contrasting with the exterior.
- Exterior lamps and selected window lighting.
- More limited visibility around the courtyard and service areas.
- Distant highway headlights and traffic ambience.
- Subtle environmental sounds such as wind, insects, distant vehicles and electrical hum.

Do not build a separate night map. Use lighting, ambience, NPC activity and access states to create the shift change.

## 3.12 Existing Visual Identity

The current MVP screenshots establish the visual baseline:
- PS1/PSX-inspired low-poly 3D.
- Low-resolution / pixelated presentation.
- Dither, vignette and retro colour treatment.
- Pixel-style UI typography.
- Wooden-panel reception walls.
- Tiled floor.
- CRT-era computer props.
- Warm daytime lighting and dark blue nighttime lighting.

Preserve this identity. The environment expansion should look like the same motel and same game, not a new art direction.

Use wooden-panel architecture throughout the motel. Small variations in wood tone, trim, flooring and prop materials are acceptable, but do not switch to a completely different concrete/brick architectural style.

## 3.13 Environment Scope Exclusions

Not part of the current environment scope:
- Multiple floors.
- Swimming pool.
- Restaurant or bar.
- Explorable highway.
- Nearby town or gas station.
- Large forest environment.
- Additional buildings.
- All six guest-room interiors.
- Vehicle driving.
- Large staff facilities.
- Open-world exploration.

---

# 4. Day and Night Shift System

The game uses day and night as important presentation and progression states. The exact final day count, shift schedule and gameplay content are not finalized.

## 4.1 Daytime Direction

The daytime environment should feel relatively safe, warm and ordinary.

Potential future gameplay may include:
- Checking guests in.
- Assigning available rooms.
- Issuing room keys.
- Answering telephone calls.
- Checking guests out.
- Learning the motel layout.
- Reading instructions from the manager.

Day 1 is currently intended to introduce the player to the motel and basic controls/mechanics, but the final day structure is not locked.

## 4.2 Nighttime Direction

Nighttime should make the same motel feel quieter, darker and less predictable.

Potential future gameplay may include:
- Continuing receptionist responsibilities.
- Handling late-night guests.
- Observing suspicious behaviour.
- Using CCTV or telephone systems if retained in the final design.
- Exploring selected areas when required by a task or event.

The exact horror mechanics and survival sequence are not finalized.

---

# 5. Core Gameplay Loop

The final gameplay loop is still under design.

The following broad experience is currently being explored:
1. Begin a work shift and receive instructions.
2. Perform ordinary motel responsibilities.
3. Interact with guests and respond to their needs.
4. Move through the motel property when tasks require it.
5. Notice unusual behaviour or events as the experience progresses.
6. Make decisions and deal with consequences.
7. Complete the shift or reach the relevant ending/failure state.

Do not implement a full management economy, scoring system, criminal AI, survival system or final day structure until those designs are explicitly approved.

---

# 6. Core Gameplay Mechanics

The following systems exist in the MVP or are part of the current project foundation. Their future expansion is not authorized merely by appearing here.

## 6.1 First-Person Movement

The player explores the motel using a first-person controller.

Existing controls:
- WASD: Movement.
- Mouse: Camera movement.
- E: Interact.
- ESC: Pause menu.
- Left click: UI interactions where applicable.

Preserve the existing controller unless a specific issue requires a change.

## 6.2 Interaction System

The player looks at an interactable object and presses E. An interaction prompt is displayed.

Existing examples include doors, computer, telephone, room-key rack, guest register and other reception objects.

New environment props should not automatically become gameplay interactables. Only add interactions when separately requested.

## 6.3 Guest and Room Management

The MVP contains a basic room/reception foundation. The expanded environment has six room doors, but this does not mean the full room-management simulation is implemented or approved.

The environment phase must create the physical spaces and consistent room identifiers only. Do not silently rewrite RoomManager or reservation logic.

## 6.4 Reception Computer, Telephone, CCTV and Tasks

These are part of the MVP foundation. Preserve working behaviour during environment changes. Any expansion of their features belongs to a later, separately approved phase.

## 6.5 Shift Clock

The MVP includes a shift clock. Do not change its timing or progression as part of environment construction unless required to keep the existing scene functional.

---

# 7. Horror and Atmosphere

The final horror direction is still being discussed.

The current creative preference is to explore a grounded, realistic human-threat experience rather than relying on ghosts or supernatural explanations. However, no final antagonist, criminal motivation, story twist or horror sequence has been approved.

Do not assume that the MVP's supernatural events define the final story.

The MVP's Room 13 incident was a prototype sequence used to test the initial gameplay and atmosphere. It has been retired and removed from the project (2026-11-14). New encounters and the story structure will be designed fresh.

For environment work, focus on atmosphere and useful spatial design:
- Reception windows and courtyard sightlines.
- Building corners and partially obscured areas.
- Exterior lighting and shadows.
- A readable route between work areas.
- Believable ambient sound placement.
- Natural property boundaries.

Do not add scripted scares, criminals, stalkers, ghosts or narrative clues during the environment phase.

---

# 8. Story and Narrative Direction

The protagonist is a newly hired motel receptionist. The player works at an isolated roadside motel.

The exact story, supporting cast, criminal/threat identity, motivation, and relationship between characters are not finalized.

The following are brainstorming directions only, not approved story canon:
- A guest using a false identity.
- A previous receptionist who stopped coming to work.
- Guests connected to the same criminal incident.
- The motel owner hiding something about the business.

The name ROOM 13 remains the project title. The MVP Room 13 reservation incident is not automatically the final story or final twist.

Do not create permanent narrative documents, character biographies, story-critical props or scripted story events without explicit approval.

---

# 9. Current Project Status and Expansion Scope

## 9.1 Completed MVP

The MVP is complete. It established:
- Title screen.
- Day introduction.
- First-person movement and interaction.
- Existing reception and short hallway.
- Three guest-room doors.
- Basic receptionist tasks.
- Existing computer, telephone and other MVP interactions.
- Day-to-night transition.
- Room 13 prototype incident (since removed, see section 10).
- Ending and restart.
- Pause menu.

The MVP should remain a working fallback during expansion.

## 9.2 Approved Environment Expansion

The next implementation milestone is the environment expansion described in `ENVIRONMENT.md`.

It includes:
- L-shaped, single-storey wooden-panel roadside motel.
- Six numbered guest rooms.
- Three fully accessible guest-room interiors.
- Central parking courtyard.
- Expanded reception while preserving existing interactions.
- Laundry room.
- Storage room.
- Owner's office.
- Small rear service area.
- Limited explorable motel exterior and non-explorable highway backdrop.
- Reused day/night environment with lighting and ambience variations.

`ENVIRONMENT.md` is the detailed implementation specification for this milestone. If a detail in this GDD conflicts with `ENVIRONMENT.md` about environment construction, use `ENVIRONMENT.md` for the environment phase, while preserving the higher-level scope and constraints in this GDD.

## 9.3 Not Yet Approved

Do not implement these until separately designed and approved:
- Final story and antagonist.
- Final number of days/shifts.
- Full motel economy and money system.
- Advanced room management.
- Guest personality/dialogue system.
- Criminal AI and survival sequence.
- Scoring and evaluation.
- Win/loss conditions and endings.
- New story encounters (to be designed fresh after the environment phase).
- Additional large locations.

---

# 10. MVP Prototype Incident: THE ROOM 13 RESERVATION (RETIRED)

**Status: removed from the project on 2026-11-14.** The incident scene, script and incident-only data were deleted. It is not canon. Do not preserve, restore or design around it. New encounters and story structure will be created fresh in a later phase. This section is kept only as a historical record of what the MVP tested.

The MVP night shift starts at 10 PM. The manager's note contains:
1. Keep the reception lights on.
2. Answer the telephone.
3. Do not assign occupied rooms.
4. If someone asks for Room 13, tell them it is unavailable.
5. Never open the entrance door after midnight unless you recognize the guest.

At approximately 12:15 AM, the prototype sequence begins.

The sequence includes:
- A guest requesting Room 13.
- An impossible reservation record.
- The player refusing the reservation.
- The guest disappearing.
- A CCTV anomaly labelled Room 13 / Camera 04.
- A telephone call claiming the guest is already inside.
- A hallway scare involving a room-door handle.

This sequence has been removed. The current build has no scripted incident: the night shift runs from 10 PM to 6 AM with ordinary receptionist tasks only.

---

# 11. Development Priorities

The MVP phases below are historical and complete.

The next milestone is the environment expansion phase:
1. Inspect and back up the current project.
2. Inspect the existing reception scene and preserve working interactions.
3. Greybox the complete L-shaped motel and property boundary.
4. Validate navigation, proportions and reception sightlines.
5. Build the six-room exterior arrangement and three accessible interiors.
6. Build laundry, storage, owner's office and rear service area.
7. Add central parking, vehicles, signage and exterior props.
8. Add day/night lighting and environmental ambience.
9. Test the full environment in-editor and validate the project.

Do not begin later gameplay expansion until the environment milestone is reviewed and approved.

---

# 12. Features for Future Expansion

These features are possible future work, not current implementation instructions:
- Multiple day/night shifts.
- More guest characters and personalities.
- More complex guest behaviour.
- Motel money and operating expenses.
- Customer satisfaction and reputation.
- Room cleanliness and maintenance.
- Additional motel tasks.
- More CCTV coverage.
- Branching dialogue.
- Main story and antagonist.
- Grounded threat/survival mechanics.
- Multiple endings.
- Additional narrative locations or clues.

Do not implement these without explicit approval.

---

# 13. Technical Architecture Guidelines

The project should use a modular architecture.

Existing or suggested systems include:
- PlayerController: Player movement and camera.
- InteractionManager: Detecting and interacting with objects.
- ShiftManager: In-game clock and shift progression.
- TaskManager: Tracking shift responsibilities.
- RoomManager: Room availability and assignments.
- EventManager: Existing scripted events.
- DialogueManager: Dialogue sequences.
- AudioManager: Ambience and sound effects.

Use Godot scenes and signals to keep systems independent.

For environment construction:
- Prefer modular/reusable scenes for repeated room doors, guest rooms, wall sections, windows, lights and props.
- Keep environment geometry separate from gameplay systems where practical.
- Avoid changing autoloads or global gameplay systems merely to build the new level.
- Do not introduce unnecessary abstractions.
- Preserve existing node paths and references when possible.

---

# 14. Development Constraints

This is a game jam project with a limited development timeline.

Prioritize:
1. A complete playable experience.
2. Interesting core gameplay.
3. Strong atmosphere.
4. Clear interactions.
5. Stable performance.
6. Visual polish.

Avoid:
- Open-world environments.
- Complex combat.
- Multiplayer.
- Procedural generation.
- Large numbers of NPCs.
- Unnecessary survival mechanics.
- Features that do not directly support the approved game direction.
- Unapproved story or gameplay additions.

The environment should feel substantially larger than the MVP but remain a compact, self-contained motel property.

---

# 15. Important Instructions for AI Development

Claude Code is responsible for helping implement the game technically.

Implementation must follow this GDD and the detailed milestone documents.

Before coding:
1. Inspect the existing project and relevant scenes/scripts.
2. Read this GDD and the active milestone document.
3. Understand what is already implemented.
4. Explain the proposed implementation plan.
5. Implement only the requested milestone.
6. Validate the changes in Godot.

Do not independently expand the scope of the game.

Do not replace the established visual identity.

Do not implement future gameplay features prematurely.

When a design decision is unclear, ask before making substantial architectural, environmental or gameplay changes.

**The goal is to expand ROOM 13 incrementally, preserving a working playable project throughout development.**
