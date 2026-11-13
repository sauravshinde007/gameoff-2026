"""Generate a ROOM 13 NPC: MPFB2 low-poly human, clothes baked into one low-res texture,
simple idle/walk animations, exported as .glb.

Requires the MPFB extension + MakeHuman system asset pack installed in Blender.

Usage:
  blender -b -P tools/blender/make_character.py -- --variant guest --out assets/models/characters/guest.glb
  blender -b -P tools/blender/make_character.py -- --variant mysterious --out ... [--preview out.png]

Clothes are not separate meshes: each body region (shoes, trousers, shirt, hair...) is chosen by
the vertex's rest-pose position and baked from CC0 fabric photos onto the skin UVs (PS1 style).
"""

import argparse
import math
import os
import sys

import addon_utils
import bpy
from mathutils import Quaternion, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FABRICS = os.path.join(ROOT, "assets", "models", "characters", "source", "fabrics")
POS_OFFSET = 10.0
MPFB_DATA = os.path.expanduser("~/.config/blender/%d.%d/extensions/.user/blender_org/mpfb/data" % bpy.app.version[:2])

# Region rules use rest-pose world coordinates (metres). Character faces -Y, height ~1.73.
VARIANTS = {
    "guest": {
        "gender": 0.0, "age": 0.5, "weight": 0.5,
        "skin": "young_caucasian_female", "skin_sat": 0.85, "skin_bright": 1.0,
        "shoe_top": 0.07, "trouser_top": 0.97, "top_top": 1.46,
        "sleeve_x": 0.27,          # sleeve ends here (|x|), forearms bare
        "inner_strip_x": 0.065,    # open shirt: white tee visible at the front centre
        "hair_front_z": 1.655, "hair_back_z": 1.53,
        "trousers": ("Fabric012.jpg", (0.55, 0.6, 0.75), 5.0),
        "top": ("Fabric080.jpg", (0.3, 0.26, 0.28), 3.0),
        "inner": (0.82, 0.8, 0.74),
        "shoes": ("Leather026.jpg", (1.0, 1.0, 1.0), 4.0),
        "hair": (0.035, 0.028, 0.024),
        "tie": False,
        "head_tilt": 0.0,
    },
    "player": {                    # the new night manager (player character)
        "gender": 0.0, "age": 0.4, "weight": 0.45,
        "skin": "young_caucasian_female", "skin_sat": 0.9, "skin_bright": 1.0,
        "shoe_top": 0.07, "trouser_top": 0.97, "top_top": 1.46,
        "sleeve_x": 0.43,          # long sleeves, only hands bare
        "inner_strip_x": 0.0,
        "hair_front_z": 1.655, "hair_back_z": 1.53,
        "trousers": ("Fabric075.jpg", (0.05, 0.05, 0.055), 5.0),
        "top": ("Fabric075.jpg", (0.42, 0.06, 0.09), 5.0),
        "inner": (0.82, 0.8, 0.74),
        "shoes": ("Leather026.jpg", (0.15, 0.15, 0.15), 4.0),
        "hair": (0.19, 0.11, 0.08),
        "tie": False,
        "head_tilt": 0.0,
    },
    "mysterious": {
        "gender": 1.0, "age": 0.8, "weight": 0.3,
        "skin": "old_caucasian_male", "skin_sat": 0.35, "skin_bright": 0.8,
        "shoe_top": 0.07, "trouser_top": 0.97, "top_top": 1.46,
        "sleeve_x": 0.43,          # long sleeves, only hands bare
        "inner_strip_x": 0.0,      # V-neck handled by "tie" rule
        "hair_front_z": 1.675, "hair_back_z": 1.56,
        "trousers": ("Fabric075.jpg", (0.22, 0.22, 0.24), 5.0),
        "top": ("Fabric075.jpg", (0.22, 0.22, 0.24), 5.0),
        "inner": (0.78, 0.78, 0.76),
        "shoes": ("Leather026.jpg", (1.0, 1.0, 1.0), 4.0),
        "hair": (0.02, 0.02, 0.022),
        "tie": True,
        "head_tilt": 9.0,          # idle head lean (degrees), slightly wrong posture
    },
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--variant", choices=VARIANTS.keys(), required=True)
    p.add_argument("--out", default="")
    p.add_argument("--preview", default="")
    p.add_argument("--tex", type=int, default=512)
    return p.parse_args(argv)


# ---------------------------------------------------------------- human

def build_human(v: dict):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    addon_utils.enable("bl_ext.blender_org.mpfb", default_set=True)
    from bl_ext.blender_org.mpfb.services.humanservice import HumanService
    from bl_ext.blender_org.mpfb.services.targetservice import TargetService

    macro = TargetService.get_default_macro_info_dict()
    macro["gender"] = v["gender"]
    macro["age"] = v["age"]
    macro["weight"] = v["weight"]
    base = HumanService.create_human(macro_detail_dict=macro, scale=0.1)
    HumanService.add_builtin_rig(base, "game_engine")
    proxy = HumanService.add_mhclo_asset(
        os.path.join(MPFB_DATA, "proxymeshes", "proxy741", "proxy741.proxy"), base,
        asset_type="Proxymeshes", subdiv_levels=0, material_type="NONE")
    skin = os.path.join(MPFB_DATA, "skins", v["skin"], v["skin"] + ".mhmat")
    HumanService.set_character_skin(skin, base, bodyproxy=proxy, skin_type="MAKESKIN")
    eyes = HumanService.add_mhclo_asset(
        os.path.join(MPFB_DATA, "eyes", "low-poly", "low-poly.mhclo"), base,
        asset_type="Eyes", subdiv_levels=0)
    rig = base.parent if base.parent and base.parent.type == "ARMATURE" else \
        next(o for o in bpy.data.objects if o.type == "ARMATURE")
    # Only the proxy body, eyes and rig are exported; the hi-res basemesh is dropped.
    bpy.data.objects.remove(base, do_unlink=True)
    return rig, proxy, eyes


def find_skin_image(obj) -> bpy.types.Image:
    for slot in obj.material_slots:
        if slot.material and slot.material.use_nodes:
            for n in slot.material.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image and "diffuse" in n.image.name.lower():
                    return n.image
    for img in bpy.data.images:
        if "diffuse" in img.name.lower():
            return img
    raise RuntimeError("Skin diffuse image not found")


# ---------------------------------------------------------------- clothes bake

class Nodes:
    def __init__(self, tree):
        self.t = tree
        self.n = tree.nodes
        self.l = tree.links

    def new(self, kind, **props):
        node = self.n.new(kind)
        for k, val in props.items():
            setattr(node, k, val)
        return node

    def link(self, a, b):
        self.l.new(a, b)

    def math(self, op, a, b=None):
        m = self.new("ShaderNodeMath", operation=op)
        self._in(m.inputs[0], a)
        if b is not None:
            self._in(m.inputs[1], b)
        return m.outputs[0]

    def _in(self, sock, val):
        if isinstance(val, (int, float)):
            sock.default_value = val
        else:
            self.link(val, sock)

    def mix(self, fac, a, b):
        """fac 0 -> a, 1 -> b (colours)."""
        m = self.new("ShaderNodeMix", data_type="RGBA")
        self._in(m.inputs[0], fac)
        self._col(m.inputs[6], a)
        self._col(m.inputs[7], b)
        return m.outputs[2]

    def _col(self, sock, val):
        if isinstance(val, tuple):
            sock.default_value = (*val, 1.0)
        else:
            self.link(val, sock)

    def fabric(self, pos, spec):
        name, tint, scale = spec
        img = bpy.data.images.load(os.path.join(FABRICS, name), check_existing=True)
        mapping = self.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (scale, scale, scale)
        self.link(pos, mapping.inputs["Vector"])
        tex = self.new("ShaderNodeTexImage", image=img, projection="BOX", projection_blend=0.2)
        self.link(mapping.outputs[0], tex.inputs[0])
        return self.mul_col(tex.outputs[0], tint)

    def mul_col(self, col, tint):
        m = self.new("ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
        m.inputs[0].default_value = 1.0
        self.link(col, m.inputs[6])
        m.inputs[7].default_value = (*tint, 1.0)
        return m.outputs[2]

    def noisy(self, pos, col, scale=60.0, amount=0.35):
        noise = self.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = scale
        self.link(pos, noise.inputs["Vector"])
        dark = tuple(c * (1.0 - amount) for c in col)
        return self.mix(noise.outputs["Fac"], dark, col)


def bake_clothes(proxy, v: dict, size: int) -> bpy.types.Image:
    skin_img = find_skin_image(proxy)
    out_img = bpy.data.images.new("npc_albedo", size, size)

    mat = bpy.data.materials.new("npc_bake")
    mat.use_nodes = True
    N = Nodes(mat.node_tree)
    N.n.clear()

    # Rest-pose positions as a vertex attribute so region masks ignore the armature.
    pos_attr = proxy.data.color_attributes.new("rest_pos", "FLOAT_COLOR", "POINT")
    for i, vert in enumerate(proxy.data.vertices):
        co = proxy.matrix_world @ vert.co
        # Offset keeps values positive (colour attributes may clamp negatives).
        pos_attr.data[i].color = (co.x + POS_OFFSET, co.y + POS_OFFSET, co.z + POS_OFFSET, 1.0)
    attr = N.new("ShaderNodeAttribute", attribute_name="rest_pos")
    unoffset = N.new("ShaderNodeVectorMath", operation="SUBTRACT")
    N.link(attr.outputs["Vector"], unoffset.inputs[0])
    unoffset.inputs[1].default_value = (POS_OFFSET, POS_OFFSET, POS_OFFSET)
    pos = unoffset.outputs[0]
    sep = N.new("ShaderNodeSeparateXYZ")
    N.link(pos, sep.inputs[0])
    x, y, z = sep.outputs
    ax = N.math("ABSOLUTE", x)

    # Skin (desaturate / brighten for the pale variant).
    uv = N.new("ShaderNodeUVMap")
    skin_tex = N.new("ShaderNodeTexImage", image=skin_img)
    N.link(uv.outputs[0], skin_tex.inputs[0])
    hsv = N.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = v["skin_sat"]
    hsv.inputs["Value"].default_value = v["skin_bright"]
    N.link(skin_tex.outputs[0], hsv.inputs["Color"])
    col = hsv.outputs[0]

    lt = lambda a, b: N.math("LESS_THAN", a, b)
    gt = lambda a, b: N.math("GREATER_THAN", a, b)
    mul = lambda a, b: N.math("MULTIPLY", a, b)

    # Top (shirt / jacket): torso band, arms up to sleeve_x.
    top_mask = mul(mul(gt(z, v["trouser_top"]), lt(z, v["top_top"])), lt(ax, v["sleeve_x"]))
    top_col = N.fabric(pos, v["top"])
    if v["inner_strip_x"] > 0.0:
        inner = mul(lt(ax, v["inner_strip_x"]), lt(y, 0.0))
        top_col = N.mix(inner, top_col, N.noisy(pos, v["inner"], 80.0, 0.15))
    if v["tie"]:
        # White shirt V-neck with a dark tie down the middle.
        vwidth = N.math("MULTIPLY", N.math("SUBTRACT", z, 1.22), 0.42)
        vmask = mul(mul(lt(ax, vwidth), lt(y, 0.0)), gt(z, 1.22))
        top_col = N.mix(vmask, top_col, N.noisy(pos, v["inner"], 80.0, 0.1))
        tie = mul(mul(lt(ax, 0.018), lt(y, 0.0)), gt(z, 1.12))
        top_col = N.mix(tie, top_col, (0.05, 0.03, 0.03))
    col = N.mix(top_mask, col, top_col)

    # Trousers, shoes.
    trouser_mask = mul(lt(z, v["trouser_top"]), gt(z, v["shoe_top"]))
    col = N.mix(trouser_mask, col, N.fabric(pos, v["trousers"]))
    col = N.mix(lt(z, v["shoe_top"]), col, N.fabric(pos, v["shoes"]))

    # Hair cap: top of head, lower at the back.
    hair_front = gt(z, v["hair_front_z"])
    hair_back = mul(gt(z, v["hair_back_z"]), gt(y, 0.02))
    hair_mask = N.math("MAXIMUM", hair_front, hair_back)
    col = N.mix(hair_mask, col, N.noisy(pos, v["hair"], 120.0, 0.6))

    emit = N.new("ShaderNodeEmission")
    N.link(col, emit.inputs[0])
    out = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], out.inputs["Surface"])
    target = N.new("ShaderNodeTexImage", image=out_img)
    N.n.active = target

    proxy.data.materials.clear()
    proxy.data.materials.append(mat)

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 4
    scene.cycles.device = "CPU"
    scene.render.bake.margin = 4
    bpy.ops.object.select_all(action="DESELECT")
    proxy.select_set(True)
    bpy.context.view_layer.objects.active = proxy
    bpy.ops.object.bake(type="EMIT")

    # Final, exportable material: baked texture -> Principled base colour.
    final = bpy.data.materials.new("npc_body")
    final.use_nodes = True
    bsdf = final.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    t = final.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = out_img
    final.node_tree.links.new(t.outputs[0], bsdf.inputs["Base Color"])
    proxy.data.materials.clear()
    proxy.data.materials.append(final)
    proxy.data.color_attributes.remove(proxy.data.color_attributes["rest_pos"])
    out_img.pack()
    return out_img


