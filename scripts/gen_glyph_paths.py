#!/usr/bin/env python3
"""
gen_glyph_paths.py — Generalized glyph-to-SVG-path converter for Rulestead tournament tooling.

Fetches any pinned OFL font TTF from fonts.gstatic.com via curl subprocess (never via the
Python standard-library HTTP client — that hangs on gstatic in this exec environment),
extracts glyph outlines for a given text string via fontTools SVGPathPen, applies Y-axis
flip + per-glyph translate, and emits one <path> element per glyph to stdout.

Per-glyph output (one <path> per character, each with its own transform) enables independent
letterform editing for Phase 103 tournament candidates. Do NOT merge paths into a single blob.

Security: TTF download URL must be from https://fonts.gstatic.com/ only (T-97-03 security
control — same guard as gen_wordmark_paths.py). The downloaded TTF is written to a temp dir
and is NOT committed.

Usage:
    python3 scripts/gen_glyph_paths.py --font-url URL --text "Rulestead" [--em-size 64] \\
        [--tracking -0.01] [--weight "700"]

    # Incumbent wordmark (Sora Bold 700, default text):
    python3 scripts/gen_glyph_paths.py \\
        --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf"

    # Space Grotesk 600, tight tracking:
    python3 scripts/gen_glyph_paths.py \\
        --font-url "https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj42VnskPMU.ttf" \\
        --text "Rulestead" --tracking -0.02 --weight "600"

    # Two-char test (expect 2 path elements):
    python3 scripts/gen_glyph_paths.py \\
        --font-url "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf" \\
        --text "RS" | grep -c 'path transform'
    # expected: 2

Output format (stdout):
    <!-- gen_glyph_paths.py: 'Rulestead' em=64.0 tracking=0.0 -->
    <!-- Font: {url} -->
    <!-- Total advance width: {w:.3f} SVG units -->
      <!-- glyph: R -->
      <path transform="translate(0.000,64.000) scale(0.064000,-0.064000)" d="..."/>
      <!-- glyph: u -->
      <path transform="translate(42.048,64.000) scale(0.064000,-0.064000)" d="..."/>
      ...

Note: The 'weight' parameter is a display label only — the weight is baked into the TTF URL.
      Use a different --font-url to change weight.
"""

import sys
import os
import argparse
import tempfile
import subprocess
import shutil

# Prepend user-installed fontTools site-packages path (fontTools 4.62.1 user install).
# Must be inserted at index 0 BEFORE any fontTools import — mirrors gen_wordmark_paths.py.
sys.path.insert(0, os.path.expanduser("~/Library/Python/3.14/lib/python/site-packages"))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen


# Reference: pinned OFL font TTF URLs (verified 2026-06-11). Use with --font-url.
# All URLs return HTTP 200 content-type font/ttf. SIL OFL 1.1 licensing confirmed for all.
# TTF URLs are stable (Google Fonts pins by version slug e.g. v17, v22, v25, v23).
SHORTLIST = {
    "sora-600": "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSeMmU-NKQc.ttf",
    "sora-700": "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf",
    "sora-800": "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSfSmU-NKQc.ttf",
    "space-grotesk-600": "https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj42VnskPMU.ttf",
    "space-grotesk-700": "https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj4PVnskPMU.ttf",
    "archivo-600": "https://fonts.gstatic.com/s/archivo/v25/k3k6o8UDI-1M0wlSV9XAw6lQkqWY8Q82sJaRE-NWIDdgffTT6jRZ9xds.ttf",
    "archivo-700": "https://fonts.gstatic.com/s/archivo/v25/k3k6o8UDI-1M0wlSV9XAw6lQkqWY8Q82sJaRE-NWIDdgffTT0zRZ9xds.ttf",
    "ibm-plex-sans-600": "https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYYaJe8bpLHnCwDKr932-G7dytD-Dmu1swZSAXcomDVmadSDNF5DB6g9.ttf",
    "ibm-plex-sans-700": "https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYYaJe8bpLHnCwDKr932-G7dytD-Dmu1swZSAXcomDVmadSDDV5DB6g9.ttf",
}


def download_font_curl(url: str, tmp_dir: str) -> str:
    """
    Download a TTF font from fonts.gstatic.com via curl subprocess.

    Security (T-97-03): Only URLs from https://fonts.gstatic.com/ are permitted.
    The assertion fails fast with a clear error for any other host.

    Returns the local path to the downloaded TTF file.
    Raises RuntimeError if curl fails (non-zero exit code).
    """
    assert url.startswith("https://fonts.gstatic.com/"), (
        f"Security (T-97-03): TTF download must be from fonts.gstatic.com only. Got: {url!r}"
    )
    out_path = os.path.join(tmp_dir, "font.ttf")
    result = subprocess.run(
        ["curl", "-s", "-o", out_path, url],
        capture_output=True,
        timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"curl download failed (exit {result.returncode}): {result.stderr.decode()!r}"
        )
    if not os.path.exists(out_path) or os.path.getsize(out_path) == 0:
        raise RuntimeError(f"curl produced empty or missing file at {out_path!r}")
    return out_path


