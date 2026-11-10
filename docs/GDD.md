# ROOM 13
## Game Design Document (GDD)

**Project:** ROOM 13  
**Game Jam:** Game Off 2026  
**Theme:** SHIFT  
**Engine:** Godot 4.x  
**Language:** GDScript  
**Genre:** Psychological Horror / Workplace Simulation  
**Perspective:** First-Person 3D  
**Platform:** Windows / Linux  
**Players:** Single-player

---

# 1. Game Overview

ROOM 13 is a first-person psychological horror game in which the player works as a receptionist at an isolated motel.

The player works alternating day and night shifts.

During the day, the motel operates normally. Guests check in and out, the telephone rings occasionally, and the receptionist performs ordinary workplace responsibilities.

However, during the night shift, strange and increasingly disturbing events begin occurring.

Guests request rooms that do not exist. Telephone calls come from disconnected rooms. Security cameras display things that should not be there.

The player must continue performing their responsibilities while investigating these incidents and surviving until the end of the shift.

The central gameplay idea is:

**The player has an ordinary job to perform in an increasingly abnormal environment.**

The game should create horror through atmosphere, environmental storytelling, unexpected events, player decisions and psychological tension rather than relying entirely on jumpscares or combat.

---

# 2. Core Vision

The experience should make the player feel:

- Comfortable and familiar with the motel during the day.
- Slightly uneasy when the night shift begins.
- Increasingly suspicious of ordinary objects and interactions.
- Vulnerable when strange events occur.
- Curious about the motel's history and the mystery of Room 13.

The contrast between the ordinary workplace and its supernatural nighttime counterpart is the game's defining feature.

The player should always have a reason to interact with the environment, even when supernatural events are happening.

The horror should emerge naturally from normal gameplay activities.

---

# 3. Setting and Environment

The game takes place inside a small, isolated roadside motel.

The motel is the primary playable location.

It should feel like an ordinary, slightly outdated establishment rather than a large luxury hotel.

## Main Areas

### 3.1 Reception

The primary player location.

Contains:
- Reception desk.
- Desktop computer.
- Telephone.
- Guest register.
- Room key rack.
- Entrance door.
- Windows overlooking the motel exterior.
- Wall clock.
- Manager's instructions.

The reception is where most interactions and important gameplay events occur.

### 3.2 Hallway

A short corridor connecting the reception area to guest rooms.

Contains:
- Three numbered guest room doors.
- Ceiling lights.
- Wall decorations.
- Carpet.
- Environmental props.

The hallway should feel ordinary during the day and increasingly unsettling at night.

### 3.3 Guest Rooms

The initial motel contains three rooms:

- Room 1
- Room 2
- Room 3

For the MVP, these rooms do not need fully explorable interiors.

Their doors should be interactive and communicate whether a room is occupied, available or inaccessible.

### 3.4 Exterior

The motel exterior is initially visible through reception windows.

It should establish the feeling of isolation.

Possible environmental details:
- Rain.
- Empty parking area.
- Roadside signage.
- Dim street lighting.
- Distant silhouettes or lights.

The exterior does not need to be explorable in the MVP.

---

# 4. Day and Night Shift System

The game revolves around two distinct shifts.

## 4.1 Day Shift

The daytime environment should feel relatively safe, cozy and ordinary.

Lighting:
- Warm interior lights.
- Natural daylight.
- Soft shadows.
- Normal environmental ambience.

Gameplay:
- Check guests in.
- Assign available rooms.
- Issue room keys.
- Answer telephone calls.
- Check guests out.
- Learn the motel layout.
- Read instructions from the manager.

The day shift introduces the player to the motel and its mechanics.

It should be relatively short and serve as a tutorial and narrative introduction.

## 4.2 Night Shift

At night, the motel becomes darker, quieter and increasingly unsettling.

Lighting:
- Cold blue or green nighttime ambience.
- Flickering fluorescent lights.
- Limited visibility in hallways.
- Warm reception desk lighting contrasting with darkness.
- Occasional electrical failures.

Gameplay:
- Continue normal receptionist responsibilities.
- Handle unusual guest requests.
- Monitor security cameras.
- Answer suspicious telephone calls.
- Investigate strange occurrences.
- Follow the manager's night-shift instructions.
- Survive until 6 AM.

The same environment should be reused for both shifts.

The nighttime experience should primarily be achieved through lighting, audio, NPC behaviour and scripted events rather than creating a completely separate environment.

---

# 5. Core Gameplay Loop

The fundamental gameplay loop is:

1. Receive shift instructions.
2. Explore the motel and perform receptionist duties.
3. Receive guest requests or unexpected events.
4. Interact with motel objects to investigate.
5. Identify whether something is abnormal.
6. Decide how to respond.
7. Deal with the consequences.
8. Continue working until the shift ends.

The game should balance ordinary workplace activities with supernatural encounters.

The player should not spend the entire game hiding from threats. They should remain actively involved in motel operations.

---

# 6. Core Gameplay Mechanics

## 6.1 First-Person Movement

The player explores the motel using a first-person controller.

