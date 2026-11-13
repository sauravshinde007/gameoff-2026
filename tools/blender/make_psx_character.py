"""Build a ROOM 13 NPC on the PSX Animation Library mannequin (CC BY 4.0, heyheythere) with a
human texture, keeping all 30 of its animations.

1. The mannequin gets a new UV layout: one cylindrical wrap per body part (head, torso, legs,
   arms) with flat caps, so each part is one continuous island with a single hidden seam.
2. Body: clothes (CC0 fabric photos) and skin are painted by rest-pose position (seamless).
3. Head: an MPFB2 human head (CC0 skin, hair, eyes) is scaled onto the mannequin head and its
   colour is transferred surface-to-surface (selected-to-active bake), so the face, sides and
   back of the head come from one continuous 3D source - no projection cuts.
4. Both are composited into one texture and exported to .glb with every animation.

Usage:
  blender -b -P tools/blender/make_psx_character.py -- --variant guest \
      --out assets/models/characters/guest.glb [--preview /tmp/p.png] [--tex 1024] \
      [--head-faces 300]
"""

import argparse
import json
import math
import os
import sys

import addon_utils
import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_character as mc  # noqa: E402  (MPFB paths, skin presets, node helpers, preview)

ROOT = mc.ROOT
MANNEQUIN_DIR = os.path.join(ROOT, "assets", "psx-animation-library-free", "glb")
POS_OFFSET = 10.0

# Per-NPC look. Skin preset / age / build come from make_character.VARIANTS[name].
PSX = {
    "guest": {                        # Ms. Carter
        "mannequin": "woman",
        "hair_asset": "ponytail01",
        "sleeve_x": 0.66,                 # long sleeves to the wrist
        "inner_strip_x": 0.045,           # open cardigan shows the blouse
        "tie": False,
        "trousers": ("Fabric012.jpg", (0.32, 0.3, 0.34), 5.0),
        "top": ("Fabric075.jpg", (1.25, 0.95, 0.62), 5.0),
        "inner": (0.86, 0.82, 0.74),
    },
    "player": {                       # the new night manager (player character)
        "mannequin": "woman",
        "hair_asset": "long01",           # long, straight, brown
        "sleeve_x": 0.66,                 # long sleeves to the wrist
        "inner_strip_x": 0.0,
        "tie": False,
        "trousers": ("Fabric075.jpg", (0.05, 0.05, 0.055), 5.0),   # black pencil skirt
        "top": ("Fabric075.jpg", (0.42, 0.06, 0.09), 5.0),         # burgundy button-up shirt
        "inner": (0.86, 0.82, 0.74),
    },
    "mysterious": {
        "hair_asset": "short04",
        "sleeve_x": 0.73,                 # long sleeves to the wrist
        "inner_strip_x": 0.0,
        "tie": True,
        "trousers": ("Fabric075.jpg", (0.22, 0.22, 0.24), 5.0),
        "top": ("Fabric075.jpg", (0.22, 0.22, 0.24), 5.0),
        "inner": (0.78, 0.78, 0.76),
    },
}
SHOES = ("Leather026.jpg", (1.0, 1.0, 1.0), 4.0)

# Mannequin rest pose (T-pose, metres, faces -Y), measured from its mesh.
SHOE_TOP = 0.11
TROUSER_TOP = 0.97
NECK_Z = 1.50                 # collar line; above it the transferred head colour is used
ARM_Z = 1.425                 # arms run along X at this height
ARM_BAND = (1.3, 1.56)        # z range that holds the arms (sleeve mask, UV part split)
LEG_X = 0.094
MQ_NECK_MIN = 1.527           # narrowest point of the neck
MQ_TOP = 1.78                 # crown
MQ_HEAD_W = 0.176             # widest (x)
MQ_HEAD_Y = (-0.12, 0.098)    # front / back (y)

BAKE_MARGIN = 8

# Angular head. The MPFB neck is slightly wider than the mannequin's, so the two overlap between
# these heights and the join is hidden.
HEAD_CUT_Z = 1.485            # MPFB head kept above this
MQ_HEAD_CUT_Z = 1.515         # mannequin faces removed above this
HEAD_ATTR = "npc_head"        # face attribute marking the new head after the join
HAIR_MIN_Z = 1.62             # only vertices above this may be pushed out onto the hair
HAIR_MAX_PUSH = 0.03

# Per-mannequin measurements (rest pose, metres). The man's values are the defaults above;
# use_mannequin() swaps them in. Head-cut heights follow the neck.
MANNEQUINS = {
    "man": {},
    "woman": {
        "TROUSER_TOP": 0.93, "NECK_Z": 1.428, "ARM_Z": 1.344, "ARM_BAND": (1.23, 1.49),
        "LEG_X": 0.104, "MQ_NECK_MIN": 1.455, "MQ_TOP": 1.69, "MQ_HEAD_W": 0.158,
        "MQ_HEAD_Y": (-0.11, 0.088), "HEAD_CUT_Z": 1.413, "MQ_HEAD_CUT_Z": 1.443, "HAIR_MIN_Z": 1.53,
    },
}
MANNEQUIN_KIND = "man"


