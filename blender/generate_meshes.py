"""Generates every low-poly mesh for Sweet Nights Tycoon and exports them as OBJ.

Run headless from the repo root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --python blender/generate_meshes.py

Outputs:
    assets/meshes/<Name>.obj       one single-colour piece per file (Roblox tints it with the part colour)
    src/shared/MeshSizes.luau      each mesh's native size, so the game can scale it to fit its part

Every mesh is centred on the origin, Y-up and -Z forward (Roblox axes), with flat shading for the
faceted low-poly look. Re-running is safe: it rebuilds everything from scratch.
"""

import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "meshes")
MANIFEST = os.path.join(ROOT, "src", "shared", "MeshSizes.luau")


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def new_object(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = False  # faceted low-poly look
    return obj


def ico(bm, radius, subdivisions, offset=(0, 0, 0), scale=(1, 1, 1)):
    geom = bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius)
    verts = geom["verts"]
    bmesh.ops.scale(bm, vec=Vector(scale), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(offset), verts=verts)
    return verts


def cylinder(bm, radius_bottom, radius_top, depth, segments, offset=(0, 0, 0)):
    geom = bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius_bottom,
        radius2=radius_top,
        depth=depth,
    )
    bmesh.ops.translate(bm, vec=Vector(offset), verts=geom["verts"])
    return geom["verts"]


def rounded_box(bm, size, bevel, segments=2):
    geom = bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=geom["verts"])
    bmesh.ops.bevel(
        bm,
        geom=list(bm.edges),
        offset=bevel,
        segments=segments,
        affect="EDGES",
        profile=0.5,
    )


# Tools are held with their long axis pointing forward, so long meshes are laid along Y
# (which becomes Roblox Z) instead of standing up.
TO_FORWARD = Matrix.Rotation(math.radians(90), 4, "X")


def lay_along_forward(verts, bm):
    bmesh.ops.rotate(bm, cent=Vector((0, 0, 0)), matrix=TO_FORWARD.to_3x3(), verts=verts)


# --- Mesh builders (Blender space: Z up, -Y forward) -------------------------------------------


def shadow_body():
    """Soft blob with a little wisp tail trailing behind and below."""
    bm = bmesh.new()
    ico(bm, 1.0, 2, scale=(1.0, 0.95, 0.9))
    ico(bm, 0.5, 1, offset=(0, 0.55, -0.55))
    ico(bm, 0.28, 1, offset=(0, 0.95, -0.85))
    return new_object("ShadowBody", bm)


def customer_body():
    """Chunky rounded body for customers and staff."""
    bm = bmesh.new()
    rounded_box(bm, (1.0, 0.7, 1.3), 0.18)
    return new_object("CustomerBody", bm)


def chef_hat():
    bm = bmesh.new()
    cylinder(bm, 0.45, 0.5, 0.5, 10, offset=(0, 0, -0.25))
    ico(bm, 0.45, 1, offset=(0.25, 0, 0.15))
    ico(bm, 0.45, 1, offset=(-0.25, 0, 0.15))
    ico(bm, 0.5, 1, offset=(0, 0, 0.3))
    return new_object("ChefHat", bm)


def gumdrop():
    """Gumdrop turret head: a squat dome with sugar-crystal facets."""
    bm = bmesh.new()
    ico(bm, 1.0, 2, scale=(1.0, 1.0, 0.85))
    bmesh.ops.bisect_plane(
        bm,
        geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        plane_co=Vector((0, 0, -0.3)),
        plane_no=Vector((0, 0, 1)),
        clear_inner=True,
    )
    edges = [e for e in bm.edges if e.is_boundary]
    bmesh.ops.holes_fill(bm, edges=edges, sides=0)
    return new_object("Gumdrop", bm)


def peppermint():
    """Peppermint candy disc (cannon head)."""
    bm = bmesh.new()
    cylinder(bm, 1.0, 1.0, 0.35, 16)
    bmesh.ops.rotate(bm, cent=Vector((0, 0, 0)), matrix=Matrix.Rotation(math.radians(90), 3, "X"), verts=bm.verts)
    return new_object("Peppermint", bm)


def cotton_candy():
    """Cloud of fluff puffs (zapper head)."""
    bm = bmesh.new()
    for offset, radius in [
        ((0, 0, 0.2), 0.6),
        ((0.45, 0.1, 0), 0.45),
        ((-0.45, -0.1, 0.05), 0.45),
        ((0.1, -0.4, -0.1), 0.4),
        ((-0.1, 0.4, -0.05), 0.4),
    ]:
        ico(bm, radius, 1, offset=offset)
    return new_object("CottonCandy", bm)


def rolling_pin():
    bm = bmesh.new()
    cylinder(bm, 0.28, 0.28, 2.0, 10)
    cylinder(bm, 0.12, 0.12, 0.7, 8, offset=(0, 0, 1.35))
    cylinder(bm, 0.12, 0.12, 0.7, 8, offset=(0, 0, -1.35))
    lay_along_forward(bm.verts, bm)
    return new_object("RollingPin", bm)


def candy_cane():
    """Hooked cane built from a bevelled curve, then converted to a mesh."""
    curve = bpy.data.curves.new("CandyCaneCurve", type="CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = 0.12
    curve.bevel_resolution = 1
    spline = curve.splines.new("POLY")
    points = [(0, 0, -1.5), (0, 0, 0.8)]
    for i in range(1, 7):  # the hook
        angle = math.pi * i / 6
        points.append((0.4 - 0.4 * math.cos(angle), 0, 0.8 + 0.4 * math.sin(angle)))
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1)
    obj = bpy.data.objects.new("CandyCane", curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.view_layer.objects.active
    obj.data.transform(TO_FORWARD)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def oven():
    bm = bmesh.new()
    rounded_box(bm, (1.0, 0.6, 1.0), 0.08)
    return new_object("Oven", bm)


BUILDERS = [shadow_body, customer_body, chef_hat, gumdrop, peppermint, cotton_candy, rolling_pin, candy_cane, oven]


# --- Export -----------------------------------------------------------------------------------


def centre(obj):
    """Moves the mesh so its bounding box is centred on the origin; returns its size (Blender axes)."""
    coords = [v.co for v in obj.data.vertices]
    lo = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
    hi = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
    mid = (lo + hi) / 2
    for v in obj.data.vertices:
        v.co -= mid
    return hi - lo


def export(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.wm.obj_export(
        filepath=os.path.join(OUT_DIR, obj.name + ".obj"),
        export_selected_objects=True,
        export_materials=False,
        export_uv=False,
        export_normals=True,
        forward_axis="NEGATIVE_Z",
        up_axis="Y",
    )


def main():
    reset_scene()
    os.makedirs(OUT_DIR, exist_ok=True)
    sizes = {}
    for build in BUILDERS:
        obj = build()
        size = centre(obj)
        # Blender (x, y, z) with Z up and -Y forward becomes Roblox (x, z, y).
        sizes[obj.name] = (size.x, size.z, size.y)
        export(obj)
        print(f"exported {obj.name}: {len(obj.data.polygons)} faces")

    lines = [
        "-- Generated by blender/generate_meshes.py. Do not edit by hand.",
        "-- Native size (studs, Roblox axes) of each exported mesh, used to scale it to fit a part.",
        "",
        "return {",
    ]
    for name in sorted(sizes):
        x, y, z = sizes[name]
        lines.append(f"\t{name} = Vector3.new({x:.4f}, {y:.4f}, {z:.4f}),")
    lines.append("}")
    with open(MANIFEST, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {MANIFEST}")


main()
