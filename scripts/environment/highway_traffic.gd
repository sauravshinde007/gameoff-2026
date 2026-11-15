class_name HighwayTraffic
extends Node3D
## Background traffic on the highway: random car models drive past on a timer, with headlights
## and tail lights. At night each car also throws a headlight beam (moving light sweeps).
## Pure scenery: collision is switched off, nothing interacts with it.

## Car scenes to pick from (model nose = +Z, origin on the ground).
@export var car_scenes: Array[PackedScene] = []
@export var x_from: float = -70.0
@export var x_to: float = 70.0
## Lane centres (z). East lane drives toward +X, west lane toward -X.
@export var lane_z_east: float = 19.7
@export var lane_z_west: float = 16.3
@export var min_speed: float = 16.0
@export var max_speed: float = 26.0
@export var min_gap_seconds: float = 5.0
@export var max_gap_seconds: float = 18.0
## Headlight beam energy at full night (scaled by the active preset's exterior_light_scale).
@export var beam_energy: float = 3.0

var _head_mat: StandardMaterial3D
var _tail_mat: StandardMaterial3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_head_mat = _make_glow(Color(1.0, 0.95, 0.75))
	_tail_mat = _make_glow(Color(0.9, 0.1, 0.08))
	if car_scenes.is_empty():
		return
	_loop()


func _loop() -> void:
	await get_tree().create_timer(_rng.randf_range(0.5, 4.0)).timeout
	while is_inside_tree():
		_spawn(_rng.randf() < 0.5)
		await get_tree().create_timer(_rng.randf_range(min_gap_seconds, max_gap_seconds)).timeout


func _spawn(eastbound: bool) -> void:
	var car: Node3D = car_scenes[_rng.randi() % car_scenes.size()].instantiate()
	if car is CollisionObject3D:
		(car as CollisionObject3D).collision_layer = 0
		(car as CollisionObject3D).collision_mask = 0
	var holder: Node3D = Node3D.new()
	holder.position = Vector3(x_from if eastbound else x_to, 0.0, lane_z_east if eastbound else lane_z_west)
	holder.rotation.y = PI * 0.5 if eastbound else -PI * 0.5
	add_child(holder)
	holder.add_child(car)
	var box: AABB = _bounds(car)
	var front: float = box.end.z
	var back: float = box.position.z
	var half_w: float = box.size.x * 0.32
	for side: float in [-half_w, half_w]:
		_add_box(holder, Vector3(0.22, 0.14, 0.06), Vector3(side, 0.65, front + 0.02), _head_mat)
		_add_box(holder, Vector3(0.2, 0.12, 0.06), Vector3(side, 0.75, back - 0.02), _tail_mat)
	var night: float = _night_scale()
	if night > 0.0:
		var beam: SpotLight3D = SpotLight3D.new()
		beam.light_color = Color(1.0, 0.93, 0.75)
		beam.light_energy = beam_energy * night
		beam.spot_range = 22.0
		beam.spot_angle = 32.0
		beam.position = Vector3(0.0, 0.8, front + 0.1)
		beam.rotation = Vector3(deg_to_rad(-6.0), PI, 0.0)
		holder.add_child(beam)
	var speed: float = _rng.randf_range(min_speed, max_speed)
	var tween: Tween = holder.create_tween()
	tween.tween_property(holder, "position:x", x_to if eastbound else x_from, absf(x_to - x_from) / speed)
	tween.tween_callback(holder.queue_free)


func _night_scale() -> float:
	var day_night: Node = get_tree().get_first_node_in_group(&"day_night")
	if day_night == null or day_night.get("current") == null:
		return 0.0
	return (day_night.get("current") as LightingPreset).exterior_light_scale


## Model-space bounds of every mesh under node, in node's parent space.
func _bounds(node: Node3D) -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mesh_node
		var local: Transform3D = node.transform * _relative_transform(node, m)
		var b: AABB = local * m.get_aabb()
		result = b if first else result.merge(b)
		first = false
	return result


func _relative_transform(root: Node3D, child: Node3D) -> Transform3D:
	var t: Transform3D = Transform3D.IDENTITY
	var n: Node = child
	while n != null and n != root:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	node.mesh = mesh
	node.position = pos
	parent.add_child(node)


func _make_glow(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	return mat