def use_mannequin(kind: str) -> None:
    global MANNEQUIN_KIND
    MANNEQUIN_KIND = kind
    globals().update(MANNEQUINS[kind])
HEAD_SHARP_DEG = 38.0         # edges sharper than this stay hard (angular PS1 look)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--variant", choices=PSX.keys(), required=True)
    p.add_argument("--out", default="")
    p.add_argument("--preview", default="")
    p.add_argument("--tex", type=int, default=1024)
    p.add_argument("--face", default="",
                   help="front face photo; default faces/<variant>_front.png if it exists, "
                        "'none' to skip")
    p.add_argument("--landmarks", default="", help="landmarks JSON (default faces/landmarks.json)")
    p.add_argument("--head-faces", type=int, default=300,
                   help="face budget of the angular head (lower = blockier)")
    return p.parse_args(argv)


# ---------------------------------------------------------------- mannequin

def load_mannequin():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    name = "mannequin_" + MANNEQUIN_KIND
    bpy.ops.import_scene.gltf(filepath=os.path.join(MANNEQUIN_DIR, name + ".glb"))
    rig = bpy.data.objects[name]
    mesh = bpy.data.objects[name + "_mesh"]
    for o in list(bpy.data.objects):
        if o not in (rig, mesh):
            bpy.data.objects.remove(o, do_unlink=True)
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.matrix_basis.identity()
    return rig, mesh


# ---------------------------------------------------------------- UVs

# Texel density per part: the head gets the most texture, like a hand-made PS1 sheet.
UV_DENSITY = {"head": 3.5, "torso": 1.0, "leg_l": 1.0, "leg_r": 1.0,
              "arm_l": 1.0, "arm_r": 1.0, "foot": 1.0}


def _part(c: Vector) -> str:
    if c.z > NECK_Z - 0.03 and abs(c.x) < 0.15:
        return "head"
    if abs(c.x) > 0.17 and c.z > ARM_BAND[0]:
        return "arm_l" if c.x > 0 else "arm_r"
    if c.z < SHOE_TOP + 0.02:
        return "foot"
    if c.z < TROUSER_TOP - 0.02:
        return "leg_l" if c.x > 0 else "leg_r"
    return "torso"


def _cyl_uv(part: str, p: Vector) -> tuple:
    """Cylindrical unwrap. Vertical parts wrap around Z (seam at the back), arms wrap around X
    (seam underneath). Returns (angle, along-axis, radius)."""
    if part in ("arm_l", "arm_r"):
        return math.atan2(-p.y, p.z - ARM_Z), abs(p.x), 0.05
    cx = {"leg_l": LEG_X, "leg_r": -LEG_X}.get(part, 0.0)
    radius = {"head": 0.09, "torso": 0.15}.get(part, 0.07)
    return math.atan2(p.x - cx, -p.y), p.z, radius


def new_uvs(mesh) -> None:
    me = mesh.data
    old = me.uv_layers.active.name
    uv_layer = me.uv_layers.new(name="UVMap_npc")
    me.uv_layers.active = uv_layer
    mw = mesh.matrix_world
    rot = mw.to_3x3()
    head_attr = me.attributes.get(HEAD_ATTR)
    head_polys = []
    groups = {}
    for poly in me.polygons:
        if head_attr is not None and head_attr.data[poly.index].value:
            head_polys.append(poly)
            continue
        part = _part(mw @ poly.center)
        n = (rot @ poly.normal).normalized()
        arm = part.startswith("arm")
        cap_axis = 0 if arm else 2
        if part == "foot":
            axis = max(range(3), key=lambda i: abs(n[i]))
            key = (part, "plane", axis, n[axis] > 0)
        elif abs(n[cap_axis]) > 0.7:
            key = (part, "cap", cap_axis, n[cap_axis] > 0)
        else:
            key = (part, "wrap", 0, False)
        groups.setdefault(key, []).append(poly)

    for (part, kind, axis, positive), polys in groups.items():
        dens = UV_DENSITY[part]
        for poly in polys:
            pts = [mw @ me.vertices[me.loops[li].vertex_index].co for li in poly.loop_indices]
            if kind == "wrap":
                coords = [_cyl_uv(part, p) for p in pts]
                angles = [c[0] for c in coords]
                if max(angles) - min(angles) > math.pi:   # face straddles the seam
                    angles = [a + 2.0 * math.pi if a < 0.0 else a for a in angles]
                uvs = [(a * c[2], c[1]) for a, c in zip(angles, coords)]
            else:
                uvs = []
                for p in pts:
                    if axis == 1:
                        uvs.append((p.x if not positive else -p.x, p.z))
                    elif axis == 0:
                        uvs.append((p.y if positive else -p.y, p.z))
                    else:
                        uvs.append((p.x, p.y if positive else -p.y))
            for li, (u, v) in zip(poly.loop_indices, uvs):
                uv_layer.data[li].uv = (u * dens, v * dens)
    if head_polys:
        # The angular head keeps its own unwrap (no overlaps), scaled to metres x density.
        src = me.uv_layers[old]
        area_3d = sum(p.area for p in head_polys)
        area_uv = 0.0
        for poly in head_polys:
            uvp = [src.data[li].uv for li in poly.loop_indices]
            for i in range(1, len(uvp) - 1):
                area_uv += abs((uvp[i] - uvp[0]).cross(uvp[i + 1] - uvp[0])) * 0.5
        k = math.sqrt(area_3d / max(area_uv, 1e-9)) * UV_DENSITY["head"]
        for poly in head_polys:
            for li in poly.loop_indices:
                uv_layer.data[li].uv = src.data[li].uv * k
        groups[("head", "own", 0, False)] = head_polys
    me.uv_layers.remove(me.uv_layers[old])
    uv_layer.active_render = True
    # The mesh has split (unwelded) vertices, so Blender's packer would treat every face as an
    # island. Pack each group as one rectangle instead.
    _pack_groups(uv_layer, list(groups.values()))


