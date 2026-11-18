class_name NpcFacing
extends RefCounted
## Turns an NPC (around Y only) so its front faces a target. NPC models are mounted so the body's
## -Z axis is their front, which is the axis Node3D.look_at() aims at the target.


## Returns the turning tween (null if no turn was needed) so callers can cancel it.
static func face(npc: Node3D, target: Node3D, seconds: float = 0.3) -> Tween:
	if npc == null or target == null or not npc.is_inside_tree():
		return null
	var offset: Vector3 = target.global_position - npc.global_position
	if Vector2(offset.x, offset.z).length() < 0.01:
		return null
	var yaw: float = atan2(-offset.x, -offset.z)
	var tween: Tween = npc.create_tween()
	tween.tween_property(npc, "global_rotation:y", lerp_angle(npc.global_rotation.y, yaw, 1.0), seconds)
	return tween