def text_to_paths(
    text: str,
    font: TTFont,
    em_size: float = 64.0,
    tracking: float = 0.0,
) -> tuple[list[str], float]:
    """
    Convert a text string to a list of SVG <path> element strings.

    One <path> element is emitted per input character (never merged).
    Each element has its own transform attribute positioning it at the correct
    horizontal advance and applying the Y-axis flip.

    Args:
        text:     Input string (e.g. "Rulestead").
        font:     Loaded fontTools TTFont object.
        em_size:  Target em height in SVG units (default 64.0). viewBox height.
        tracking: Letter-spacing in em fractions per glyph (e.g. -0.02 = tighten
                  by 2% of em_size after each glyph; 0.0 = no extra spacing).

    Returns:
        Tuple of (path_elements, total_advance_width_in_svg_units).
        path_elements is a list of strings, each being a two-line block:
            '  <!-- glyph: X -->\n  <path transform="..." d="..."/>'

    Y-flip rationale: Font coordinates are Y-up (baseline at y=0, ascenders go
    positive). SVG coordinates are Y-down. The transform
        translate(x_px, em_size) scale(scale, -scale)
    flips the Y axis (scale negative) and then shifts the baseline down to y=em_size
    so glyphs render within the viewBox with ascenders toward y=0.

    Tracking is applied in font units (tracking_units = tracking * upm) and added
    to x_cursor after each glyph (including missing glyphs). This keeps the unit
    accumulation consistent with the advance width units.
    """
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    scale = em_size / upm
    tracking_units = tracking * upm  # em fraction -> font units

    path_elements = []
    x_cursor = 0.0  # accumulates in font units (pre-scale)

    for ch in text:
        cp = ord(ch)
        glyph_name = cmap.get(cp)

        if not glyph_name:
            # Missing glyph: warn, advance by space width + tracking, skip emission.
            fallback_adv = font["hmtx"].metrics.get("space", (500, 0))[0]
            print(
                f"  Warning: no glyph for U+{cp:04X} {ch!r} — advancing by space width",
                file=sys.stderr,
            )
            x_cursor += fallback_adv + tracking_units
            continue

        pen = SVGPathPen(glyphs)
        glyphs[glyph_name].draw(pen)
        d = pen.getCommands()
        adv = glyphs[glyph_name].width  # advance width in font units

        if d:
            x_px = x_cursor * scale
            transform = (
                f"translate({x_px:.3f},{em_size:.3f}) "
                f"scale({scale:.6f},-{scale:.6f})"
            )
            path_elements.append(
                f"  <!-- glyph: {ch} -->\n"
                f'  <path transform="{transform}" d="{d}"/>'
            )

        x_cursor += adv + tracking_units

    total_w = x_cursor * scale
    return path_elements, total_w


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Rulestead tournament glyph-to-path converter. "
            "Fetches any pinned fonts.gstatic.com TTF via curl and emits "
            "one <path> per glyph with per-glyph transform to stdout."
        )
    )
    parser.add_argument(
        "--font-url",
        required=True,
        help=(
            "Pinned fonts.gstatic.com TTF URL (required). "
            "Must start with https://fonts.gstatic.com/. "
            "See SHORTLIST dict in this file for verified URLs."
        ),
    )
    parser.add_argument(
        "--text",
        default="Rulestead",
        help="Text string to convert (default: Rulestead)",
    )
    parser.add_argument(
        "--em-size",
        type=float,
        default=64.0,
        help="Target em height in SVG units (default: 64.0)",
    )
    parser.add_argument(
        "--tracking",
        type=float,
        default=0.0,
        help=(
            "Letter-spacing in em fractions per glyph "
            "(default: 0.0; -0.02 = tighten by 2%% em per glyph)"
        ),
    )
    parser.add_argument(
        "--weight",
        default=None,
        help=(
            "Display label for the font weight (e.g. '700'). "
            "Printed in stderr header only — weight is baked into --font-url."
        ),
    )
    args = parser.parse_args()

    weight_label = f" weight={args.weight}" if args.weight else ""
    print(
        f"gen_glyph_paths.py: text={args.text!r} em={args.em_size}{weight_label} "
        f"url={args.font_url}",
        file=sys.stderr,
    )

    tmp_dir = tempfile.mkdtemp(prefix="rulestead_glyphs_")
    try:
        print(f"Downloading font from {args.font_url}", file=sys.stderr)
        ttf_path = download_font_curl(args.font_url, tmp_dir)
        font = TTFont(ttf_path)
        upm = font["head"].unitsPerEm
        print(f"Font loaded. UPM={upm}", file=sys.stderr)

        path_elements, total_w = text_to_paths(
            args.text, font, args.em_size, args.tracking
        )
        print(
            f"'{args.text}': {len(path_elements)} glyphs, "
            f"total_w={total_w:.1f} SVG units at em={args.em_size}",
            file=sys.stderr,
        )

        # Stdout output: paste directly into SVG <g> body
        print(
            f"<!-- gen_glyph_paths.py: {args.text!r} em={args.em_size} "
            f"tracking={args.tracking} -->"
        )
        print(f"<!-- Font: {args.font_url} -->")
        print(f"<!-- Total advance width: {total_w:.3f} SVG units -->")
        for elem in path_elements:
            print(elem)

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
