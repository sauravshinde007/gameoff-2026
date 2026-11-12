"""Build a ROOM 13 NPC on the "PS1/PSX Retro Base v2" body (male/female, CC BY - see CREDITS.md).

The base comes untextured and unanimated, with a UE4-style skeleton in an A-pose. This script:
1. Retargets all 30 PSX Animation Library animations (15-bone mannequin, T-pose) onto it:
   per frame, each mapped bone gets the source bone's world-space rotation change since rest,
   applied on top of the target bone aligned to the source rest direction (A-pose -> T-pose).
2. Paints clothes and skin onto the model's own UVs by rest position and bone weights
   (make_psx_character's bakes, with the sleeves found by distance along the arm).
3. Keeps the model's own low-poly PS1 head and bakes onto it the MPFB skin/hair colour and,
   when present, the front face photo (faces/<variant>_front.png).

Usage:
  blender -b -P tools/blender/make_retro_character.py -- --variant guest \
      --out assets/models/characters/guest.glb [--face none] [--tex 1024]
"""

import argparse
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_character as mc  # noqa: E402
import make_psx_character as psx  # noqa: E402

BASES = os.path.join(psx.ROOT, "assets", "models", "characters", "source", "retro_base")

# Per NPC: which body, which PSX mannequin the animations come from, clothes (see psx.PSX).
RETRO = {
    "guest": dict(psx.PSX["guest"], body="female", anim_from="woman", sleeve_t=0.97),
    "mysterious": dict(psx.PSX["mysterious"], body="male", anim_from="man", sleeve_t=0.97),
}

# Source (PSX mannequin) bone -> target (retro base) bone. Sides are checked by position.
BONE_MAP = {
    "Hips": "pelvis", "Spine": "spine_01", "Head": "head",
    "LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l",
    "RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r",
    "LeftArm": "arm_l", "LeftForeArm": "forearm_l", "LeftHand": "hand_l",
    "RightArm": "arm_r", "RightForeArm": "forearm_r", "RightHand": "hand_r",
}
# Limbs are re-aimed from the A-pose to the source T-pose; these keep their rest orientation.
NO_ALIGN = {"pelvis", "spine_01", "head", "foot_l", "foot_r"}
ARM_CHAIN = ("clavicle", "arm", "forearm", "hand", "thumb", "index", "fingers")


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--variant", choices=RETRO.keys(), required=True)
    p.add_argument("--out", default="")
    p.add_argument("--tex", type=int, default=1024)
    p.add_argument("--face", default="", help="front face photo; 'none' to skip")
    p.add_argument("--landmarks", default="")
    return p.parse_args(argv)


# ---------------------------------------------------------------- loading

def load_source(kind: str):
    """PSX mannequin + its actions (renamed src_*). Resets the scene."""
    psx.use_mannequin(kind)
    rig, mesh = psx.load_mannequin()
    for act in list(bpy.data.actions):     # list(): renaming re-sorts the collection
        act.name = "src_" + act.name
    mesh.hide_render = True
    mesh.hide_set(True)
    return rig


def load_target(body: str):
    bpy.ops.import_scene.fbx(filepath=os.path.join(BASES, body + ".fbx"))
    rig = next(o for o in bpy.context.selected_objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.context.selected_objects if o.type == "MESH")
    rig.name, mesh.name = "npc_rig", "npc_mesh"
    # FBX comes in at 0.01 scale (cm): apply so everything is in metres with identity transforms.
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    rig.data.pose_position = "REST"
    _remove_duplicate_faces(mesh)
    return rig, mesh


def _remove_duplicate_faces(mesh) -> None:
    """The base meshes have the nose side faces twice (same vertices); the copies z-fight and
    one of them shows a dark texel. Keep the first of each."""
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    seen, dupes = set(), []
    for f in bm.faces:
        key = frozenset(tuple(round(c, 4) for c in v.co) for v in f.verts)
        if key in seen:
            dupes.append(f)
        seen.add(key)
    bmesh.ops.delete(bm, geom=dupes, context="FACES")
    bm.to_mesh(mesh.data)
    bm.free()
    print(f"[make_retro_character] removed {len(dupes)} duplicate faces")


