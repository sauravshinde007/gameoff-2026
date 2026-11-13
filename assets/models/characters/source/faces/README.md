# NPC face photos

Front-facing portraits projected onto the NPC heads by `tools/blender/make_retro_character.py`.
Source art only: the game loads the baked `.glb`, not these files.

## Files
- `guest_front.png` — Ms. Carter (check-in guest)
- `mysterious_front.png` — the Room 13 Stranger
- `player_front.png` — the player (the new night manager)
- `landmarks.json` — pixel positions (origin top-left) of facial points in each photo:

```json
{
  "guest": {
    "eye_left": [x, y],    "eye_right": [x, y],
    "mouth": [x, y],       "chin": [x, y],       "hairline": [x, y]
  }
}
```
`eye_left` / `eye_right` are the eyes on the left / right side **of the image**.
Optional per entry: `"vertical_scale"` (stretch the face up/down, default 1.0),
`"oval_scale"` (size of the blended face area, default 1.05).

## Photo requirements
Square, at least 1024 px. Face centred and straight-on, neutral expression, mouth closed, eyes open,
flat even lighting (no strong shadows or highlights), plain grey background, hair visible,
no glasses, hands or jewellery covering the face.

## Prompts used
- guest: "Passport-style frontal photo of a woman in her early 30s, tired but polite,
  shoulder-length dark brown hair tied back, plain face, no makeup, 1990s, neutral expression,
  mouth closed, looking straight into the camera, flat soft even studio lighting, plain grey
  background, sharp focus, photorealistic"
- mysterious: "Passport-style frontal photo of a gaunt man around 60, pale greyish skin,
  slicked-back thin dark hair, sunken cheeks, faint unsettling calm, neutral expression,
  mouth closed, looking straight into the camera, flat soft even studio lighting, plain grey
  background, sharp focus, photorealistic"
- player: "Passport-style frontal photo of an attractive young woman around 23, fair Caucasian
  skin with a light warm undertone, soft natural features, long straight chestnut-brown hair
  parted in the centre and falling behind her shoulders so the whole face is unobstructed,
  clear hazel-brown eyes, subtle natural makeup, a faint hint of nervous curiosity, neutral
  expression, mouth closed, looking straight into the camera, wearing a burgundy collared shirt,
  flat soft even studio lighting, plain grey background, sharp focus, photorealistic"

## Rebuild
```
blender -b -P tools/blender/make_retro_character.py -- --variant guest --out assets/models/characters/guest.glb
blender -b -P tools/blender/make_retro_character.py -- --variant mysterious --out assets/models/characters/mysterious_guest.glb
blender -b -P tools/blender/make_retro_character.py -- --variant player --out assets/models/characters/player.glb
blender -b -P tools/blender/make_retro_character.py -- --variant player --headless --out assets/models/characters/player_fp.glb
```
The player needs both: `player.glb` is the full body (CCTV, shadows), `player_fp.glb` is the
headless first-person body (`scripts/player/player_body.gd`).

A variant with no `<variant>_front.png` builds with the stock MakeHuman face.
