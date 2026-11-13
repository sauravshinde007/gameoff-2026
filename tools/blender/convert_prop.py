"""Convert a downloaded prop FBX into a game-ready GLB.

Imports the FBX, applies all transforms, joins the meshes, scales the longest side to --size
metres, puts the origin at the bottom centre, and exports GLB (Y up, textures embedded).

Usage:
  blender -b -P tools/blender/convert_prop.py -- --in source.fbx --out prop.glb --size 0.25
         [--rot-z 180] [--axis x|y|z]   (--axis: which side --size applies to; default longest)
         [--tex MATERIAL=texture.png ...]  (FBX texture paths are usually broken: assign by hand)
"""
import argparse
import sys

import bpy
from mathutils import Matrix, Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--in", dest="src", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--size", type=float, default=0.0, help="metres; 0 = keep the FBX size")
    p.add_argument("--axis", default="", choices=["", "x", "y", "z"])
    p.add_argument("--tex", action="append", default=[], metavar="MATERIAL=FILE")
    p.add_argument("--rot-z", type=float, default=0.0, help="degrees about Blender Z (up)")
    return p.parse_args(argv)


def main() -> None:
    a = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=a.src)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in bpy.data.objects:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = meshes[0]
    for o in meshes:
        o.parent = None
        o.matrix_world = o.matrix_world.copy()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    for o in [o for o in bpy.data.objects if o is not obj]:
        bpy.data.objects.remove(o, do_unlink=True)
    if a.rot_z:
        obj.rotation_euler.z = a.rot_z * 3.14159265 / 180.0
        bpy.ops.object.transform_apply(rotation=True)
    vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
    mn = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    mx = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    dims = mx - mn
    if a.size > 0.0:
        ref = {"x": dims.x, "y": dims.y, "z": dims.z}.get(a.axis, max(dims))
        k = a.size / ref
        obj.scale = (k, k, k)
        bpy.ops.object.transform_apply(scale=True)
        vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
        mn = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
        mx = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    obj.location = Vector((-(mn.x + mx.x) * 0.5, -(mn.y + mx.y) * 0.5, -mn.z))
    bpy.ops.object.transform_apply(location=True)
    textures = dict(t.split("=", 1) for t in a.tex)
    for slot in obj.material_slots:
        mat = slot.material
        if mat is None or mat.name not in textures:
            continue
        mat.use_nodes = True
        nt = mat.node_tree
        for n in [n for n in nt.nodes if n.type == "TEX_IMAGE"]:
            nt.nodes.remove(n)
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(textures[mat.name])
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 1.0
        bsdf.inputs["Emission Strength"].default_value = 0.0
    bpy.ops.export_scene.gltf(filepath=a.out, export_format="GLB", use_selection=False,
                              export_apply=False, export_yup=True)
    print("[convert_prop] dims (m):", tuple(round(x, 3) for x in (mx - mn)), "->", a.out)


main()
