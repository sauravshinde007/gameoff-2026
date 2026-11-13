class_name LightingPreset
extends Resource
## One look for the motel (day or night). Light scales multiply each light's authored energy,
## so 1.0 = the value set in the scene.

@export_group("Environment")
@export var background_color: Color = Color(0.05, 0.05, 0.08)
@export var ambient_color: Color = Color(0.3, 0.3, 0.35)
@export var ambient_energy: float = 1.0
@export var fog_color: Color = Color(0.1, 0.1, 0.14)
@export var fog_density: float = 0.03
@export_group("Sky")
## Equirectangular (2:1) sky panorama, seen through the windows (PSX Sky Sampler).
@export var sky_panorama: Texture2D
## Sky brightness multiplier.
@export var sky_energy: float = 1.0
## How much the fog covers the sky (0 = sky fully visible, 1 = only fog colour).
@export_range(0.0, 1.0) var sky_fog_affect: float = 0.3
@export_group("Grade")
## Environment colour adjustment (1.0 = unchanged).
@export var grade_brightness: float = 1.0
@export var grade_contrast: float = 1.0
@export var grade_saturation: float = 1.0
## Multiplies the final picture (RetroFilter): warm for day, cold green-blue for night.
@export var retro_tint: Color = Color.WHITE
## Dark screen corners, 0 = none.
@export_range(0.0, 1.0) var retro_vignette: float = 0.4
@export_group("Lights")
@export var reception_light_color: Color = Color.WHITE
@export var reception_light_scale: float = 1.0
@export var hallway_light_scale: float = 1.0
@export var exterior_light_scale: float = 1.0
## Warm lamp on the reception desk (group desk_lamp).
@export var desk_lamp: bool = false
@export_group("Audio")
## AudioManager ambience name. Empty = silence.
@export var ambience: StringName = &""