def _pack_groups(uv_layer, groups: list, margin_frac: float = 0.02) -> None:
    rects = []
    for polys in groups:
        loops = [li for poly in polys for li in poly.loop_indices]
        us = [uv_layer.data[li].uv.x for li in loops]
        vs = [uv_layer.data[li].uv.y for li in loops]
        rects.append({"loops": loops, "u0": min(us), "v0": min(vs),
                      "w": max(us) - min(us), "h": max(vs) - min(vs)})
    area = sum(r["w"] * r["h"] for r in rects)
    pad = math.sqrt(area) * margin_frac
    best = None
    for k in [1.0 + 0.05 * i for i in range(30)]:
        width = math.sqrt(area) * k
        x = y = shelf_h = 0.0
        places = []
        for r in sorted(rects, key=lambda r: -r["h"]):
            w, h = r["w"] + pad, r["h"] + pad
            if x + w > width and x > 0.0:
                y += shelf_h
                x = shelf_h = 0.0
            places.append((r, x, y))
            x += w
            shelf_h = max(shelf_h, h)
        side = max(width, y + shelf_h)
        if best is None or side < best[0]:
            best = (side, places)
    side, places = best
    for r, x, y in places:
        for li in r["loops"]:
            uv = uv_layer.data[li].uv
            uv_layer.data[li].uv = ((uv.x - r["u0"] + x + pad * 0.5) / side,
                                    (uv.y - r["v0"] + y + pad * 0.5) / side)


# ---------------------------------------------------------------- MPFB head source

def _emission_material(src, sat: float, bright: float):
    """Unlit copy of an MPFB material. Transparent hair-card pixels fall back to the image's
    average opaque colour, because a bake ray stops at the first surface it hits."""
    img = None
    for n in src.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image:
            if img is None or "diffuse" in n.image.name.lower():
                img = n.image
    if img is None:
        return None
    mat = bpy.data.materials.new(src.name + "_emit")
    mat.use_nodes = True
    N = mc.Nodes(mat.node_tree)
    N.n.clear()
    uv = N.new("ShaderNodeUVMap")
    tex = N.new("ShaderNodeTexImage", image=img)
    N.link(uv.outputs[0], tex.inputs[0])
    col = N.mix(tex.outputs["Alpha"], _average_opaque(img), tex.outputs["Color"])
    hsv = N.new("ShaderNodeHueSaturation")
    hsv.inputs["Saturation"].default_value = sat
    hsv.inputs["Value"].default_value = bright
    N.link(col, hsv.inputs["Color"])
    emit = N.new("ShaderNodeEmission")
    N.link(hsv.outputs[0], emit.inputs[0])
    out = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], out.inputs["Surface"])
    return mat