# ---------------------------------------------------------------- animation

FPS = 24
IDLE_FRAMES = 96
WALK_FRAMES = 32      # one full stride cycle; matches guest.gd walk_speed ~1.8 m/s
ARM_OUT_DEG = 7.0     # arms hang this far out from vertical
LEG_OUT_DEG = 2.5     # feet roughly hip-width apart
DOWN = Vector((0.0, 0.0, -1.0))


def rot_x(deg: float) -> Quaternion:
    # +deg swings a hanging limb backwards (+Y); the character faces -Y.
    return Quaternion((1.0, 0.0, 0.0), math.radians(deg))


def _out(side: str, deg: float) -> Vector:
    """Straight down, tilted outward to the character's `side` by deg."""
    sign = 1.0 if side == "l" else -1.0   # MPFB: left side is +X
    a = math.radians(deg)
    return Vector((sign * math.sin(a), 0.0, -math.cos(a)))


def key_chain(rig, bones: list, targets: list, frame: int) -> None:
    """Aim each bone of a parent->child chain along its target direction (armature space).
    A child's armature-space rotation is parent_total @ own, so each bone solves its own
    rotation in the parent's already-rotated frame."""
    acc = Quaternion()
    for name, target in zip(bones, targets):
        bone = rig.data.bones[name]
        cur = (bone.tail_local - bone.head_local).normalized()
        own = cur.rotation_difference(acc.inverted() @ target.normalized())
        pb = rig.pose.bones[name]
        rest = bone.matrix_local.to_quaternion()
        pb.rotation_quaternion = rest.inverted() @ own @ rest
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        acc = acc @ own


