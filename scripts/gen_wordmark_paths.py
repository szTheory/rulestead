#!/usr/bin/env python3
"""
gen_wordmark_paths.py — Rulestead wordmark text-to-path converter.

Downloads Sora Bold TTF from Google Fonts CDN (fonts.gstatic.com ONLY),
extracts glyph outlines for a given text string via fontTools SVGPathPen,
applies the required Y-axis flip (SVG is Y-down, font is Y-up), and emits
SVG <path> elements with correct advance widths.

The TTF is written to a temp directory and is NOT committed.

Usage:
    python3 scripts/gen_wordmark_paths.py [--text TEXT] [--em-size SIZE]
    python3 scripts/gen_wordmark_paths.py                  # defaults: "Rulestead", em=64
    python3 scripts/gen_wordmark_paths.py --text "Hello"
    python3 scripts/gen_wordmark_paths.py --text "Rulestead" --em-size 48

Output: one <path> element per glyph, printed to stdout, with transform for
        positioning and the Y-flip applied.

Security: TTF download is HTTPS-only from fonts.gstatic.com. No other host is
          permitted. See T-97-03 in the STRIDE threat register.
"""

import sys
import os
import argparse
import tempfile
import urllib.request

# Prepend user-installed fontTools site-packages path (confirmed working 2026-06-05)
sys.path.insert(0, os.path.expanduser("~/Library/Python/3.14/lib/python/site-packages"))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

# Security: ONLY this URL is permitted for the TTF download (T-97-03).
SORA_BOLD_TTF_URL = "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mX-K.ttf"


def download_font(url: str) -> str:
    """Download TTF from the approved Google Fonts CDN URL to a temp file. Returns path."""
    assert url.startswith("https://fonts.gstatic.com/"), (
        f"Security violation: TTF download URL must be from fonts.gstatic.com. Got: {url}"
    )
    tmp_dir = tempfile.mkdtemp(prefix="rulestead_wordmark_")
    ttf_path = os.path.join(tmp_dir, "sora-bold.ttf")
    urllib.request.urlretrieve(url, ttf_path)
    return ttf_path


def text_to_svg_paths(text: str, font: TTFont, em_size: float = 64.0) -> list[str]:
    """
    Convert a text string to a list of SVG <path> elements.

    Each glyph is extracted using SVGPathPen, scaled from font units to em_size,
    and translated horizontally by accumulated advance widths. The Y-axis is
    flipped (scale(s, -s)) because SVG is Y-down and font coordinates are Y-up.

    Returns a list of SVG <path> element strings (one per glyph).
    """
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    units_per_em = font["head"].unitsPerEm
    scale = em_size / units_per_em

    paths = []
    x_cursor = 0.0  # in font units (pre-scale)

    for ch in text:
        code_point = ord(ch)
        glyph_name = cmap.get(code_point)
        if not glyph_name:
            print(f"  Warning: no glyph for U+{code_point:04X} '{ch}'", file=sys.stderr)
            # Advance by a fallback width so subsequent glyphs still position correctly.
            adv = font["hmtx"].metrics.get(glyph_name or "", (500, 0))[0]
            x_cursor += adv
            continue

        pen = SVGPathPen(glyphs)
        glyphs[glyph_name].draw(pen)
        d = pen.getCommands()

        adv = glyphs[glyph_name].width  # advance width in font units

        if d:
            x_px = x_cursor * scale
            # Y-flip: SVG Y-axis is inverted relative to font. Use scale(s, -s).
            # We also need to translate up by em_size so glyphs don't render
            # below the baseline (after the Y-flip the baseline is at y=0;
            # ascender goes negative in SVG coords, so shift down by em_size).
            # The transform order: translate(x, em_size) then scale(s, -s).
            # In SVG transform attribute notation (applied right-to-left):
            #   transform="translate(x_px, em_size) scale(s, -s)"
            paths.append(
                f'<path transform="translate({x_px:.3f},{em_size:.3f}) scale({scale:.6f},-{scale:.6f})" d="{d}"/>'
            )

        x_cursor += adv

    return paths


def total_width(text: str, font: TTFont, em_size: float = 64.0) -> float:
    """Return total advance width in SVG pixels for the string."""
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    units_per_em = font["head"].unitsPerEm
    scale = em_size / units_per_em
    total = 0.0
    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if glyph_name:
            total += glyphs[glyph_name].width * scale
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Rulestead wordmark text-to-path converter")
    parser.add_argument("--text", default="Rulestead", help="Text to convert (default: Rulestead)")
    parser.add_argument("--em-size", type=float, default=64.0, help="Target em size in SVG units (default: 64)")
    args = parser.parse_args()

    text = args.text
    em_size = args.em_size

    print(f"Downloading Sora Bold from {SORA_BOLD_TTF_URL}", file=sys.stderr)
    ttf_path = download_font(SORA_BOLD_TTF_URL)
    print(f"Downloaded to: {ttf_path}", file=sys.stderr)

    font = TTFont(ttf_path)
    print(f"Font loaded. units_per_em={font['head'].unitsPerEm}", file=sys.stderr)

    paths = text_to_svg_paths(text, font, em_size)
    w = total_width(text, font, em_size)
    print(f"Text '{text}': {len(paths)} glyphs, total width ≈ {w:.1f}px at em={em_size}", file=sys.stderr)

    print(f"<!-- Sora Bold paths for '{text}' at em_size={em_size} -->")
    print(f"<!-- Total advance width: {w:.3f} SVG units -->")
    for p in paths:
        print(p)

    # Clean up temp TTF
    os.unlink(ttf_path)
    os.rmdir(os.path.dirname(ttf_path))
    print(f"Temp TTF removed.", file=sys.stderr)


if __name__ == "__main__":
    main()
