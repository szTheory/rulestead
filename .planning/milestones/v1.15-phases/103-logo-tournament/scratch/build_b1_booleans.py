#!/usr/bin/env python3
"""Scratch helper (Phase 103, Axis B): compute band-over-R intersection pieces
for b1 interleaved strata occlusion. Throwaway tooling, not a deliverable.

Coordinate space: final SVG units (em=64, baseline y=64). The R glyph path is
in font units (UPM=1000) with transform X=0.064x, Y=64-0.064y applied here.
"""
import pathops
from fontTools.svgLib.path import parse_path
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.misc.transform import Transform

R_D = ("M82 0V736H246V0ZM525 0 311 314H491L715 0ZM202 234V363H382Q418 363 "
       "444.5 377.5Q471 392 485.5 418.5Q500 445 500 480Q500 515 485.5 541.5"
       "Q471 568 444.5 582.5Q418 597 382 597H202V736H369Q460 736 527.0 708.5"
       "Q594 681 630.0 627.0Q666 573 666 491V475Q666 394 629.5 340.5Q593 287 "
       "526.5 260.5Q460 234 369 234Z")

def glyph_path():
    p = pathops.Path()
    # font units -> SVG units: scale 0.064, flip y around baseline 64
    t = Transform(0.064, 0, 0, -0.064, 0.0, 64.0)
    parse_path(R_D, TransformPen(p.getPen(), t))
    p.simplify()  # resolve self-overlapping bowl winding
    return p

def rect(x0, y0, x1, y1):
    p = pathops.Path()
    pen = p.getPen()
    pen.moveTo((x0, y0)); pen.lineTo((x1, y0)); pen.lineTo((x1, y1))
    pen.lineTo((x0, y1)); pen.closePath()
    return p

def d_of(p):
    pen = SVGPathPen(None)
    p.draw(pen)
    return pen.getCommands()

R = glyph_path()

# bands: (name, y0, y1, front_window_x0, front_window_x1)
BANDS = [
    ("mid stead  y31-37  front=stem", 31.0, 37.0,  4.0, 17.0),
    ("low copper y50-56  front=leg",  50.0, 56.0, 22.0, 42.0),
]

for name, y0, y1, wx0, wx1 in BANDS:
    band = rect(-40, y0, 60, y1)          # generous; real band drawn in SVG
    inter = pathops.op(band, R, pathops.PathOp.INTERSECTION)
    window = rect(wx0, y0 - 0.2, wx1, y1 + 0.2)
    front = pathops.op(inter, window, pathops.PathOp.INTERSECTION)
    print(f"<!-- band {name} : front piece -->")
    print(f'<path d="{d_of(front)}"/>')
    print()