def key_rot(rig, name: str, q_arm: Quaternion, frame: int) -> None:
    """Key a bone with a rotation given in armature rest space (no parent rotation assumed)."""
    pb = rig.pose.bones[name]
    rest = rig.data.bones[name].matrix_local.to_quaternion()
    pb.rotation_quaternion = rest.inverted() @ q_arm @ rest
    pb.keyframe_insert("rotation_quaternion", frame=frame)


def key_arm(rig, side: str, swing: float, elbow: float, frame: int) -> None:
    upper = rot_x(swing) @ _out(side, ARM_OUT_DEG)
    fore = rot_x(swing - elbow) @ _out(side, ARM_OUT_DEG * 0.5)
    key_chain(rig, ["upperarm_" + side, "lowerarm_" + side, "hand_" + side], [upper, fore, fore], frame)


def key_leg(rig, side: str, hip: float, knee: float, frame: int) -> None:
    thigh = rot_x(hip) @ _out(side, LEG_OUT_DEG)
    calf = rot_x(hip + knee) @ _out(side, LEG_OUT_DEG)
    key_chain(rig, ["thigh_" + side, "calf_" + side], [thigh, calf], frame)


def new_action(rig, name: str, length: int):
    """New action with every bone keyed at rest on the first and last frame, so bones an
    animation doesn't move never keep a pose left over from another animation."""
    rig.animation_data_create()
    act = bpy.data.actions.new(name)
    rig.animation_data.action = act
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = Quaternion()
        pb.location = (0.0, 0.0, 0.0)
        for f in (0, length):
            pb.keyframe_insert("rotation_quaternion", frame=f)
    return act