def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _average_opaque(img, region=None) -> tuple:
    w, h = img.size
    px = img.pixels[:]
    acc = [0.0, 0.0, 0.0]
    wsum = 0.0
    x0, y0, x1, y1 = region if region else (0, 0, w, h)
    step = max(1, (x1 - x0) // 64)
    for yy in range(y0, y1, step):
        for xx in range(x0, x1, step):
            i = (yy * w + xx) * 4
            a = px[i + 3]
            for c in range(3):
                acc[c] += px[i + c] * a
            wsum += a
    if wsum == 0.0:
        return (0.05, 0.04, 0.03)
    # Image buffers of 8-bit sRGB files hold sRGB values; node colours are linear.
    if img.colorspace_settings.name == "sRGB":
        return tuple(_srgb_to_linear(a / wsum) for a in acc)
    return tuple(a / wsum for a in acc)


def build_head_source(name: str, v: dict) -> tuple:
    """Add an MPFB human (skin, eyes, hair) to the scene, scaled so its head matches the
    mannequin head. Returns (objects to bake from, skin colour for the body)."""
    vm = mc.VARIANTS[name]
    addon_utils.enable("bl_ext.blender_org.mpfb", default_set=True)
    from bl_ext.blender_org.mpfb.services.humanservice import HumanService
    from bl_ext.blender_org.mpfb.services.targetservice import TargetService

    macro = TargetService.get_default_macro_info_dict()
    for k in ("gender", "age", "weight"):
        macro[k] = vm[k]
    base = HumanService.create_human(macro_detail_dict=macro, scale=0.1)
    d = mc.MPFB_DATA
    proxy = HumanService.add_mhclo_asset(
        os.path.join(d, "proxymeshes", "proxy741", "proxy741.proxy"), base,
        asset_type="Proxymeshes", subdiv_levels=0, material_type="NONE")
    HumanService.set_character_skin(
        os.path.join(d, "skins", vm["skin"], vm["skin"] + ".mhmat"), base,
        bodyproxy=proxy, skin_type="MAKESKIN")
    eyes = HumanService.add_mhclo_asset(os.path.join(d, "eyes", "low-poly", "low-poly.mhclo"),
                                        base, asset_type="Eyes", subdiv_levels=0)
    hair = HumanService.add_mhclo_asset(
        os.path.join(d, "hair", v["hair_asset"], v["hair_asset"] + ".mhclo"),
        base, asset_type="Hair", subdiv_levels=0)
    sources = [proxy, eyes, hair]

    skin_img = mc.find_skin_image(proxy)
    w, h = skin_img.size
    # MakeHuman UV: the cheeks/forehead sit in the upper-middle of the skin texture.
    skin = _average_opaque(skin_img, (int(w * 0.40), int(h * 0.70), int(w * 0.60), int(h * 0.85)))
    skin = tuple(c * vm["skin_bright"] for c in skin)
    lum = sum(skin) / 3.0
    skin = tuple(lum + (c - lum) * vm["skin_sat"] for c in skin)

    for o in sources:
        for slot in o.material_slots:
            if slot.material and slot.material.use_nodes:
                m = _emission_material(slot.material, vm["skin_sat"], vm["skin_bright"])
                if m:
                    slot.material = m

    _align_head(base, proxy)
    base.hide_render = True
    return sources, skin, base


def _align_head(base, proxy) -> None:
    """Scale/translate the MPFB human so its neck-to-crown box matches the mannequin's."""
    bpy.context.view_layer.update()
    vs = [proxy.matrix_world @ p.co for p in proxy.data.vertices]
    top = max(v.z for v in vs)
    # Neck = narrowest slice between 0.12 and 0.32 m below the crown.
    best = None
    for i in range(40):
        z0 = top - 0.32 + i * 0.005
        sl = [v for v in vs if z0 <= v.z < z0 + 0.01 and abs(v.x) < 0.12]
        if len(sl) >= 4:
            width = max(abs(v.x) for v in sl)
            if best is None or width < best[0]:
                best = (width, z0 + 0.005)
    neck = best[1] if best else top - 0.25
    head = [v for v in vs if v.z > neck + 0.03 and abs(v.x) < 0.14]
    width = 2.0 * max(abs(v.x) for v in head)
    y0, y1 = min(v.y for v in head), max(v.y for v in head)
    sx = MQ_HEAD_W / width
    sy = (MQ_HEAD_Y[1] - MQ_HEAD_Y[0]) / (y1 - y0)
    sz = (MQ_TOP - MQ_NECK_MIN) / (top - neck)
    tx = 0.0
    ty = (MQ_HEAD_Y[0] + MQ_HEAD_Y[1]) * 0.5 - sy * (y0 + y1) * 0.5
    tz = MQ_TOP - sz * top
    base.matrix_world = Matrix.Translation((tx, ty, tz)) @ Matrix.Diagonal((sx, sy, sz, 1.0)) \
        @ base.matrix_world
    bpy.context.view_layer.update()


# ---------------------------------------------------------------- angular head

def build_angular_head(rig, mesh, base, hair, faces: int) -> None:
    """Replace the mannequin head with a decimated, flat-shaded copy of the MPFB head."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    # Evaluated = targets applied and helper geometry (tongue, joints...) masked out.
    bm = bmesh.new()
    bm.from_object(base, dg)
    bm.transform(base.matrix_world)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < HEAD_CUT_Z or abs(v.co.x) > 0.14],
                     context="VERTS")
    # Drop any floating bits (eyelash/eyebrow islands) - keep the largest connected piece.
    bm.verts.ensure_lookup_table()
    seen, islands = set(), []
    for v in bm.verts:
        if v in seen:
            continue
        stack, isl = [v], []
        seen.add(v)
        while stack:
            cur = stack.pop()
            isl.append(cur)
            for e in cur.link_edges:
                o = e.other_vert(cur)
                if o not in seen:
                    seen.add(o)
                    stack.append(o)
        islands.append(isl)
    islands.sort(key=len, reverse=True)
    bmesh.ops.delete(bm, geom=[v for isl in islands[1:] for v in isl], context="VERTS")
    me = bpy.data.meshes.new("npc_head")
    bm.to_mesh(me)
    bm.free()
    for uv in list(me.uv_layers):
        me.uv_layers.remove(uv)
    head = bpy.data.objects.new("npc_head", me)
    bpy.context.scene.collection.objects.link(head)

    _select_only(head)
    dec = head.modifiers.new("dec", "DECIMATE")
    dec.ratio = min(1.0, faces / max(1, len(me.polygons)))
    dec.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=dec.name)
    _push_onto_hair(head, hair)
    # Smooth inside each plane, hard edges at the jaw, nose and brow: angular, not faceted noise.
    head.data.shade_smooth()
    head.data.set_sharp_from_angle(angle=math.radians(HEAD_SHARP_DEG))

    # Unwrap (angular facets, no overlaps); the UV map name must match the mannequin's so the
    # join keeps it.
    head.data.uv_layers.new(name=mesh.data.uv_layers.active.name)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Skin weights from the nearest mannequin surface (head bone above the neck, spine blend).
    dt = head.modifiers.new("weights", "DATA_TRANSFER")
    dt.object = mesh
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    dt.layers_vgroup_select_src = "ALL"
    dt.layers_vgroup_select_dst = "NAME"
    bpy.ops.object.datalayout_transfer(modifier=dt.name)
    bpy.ops.object.modifier_apply(modifier=dt.name)

    attr = head.data.attributes.new(HEAD_ATTR, "INT", "FACE")
    for d in attr.data:
        d.value = 1

    # Remove the mannequin head, then merge the new one into the skinned mesh.
    mw = mesh.matrix_world
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    gone = [f for f in bm.faces if (mw @ f.calc_center_median()).z > MQ_HEAD_CUT_Z
            and abs((mw @ f.calc_center_median()).x) < 0.15]
    bmesh.ops.delete(bm, geom=gone, context="FACES")
    bm.to_mesh(mesh.data)
    bm.free()
    # The head is in world space; join() converts it into the mannequin's local space.
    bpy.ops.object.select_all(action="DESELECT")
    head.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.join()
    print(f"[make_psx_character] head: {len(me.polygons)} faces")


def _select_only(obj) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def _push_onto_hair(head, hair) -> None:
    """Move scalp vertices out to the hair surface, so the hairstyle has volume."""
    dg = bpy.context.evaluated_depsgraph_get()
    bm = bmesh.new()
    bm.from_object(hair, dg)
    bm.transform(hair.matrix_world)
    tree = BVHTree.FromBMesh(bm)
    bm.free()
    me = head.data
    me.update()
    push = {}
    for v in me.vertices:
        if v.co.z < HAIR_MIN_Z:
            continue
        n = v.normal
        if n.z < -0.2:
            continue
        hit = tree.ray_cast(v.co + n * HAIR_MAX_PUSH, -n, HAIR_MAX_PUSH)
        if hit[0] is not None:
            push[v.index] = max(0.0, HAIR_MAX_PUSH - hit[3]) + 0.002
    # One smoothing pass so the hair shell has no single-vertex spikes.
    adj = {v.index: [] for v in me.vertices}
    for e in me.edges:
        a, b = e.vertices
        adj[a].append(b)
        adj[b].append(a)
    smooth = {}
    for i in push:
        vals = [push.get(j, 0.0) for j in adj[i]] + [push[i]] * 2
        smooth[i] = sum(vals) / len(vals)
    for i, d in smooth.items():
        me.vertices[i].co += me.vertices[i].normal * d


# ---------------------------------------------------------------- bakes

def _bake_setup() -> None:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 4
    scene.cycles.device = "CPU"
    scene.render.bake.margin = BAKE_MARGIN


def _target_material(img, name: str):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    t = mat.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = img
    mat.node_tree.nodes.active = t
    return mat


def _rest_pos_nodes(mesh, N):
    pos_attr = mesh.data.color_attributes.get("rest_pos")
    if pos_attr is None:
        pos_attr = mesh.data.color_attributes.new("rest_pos", "FLOAT_COLOR", "POINT")
        for i, vert in enumerate(mesh.data.vertices):
            co = mesh.matrix_world @ vert.co
            # Offset keeps values positive (colour attributes may clamp negatives).
            pos_attr.data[i].color = (co.x + POS_OFFSET, co.y + POS_OFFSET, co.z + POS_OFFSET, 1.0)
    attr = N.new("ShaderNodeAttribute", attribute_name="rest_pos")
    unoff = N.new("ShaderNodeVectorMath", operation="SUBTRACT")
    N.link(attr.outputs["Vector"], unoff.inputs[0])
    unoff.inputs[1].default_value = (POS_OFFSET,) * 3
    sep = N.new("ShaderNodeSeparateXYZ")
    N.link(unoff.outputs[0], sep.inputs[0])
    return unoff.outputs[0], sep.outputs


def _bake_active(mesh, mat) -> None:
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.bake(type="EMIT")


def bake_body(mesh, v: dict, skin: tuple, size: int):
    """Clothes and skin painted by rest position (seamless across UV islands)."""
    img = bpy.data.images.new("npc_body", size, size)
    mat = bpy.data.materials.new("npc_body_bake")
    mat.use_nodes = True
    N = mc.Nodes(mat.node_tree)
    N.n.clear()
    pos, (x, y, z) = _rest_pos_nodes(mesh, N)
    ax = N.math("ABSOLUTE", x)
    lt = lambda a, b: N.math("LESS_THAN", a, b)
    gt = lambda a, b: N.math("GREATER_THAN", a, b)
    mul = lambda a, b: N.math("MULTIPLY", a, b)

    col = N.noisy(pos, skin, 40.0, 0.06)
    on_torso = mul(gt(z, TROUSER_TOP), lt(z, NECK_Z))
    on_arm = mul(gt(z, ARM_BAND[0]), lt(z, ARM_BAND[1]))
    sleeve = mul(on_arm, mul(gt(ax, 0.17), lt(ax, v["sleeve_x"])))
    torso = mul(on_torso, lt(ax, 0.2))
    top_mask = N.math("MAXIMUM", torso, sleeve)
    top_col = N.fabric(pos, v["top"])
    if v["inner_strip_x"] > 0.0:
        inner = mul(lt(ax, v["inner_strip_x"]), lt(y, -0.02))
        top_col = N.mix(inner, top_col, N.noisy(pos, v["inner"], 80.0, 0.15))
    if v["tie"]:
        vwidth = N.math("MULTIPLY", N.math("SUBTRACT", z, 1.27), 0.45)
        vmask = mul(mul(lt(ax, vwidth), lt(y, -0.02)), gt(z, 1.27))
        top_col = N.mix(vmask, top_col, N.noisy(pos, v["inner"], 80.0, 0.1))
        tie = mul(mul(lt(ax, 0.018), lt(y, -0.02)), gt(z, 1.17))
        top_col = N.mix(tie, top_col, (0.05, 0.03, 0.03))
    col = N.mix(top_mask, col, top_col)
    trousers = mul(lt(z, TROUSER_TOP), gt(z, SHOE_TOP))
    col = N.mix(trousers, col, N.fabric(pos, v["trousers"]))
    col = N.mix(lt(z, SHOE_TOP), col, N.fabric(pos, SHOES))

    emit = N.new("ShaderNodeEmission")
    N.link(col, emit.inputs[0])
    out = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], out.inputs["Surface"])
    target = N.new("ShaderNodeTexImage", image=img)
    N.n.active = target
    _bake_active(mesh, mat)
    return img


def bake_head(mesh, sources: list, skin: tuple, size: int):
    """Transfer the MPFB head colour onto the mannequin head (rays cast inward from just
    outside the mannequin surface). Misses keep the skin colour the image was cleared to."""
    img = bpy.data.images.new("npc_head", size, size)
    img.generated_color = (*skin, 1.0)
    mesh.data.materials.clear()
    mesh.data.materials.append(_target_material(img, "npc_head_bake"))
    bpy.ops.object.select_all(action="DESELECT")
    for o in sources:
        o.hide_render = False
        o.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.bake(type="EMIT", use_selected_to_active=True, cage_extrusion=0.05,
                        max_ray_distance=0.15, use_clear=False)
    return img


# ---------------------------------------------------------------- face photo

FACES_DIR = os.path.join(ROOT, "assets", "models", "characters", "source", "faces")


def face_photo_path(variant: str, arg: str) -> str:
    if arg == "none":
        return ""
    if arg:
        return os.path.abspath(arg)
    path = os.path.join(FACES_DIR, f"{variant}_front.png")
    return path if os.path.exists(path) else ""


def _load_landmarks(variant: str, photo: str, path: str = "") -> dict:
    with open(path or os.path.join(FACES_DIR, "landmarks.json")) as f:
        data = json.load(f)
    lm = data.get(variant) or data.get(os.path.basename(photo))
    if lm is None:
        raise RuntimeError(f"landmarks.json has no entry for '{variant}'")
    return lm


def _mesh_face_points(base, eyes) -> dict:
    """Eye centres (from the MPFB eye meshes) and mouth slit height (deepest point of the lip
    profile below the nose tip) on the aligned MPFB head, in world space."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = eyes.evaluated_get(dg)
    me = ev.to_mesh()
    pts = [eyes.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    left = [p for p in pts if p.x < 0.0]
    right = [p for p in pts if p.x >= 0.0]
    eye_l = sum(left, Vector()) / len(left)          # image-left eye = person's right = -x
    eye_r = sum(right, Vector()) / len(right)
    ev = base.evaluated_get(dg)
    me = ev.to_mesh()
    prof = [base.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    eye_z = (eye_l.z + eye_r.z) * 0.5
    prof = [p for p in prof if abs(p.x) < 0.006 and eye_z - 0.16 < p.z < eye_z and p.y < 0.0]
    nose = min(prof, key=lambda p: p.y)
    band = [p for p in prof if nose.z - 0.05 < p.z < nose.z - 0.022]
    mouth_z = max(band, key=lambda p: p.y).z if band else nose.z - 0.035
    return {"eye_l": eye_l, "eye_r": eye_r, "mouth_z": mouth_z}


def _photo_average(img, centre: tuple, radius: float) -> tuple:
    w, h = img.size
    cx, cy, r = int(centre[0]), int(h - 1 - centre[1]), max(1, int(radius))
    x0, x1, y0, y1 = max(0, cx - r), min(w, cx + r), max(0, cy - r), min(h, cy + r)
    return _average_opaque(img, (x0, y0, x1, y1))


def bake_face_photo(mesh, base, eyes, head_img, skin: tuple, photo: str, lm: dict, size: int,
                    hair=None):
    """Project a straight-on face photo onto the head (orthographic, from the front), aligned by
    the eyes and mouth, and blend it over the MPFB head colour. Sides and back keep the MPFB
    colour, tinted towards the photo's skin tone so there is no seam."""
    img = bpy.data.images.load(photo, check_existing=True)
    w, h = img.size
    pt = lambda k: (lm[k][0] / w, 1.0 - lm[k][1] / h)       # pixels (top-left) -> uv (bottom-left)
    mp = _mesh_face_points(base, eyes)

    # Similarity transform mesh (x, z) -> photo (u, v) from the two eyes (complex-number form).
    p1, p2 = complex(mp["eye_l"].x, mp["eye_l"].z), complex(mp["eye_r"].x, mp["eye_r"].z)
    q1, q2 = complex(*pt("eye_left")), complex(*pt("eye_right"))
    a = (q2 - q1) / (p2 - p1)
    b = q1 - a * p1
    # Vertical stretch about the eye line so the mouth lands on the mouth.
    eye_z = (mp["eye_l"].z + mp["eye_r"].z) * 0.5
    eye_v = (q1.imag + q2.imag) * 0.5
    photo_dist = (eye_v - pt("mouth")[1]) / abs(a)
    k = max(0.8, min(1.25, photo_dist / max(1e-4, eye_z - mp["mouth_z"])))
    k *= lm.get("vertical_scale", 1.0)

    # Face oval (photo uv): hairline to chin, a bit wider than the eyes.
    eye_d = abs(q2 - q1)
    cy = (pt("hairline")[1] + pt("chin")[1]) * 0.5
    ry = abs(pt("hairline")[1] - pt("chin")[1]) * 0.5 * lm.get("oval_scale", 1.05)
    cx = (q1.real + q2.real) * 0.5
    rx = eye_d * 1.05 * lm.get("oval_scale", 1.05)

    # Skin tone match: cheek patches just below each eye.
    cheeks = []
    for key in ("eye_left", "eye_right"):
        ex, ey = lm[key]
        cheeks.append(_photo_average(img, (ex, ey + eye_d * w * 0.45), eye_d * w * 0.12))
    photo_skin = tuple((cheeks[0][i] + cheeks[1][i]) * 0.5 for i in range(3))
    gain = tuple(max(0.5, min(2.0, photo_skin[i] / max(1e-4, skin[i])))
                 for i in range(3))
    # Hair colour match: photo hair just above the hairline vs the MPFB hair texture.
    hair_gain = gain
    if hair is not None:
        hx, hy = lm["hairline"]
        photo_hair = _photo_average(img, (hx, hy - eye_d * w * 0.35), eye_d * w * 0.15)
        hair_img = next((n.image for sl in hair.material_slots if sl.material
                         for n in sl.material.node_tree.nodes
                         if n.type == "TEX_IMAGE" and n.image), None)
        if hair_img is not None:
            mpfb_hair = _average_opaque(hair_img)
            hair_gain = tuple(max(0.2, min(1.6, photo_hair[i] / max(1e-4, mpfb_hair[i])))
                              for i in range(3))

    out = bpy.data.images.new("npc_head_photo", size, size)
    mat = bpy.data.materials.new("npc_face_photo")
    mat.use_nodes = True
    N = mc.Nodes(mat.node_tree)
    N.n.clear()
    _pos, (x, _y, z) = _rest_pos_nodes(mesh, N)
    m = lambda op, p, q=None: N.math(op, p, q)
    zk = m("ADD", m("MULTIPLY", m("SUBTRACT", z, eye_z), k), eye_z)
    u = m("ADD", m("SUBTRACT", m("MULTIPLY", x, a.real), m("MULTIPLY", zk, a.imag)), b.real)
    v = m("ADD", m("ADD", m("MULTIPLY", x, a.imag), m("MULTIPLY", zk, a.real)), b.imag)
    uvv = N.new("ShaderNodeCombineXYZ")
    N.link(u, uvv.inputs[0])
    N.link(v, uvv.inputs[1])
    tp = N.new("ShaderNodeTexImage", image=img, extension="EXTEND")
    N.link(uvv.outputs[0], tp.inputs[0])
    # Facing the camera: rest-pose normal . -Y
    geo = N.new("ShaderNodeNewGeometry")
    sep_n = N.new("ShaderNodeSeparateXYZ")
    N.link(geo.outputs["Normal"], sep_n.inputs[0])
    facing = N.new("ShaderNodeMapRange")
    facing.interpolation_type = "SMOOTHSTEP"
    N.link(m("MULTIPLY", sep_n.outputs[1], -1.0), facing.inputs["Value"])
    # Low thresholds: the sides of the nose wedge face mostly sideways but must show the photo.
    facing.inputs["From Min"].default_value = 0.0
    facing.inputs["From Max"].default_value = 0.3
    # Oval: ((u-cx)/rx)^2 + ((v-cy)/ry)^2 < 1, soft edge
    du = m("DIVIDE", m("SUBTRACT", u, cx), rx)
    dv = m("DIVIDE", m("SUBTRACT", v, cy), ry)
    d = m("ADD", m("MULTIPLY", du, du), m("MULTIPLY", dv, dv))
    oval = N.new("ShaderNodeMapRange")
    oval.interpolation_type = "SMOOTHSTEP"
    N.link(d, oval.inputs["Value"])
    oval.inputs["From Min"].default_value = 1.0
    oval.inputs["From Max"].default_value = 0.6
    weight = m("MULTIPLY", facing.outputs[0], oval.outputs[0])
    # Only the head (the collar/body keep their colour).
    weight = m("MULTIPLY", weight, m("GREATER_THAN", z, NECK_Z))

    uvn = N.new("ShaderNodeUVMap")
    th = N.new("ShaderNodeTexImage", image=head_img, interpolation="Closest")
    N.link(uvn.outputs[0], th.inputs[0])
    # Dark texels of the MPFB bake are hair: tint them with hair_gain, the rest with gain.
    lum_skin = sum(skin) / 3.0
    bw = N.new("ShaderNodeRGBToBW")
    N.link(th.outputs["Color"], bw.inputs[0])
    is_hair = N.new("ShaderNodeMapRange")
    is_hair.interpolation_type = "SMOOTHSTEP"
    N.link(bw.outputs[0], is_hair.inputs["Value"])
    is_hair.inputs["From Min"].default_value = lum_skin * 0.6
    is_hair.inputs["From Max"].default_value = lum_skin * 0.35
    base_col = N.mix(is_hair.outputs[0], N.mul_col(th.outputs["Color"], gain),
                     N.mul_col(th.outputs["Color"], hair_gain))
    col = N.mix(weight, base_col, tp.outputs["Color"])
    emit = N.new("ShaderNodeEmission")
    N.link(col, emit.inputs[0])
    outn = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], outn.inputs["Surface"])
    target = N.new("ShaderNodeTexImage", image=out)
    N.n.active = target
    _bake_active(mesh, mat)
    print(f"[make_psx_character] face photo {os.path.basename(photo)}: vertical k {k:.2f}, "
          f"skin gain {tuple(round(g, 2) for g in gain)}, "
          f"hair gain {tuple(round(g, 2) for g in hair_gain)}")
    return out


def composite(mesh, body_img, head_img, size: int):
    """Head colour above the collar, body colour below, blended over 2 cm."""
    img = bpy.data.images.new("npc_albedo", size, size)
    mat = bpy.data.materials.new("npc_composite")
    mat.use_nodes = True
    N = mc.Nodes(mat.node_tree)
    N.n.clear()
    _pos, (_x, _y, z) = _rest_pos_nodes(mesh, N)
    uv = N.new("ShaderNodeUVMap")
    tb = N.new("ShaderNodeTexImage", image=body_img, interpolation="Closest")
    th = N.new("ShaderNodeTexImage", image=head_img, interpolation="Closest")
    N.link(uv.outputs[0], tb.inputs[0])
    N.link(uv.outputs[0], th.inputs[0])
    ramp = N.new("ShaderNodeMapRange")
    ramp.inputs["From Min"].default_value = NECK_Z
    ramp.inputs["From Max"].default_value = NECK_Z + 0.02
    N.link(z, ramp.inputs["Value"])
    col = N.mix(ramp.outputs[0], tb.outputs["Color"], th.outputs["Color"])
    emit = N.new("ShaderNodeEmission")
    N.link(col, emit.inputs[0])
    out = N.new("ShaderNodeOutputMaterial")
    N.link(emit.outputs[0], out.inputs["Surface"])
    target = N.new("ShaderNodeTexImage", image=img)
    N.n.active = target
    _bake_active(mesh, mat)

    final = bpy.data.materials.new("npc_body")
    final.use_nodes = True
    bsdf = final.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    t = final.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = img
    final.node_tree.links.new(t.outputs[0], bsdf.inputs["Base Color"])
    mesh.data.materials.clear()
    mesh.data.materials.append(final)
    img.pack()


# ---------------------------------------------------------------- output

def export_glb(rig, mesh, path: str) -> None:
    # Leftover vertex colours would tint the texture in Godot (used as albedo on import).
    for ca in list(mesh.data.color_attributes):
        mesh.data.color_attributes.remove(ca)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.context.scene.render.fps = 30
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_animation_mode="ACTIONS",
        export_apply=False,
    )


