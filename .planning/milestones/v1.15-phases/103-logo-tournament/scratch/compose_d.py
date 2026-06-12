#!/usr/bin/env python3
"""Axis D composer — Phase 103 Round 1 (throwaway scratch tooling).

Reads gen_glyph_paths.py segment outputs in this scratch dir, applies the
Axis D structural treatments, writes candidates/d1.svg d2.svg d3.svg and a
scratch studio HTML grid (white bg, ~480px cells + 36px row + dark strip).

Iterate by editing the PARAMS block and re-running.
"""
import re, os

SCRATCH = os.path.dirname(os.path.abspath(__file__))
CAND = os.path.normpath(os.path.join(SCRATCH, "..", "candidates"))

INK = "#183247"
INK_DARK = "#e8edf3"
COPPER = "#9b5931"
STEAD_BLUE = "#3A6F8F"
QUARRY = "#C4CCD1"

# ---------------------------------------------------------------- PARAMS
# d1 — Space Grotesk 700, R leg recut into a route-step + copper node
D1_STEP = "right"         # "left" or "right" step variant
# left step: lower leg shifts left 75u; node in right pocket
D1_LEFT_RECUT = ("562 232V0H453V217", "562 232V100H487V0H378V120H453V217")
D1_LEFT_NODE = (524, 30, 28)   # cx, cy, r in R-local font units
# right step: lower leg shifts right 75u; node in left pocket
D1_RIGHT_RECUT = ("562 232V0H453V217", "562 232V120H637V0H528V80H453V217")
D1_RIGHT_NODE = (489, 30, 30)

# d2 — Archivo weight contrast: Rule 700 + stead 500, zero extra gap
D2_STEAD_DX = 135.808     # natural advance of "Rule" 700 segment
D2_STEAD_FILL = INK       # variant: STEAD_BLUE

# d3 — Sora stepped baseline: stead drops half x-height, engineered step
# profile at the seam: short top tread + riser (Stead Blue) + copper footing.
D3_STEP = 17.5            # half Sora x-height (548u * 0.064 / 2)
D3_STEAD_DX = 144.0       # x where the stead terrace starts
D3_TREAD = (138.6, 64.0, 7.0, 1.7)    # x, y, w, h — terrace-1 floor edge
D3_RISER = (143.15, 64.0, 2.4, 14.7)  # x, y, w, h — riser (blue)
D3_FOOT = (143.15, 78.7, 2.4, 2.8)    # x, y, w, h — copper footing block

EM = 0.064


def load(fname):
    txt = open(os.path.join(SCRATCH, fname)).read()
    out = []
    pat = (r'<!-- glyph: (.) -->\s*<path transform="translate\(([-\d.]+),'
           r'64\.000\) scale\(0\.064000,-0\.064000\)" d="([^"]+)"/>')
    for m in re.finditer(pat, txt):
        out.append({"g": m.group(1), "tx": float(m.group(2)), "d": m.group(3)})
    if not out:
        raise SystemExit(f"no glyphs parsed from {fname}")
    return out


def path_pts(d):
    toks = re.findall(r"[A-Za-z]|-?\d+(?:\.\d+)?", d)
    pts, i, cmd, x, y = [], 0, None, 0.0, 0.0
    while i < len(toks):
        t = toks[i]
        if t.isalpha():
            cmd = t
            i += 1
            continue
        if cmd in ("M", "L"):
            x, y = float(toks[i]), float(toks[i + 1]); i += 2; pts.append((x, y))
        elif cmd == "H":
            x = float(toks[i]); i += 1; pts.append((x, y))
        elif cmd == "V":
            y = float(toks[i]); i += 1; pts.append((x, y))
        elif cmd == "Q":
            for _ in range(2):
                x, y = float(toks[i]), float(toks[i + 1]); i += 2; pts.append((x, y))
        else:
            i += 1
    return pts


def seg_svg_paths(glyphs, indent="  "):
    lines = []
    for g in glyphs:
        lines.append(
            f'{indent}<path transform="translate({g["tx"]:.3f},64.000) '
            f'scale(0.064000,-0.064000)" d="{g["d"]}"/>'
        )
    return "\n".join(lines)