Controls:
- WASD: Movement.
- Mouse: Camera movement.
- E: Interact.
- ESC: Pause menu.
- Left click: UI interactions where applicable.

Movement should feel responsive and grounded.

No jumping or advanced movement mechanics are required initially.

## 6.2 Interaction System

The player can interact with objects by looking at them and pressing E.

When looking at an interactable object, an interaction prompt should appear.

Examples:
- Doors.
- Computers.
- Telephones.
- Room key rack.
- Guest register.
- Light switches.
- CCTV monitor.

The interaction system must be modular and reusable.

New interactable objects should be easy to add without rewriting the player controller.

## 6.3 Guest Management

The player performs basic receptionist duties.

Possible interactions:
- Check in guests.
- Assign rooms.
- Issue keys.
- Check out guests.

The motel has three normal rooms in the initial version.

Room availability should be tracked by a simple room management system.

Complex hotel management simulation is not required.

## 6.4 Reception Computer

The computer provides access to basic motel information.

For the MVP, it should support:
- Viewing room availability.
- Viewing reservations.
- Displaying guest information.
- Showing unusual reservation records.

The computer interface should feel like an old motel management system.

## 6.5 Telephone

The telephone is an important gameplay and horror device.

Normal calls may contain guest requests.

Supernatural calls may:
- Originate from empty rooms.
- Contain strange messages.
- Come from unknown extensions.
- Reveal information about upcoming incidents.

The player should interact with the telephone to answer incoming calls.

## 6.6 CCTV

The CCTV system allows the player to observe selected motel areas.

For the MVP, only a small number of fixed cameras are required.

CCTV can be used for:
- Checking hallway activity.
- Investigating suspicious guests.
- Revealing supernatural events.
- Creating tension through visual anomalies.

## 6.7 Task System

The player receives a list of responsibilities for their shift.

Examples:
- Check the guest register.
- Keep reception lights on.
- Answer the telephone.
- Verify room availability.
- Investigate unusual activity.

Tasks should be displayed through a simple UI.

## 6.8 Shift Clock

The game uses an accelerated in-game clock.

The player begins the night shift at 10 PM.

The night shift ends at 6 AM.

Specific supernatural events can be triggered at predefined times or through gameplay conditions.

The clock should be configurable rather than hardcoding event timings into unrelated scripts.

---

# 7. Horror and Atmosphere

ROOM 13 should prioritize psychological horror and environmental storytelling.

The horror should be built through:

- Unexpected environmental changes.
- Strange guest behaviour.
- Unexplained sounds.
- Flickering lights.
- Suspicious telephone calls.
- CCTV anomalies.
- Unusual room records.
- Changes in familiar locations.

Avoid excessive jumpscares.

The player should frequently question whether something is actually wrong.

## Visual Direction

The desired art style is:

**Stylized low-poly 3D with retro-inspired atmospheric horror.**

Visual characteristics:
- Low-poly geometry.
- Slightly exaggerated proportions.
- Simple but attractive materials.
- Retro-inspired textures.
- Atmospheric lighting.
- Subtle fog.
- Limited colour palette.
- Warm daytime environments.
- Cold nighttime environments.

The game should look visually appealing during the day.

Nighttime should transform the same environment into something unsettling.

Do not aim for photorealism.

---

# 8. Story and Narrative Direction

The player is a newly hired motel receptionist.

The motel appears ordinary initially.

The manager provides a set of instructions for the night shift.

Some instructions seem unnecessarily specific.

As the player experiences supernatural events, they begin discovering that the motel has a history involving a mysterious Room 13.

The central mystery is:

**Why does Room 13 appear in the motel's reservation system when the motel only has three rooms?**

The narrative should unfold gradually through:
- Manager instructions.
- Guest conversations.
- Reservation records.
- Telephone calls.
- CCTV footage.
- Environmental clues.
- Unusual events.

Do not reveal the complete mystery immediately.

## Current Narrative Direction

The current preferred direction is:

Room 13 was associated with a guest who mysteriously disappeared in the motel's past.

The motel staff have been instructed never to acknowledge the room or its reservations.

Elements of a larger supernatural mystery may be revealed in later gameplay.

This narrative is intentionally expandable.

---

# 9. MVP Scope

The initial MVP should prove that the core concept works.

The MVP should contain:

## Environment
- One motel reception.
- One short hallway.
- Three guest room doors.
- Basic exterior visible through windows.
- Day and night lighting.

## Player
- First-person movement.
- Mouse look.
- Collision.
- Interaction raycasting.
- Interaction prompts.

## Gameplay
- Basic room management.
- Functional reception computer.
- Telephone interaction.
- Basic task system.
- Accelerated shift clock.

## Horror
- One scripted supernatural incident.
- One mysterious guest.
- One impossible reservation.
- One CCTV anomaly.
- One supernatural telephone call.
- One final scare.

## Ending
- A simple night shift completion or failure condition.
- Basic restart functionality.

The MVP should be approximately 5–10 minutes long.

It must be playable from start to finish.

---

# 10. First Supernatural Incident: THE ROOM 13 RESERVATION

This is the first major horror sequence and the main feature of the initial MVP.

## Background

The player starts their night shift at 10 PM.

