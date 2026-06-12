#!/usr/bin/env python3
"""
build_candidates.py — Axis C (pure custom typemarks on Sora) candidate builder.

THROWAWAY Phase 103 scratch tooling. Reads glyphs-sora700-t020.txt (Sora Bold 700,
em=64, tracking -0.02, one <path> per glyph) and performs glyph surgery via
skia-pathops booleans, emitting:

  candidates/c1.svg — THE FORKED R   (counter recut as forked-route negative space)
  candidates/c2.svg — THE st BEAM    (s-t ligature; t crossbar extends left as a lintel beam)
  candidates/c3.svg — THE LIT TERMINAL (d ascender steps into a copper status node)

All surgery happens in per-glyph FONT UNITS (UPM 1000, y-up); glyph transforms
translate(tx,64) scale(0.064,-0.064) are preserved in the output SVGs.
"""

import re
import sys
import pathops
from fontTools.svgLib.path import parse_path
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = "/Users/jon/projects/rulestead/.planning/phases/103-logo-tournament"
GLYPH_DUMP = f"{HERE}/scratch/glyphs-sora700-t020.txt"
OUT_DIR = f"{HERE}/candidates"

INK = "#183247"
COPPER = "#9b5931"
SCALE = 0.064
BASELINE = 64.0

# ---------------------------------------------------------------- glyph parsing

def load_glyphs():
    """Return list of dicts {char, tx, d} in document order."""
    text = open(GLYPH_DUMP).read()
    glyphs = []
    pattern = re.compile(
        r'<!-- glyph: (.) -->\s*<path transform="translate\(([\d.]+),64\.000\) '
        r'scale\(0\.064000,-0\.064000\)" d="([^"]+)"/>')
    for m in pattern.finditer(text):
        glyphs.append({"char": m.group(1), "tx": float(m.group(2)), "d": m.group(3)})
    assert len(glyphs) == 9, f"expected 9 glyphs, got {len(glyphs)}"
    return glyphs

def d_to_path(d, dx=0.0):
    """SVG path data (font units) -> pathops.Path, optionally x-shifted."""
    p = pathops.Path()
    pen = p.getPen()
    if dx:
        pen = TransformPen(pen, (1, 0, 0, 1, dx, 0))
    parse_path(d, pen)
    return p

def path_to_d(p):
    pen = SVGPathPen(None)
    p.draw(pen)
    return pen.getCommands()

def poly(points):
    p = pathops.Path()
    pen = p.getPen()
    pen.moveTo(points[0])
    for pt in points[1:]:
        pen.lineTo(pt)
    pen.closePath()
    return p

def rect(x0, y0, x1, y1):
    return poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])

def union(*paths):
    out = paths[0]
    for p in paths[1:]:
        out = pathops.op(out, p, pathops.PathOp.UNION, fix_winding=True)
    return out

def difference(a, b):
    return pathops.op(a, b, pathops.PathOp.DIFFERENCE, fix_winding=True)

def simplify(p):
    return pathops.simplify(p, fix_winding=True)

# ---------------------------------------------------------------- bbox / emit

def path_bounds_svg(p, tx):
    l, t, r, b = p.bounds  # font units, y-up
    return (tx + l * SCALE, BASELINE - b * SCALE, tx + r * SCALE, BASELINE - t * SCALE)

def emit_svg(out_name, title, desc, elements, bboxes, pad=3.0):
    """elements: list of svg element strings. bboxes: list of (x0,y0,x1,y1) svg-space."""
    x0 = min(b[0] for b in bboxes) - pad
    y0 = min(b[1] for b in bboxes) - pad
    x1 = max(b[2] for b in bboxes) + pad
    y1 = max(b[3] for b in bboxes) + pad
    w, h = x1 - x0, y1 - y0
    body = "\n  ".join(elements)
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" role="img" '
        f'viewBox="{x0:.2f} {y0:.2f} {w:.2f} {h:.2f}" '
        f'aria-labelledby="rs-title rs-desc">\n'
        f'  <title id="rs-title">{title}</title>\n'
        f'  <desc id="rs-desc">{desc}</desc>\n'
        f'  {body}\n'
        f'</svg>\n'
    )
    out = f"{OUT_DIR}/{out_name}"
    open(out, "w").write(svg)
    print(f"wrote {out}  viewBox {x0:.1f} {y0:.1f} {w:.1f} {h:.1f}")

def glyph_el(d, tx, fill=INK):
    return (f'<path fill="{fill}" transform="translate({tx:.3f},{BASELINE:.3f}) '
            f'scale({SCALE},-{SCALE})" d="{d}"/>')

def circle_el(cx, cy, r, tx, fill=COPPER):
    return (f'<circle fill="{fill}" transform="translate({tx:.3f},{BASELINE:.3f}) '
            f'scale({SCALE},-{SCALE})" cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}"/>')

# ---------------------------------------------------------------- c1: FORKED R

# Parameters (R-local font units, y-up). Counter zone: x 246..500, y 363..597.
# v2: keep original counter; weld a left-pointing divider wedge into the inner
# wall so the counter's negative space forks into two tapering route channels.
C1 = dict(
    # Divider wedge: apex left, curved edges bowing inward (channels stay ~70 wide
    # mid-run, taper at the wall), right side welds into the inner wall.
    wedge_apex=(305, 480),
    wedge_top=((420, 512), (465, 543), (510, 572)),   # ctrl, end, weld corner
    wedge_bot=((420, 448), (465, 417), (510, 388)),   # mirror
    node=(300, 480, 24),                              # tiny copper node at the commit point
)