def main() -> None:
    args = parse_args()
    v = PSX[args.variant]
    use_mannequin(v.get("mannequin", "man"))
    rig, mesh = load_mannequin()
    sources, skin, base = build_head_source(args.variant, v)
    build_angular_head(rig, mesh, base, sources[2], args.head_faces)
    new_uvs(mesh)
    _bake_setup()
    body_img = bake_body(mesh, v, skin, args.tex)
    head_img = bake_head(mesh, sources, skin, args.tex)
    photo = face_photo_path(args.variant, args.face)
    if photo:
        head_img = bake_face_photo(mesh, base, sources[1], head_img, skin, photo,
                                   _load_landmarks(args.variant, photo, args.landmarks), args.tex)
    composite(mesh, body_img, head_img, args.tex)
    for o in sources:
        o.hide_render = True
    for o in list(bpy.data.objects):
        if o not in (rig, mesh):
            o.hide_render = True
    if args.preview:
        rig.animation_data.action = bpy.data.actions["idle"]
        bpy.context.scene.frame_set(10)
        mc.render_preview(args.preview)
        rig.animation_data.action = None
    if args.out:
        export_glb(rig, mesh, os.path.abspath(args.out))
    print(f"[make_psx_character] {args.variant}: actions {len(bpy.data.actions)}, "
          f"skin {tuple(round(c, 2) for c in skin)}")


if __name__ == "__main__":
    main()
