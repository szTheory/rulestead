#!/usr/bin/env python3
"""Assemble Round 1 gallery studio HTML (light + dark sheets) from candidate SVGs."""
import re
from pathlib import Path

PHASE = Path(__file__).resolve().parent.parent
CAND = PHASE / "candidates"
ROOT = PHASE.parent.parent.parent

# Dark-surface mechanical hex swap (R-05/R-07)
DARK_SWAP = {
    "#183247": "#e8edf3",  # ink type -> light type
    "#C4CCD1": "#3d4a55",  # quarry muted -> dark muted
    "#c4ccd1": "#3d4a55",
    "#3A6F8F": "#5885a0",  # stead blue -> lightened (admin dark precedent)
    "#3a6f8f": "#5885a0",
}

LABELS = {
    "ctrl": ("CTRL", "Incumbent — shipped rs-wordmark.svg (known-failing control)"),
    "a1": ("A1", "Branch grows out of the R leg (routing bus + 3 nodes)"),
    "a2": ("A2", "Routing junction carved into the d counter (negative space)"),
    "a3": ("A3", "Route threads the baseline, rises through the d stem"),
    "b1": ("B1", "Strata terraces woven through the R (over/under weave)"),
    "b2": ("B2", "Route-path drops through the word to a lit node"),
    "b3": ("B3", "Topography contours emerge from the final d"),
    "c1": ("C1", "Forked R — counter recut as a route fork (negative space)"),
    "c2": ("C2", "st beam ligature — crossbar extends as a lintel + copper cap"),
    "c3": ("C3", "Lit terminal — d ascender steps into a copper status node"),
    "d1": ("D1", "Space Grotesk 700 — route-step recut into the R leg"),
    "d2": ("D2", "Archivo weight-contrast seam: Rule(700)+stead(500)"),
    "d3": ("D3", "Sora stepped baseline — stead drops to a lower terrace"),
}
ORDER = ["ctrl", "a1", "a2", "a3", "b1", "b2", "b3", "c1", "c2", "c3", "d1", "d2", "d3"]


def load_svg(key: str) -> str:
    if key == "ctrl":
        src = ROOT / "brandbook/assets/logo/rs-wordmark.svg"
    else:
        src = CAND / f"{key}.svg"
    svg = src.read_text()
    svg = re.sub(r"<\?xml[^>]*\?>\s*", "", svg)
    return svg


def darken(svg: str) -> str:
    for a, b in DARK_SWAP.items():
        svg = svg.replace(a, b)
    return svg


def cell(key: str, dark: bool) -> str:
    label, desc = LABELS[key]
    svg = load_svg(key)
    if dark:
        svg = darken(svg)
    return f"""
    <div class="cell{' cell--ctrl' if key == 'ctrl' else ''}">
      <div class="cell__head"><span class="cell__id">{label}</span><span class="cell__desc">{desc}</span></div>
      <div class="cell__art">{svg}</div>
    </div>"""


def sheet(dark: bool) -> str:
    cells = "".join(cell(k, dark) for k in ORDER)
    cls = "sheet--dark" if dark else "sheet--light"
    title = "Dark surface — #10161F" if dark else "Light surface — #FFFFFF"
    return f"""
  <section class="sheet {cls}">
    <h2>{title}</h2>
    <div class="grid">{cells}</div>
  </section>"""


html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<title>Rulestead — Tournament Round 1</title>
<style>
  * {{ margin:0; box-sizing:border-box; }}
  body {{ font-family: -apple-system, "Helvetica Neue", sans-serif; background:#E8ECE8; padding:32px; }}
  h1 {{ font-size:22px; color:#0F1720; margin-bottom:4px; }}
  .sub {{ font-size:13px; color:#606d66; margin-bottom:24px; }}
  h2 {{ font-size:14px; letter-spacing:.08em; text-transform:uppercase; color:#606d66; margin:28px 0 12px; }}
  .grid {{ display:grid; grid-template-columns:repeat(3, 1fr); gap:16px; }}
  .cell {{ border-radius:10px; padding:18px 20px 22px; }}
  .sheet--light .cell {{ background:#FFFFFF; border:1px solid #C4CCD1; }}
  .sheet--dark .cell {{ background:#10161F; border:1px solid #24313D; }}
  .cell--ctrl {{ outline:2px dashed #9b5931; outline-offset:2px; }}
  .cell__head {{ display:flex; gap:8px; align-items:baseline; margin-bottom:14px; }}
  .cell__id {{ font-weight:700; font-size:13px; color:#9b5931; }}
  .cell__desc {{ font-size:10.5px; color:#606d66; line-height:1.35; }}
  .sheet--dark .cell__desc {{ color:#8a97a3; }}
  .cell__art {{ display:flex; align-items:center; justify-content:center; min-height:120px; }}
  .cell__art svg {{ width:100%; max-width:480px; height:auto; max-height:130px; }}
</style></head>
<body>
  <h1>Rulestead — Logo Tournament, Round 1</h1>
  <div class="sub">12 candidates + incumbent control (dashed copper outline). Axes: A evolved incumbent · B interlocked marks · C pure Sora typemarks · D alt-font / structural.</div>
  {sheet(False)}
  {sheet(True)}
</body></html>"""

out = PHASE / "round-1-studio.html"
out.write_text(html)
print(f"wrote {out} ({len(html)} bytes)")