def measure_target(rig, mesh) -> None:
    """Set make_psx_character's body constants from the target's bones and mesh."""
    b = rig.data.bones
    neck0, head0 = b["neck"].head_local.z, b["head"].head_local.z
    vs = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    top = max(v.z for v in vs)
    head = [v for v in vs if v.z > head0 and abs(v.x) < 0.15]
    neck = min((max((abs(v.x) for v in vs if abs(v.z - z) < 0.012 and abs(v.x) < 0.12), default=1.0), z)
               for z in [neck0 + i * 0.005 for i in range(int((head0 - neck0) / 0.005) + 1)])
    values = {
        "SHOE_TOP": b["foot_l"].head_local.z + 0.02,
        "TROUSER_TOP": b["pelvis"].head_local.z + 0.11,
        "NECK_Z": neck0 + 0.012,
        "MQ_NECK_MIN": neck[1],
        "MQ_TOP": top,
        "MQ_HEAD_W": 2.0 * max(abs(v.x) for v in head),
        "MQ_HEAD_Y": (min(v.y for v in head), max(v.y for v in head)),
        "HAIR_MIN_Z": head0 + (top - head0) * 0.45,
    }
    for k, val in values.items():
        setattr(psx, k, val)
    print("[make_retro_character] body:",
          {k: (tuple(round(x, 3) for x in v) if isinstance(v, tuple) else round(v, 3))
           for k, v in values.items()})


# ---------------------------------------------------------------- arm attribute

def arm_info(rig, mesh) -> None:
    """Colour attribute arm_info: r = position along the arm (0 shoulder, 1 wrist, >1 hand),
    g = 1 on the arms. Lets the sleeve mask follow the A-pose arm."""
    groups = {g.index: g.name for g in mesh.vertex_groups}
    b = rig.data.bones
    attr = mesh.data.color_attributes.new("arm_info", "FLOAT_COLOR", "POINT")
    for v in mesh.data.vertices:
        best = max(v.groups, key=lambda g: g.weight, default=None)
        name = groups.get(best.group, "") if best else ""
        side = name[-1:] if name.endswith(("_l", "_r")) else ""
        if not side or not name.startswith(ARM_CHAIN):
            attr.data[v.index].color = (0.0, 0.0, 0.0, 1.0)
            continue
        sh = b["arm_" + side].head_local
        el = b["forearm_" + side].head_local
        wr = b["hand_" + side].head_local
        p = mesh.matrix_world @ v.co
        upper = (el - sh).length
        lower = (wr - el).length
        t1 = max(0.0, (p - sh).dot((el - sh).normalized()))
        if t1 <= upper:
            t = t1 / (upper + lower)
        else:
            t = (upper + (p - el).dot((wr - el).normalized())) / (upper + lower)
        attr.data[v.index].color = (max(0.0, t), 1.0, 0.0, 1.0)


