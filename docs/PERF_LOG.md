# Performance Log

Measure with the in-game overlay: **F3** toggles it, **F4** appends a snapshot line to `user://perf_log.txt`
(Linux: `~/.local/share/godot/app_userdata/<project name>/perf_log.txt`) and prints `[perf]` in the console.

Run in **Free Roam**, standing still ~3 s at each spot before reading. Press **N** to switch day/night.

Spots: **A** behind reception desk, **B** courtyard facing room row, **C** inside Room 03 facing bathroom mirror,
**D** storage room, **E** by the highway.

Cell format: `FPS / draw calls`.

| Step | A day | A night | B day | B night | C day | C night | D day | D night | E day | E night | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Baseline (T0) | | | | | | | | | | | |
| T1 render scale | | | | | | | | | | | |
| T2 SSAO | | | | | | | | | | | |
| T3 shadows | | | | | | | | | | | |
| T4 mirrors | | | | | | | | | | | |
| T5 day/night | | | | | | | | | | | |
| T6 room culling | | | | | | | | | | | |
| T7 CSG bake | | | | | | | | | | | |
| T8 traffic pool | | | | | | | | | | | |
| T9 anim/materials | | | | | | | | | | | |
| T10 cleanups | | | | | | | | | | | |
| T11 assets | | | | | | | | | | | |
