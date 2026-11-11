class_name CctvCamera
extends Camera3D
## A fixed security camera. The CCTV screen finds these by group and renders the chosen one.
## Never current: it only marks a viewpoint (the editor preview shows what it sees).

@export var label: String = "CAM 01"
## Lower numbers come first when cycling.
@export var sort_order: int = 0
## World-space point the camera looks at (set in the Inspector).
@export var look_target: Vector3 = Vector3.ZERO
## If set, the camera only appears on the monitor once this story flag is set.
@export var hidden_until_flag: StringName = &""
## Story flag set when the player sees this camera's feed (e.g. viewed_cam_04).
@export var viewed_flag: StringName = &""


func _ready() -> void:
	add_to_group(&"cctv_camera")
	if not global_position.is_equal_approx(look_target):
		look_at(look_target)


func is_available() -> bool:
	return hidden_until_flag == &"" or EventManager.has_flag(hidden_until_flag)
