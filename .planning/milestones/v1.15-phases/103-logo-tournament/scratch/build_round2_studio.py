#!/usr/bin/env python3
"""Assemble Round 2 context studio: per-variant light/dark/mono + 36px strip + favicon row."""
import re
from pathlib import Path

PHASE = Path(__file__).resolve().parent.parent
CAND = PHASE / "candidates"

DARK_SWAP = {
    "#183247": "#e8edf3", "#C4CCD1": "#3d4a55", "#c4ccd1": "#3d4a55",
    "#3A6F8F": "#5885a0", "#3a6f8f": "#5885a0",
}

VARIANTS = [
    ("a3-1", "Refined original — inset trace start, tuned weight/radii/nodes"),
    ("a3-2", "Single lit node — one copper node, no stubs (calmest; favicon-native)"),
    ("a3-3", "R-anchored entry — trace grows collinear from the R's leg"),
    ("a3-4", "Partial route — trace carries only 'stead', rises through the d"),
    ("a3-5", "Copper trace — the route itself is Ember Copper, nodes muted"),
    ("a3-6", "Fanned exit — three diverging routes from the d stem (G4c DNA)"),
]


def load(key):
    svg = (CAND / f"{key}.svg").read_text()
    return re.sub(r"<\?xml[^>]*\?>\s*", "", svg)


def darken(svg):
    for a, b in DARK_SWAP.items():
        svg = svg.replace(a, b)
    return svg


def mono(svg, color="#0F1720"):
    svg = re.sub(r'fill="#(?:183247|9b5931|3A6F8F|3a6f8f|C4CCD1|c4ccd1)"', f'fill="{color}"', svg)
    svg = re.sub(r'stroke="#(?:183247|9b5931|3A6F8F|3a6f8f|C4CCD1|c4ccd1)"', f'stroke="{color}"', svg)
    return svg


def favcrop(svg, px):
    """Crop to a right-end square via viewBox override, render at px size."""
    m = re.search(r'viewBox="([-\d.]+) ([-\d.]+) ([-\d.]+) ([-\d.]+)"', svg)
    x, y, w, h = (float(v) for v in m.groups())
    side = h
    crop = f'viewBox="{x + w - side:.1f} {y:.1f} {side:.1f} {side:.1f}" width="{px}" height="{px}" preserveAspectRatio="xMidYMid meet"'
    out = re.sub(r'viewBox="[^"]*"', crop, svg, count=1)
    out = re.sub(r'\s(width|height)="[^"]*"(?=[^>]*>)', "", out, count=2) if 'width="' in svg.split(">")[0] else out
    return out


def block(key, desc):
    svg = load(key)
    return f"""
  <section class="variant">
    <h2><span>{key.upper()}</span> {desc}</h2>
    <div class="row">
      <div class="card card--light"><div class="art">{svg}</div><div class="cap">light</div></div>
      <div class="card card--dark"><div class="art">{darken(svg)}</div><div class="cap">dark</div></div>
      <div class="card card--light"><div class="art">{mono(svg)}</div><div class="cap">mono</div></div>
    </div>
    <div class="strip card--light"><div class="strip__label">36px admin header</div><div class="strip__art">{svg}</div></div>
    <div class="strip card--dark"><div class="strip__label">36px dark header</div><div class="strip__art">{darken(svg)}</div></div>
    <div class="favrow card--light"><div class="strip__label">favicon crop 16 / 24 / 32px (d-end element)</div>
      {favcrop(svg, 16)}{favcrop(svg, 24)}{favcrop(svg, 32)}
      <div class="strip__label" style="width:auto">on dark:</div>
      <span class="favdark">{favcrop(darken(svg), 16)}{favcrop(darken(svg), 24)}{favcrop(darken(svg), 32)}</span>
    </div>
  </section>"""


body = "".join(block(k, d) for k, d in VARIANTS)
html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Rulestead — Tournament Round 2 (A3 variants)</title>
<style>
  * {{ margin:0; box-sizing:border-box; }}
  body {{ font-family:-apple-system,"Helvetica Neue",sans-serif; background:#E8ECE8; padding:32px; }}
  h1 {{ font-size:22px; color:#0F1720; }}
  .sub {{ font-size:13px; color:#606d66; margin:4px 0 8px; }}
  .variant {{ margin:26px 0 34px; }}
  h2 {{ font-size:13px; color:#0F1720; margin-bottom:10px; font-weight:600; }}
  h2 span {{ color:#9b5931; font-weight:800; margin-right:6px; }}
  .row {{ display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:10px; }}
  .card {{ border-radius:10px; padding:16px; }}
  .card--light {{ background:#FFFFFF; border:1px solid #C4CCD1; }}
  .card--dark {{ background:#10161F; border:1px solid #24313D; }}
  .art {{ display:flex; justify-content:center; align-items:center; min-height:86px; }}
  .art svg {{ width:100%; max-width:420px; height:auto; max-height:96px; }}
  .cap {{ font-size:10px; color:#8a97a3; text-transform:uppercase; letter-spacing:.08em; margin-top:8px; }}
  .strip {{ display:flex; align-items:center; gap:16px; border-radius:8px; padding:8px 14px; margin-bottom:8px; border:1px solid #C4CCD1; }}
  .strip.card--dark {{ border-color:#24313D; }}
  .strip__label {{ font-size:10px; width:150px; color:#8a97a3; text-transform:uppercase; letter-spacing:.06em; flex:none; }}
  .strip__art svg {{ height:36px; width:auto; }}
  .favrow {{ display:flex; align-items:center; gap:18px; border-radius:8px; padding:10px 14px; border:1px solid #C4CCD1; }}
  .favrow svg {{ flex:none; vertical-align:middle; }}
  .favdark {{ background:#10161F; border-radius:6px; padding:6px 10px; display:inline-flex; gap:18px; align-items:center; }}
</style></head><body>
  <h1>Rulestead — Logo Tournament, Round 2</h1>
  <div class="sub">Six variants of Round 1 survivor A3 ("route threads the baseline, rises through the d stem"). Each shown light / dark / mono, at 36px header height, and a right-end crop at favicon sizes.</div>
  {body}
</body></html>"""

out = PHASE / "round-2-studio.html"
out.write_text(html)
print(f"wrote {out} ({len(html)} bytes)")