def bake_body(mesh, v: dict, skin: tuple, size: int):
    """make_psx_character.bake_body with arm masks from the arm_info attribute."""
    img = bpy.data.images.new("npc_body", size, size)
    mat = bpy.data.materials.new("npc_body_bake")
    mat.use_nodes = True
    N = mc.Nodes(mat.node_tree)
    N.n.clear()
    pos, (x, y, z) = psx._rest_pos_nodes(mesh, N)
    ax = N.math("ABSOLUTE", x)
    lt = lambda a, b: N.math("LESS_THAN", a, b)
    gt = lambda a, b: N.math("GREATER_THAN", a, b)
    mul = lambda a, b: N.math("MULTIPLY", a, b)
    arm = N.new("ShaderNodeAttribute", attribute_name="arm_info")
    sep = N.new("ShaderNodeSeparateColor")
    N.link(arm.outputs["Color"], sep.inputs[0])
    arm_t, is_arm = sep.outputs[0], sep.outputs[1]
    front_y = psx.MQ_HEAD_Y[0] * 0.2 + 0.02      # chest front, relative to this body

    col = N.noisy(pos, skin, 40.0, 0.06)
    torso = mul(mul(gt(z, psx.TROUSER_TOP), lt(z, psx.NECK_Z)), lt(is_arm, 0.5))
    sleeve = mul(gt(is_arm, 0.5), lt(arm_t, v["sleeve_t"]))
    top_mask = N.math("MAXIMUM", torso, sleeve)
    top_col = N.fabric(pos, v["top"])
    if v["inner_strip_x"] > 0.0:
        inner = mul(lt(ax, v["inner_strip_x"]), lt(y, front_y))
        top_col = N.mix(inner, top_col, N.noisy(pos, v["inner"], 80.0, 0.15))
    if v["tie"]:
        v_top = psx.NECK_Z - 0.23
        vwidth = N.math("MULTIPLY", N.math("SUBTRACT", z, v_top), 0.45)
        vmask = mul(mul(lt(ax, vwidth), lt(y, front_y)), gt(z, v_top))
        top_col = N.mix(vmask, top_col, N.noisy(pos, v["inner"], 80.0, 0.1))
        tie = mul(mul(lt(ax, 0.018), lt(y, front_y)), gt(z, psx.NECK_Z - 0.33))
        top_col = N.mix(mul(tie, lt(z, psx.NECK_Z)), top_col, (0.05, 0.03, 0.03))
    col = N.mix(top_mask, col, top_col)
    trousers = mul(mul(lt(z, psx.TROUSER_TOP), gt(z, psx.SHOE_TOP)), lt(is_arm, 0.5))
    col = N.mix(trousers, col, N.fabric(pos, v["trousers"]))
    col = N.mix(lt(z, psx.SHOE_TOP), col, N.fabric(pos, psx.SHOES))

    emit = N.new("ShaderNodeEmission")
    N.link(col, emit.inputs[0])
    out = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], out.inputs["Surface"])
    target = N.new("ShaderNodeTexImage", image=img)
    N.n.active = target
    psx._bake_active(mesh, mat)
    return img


def push_hair(mesh, hair) -> None:
    """Scalp vertices out onto the MPFB hair (make_psx_character._push_onto_hair), only for
    vertices skinned to the head."""
    head_idx = mesh.vertex_groups["head"].index
    keep = {v.index: v.co.copy() for v in mesh.data.vertices
            if not any(g.group == head_idx and g.weight > 0.5 for g in v.groups)}
    psx._push_onto_hair(mesh, hair)
    for i, co in keep.items():
        mesh.data.vertices[i].co = co


# ---------------------------------------------------------------- retarget

def _dir(rig, bone: str, child: str = "") -> Vector:
    b = rig.data.bones[bone]
    mw = rig.matrix_world.to_3x3()
    end = rig.data.bones[child].head_local if child else b.tail_local
    return (mw @ (end - b.head_local)).normalized()


def _side_map(src, tgt) -> dict:
    """BONE_MAP, swapping left/right if the source's Left bones sit on the other side."""
    sx = (src.matrix_world @ src.data.bones["LeftArm"].head_local).x
    tx = (tgt.matrix_world @ tgt.data.bones["arm_l"].head_local).x
    if sx * tx > 0:
        return dict(BONE_MAP)
    swap = {}
    for s, t in BONE_MAP.items():
        if t.endswith("_l"):
            t = t[:-2] + "_r"
        elif t.endswith("_r"):
            t = t[:-2] + "_l"
        swap[s] = t
    return swap


