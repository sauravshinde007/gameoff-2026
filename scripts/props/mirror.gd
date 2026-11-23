class_name Mirror
extends Node3D
## Planar mirror. A second camera renders the scene into a SubViewport from the player's camera
## position reflected through the mirror plane; the mirror surface shows that image flipped.
## The reflection camera uses an off-axis (frustum) projection fitted exactly to the glass, with
## the near plane on the glass, so only what is in front of the mirror is reflected.
##
## Local frame: the glass faces +Z, centred on this node. Rotate the node to aim it.
## The player's full body (render layer 3) is visible in the mirror; the first-person body
## (layer 4) is not.

## Render layer 3: the player's full body (see PlayerBody).
const PLAYER_FULL_LAYER: int = 1 << 2
## Render layer 4: first-person body, never reflected.
const PLAYER_FP_LAYER: int = 1 << 3
## Render layer 5: objects that only mirrors see (the player's camera masks it out).
const MIRROR_ONLY_LAYER: int = 1 << 4
## Render layer 20: mirror glass itself, hidden from reflection cameras (no mirror-in-mirror).
const MIRROR_SURFACE_LAYER: int = 1 << 19
## Render layer 2: CCTV-only objects, not reflected.
const CCTV_ONLY_LAYER: int = 1 << 1

const SHADER: Shader = preload("res://assets/shaders/mirror.gdshader")

## Glass size in metres (width, height).
@export var size: Vector2 = Vector2(0.45, 0.6):
	set(value):
		size = value
		if is_node_ready():
			_build_surface()
## Reflection resolution per metre of glass. Low values keep the chunky PS1 look and are cheap.
@export var pixels_per_meter: float = 360.0
## The reflection is only rendered while the player's camera is closer than this.
@export var max_distance: float = 4.5
@export var tint: Color = Color(0.88, 0.92, 0.9, 1.0)
@export var far_clip: float = 40.0
## Physics layers that hide the mirror from the player (walls, closed doors).
@export_flags_3d_physics var occlusion_mask: int = 1
## Layers the reflection camera renders.
@export_flags_3d_render var reflect_layers: int = 0xFFFFF & ~(PLAYER_FP_LAYER | MIRROR_SURFACE_LAYER | CCTV_ONLY_LAYER)
## Draw a wooden frame around the glass.
@export var frame: bool = true
@export var frame_width: float = 0.04

var _viewport: SubViewport
var _camera: Camera3D
var _surface: MeshInstance3D
var _material: ShaderMaterial
var _notifier: VisibleOnScreenNotifier3D
var _frame: CSGBox3D
var _active: bool = false


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "ReflectionViewport"
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.positional_shadow_atlas_size = 0
	add_child(_viewport)
	_camera = Camera3D.new()
	_camera.name = "ReflectionCamera"
	_camera.projection = Camera3D.PROJECTION_FRUSTUM
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.cull_mask = reflect_layers
	_camera.far = far_clip
	_viewport.add_child(_camera)
	_camera.current = true
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"reflection", _viewport.get_texture())
	_material.set_shader_parameter(&"tint", tint)
	_surface = MeshInstance3D.new()
	_surface.name = "Glass"
	_surface.layers = MIRROR_SURFACE_LAYER
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_surface.material_override = _material
	add_child(_surface)
	_notifier = VisibleOnScreenNotifier3D.new()
	add_child(_notifier)
	_build_surface()
	_material.set_shader_parameter(&"active", 0.0)


func _build_surface() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	_surface.mesh = quad
	_notifier.aabb = AABB(Vector3(-size.x * 0.5, -size.y * 0.5, -0.05), Vector3(size.x, size.y, 0.1))
	_viewport.size = Vector2i(maxi(8, roundi(size.x * pixels_per_meter)),
			maxi(8, roundi(size.y * pixels_per_meter)))
	if _frame != null:
		_frame.queue_free()
		_frame = null
	if frame:
		_frame = CSGBox3D.new()
		_frame.name = "Frame"
		_frame.size = Vector3(size.x + frame_width * 2.0, size.y + frame_width * 2.0, 0.03)
		_frame.position = Vector3(0.0, 0.0, -0.016)
		_frame.material = preload("res://assets/materials/wood.tres")
		add_child(_frame)


func _process(_delta: float) -> void:
	var eye_cam: Camera3D = get_viewport().get_camera_3d()
	if eye_cam == null or eye_cam == _camera:
		_set_active(false)
		return
	var xf: Transform3D = global_transform.orthonormalized()
	var normal: Vector3 = xf.basis.z
	var eye: Vector3 = eye_cam.global_position
	var dist: float = (eye - xf.origin).dot(normal)
	var in_range: bool = dist > 0.02 and eye.distance_to(xf.origin) < max_distance
	_set_active(in_range and _notifier.is_on_screen() and _has_line_of_sight(eye, xf))
	if _active:
		_place_camera(xf, eye, dist)


## False when a wall or closed door sits between the eye and the glass, so mirrors in rooms the
## player is not looking into never render.
func _has_line_of_sight(eye: Vector3, xf: Transform3D) -> bool:
	var target: Vector3 = xf.origin + xf.basis.z * 0.08
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, target, occlusion_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Reflected eye position, looking straight into the glass, frustum fitted to the glass rectangle.
func _place_camera(xf: Transform3D, eye: Vector3, dist: float) -> void:
	var right: Vector3 = xf.basis.x
	var up: Vector3 = xf.basis.y
	var normal: Vector3 = xf.basis.z
	var mirrored_eye: Vector3 = eye - 2.0 * dist * normal
	# Camera looks along +normal (its -Z = normal); its right is the mirror's left.
	var cam_basis: Basis = Basis(-right, up, -normal)
	_camera.global_transform = Transform3D(cam_basis, mirrored_eye)
	var to_centre: Vector3 = xf.origin - mirrored_eye
	_camera.near = maxf(dist, 0.01)
	_camera.size = size.y
	_camera.frustum_offset = Vector2(to_centre.dot(-right), to_centre.dot(up))
	_camera.far = far_clip


## Only render the reflection while someone can see it; otherwise show dull glass.
func _set_active(on: bool) -> void:
	if on == _active:
		return
	_active = on
	_viewport.render_target_update_mode = (SubViewport.UPDATE_ALWAYS if on
			else SubViewport.UPDATE_DISABLED)
	_material.set_shader_parameter(&"active", 1.0 if on else 0.0)
