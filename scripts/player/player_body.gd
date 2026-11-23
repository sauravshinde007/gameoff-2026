class_name PlayerBody
extends Node3D
## The player's visible body. Child of the Player (CharacterBody3D); reads its velocity and plays
## idle / walk animations on two copies of the player model:
## - full_model: whole body on FULL_LAYER. The player's own camera hides it; CCTV feeds and
##   shadows see it.
## - fp_model: headless body on FP_LAYER. Only the player's camera sees it (look down to see
##   yourself); casts no shadow. CCTV feeds mask this layer out.

## Render layer 3: full body (seen by CCTV, hidden from the first-person camera).
const FULL_LAYER_MASK: int = 1 << 2
## Render layer 4: first-person body (seen only by the first-person camera).
const FP_LAYER_MASK: int = 1 << 3

@export var full_model: RetroModel
@export var fp_model: RetroModel
## Below this horizontal speed (m/s) the body plays idle.
@export var walk_speed_threshold: float = 0.3
## Cross-fade time between animations (seconds).
@export var blend_time: float = 0.2
## Walk animation speed at the player's full move speed (1.0 = authored speed).
@export var walk_anim_speed: float = 1.0
## Move speed the walk animations were authored for (m/s); scales walk_anim_speed.
@export var walk_reference_speed: float = 4.5
@export var idle_anim: StringName = &"idle"
@export var walk_forward_anim: StringName = &"walk"
@export var walk_backward_anim: StringName = &"walk_backward"
@export var walk_left_anim: StringName = &"walk_left"
@export var walk_right_anim: StringName = &"walk_right"

var _body: CharacterBody3D
var _current: StringName = &""


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	# Saved hidden so the editor viewport (which shows every render layer) does not draw the
	# player twice. In game only the player's own camera sees the first-person copy (layer 4).
	if fp_model != null:
		fp_model.visible = true
	_play(idle_anim, 0.0)


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	# Velocity in the player's local space: -Z forward, +X right.
	var local: Vector3 = _body.global_transform.basis.inverse() * _body.velocity
	var flat: Vector2 = Vector2(local.x, local.z)
	var speed: float = flat.length()
	if speed < walk_speed_threshold:
		_play(idle_anim, blend_time)
		_set_speed(1.0)
		return
	var anim: StringName
	if absf(flat.y) >= absf(flat.x):
		anim = walk_forward_anim if flat.y < 0.0 else walk_backward_anim
	else:
		anim = walk_right_anim if flat.x > 0.0 else walk_left_anim
	_play(anim, blend_time)
	_set_speed(walk_anim_speed * speed / maxf(walk_reference_speed, 0.01))


func _play(anim: StringName, blend: float) -> void:
	if anim == _current:
		return
	_current = anim
	if full_model != null:
		full_model.play(anim, blend)
	if fp_model != null:
		fp_model.play(anim, blend)


func _set_speed(speed: float) -> void:
	if full_model != null and not is_equal_approx(full_model.anim_speed, speed):
		full_model.set_anim_speed(speed)
	if fp_model != null and not is_equal_approx(fp_model.anim_speed, speed):
		fp_model.set_anim_speed(speed)