def retarget(src, tgt) -> None:
    bmap = _side_map(src, tgt)
    src_child = {"LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "LeftUpLeg": "LeftLeg",
                 "LeftLeg": "LeftFoot", "RightArm": "RightForeArm", "RightForeArm": "RightHand",
                 "RightUpLeg": "RightLeg", "RightLeg": "RightFoot"}
    tgt_child = {"arm": "forearm", "forearm": "hand", "thigh": "calf", "calf": "foot"}
    s_mw, t_mw = src.matrix_world, tgt.matrix_world
    t_mw_q = t_mw.to_quaternion()

    # Rest: world rotations and the A-pose -> T-pose alignment per mapped bone.
    s_rest = {s: (s_mw @ src.data.bones[s].matrix_local).to_quaternion() for s in bmap}
    t_rest = {t: (t_mw @ tgt.data.bones[t].matrix_local).to_quaternion() for t in bmap.values()}
    align = {}
    for s, t in bmap.items():
        if t in NO_ALIGN:
            align[t] = Quaternion()
            continue
        stem, side = t[:-2], t[-2:]
        td = _dir(tgt, t, tgt_child[stem] + side if stem in tgt_child else "")
        sd = _dir(src, s, src_child.get(s, ""))
        align[t] = td.rotation_difference(sd)
    hips_rest = s_mw @ src.data.bones["Hips"].head_local
    pelvis_rest = t_mw @ tgt.data.bones[bmap["Hips"]].head_local
    hip_scale = pelvis_rest.z / max(1e-4, hips_rest.z)

    order = sorted(tgt.data.bones, key=lambda b: len(b.parent_recursive))
    inv = {t: s for s, t in bmap.items()}
    tgt.data.pose_position = "POSE"
    for pb in tgt.pose.bones:
        pb.rotation_mode = "QUATERNION"
    tgt.animation_data_create()
    scene = bpy.context.scene
    src_actions = [a for a in bpy.data.actions if a.name.startswith("src_")]
    for act in src_actions:
        src.animation_data.action = act
        if act.slots:
            src.animation_data.action_slot = act.slots[0]
        new = bpy.data.actions.new(act.name[4:])
        new.use_fake_user = True
        tgt.animation_data.action = new
        f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
        prev = {}
        for f in range(f0, f1 + 1):
            scene.frame_set(f)
            pose_arm = {}
            for b in order:
                rest_arm = b.matrix_local
                if b.parent:
                    unposed = pose_arm[b.parent.name] @ b.parent.matrix_local.inverted() @ rest_arm
                else:
                    unposed = rest_arm.copy()
                s = inv.get(b.name)
                if s is None:
                    pose_arm[b.name] = unposed
                    continue
                spb = src.pose.bones[s]
                d = (s_mw @ spb.matrix).to_quaternion() @ s_rest[s].inverted()
                want = t_mw_q.inverted() @ d @ align[b.name] @ t_rest[b.name]
                loc = unposed.translation
                if s == "Hips":
                    off = (s_mw @ spb.matrix).translation - hips_rest
                    loc = t_mw.inverted() @ (pelvis_rest + off * hip_scale)
                m = Matrix.LocRotScale(loc, want, None)
                pose_arm[b.name] = m
                basis = unposed.inverted() @ m
                pbt = tgt.pose.bones[b.name]
                q = basis.to_quaternion()
                if b.name in prev:
                    q.make_compatible(prev[b.name])
                prev[b.name] = q
                pbt.rotation_quaternion = q
                pbt.keyframe_insert("rotation_quaternion", frame=f, group=b.name)
                if s == "Hips":
                    pbt.location = basis.translation
                    pbt.keyframe_insert("location", frame=f, group=b.name)
    tgt.animation_data.action = None
    for pb in tgt.pose.bones:
        pb.matrix_basis.identity()
    print(f"[make_retro_character] retargeted {len(src_actions)} actions")


# ---------------------------------------------------------------- main

def main() -> None:
    args = parse_args()
    v = RETRO[args.variant]
    src = load_source(v["anim_from"])
    rig, mesh = load_target(v["body"])
    measure_target(rig, mesh)
    arm_info(rig, mesh)
    sources, skin, base = psx.build_head_source(args.variant, v)
    push_hair(mesh, sources[2])
    psx._bake_setup()
    body_img = bake_body(mesh, v, skin, args.tex)
    head_img = psx.bake_head(mesh, sources, skin, args.tex)
    photo = psx.face_photo_path(args.variant, args.face)
    if photo:
        head_img = psx.bake_face_photo(mesh, base, sources[1], head_img, skin, photo,
                                       psx._load_landmarks(args.variant, photo, args.landmarks),
                                       args.tex, hair=sources[2])
    psx.composite(mesh, body_img, head_img, args.tex)
    for o in list(bpy.data.objects):
        if o not in (rig, mesh, src):
            o.hide_render = True
    retarget(src, rig)
    # Drop the source rig and its actions so only the NPC is exported.
    for a in [a for a in bpy.data.actions if a.name.startswith("src_")]:
        bpy.data.actions.remove(a)
    for o in list(bpy.data.objects):
        if o not in (rig, mesh):
            bpy.data.objects.remove(o, do_unlink=True)
    if args.out:
        psx.export_glb(rig, mesh, os.path.abspath(args.out))
    print(f"[make_retro_character] {args.variant}: actions {len(bpy.data.actions)}")


if __name__ == "__main__":
    main()
