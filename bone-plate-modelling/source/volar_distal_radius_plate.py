# Volar Distal Radius Fixation Plate - V3
# FreeCAD Macro (Python)
# Creates a parametric plate with correct geometry and features.
# Units: mm
#
# How to use:
#   1. Open FreeCAD.
#   2. Go to Macro -> Macros...
#   3. Create a new macro, paste this code, save (e.g. plate_v3.FCMacro).
#   4. Run the macro; the model is generated in the FreeCAD tree.

import FreeCAD as App
import FreeCADGui as Gui
import Part
import math

DOC_NAME = "Volar_Distal_Radius_Plate_V3"

# Close document if it already exists
try:
    App.closeDocument(DOC_NAME)
except Exception:
    pass

doc = App.newDocument(DOC_NAME)

# === PARAMETERS (mm) ===
L        = 58.0   # overall length
W_dist   = 24.0   # distal width
W_shaft  = 10.0   # shaft width
t        = 2.5    # thickness
fillet_r = 1.0    # edge fillet radius
hole_d   = 3.5    # through-hole diameter
cs_d     = 6.0    # countersink diameter
cs_depth = 1.0    # countersink depth
slot_w   = 3.5    # slot width
slot_l   = 8.0    # slot length


# === HELPER FUNCTIONS ===
def V(x, y, z=0):
    return App.Vector(x, y, z)


def make_countersunk_hole(x, y, dia=hole_d, cs_dia=cs_d, cs_depth=cs_depth):
    """A through hole with a conical countersink on the top face."""
    hole = Part.makeCylinder(dia / 2, t + 2, V(x, y, -1))
    cs = Part.makeCone(cs_dia / 2, dia / 2, cs_depth, V(x, y, t - cs_depth), V(0, 0, 1))
    return hole.fuse(cs)


def make_slot(x, y, length=slot_l, width=slot_w):
    """A rounded slot (obround) through the thickness."""
    straight = length - width
    box = Part.makeBox(width, straight, t + 2, V(x - width / 2, y - straight / 2, -1))
    top = Part.makeCylinder(width / 2, t + 2, V(x, y + straight / 2, -1))
    bottom = Part.makeCylinder(width / 2, t + 2, V(x, y - straight / 2, -1))
    return box.fuse(top).fuse(bottom)


def make_slot_countersunk(x, y, length=slot_l, width=slot_w):
    """A slot with a countersink profile (width + 2 mm at the top face)."""
    return make_slot(x, y, length, width + 2.0)


# === 1. CREATE SYMMETRIC OUTLINE ===
# Half-profile (right side), then mirror for symmetry.
half_pts = [
    V(0, 0),
    V(W_shaft / 2, 0),
    V(W_shaft / 2, 34),
    V(W_shaft / 2 + 2, 38),
    V(W_dist / 2, 44),
    V(W_dist / 2, 54),
    V(W_dist / 2 - 3, 58),
    V(0, 58),
]

# Mirror the half-profile across the Y axis to build the full closed outline.
full_pts = list(half_pts)
for pnt in reversed(half_pts[1:-1]):
    full_pts.append(V(-pnt.x, pnt.y))
full_pts.append(half_pts[0])

wire = Part.makePolygon(full_pts)
face = Part.Face(wire)
plate = face.extrude(V(0, 0, t))

# === 2. FEATURES: DISTAL HOLE CLUSTER (T-head) ===
# Countersunk locking holes arranged across the broad distal head.
distal_holes = [
    (-8, 52), (0, 52), (8, 52),      # top row
    (-6, 46), (6, 46),               # middle pair
    (-8, 40), (0, 40), (8, 40),      # lower row
]
for (hx, hy) in distal_holes:
    plate = plate.cut(make_countersunk_hole(hx, hy))

# === 3. FEATURES: SHAFT SLOTS AND HOLES ===
plate = plate.cut(make_slot(0, 26))                    # upper compression slot
plate = plate.cut(make_countersunk_hole(0, 18))        # mid shaft hole
plate = plate.cut(make_slot(0, 12))                    # lower compression slot
plate = plate.cut(make_countersunk_hole(0, 4))         # distal-most shaft hole

# === 4. EDGE FILLETS ===
# Fillet all edges to R1.0 for a low-profile, atraumatic plate.
try:
    edges = plate.Edges
    plate = plate.makeFillet(fillet_r, edges)
except Exception as e:
    App.Console.PrintWarning("Fillet step skipped: {}\n".format(e))

# === 5. ADD TO DOCUMENT ===
obj = doc.addObject("Part::Feature", "VolarDistalRadiusPlate")
obj.Shape = plate
doc.recompute()

try:
    Gui.ActiveDocument.ActiveView.viewIsometric()
    Gui.SendMsgToActiveView("ViewFit")
except Exception:
    pass

App.Console.PrintMessage("Volar distal radius plate V3 generated.\n")