def finish_action(rig, act, name: str) -> None:
    act.use_fake_user = True
    rig.animation_data.action = None
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, act)


def make_idle(rig, v: dict) -> None:
    act = new_action(rig, "idle", IDLE_FRAMES)
    tilt = Quaternion((0.0, 1.0, 0.0), math.radians(v["head_tilt"]))
    for f, breath in ((0, 0.0), (IDLE_FRAMES // 2, 1.0), (IDLE_FRAMES, 0.0)):
        key_rot(rig, "spine_02", rot_x(-1.2 * breath), f)
        key_rot(rig, "neck_01", rot_x(0.8 * breath), f)
        key_rot(rig, "head", tilt, f)
        for s in ("l", "r"):
            key_arm(rig, s, 1.5 * breath, 8.0, f)
            key_leg(rig, s, 0.0, 2.0, f)
    finish_action(rig, act, "idle")


def make_walk(rig) -> None:
    act = new_action(rig, "walk", WALK_FRAMES)
    bones = rig.data.bones
    leg_len = (bones["thigh_l"].head_local - bones["foot_l"].head_local).length
    # Phase keys for the left side (forward, passing, back, passing, forward);
    # the right side runs half a cycle later.
    hip = [-24.0, 0.0, 22.0, 0.0, -24.0]
    knee = [5.0, 8.0, 12.0, 45.0, 5.0]       # knee bends as the leg swings through
    arm = [16.0, 0.0, -16.0, 0.0, 16.0]       # opposite to the same-side leg
    step = WALK_FRAMES // 4
    for i in range(5):
        f = i * step
        j = (i + 2) % 4
        key_leg(rig, "l", hip[i], knee[i], f)
        key_leg(rig, "r", hip[j], knee[j], f)
        key_arm(rig, "l", arm[i], 14.0, f)
        key_arm(rig, "r", arm[j], 14.0, f)
        # Drop the hips while both legs are spread so the feet stay on the floor.
        spread = max(abs(hip[i]), abs(hip[j]))
        key_hips(rig, -leg_len * (1.0 - math.cos(math.radians(spread))), f)
    finish_action(rig, act, "walk")


def key_hips(rig, dz: float, frame: int) -> None:
    pb = rig.pose.bones["pelvis"]
    rest = rig.data.bones["pelvis"].matrix_local.to_quaternion()
    pb.location = rest.inverted() @ Vector((0.0, 0.0, dz))
    pb.keyframe_insert("location", frame=frame)


def export_glb(rig, objs: list, path: str) -> None:
    # Everything except the baked body texture (eyes etc.) is tiny on screen.
    for img in bpy.data.images:
        if img.name != "npc_albedo" and img.size[0] > 64:
            img.scale(64, 64)
            img.pack()
    bpy.ops.object.select_all(action="DESELECT")
    for o in [rig, *objs]:
        o.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.context.scene.render.fps = FPS
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_animation_mode="NLA_TRACKS",
        export_apply=False,
    )


# ---------------------------------------------------------------- preview

def render_preview(path: str) -> None:
    scene = bpy.context.scene
    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun = bpy.data.objects.new("PreviewSun", bpy.data.lights.new("PreviewSun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (0.8, 0.2, 0.3)
    scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("PreviewWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scene.world = world
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 400
    scene.render.resolution_y = 560
    base, ext = os.path.splitext(path)
    for label, loc, rot in (("front", (0, -3.2, 1.0), (88, 0, 0)), ("back", (0, 3.2, 1.0), (88, 0, 180)),
                           ("side", (-3.2, 0, 1.0), (88, 0, -90))):
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)
        scene.render.filepath = f"{base}_{label}{ext}"
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)


# ---------------------------------------------------------------- main

def main() -> None:
    args = parse_args()
    v = VARIANTS[args.variant]
    rig, proxy, eyes = build_human(v)
    bake_clothes(proxy, v, args.tex)
    make_idle(rig, v)
    make_walk(rig)
    if args.preview:
        # Preview in the idle pose (first idle key) and mid-stride.
        rig.animation_data.action = bpy.data.actions["idle"]
        bpy.context.scene.frame_set(0)
        render_preview(args.preview)
        rig.animation_data.action = bpy.data.actions["walk"]
        bpy.context.scene.frame_set(0)
        base, ext = os.path.splitext(args.preview)
        render_preview(base + "_walk" + ext)
        rig.animation_data.action = None
    if args.out:
        export_glb(rig, [proxy, eyes], os.path.abspath(args.out))
    tris = 0
    for o in (proxy, eyes):
        o.data.calc_loop_triangles()
        tris += len(o.data.loop_triangles)
    print(f"[make_character] {args.variant}: triangles {tris}")


if __name__ == "__main__":
    main()
