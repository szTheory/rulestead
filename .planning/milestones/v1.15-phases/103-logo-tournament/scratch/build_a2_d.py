#!/usr/bin/env python3
"""Build the carved 'd' glyph for candidate a2: replace the round bowl counter
with a fork-shaped routing-junction counter via skia-pathops booleans.

Outputs an absolute-coordinate SVG path d-string (SVG units, baseline y=64).
"""
import sys, os, math
sys.path.insert(0, os.path.expanduser("~/Library/Python/3.14/lib/python/site-packages"))

import pathops
from fontTools.svgLib.path import parse_path
from fontTools.pens.transformPen import TransformPen
from fontTools.misc.transform import Transform
from fontTools.pens.svgPathPen import SVGPathPen

# d glyph: OUTER contour only (counter contour dropped — we replace it)
D_OUTER = (
    "M299 -18Q241 -18 193.5 3.0Q146 24 111.0 61.5Q76 99 57.5 150.0Q39 201 39 260"
    "V283Q39 342 56.5 393.0Q74 444 107.5 482.5Q141 521 188.0 542.5Q235 564 293 564"
    "Q359 564 407.0 535.5Q455 507 482.0 451.5Q509 396 512 315L470 354V730H631V0"
    "H504V227H526Q523 149 493.5 94.0Q464 39 414.0 10.5Q364 -18 299 -18Z"
)
# transform: translate(281.728,64) scale(0.064,-0.064)
XFORM = Transform(0.064, 0, 0, -0.064, 281.728, 64.0)

K = 0.5519150244935105  # cubic circle constant

def circle_path(cx, cy, r):
    p = pathops.Path()
    pen = p.getPen()
    k = K * r
    pen.moveTo((cx + r, cy))
    pen.curveTo((cx + r, cy + k), (cx + k, cy + r), (cx, cy + r))
    pen.curveTo((cx - k, cy + r), (cx - r, cy + k), (cx - r, cy))
    pen.curveTo((cx - r, cy - k), (cx - k, cy - r), (cx, cy - r))
    pen.curveTo((cx + k, cy - r), (cx + r, cy - k), (cx + r, cy))
    pen.closePath()
    return p

def capsule_path(p1, p2, w):
    """Stadium shape: line p1->p2 with width w, round ends (circle union rect)."""
    x1, y1 = p1; x2, y2 = p2
    dx, dy = x2 - x1, y2 - y1
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    nx, ny = -uy * w / 2, ux * w / 2
    p = pathops.Path()
    pen = p.getPen()
    pen.moveTo((x1 + nx, y1 + ny))
    pen.lineTo((x2 + nx, y2 + ny))
    pen.lineTo((x2 - nx, y2 - ny))
    pen.lineTo((x1 - nx, y1 - ny))
    pen.closePath()
    body = p
    out = pathops.op(body, circle_path(x1, y1, w / 2), pathops.PathOp.UNION)
    out = pathops.op(out, circle_path(x2, y2, w / 2), pathops.PathOp.UNION)
    return out

def union(paths):
    out = paths[0]
    for q in paths[1:]:
        out = pathops.op(out, q, pathops.PathOp.UNION)
    return out

def main():
    # --- d outer contour in SVG space ---
    outer = pathops.Path()
    parse_path(D_OUTER, TransformPen(outer.getPen(), XFORM))

    # --- fork cutout (SVG units; counter region x 294.5-312.1, y 36.4-56.6) ---
    # geometry params (tweak between iterations)
    import json
    cfg = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    w        = cfg.get("w", 4.8)          # slot width
    jx, jy   = cfg.get("j", (302.6, 46.5))  # junction
    sx       = cfg.get("sx", 296.6)       # stem start x (left)
    up_end   = cfg.get("up", (308.6, 40.4))
    dn_end   = cfg.get("dn", (308.6, 52.6))
    chamber  = cfg.get("chamber", 3.8)    # top terminal chamber radius
    node_r   = cfg.get("node", 2.1)       # copper node radius (emitted separately)

    fork = union([
        capsule_path((sx, jy), (jx, jy), w),
        capsule_path((jx, jy), tuple(up_end), w),
        capsule_path((jx, jy), tuple(dn_end), w),
        circle_path(up_end[0], up_end[1], chamber),
    ])

    carved = pathops.op(outer, fork, pathops.PathOp.DIFFERENCE)
    carved.simplify()

    spen = SVGPathPen(None, ntos=lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
    carved.draw(spen)
    print(spen.getCommands())
    print(f"<!-- copper node: cx={up_end[0]} cy={up_end[1]} r={node_r} -->", file=sys.stderr)

if __name__ == "__main__":
    main()
