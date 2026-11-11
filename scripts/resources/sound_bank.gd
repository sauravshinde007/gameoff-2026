class_name SoundBank
extends Resource
## Sound name -> file path. A path without extension is tried as .ogg, .wav, .mp3.
## Missing files are skipped silently, so audio can be dropped in at any time.

@export var sfx: Dictionary[StringName, String] = {}
@export var loops: Dictionary[StringName, String] = {}
## Optional per-name volume in dB (default 0).
@export var volume_db: Dictionary[StringName, float] = {}
