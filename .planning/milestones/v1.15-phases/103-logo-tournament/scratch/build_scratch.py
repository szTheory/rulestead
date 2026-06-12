#!/usr/bin/env python3
"""Scratch grid builder (Phase 103, Axis B). Throwaway decision aid.
Inlines candidates/b*.svg into scratch/axis-b-scratch.html — no img src fetch races.
~480px cells on white + 36px admin-header strip row per candidate.
"""
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
CAND = HERE.parent / "candidates"

cards = []
strips = []
for name in ("b1", "b2", "b3"):
    svg = (CAND / f"{name}.svg").read_text()
    cards.append(f'<figure class="card"><div class="art">{svg}</div>'
                 f'<figcaption>{name}</figcaption></figure>')
    strips.append(f'<div class="strip"><div class="strip-art">{svg}</div>'
                  f'<span class="strip-label">{name} @ 36px row</span></div>')

html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Axis B scratch — Phase 103</title>
<style>
  body {{ margin: 0; background: #ffffff; font-family: system-ui, sans-serif; }}
  .wrap {{ padding: 24px 32px 48px; max-width: 1140px; }}
  h1 {{ font-size: 15px; color: #5c6b7a; font-weight: 600; margin: 0 0 16px; }}
  .grid {{ display: grid; grid-template-columns: 1fr; gap: 18px; }}
  .card {{ margin: 0; border: 1px solid rgba(0,0,0,0.10); border-radius: 10px;
           padding: 20px 24px; background: #ffffff; }}
  .art svg {{ width: 480px; height: auto; display: block; }}
  figcaption {{ margin-top: 8px; font-size: 12px; color: #8a97a3; }}
  .strips {{ margin-top: 26px; display: grid; gap: 10px; }}
  .strip {{ display: flex; align-items: center; gap: 14px; height: 36px;
            border: 1px solid rgba(0,0,0,0.10); border-radius: 6px; padding: 0 12px;
            background: #ffffff; }}
  .strip-art svg {{ height: 26px; width: auto; display: block; }}
  .strip-label {{ font-size: 11px; color: #8a97a3; }}
</style></head>
<body><div class="wrap">
  <h1>Phase 103 / Axis B scratch — abstract marks interlocked with logotype</h1>
  <div class="grid">{''.join(cards)}</div>
  <div class="strips">{''.join(strips)}</div>
</div></body></html>
"""
out = HERE / "axis-b-scratch.html"
out.write_text(html)
print(f"wrote {out}")