def c1_wedge(p):
    w = pathops.Path()
    pen = w.getPen()
    pen.moveTo(p["wedge_apex"])
    ctrl_t, end_t, weld_t = p["wedge_top"]
    ctrl_b, end_b, weld_b = p["wedge_bot"]
    pen.qCurveTo(ctrl_t, end_t)
    pen.lineTo(weld_t)
    pen.lineTo(weld_b)
    pen.lineTo(end_b)
    pen.qCurveTo(ctrl_b, p["wedge_apex"])
    pen.closePath()
    return w

def rot_rect(start, end, w):
    """Rotated rectangle (channel) from start center to end center, width w."""
    sx, sy = start
    ex, ey = end
    dx, dy = ex - sx, ey - sy
    ln = (dx * dx + dy * dy) ** 0.5
    px, py = -dy / ln * (w / 2), dx / ln * (w / 2)
    return poly([(sx + px, sy + py), (ex + px, ey + py),
                 (ex - px, ey - py), (sx - px, sy - py)])

def build_c1(glyphs):
    R = glyphs[0]
    p = C1
    r_forked = simplify(union(d_to_path(R["d"]), c1_wedge(p)))
    elements = [glyph_el(path_to_d(r_forked), R["tx"])]
    bboxes = [path_bounds_svg(r_forked, R["tx"])]
    for g in glyphs[1:]:
        elements.append(glyph_el(g["d"], g["tx"]))
        bboxes.append(path_bounds_svg(d_to_path(g["d"]), g["tx"]))
    if p["node"]:
        cx, cy, r = p["node"]
        elements.append(circle_el(cx, cy, r, R["tx"]))
    emit_svg(
        "c1.svg", "Rulestead",
        "Rulestead wordmark in Sora Bold; the counter of the R is recut so its "
        "negative space reads as a route that forks — one way in, two ways out.",
        elements, bboxes)

# ---------------------------------------------------------------- c2: st BEAM

# Parameters (t-local font units; s sits at dx = -536).
C2 = dict(
    s_dx=-536.0,
    beam_y0=431, beam_y1=548,    # same band as t crossbar -> one continuous beam
    beam_x0=-495,                # left terminus of the ink beam (t-local)
    node=(-495, 489.5, 58.5),    # copper end-cap circle (cx, cy, r), t-local
    shave_above=548,             # remove s ink poking above the beam line
)

def build_c2(glyphs):
    s, t = glyphs[4], glyphs[5]
    p = C2
    s_shift = d_to_path(s["d"], dx=p["s_dx"])
    s_shift = difference(s_shift, rect(-560, p["shave_above"], 20, 640))
    t_path = d_to_path(t["d"])
    beam = rect(p["beam_x0"], p["beam_y0"], 399, p["beam_y1"])
    st = simplify(union(s_shift, t_path, beam))
    elements, bboxes = [], []
    for i, g in enumerate(glyphs):
        if i == 4:
            continue  # s merged into the st ligature under t's transform
        if i == 5:
            elements.append(glyph_el(path_to_d(st), t["tx"]))
            bboxes.append(path_bounds_svg(st, t["tx"]))
        else:
            elements.append(glyph_el(g["d"], g["tx"]))
            bboxes.append(path_bounds_svg(d_to_path(g["d"]), g["tx"]))
    if p["node"]:
        cx, cy, r = p["node"]
        elements.append(circle_el(cx, cy, r, t["tx"]))
        bboxes.append((t["tx"] + (cx - r) * SCALE, BASELINE - (cy + r) * SCALE,
                       t["tx"] + (cx + r) * SCALE, BASELINE - (cy - r) * SCALE))
    emit_svg(
        "c2.svg", "Rulestead",
        "Rulestead wordmark in Sora Bold; the interior s and t fuse into a ligature "
        "whose crossbar extends left as a steady lintel beam ending in a copper node.",
        elements, bboxes)

# ---------------------------------------------------------------- c3: LIT TERMINAL

# Parameters (d-local font units). Stem: x 470..631, cap y=730, center x 550.5.
C3 = dict(
    cut_y=560,                    # stem truncation line (the step shoulder)
    neck=(510, 560, 591, 640),    # narrower neck rising from the step into the node
    node=(550.5, 660, 76),        # copper node (cx, cy, r); top 736, round overshoot
)

def build_c3(glyphs):
    d = glyphs[8]
    p = C3
    d_path = d_to_path(d["d"])
    clip = rect(460, p["cut_y"], 645, 800)
    d_cut = difference(d_path, clip)
    d_cut = simplify(union(d_cut, rect(*p["neck"])))
    elements, bboxes = [], []
    for i, g in enumerate(glyphs):
        if i == 8:
            elements.append(glyph_el(path_to_d(d_cut), d["tx"]))
            bboxes.append(path_bounds_svg(d_cut, d["tx"]))
        else:
            elements.append(glyph_el(g["d"], g["tx"]))
            bboxes.append(path_bounds_svg(d_to_path(g["d"]), g["tx"]))
    cx, cy, r = p["node"]
    elements.append(circle_el(cx, cy, r, d["tx"]))
    bboxes.append((d["tx"] + (cx - r) * SCALE, BASELINE - (cy + r) * SCALE,
                   d["tx"] + (cx + r) * SCALE, BASELINE - (cy - r) * SCALE))
    emit_svg(
        "c3.svg", "Rulestead",
        "Rulestead wordmark in Sora Bold; the final d ascender steps into a lit "
        "circular copper node — a status indicator integrated into the stroke.",
        elements, bboxes)

# ----------------------------------------------------------------

if __name__ == "__main__":
    glyphs = load_glyphs()
    which = sys.argv[1:] or ["c1", "c2", "c3"]
    if "c1" in which:
        build_c1(glyphs)
    if "c2" in which:
        build_c2(glyphs)
    if "c3" in which:
        build_c3(glyphs)