def bounds(groups):
    """groups: list of (glyphs, gx, gy). Returns svg-space bbox."""
    xs, ys = [], []
    for glyphs, gx, gy in groups:
        for g in glyphs:
            for px, py in path_pts(g["d"]):
                xs.append(gx + g["tx"] + EM * px)
                ys.append(gy + 64 - EM * py)
    return min(xs), min(ys), max(xs), max(ys)


def svg_doc(vb, title, desc, body):
    x, y, w, h = vb
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x:.1f} {y:.1f} {w:.1f} {h:.1f}" role="img" aria-labelledby="t d">
  <title id="t">{title}</title>
  <desc id="d">{desc}</desc>
{body}
</svg>
"""


def pad_vb(b, pad=0.6):
    x0, y0, x1, y1 = b
    return (x0 - pad, y0 - pad, (x1 - x0) + 2 * pad, (y1 - y0) + 2 * pad)


# ---------------------------------------------------------------- d1
def build_d1(step=D1_STEP):
    glyphs = [dict(g) for g in load("sg700-rulestead.txt")]
    recut, node = (D1_LEFT_RECUT, D1_LEFT_NODE) if step == "left" else (
        D1_RIGHT_RECUT, D1_RIGHT_NODE)
    assert recut[0] in glyphs[0]["d"], "R leg substring not found"
    glyphs[0]["d"] = glyphs[0]["d"].replace(recut[0], recut[1])
    cx, cy, r = node
    b = bounds([(glyphs, 0, 0)])
    vb = pad_vb(b)
    body = f'  <g fill="{INK}">\n{seg_svg_paths(glyphs, "    ")}\n  </g>\n'
    body += (f'  <circle fill="{COPPER}" cx="{0 + cx * EM:.3f}" '
             f'cy="{64 - cy * EM:.3f}" r="{r * EM:.3f}"/>')
    return svg_doc(vb, "Rulestead",
                   "Rulestead wordmark in Space Grotesk Bold; the R leg is recut "
                   "into a route-step with a single copper node at the turn.",
                   body)


# ---------------------------------------------------------------- d2
def build_d2(stead_fill=D2_STEAD_FILL, stead_dx=D2_STEAD_DX):
    rule = load("archivo700-rule.txt")
    stead = load("archivo500-stead.txt")
    b = bounds([(rule, 0, 0), (stead, stead_dx, 0)])
    vb = pad_vb(b)
    body = f'  <g fill="{INK}">\n{seg_svg_paths(rule, "    ")}\n  </g>\n'
    body += (f'  <g fill="{stead_fill}" transform="translate({stead_dx:.3f},0)">\n'
             f'{seg_svg_paths(stead, "    ")}\n  </g>')
    return svg_doc(vb, "Rulestead",
                   "Rulestead wordmark in Archivo; Rule set bold, stead set medium "
                   "— the weight shift is the seam between hard logic and calm home.",
                   body)


# ---------------------------------------------------------------- d3
def build_d3(step=D3_STEP, stead_dx=D3_STEAD_DX,
             tread=D3_TREAD, riser=D3_RISER, foot=D3_FOOT):
    rule = load("sora700-rule.txt")
    stead = load("sora700-stead.txt")
    b = bounds([(rule, 0, 0), (stead, stead_dx, step)])
    vb = pad_vb(b)

    def rect(spec, fill):
        x, y, w, h = spec
        return (f'  <rect fill="{fill}" x="{x:.2f}" y="{y:.2f}" '
                f'width="{w:.2f}" height="{h:.2f}"/>\n')

    body = f'  <g fill="{INK}">\n{seg_svg_paths(rule, "    ")}\n  </g>\n'
    if tread:
        body += rect(tread, STEAD_BLUE)
    body += rect(riser, STEAD_BLUE)
    if foot:
        body += rect(foot, COPPER)
    body += (f'  <g fill="{INK}" transform="translate({stead_dx:.3f},{step:.2f})">\n'
             f'{seg_svg_paths(stead, "    ")}\n  </g>')
    return svg_doc(vb, "Rulestead",
                   "Rulestead wordmark in Sora Bold; stead steps down half an "
                   "x-height onto a lower terrace, joined by a thin Stead Blue riser.",
                   body)


# ---------------------------------------------------------------- studio
CELL = """
<div class="card {tone}">
  <p class="lab">{label}</p>
  <div class="row main">{svg480}</div>
  <div class="row small"><span class="cap">36px row</span>{svg36}</div>
