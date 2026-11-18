@tool
class_name WindowUnit
extends Node3D
## Reusable window: wooden frame, glass and curtains. Origin = centre of the wall opening,
## local +Z = outside. Cut the matching hole in the wall separately (subtract box).

@export var size: Vector2 = Vector2(1.0, 1.2):
	set(value):
		size = value
		_apply()
## Closed curtains hide the interior (used for rooms the player cannot enter).
@export var curtains_closed: bool = false:
	set(value):
		curtains_closed = value
		_apply()
@export var curtain_color: Color = Color(0.62, 0.38, 0.3, 1.0):
	set(value):
		curtain_color = value
		_apply()

## Lit windows glow warmly from outside at night (the room lights are on). Driven by DayNight.
@export var lit: bool = false:
	set(value):
		lit = value
		if is_inside_tree():
			if lit:
				add_to_group(&"lit_windows")
			else:
				remove_from_group(&"lit_windows")

const FRAME: float = 0.08
const OVERLAP: float = 0.01  # frame sticks 1 cm into the opening: no coplanar faces with the wall hole
const CURTAIN_Z: float = -0.17

@onready var frame_top: CSGBox3D = $FrameTop
@onready var frame_sill: CSGBox3D = $FrameSill
@onready var frame_left: CSGBox3D = $FrameLeft
@onready var frame_right: CSGBox3D = $FrameRight
@onready var glass: CSGBox3D = $Glass
@onready var curtain_closed: CSGBox3D = $CurtainClosed
@onready var curtain_left: CSGBox3D = $CurtainLeft
@onready var curtain_right: CSGBox3D = $CurtainRight
@onready var glow: MeshInstance3D = $Glow


var _curtain_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D


func _ready() -> void:
	# Own material copy so each window instance can have its own curtain colour.
	_curtain_mat = (curtain_closed.material as StandardMaterial3D).duplicate()
	for c: CSGBox3D in [curtain_closed, curtain_left, curtain_right]:
		c.material = _curtain_mat
	_glow_mat = (glow.material_override as StandardMaterial3D).duplicate()
	glow.material_override = _glow_mat
	glow.mesh = glow.mesh.duplicate()
	glow.visible = false
	if lit:
		add_to_group(&"lit_windows")
	_apply()


## amount 0 = off (day), 1 = full night glow. Called through the "lit_windows" group.
func set_glow(amount: float) -> void:
	if glow == null or _glow_mat == null:
		return
	glow.visible = lit and amount > 0.01
	var base: Color = curtain_color.lightened(0.55) if curtains_closed else Color(1.0, 0.78, 0.45)
	_glow_mat.albedo_color = base
	_glow_mat.emission = base
	_glow_mat.emission_energy_multiplier = 1.4 * amount


func _apply() -> void:
	if not is_node_ready() or _curtain_mat == null:
		return
	var w: float = size.x
	var h: float = size.y
	frame_top.size = Vector3(w + FRAME * 2.0, FRAME, 0.26)
	frame_top.position = Vector3(0.0, h * 0.5 + FRAME * 0.5 - OVERLAP, 0.0)
	frame_sill.size = Vector3(w + FRAME * 2.0, FRAME, 0.4)
	frame_sill.position = Vector3(0.0, -h * 0.5 - FRAME * 0.5 + OVERLAP, 0.08)
	frame_left.size = Vector3(FRAME, h, 0.26)
	frame_left.position = Vector3(-w * 0.5 - FRAME * 0.5 + OVERLAP, 0.0, 0.0)
	frame_right.size = Vector3(FRAME, h, 0.26)
	frame_right.position = Vector3(w * 0.5 + FRAME * 0.5 - OVERLAP, 0.0, 0.0)
	glass.size = Vector3(w, h, 0.02)
	curtain_closed.size = Vector3(w, h, 0.05)
	curtain_closed.position = Vector3(0.0, 0.0, CURTAIN_Z)
	var side: float = minf(0.28, w * 0.3)
	curtain_left.size = Vector3(side, h, 0.05)
	curtain_left.position = Vector3(-w * 0.5 + side * 0.5, 0.0, CURTAIN_Z)
	curtain_right.size = Vector3(side, h, 0.05)
	curtain_right.position = Vector3(w * 0.5 - side * 0.5, 0.0, CURTAIN_Z)
	curtain_closed.visible = curtains_closed
	curtain_left.visible = not curtains_closed
	curtain_right.visible = not curtains_closed
	_curtain_mat.albedo_color = curtain_color
	(glow.mesh as QuadMesh).size = size
	glow.position = Vector3(0.0, 0.0, -0.04)