The manager leaves a note containing the following instructions:

NIGHT SHIFT INSTRUCTIONS

1. Keep the reception lights on.
2. Answer the telephone.
3. Do not assign occupied rooms.
4. If someone asks for Room 13, tell them it is unavailable.
5. Never open the entrance door after midnight unless you recognize the guest.

The player continues normal responsibilities.

At approximately 12:15 AM, the first supernatural incident begins.

## Event Sequence

### Event 1: Guest Arrival

The entrance bell rings.

A mysterious guest appears at the reception desk.

Guest:

"Good evening. I have a reservation for Room 13."

### Event 2: Impossible Reservation

The player checks the reception computer.

The computer displays:

Reservation ID: #0013  
Guest: Unknown  
Room: 13  
Status: Check-in Pending

However, the motel only has three rooms.

### Event 3: Player Decision

The player can refuse the reservation.

For the initial MVP, only the refusal outcome needs to be implemented.

Player:

"I'm sorry, but we don't have a Room 13."

Guest:

"Are you sure?"

Player:

"Yes. This motel only has three rooms."

Guest:

"That's strange. I stayed here yesterday."

### Event 4: Guest Disappearance

The reception lights flicker.

When the lights stabilize, the guest has disappeared.

The entrance door remains locked.

There is no indication that the guest left.

### Event 5: CCTV Anomaly

The telephone rings.

The player checks the CCTV system.

A mysterious figure is standing at the end of the hallway.

The camera label displays:

ROOM 13 - CAMERA 04

There is no Camera 04.

### Event 6: Telephone Call

The telephone rings again.

The player answers.

Unknown Guest:

"You forgot to give me my key."

Pause.

"I'm already inside."

A door-opening sound plays somewhere in the hallway.

### Event 7: Final Scare

The player hears footsteps.

The player can investigate the hallway.

All three room doors appear closed.

Room 2's handle slowly turns.

The incident ends.

The next objective appears:

"Investigate the hallway. Return to reception before 6:00 AM."

For the MVP, this can conclude with a short fade to black or a simple final scare.

## Important Design Principle

The player followed the manager's instructions correctly.

However, the supernatural incident still occurred.

This establishes that the instructions are not a complete solution to the motel's mysteries.

---

# 11. MVP Development Priorities

Development must happen incrementally.

## Phase 1: Greybox Environment and Player
- Create Godot project.
- Implement first-person movement.
- Implement camera controls.
- Implement interaction system.
- Build basic reception.
- Build hallway with three doors.
- Add basic collision and lighting.

## Phase 2: Motel Functionality
- Implement doors.
- Implement room availability.
- Implement reception computer.
- Implement telephone.
- Implement basic guest interactions.
- Implement task UI.

## Phase 3: Horror Sequence
- Implement shift clock.
- Implement event manager.
- Create mysterious guest.
- Implement Room 13 reservation.
- Implement refusal dialogue.
- Implement guest disappearance.
- Implement CCTV anomaly.
- Implement telephone call.
- Implement final scare.

## Phase 4: Complete MVP
- Add audio and atmosphere.
- Add day/night lighting.
- Add ending.
- Add restart.
- Test the complete gameplay loop.
- Fix bugs and improve presentation.

---

# 12. Features for Future Expansion

These features are NOT part of the initial MVP.

They may be considered after the first playable prototype is complete.

- Multiple night shifts.
- Additional supernatural incidents.
- Multiple endings.
- More motel rooms.
- Explorable room interiors.
- Additional guests.
- More complex guest behaviour.
- Manager backstory.
- Motel history and environmental storytelling.
- More CCTV cameras.
- Additional puzzles.
- Branching dialogue.
- Additional supernatural entities.
- Expanded exterior environment.
- More complex survival mechanics.

Do not implement these features without explicit approval.

---

# 13. Technical Architecture Guidelines

The project should use a modular architecture.

Suggested systems:

- PlayerController: Player movement and camera.
- InteractionManager: Detecting and interacting with objects.
- ShiftManager: In-game clock and shift progression.
- TaskManager: Tracking shift responsibilities.
- RoomManager: Room availability and assignments.
- EventManager: Triggering supernatural incidents.
- DialogueManager: Handling dialogue sequences.
- AudioManager: Managing ambience and sound effects.

Use Godot scenes and signals to keep systems independent.

Prefer reusable components over large scripts containing unrelated responsibilities.

Avoid unnecessary abstraction.

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
- Features that do not directly support the core gameplay loop.

The first priority is a small but polished playable MVP.

---

# 15. Important Instructions for AI Development

Claude Code is responsible for helping implement the game technically.

However, implementation must follow the GDD.

Before adding new mechanics or changing the design:

1. Inspect the existing project.
2. Refer to this GDD.
3. Understand the current development milestone.
4. Explain the proposed implementation.
5. Implement only the requested feature.
6. Validate the changes.

Do not independently expand the scope of the game.

Do not replace the established concept with a different horror game.

Do not implement future expansion features prematurely.

When a design decision is unclear, ask before making substantial architectural or gameplay changes.

**The goal is to build ROOM 13 incrementally, maintaining a working playable project throughout development.**