</div>
"""

PAGE = """<!doctype html><html><head><meta charset="utf-8">
<title>103 Axis D scratch</title>
<style>
 body {{ margin:0; background:#ffffff; font-family: system-ui, sans-serif; color:#1a2332; }}
 .wrap {{ max-width:1180px; margin:0 auto; padding:28px; }}
 h1 {{ font-size:1.1rem; margin:0 0 18px; }}
 .grid {{ display:grid; grid-template-columns:1fr 1fr; gap:16px; }}
 .card {{ border:1px solid rgba(0,0,0,.14); border-radius:10px; padding:18px 20px; }}
 .card.dark {{ background:#10161f; color:#dfe6ee; border-color:rgba(255,255,255,.12); }}
 .lab {{ font-size:.68rem; text-transform:uppercase; letter-spacing:.07em; opacity:.55; margin:0 0 12px; }}
 .row.main svg {{ width:480px; height:auto; display:block; }}
 .row.small {{ margin-top:14px; padding-top:10px; border-top:1px solid rgba(0,0,0,.1); display:flex; align-items:center; gap:14px; }}
 .card.dark .row.small {{ border-top-color:rgba(255,255,255,.12); }}
 .row.small svg {{ height:11px; width:auto; display:block; }}
 .cap {{ font-size:.62rem; font-family:monospace; opacity:.5; }}
 .zoom {{ width:480px; overflow:hidden; }}
 .zoom svg {{ width:1500px !important; height:auto; }}
</style></head><body><div class="wrap">
<h1>Phase 103 — Axis D scratch ({stamp})</h1>
<div class="grid">
{cells}
</div></div></body></html>
"""


def cell(label, svg, tone="light"):
    dark_svg = svg.replace(INK, INK_DARK) if tone == "dark" else svg
    return CELL.format(tone=tone, label=label, svg480=dark_svg, svg36=dark_svg)


def zoom_cell(label, svg, shift=0):
    return (f'<div class="card light"><p class="lab">{label}</p>'
            f'<div class="zoom"><div style="margin-left:-{shift}px">{svg}</div>'
            f'</div></div>')


def main():
    import datetime
    os.makedirs(CAND, exist_ok=True)
    d1 = build_d1()
    d2 = build_d2()
    d3 = build_d3()
    for name, doc in (("d1", d1), ("d2", d2), ("d3", d3)):
        with open(os.path.join(CAND, f"{name}.svg"), "w") as f:
            f.write(doc)
        print(f"wrote candidates/{name}.svg")

    cells = []
    cells.append(cell("d1 — Space Grotesk 700 / route-step R (right)", d1))
    cells.append(cell("d1 ALT — left-step variant", build_d1("left")))
    cells.append(cell("d2 — Archivo 700+500 weight seam (ink/ink)", d2))
    cells.append(cell("d2 ALT — stead in Stead Blue", build_d2(STEAD_BLUE)))
    cells.append(cell("d3 — Sora stepped baseline + riser", d3))
    cells.append(cell("d3 — dark check", d3, tone="dark"))
    cells.append(cell("d1 — dark check", d1, tone="dark"))
    cells.append(cell("d2 — dark check", d2, tone="dark"))
    cells.append(zoom_cell("ZOOM d1 R (right-step)", d1))
    cells.append(zoom_cell("ZOOM d1 ALT R (left-step)", build_d1("left")))
    cells.append(zoom_cell("ZOOM d2 seam", d2, shift=500))
    cells.append(zoom_cell("ZOOM d3 seam", d3, shift=450))
    stamp = datetime.datetime.now().strftime("%H:%M:%S")
    with open(os.path.join(SCRATCH, "d-studio.html"), "w") as f:
        f.write(PAGE.format(cells="\n".join(cells), stamp=stamp))
    print("wrote scratch/d-studio.html")


if __name__ == "__main__":
    main()
