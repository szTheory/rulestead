#!/usr/bin/env python3
"""WCAG 2.x contrast ratio + OKLCH hue-angle verification for Phase 95 palette reconciliation.

Computes WCAG 2.1 relative-luminance contrast ratios and Ottosson OKLCH hue angles for
every AA-verified hex in the Phase 95 brand-audit palette reconciliation table.

Self-tests four known-good anchor values on startup and exits non-zero if any fails.
Then verifies all Phase 95 AA-passing targets exit 0 and prints CONTRAST CHECK PASS.

Usage (from repo root):
    python3 scripts/check_contrast.py
Exits 0 and prints "ANCHORS OK" + "CONTRAST CHECK PASS (N checks)" on success; exits 1 on failure.

Formula citations:
  WCAG 2.x relative luminance: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  OKLCH / OKLab: Bjorn Ottosson 2020 — https://bottosson.github.io/posts/oklab/
"""
import math
import sys


# ---------------------------------------------------------------------------
# WCAG 2.x relative luminance + contrast ratio
# ---------------------------------------------------------------------------

def linearize(c_byte):
    """sRGB channel byte (0-255) to linear light per WCAG 2.1."""
    c = c_byte / 255.0
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(r, g, b):
    """WCAG 2.x relative luminance from sRGB channel bytes."""
    return (0.2126 * linearize(r) +
            0.7152 * linearize(g) +
            0.0722 * linearize(b))


def contrast_ratio(hex1, hex2):
    """WCAG 2.x contrast ratio between two hex color strings."""
    def parse(h):
        h = h.lstrip('#')
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

    L1 = relative_luminance(*parse(hex1))
    L2 = relative_luminance(*parse(hex2))
    lighter, darker = max(L1, L2), min(L1, L2)
    return (lighter + 0.05) / (darker + 0.05)


# ---------------------------------------------------------------------------
# OKLCH hue angle (Ottosson sRGB -> linear -> XYZ D65 -> LMS -> OKLab -> OKLCH)
# ---------------------------------------------------------------------------

def rgb_to_oklch(r, g, b):
    """Compute OKLCH from sRGB bytes (0-255). Returns (L, C, H_degrees)."""
    # 1. sRGB bytes -> linear light
    rl, gl, bl = linearize(r), linearize(g), linearize(b)

    # 2. Linear sRGB -> XYZ D65 (standard IEC 61966-2-1 matrix)
    x = 0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl
    y = 0.2126729 * rl + 0.7151522 * gl + 0.0721750 * bl
    z = 0.0193339 * rl + 0.1191920 * gl + 0.9503041 * bl

    # 3. XYZ -> LMS (Ottosson M1)
    lm = 0.8189330101 * x + 0.3618667424 * y - 0.1288597137 * z
    mm = 0.0329845436 * x + 0.9293118715 * y + 0.0361456387 * z
    sm = 0.0482003018 * x + 0.2643662691 * y + 0.6338517070 * z

    # 4. LMS -> LMS^(1/3) (cube root)
    lg, mg, sg = lm ** (1 / 3), mm ** (1 / 3), sm ** (1 / 3)

    # 5. LMS^(1/3) -> OKLab (Ottosson M2)
    L = 0.2104542553 * lg + 0.7936177850 * mg - 0.0040720468 * sg
    a = 1.9779984951 * lg - 2.4285922050 * mg + 0.4505937099 * sg
    b_ok = 0.0259040371 * lg + 0.7827717662 * mg - 0.8086757660 * sg

    # 6. OKLab -> OKLCH
    C = math.sqrt(a ** 2 + b_ok ** 2)
    H = math.degrees(math.atan2(b_ok, a)) % 360
    return L, C, H


def hue_drift(hex_before, hex_after):
    """Absolute hue drift in degrees between two hex colors (OKLCH), with 360-wraparound correction."""
    def parse(h):
        h = h.lstrip('#')
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

    _, _, H_before = rgb_to_oklch(*parse(hex_before))
    _, _, H_after = rgb_to_oklch(*parse(hex_after))
    diff = abs(H_after - H_before)
    if diff > 180:
        diff = 360 - diff
    return diff


# ---------------------------------------------------------------------------
# Self-test anchors (run on startup; exit non-zero on any failure)
# ---------------------------------------------------------------------------

def run_self_tests():
    """Run four known-good anchor assertions. Exit 1 if any fails."""
    failures = []

    # Anchor 1: black on white = 21.0:1 exactly
    r = contrast_ratio('#000000', '#ffffff')
    if not abs(r - 21.0) < 0.01:
        failures.append(f"ANCHOR FAIL: black/white expected ~21.0, got {r:.4f}")

    # Anchor 2: white on white = 1.0:1 exactly
    r = contrast_ratio('#ffffff', '#ffffff')
    if not abs(r - 1.0) < 0.01:
        failures.append(f"ANCHOR FAIL: white/white expected ~1.0, got {r:.4f}")

    # Anchor 3: Stead Blue #3A6F8F on white — confirmed 5.45:1 pass
    r = contrast_ratio('#3A6F8F', '#ffffff')
    if not r >= 5.40:
        failures.append(f"ANCHOR FAIL: Stead Blue on white expected >=5.40, got {r:.4f}")

    # Anchor 4: Ember Copper #B96A3A on white — confirmed 4.05:1 (known fail, remediation anchor)
    r = contrast_ratio('#B96A3A', '#ffffff')
    if not (3.9 <= r <= 4.2):
        failures.append(f"ANCHOR FAIL: Ember Copper on white expected 3.9-4.2, got {r:.4f}")

    if failures:
        for msg in failures:
            print(msg)
        sys.exit(1)

    print("ANCHORS OK")


# ---------------------------------------------------------------------------
# Phase 95 palette verification checks
# ---------------------------------------------------------------------------

# Each entry: (description, fg_hex, bg_hex, min_ratio)
# OKLCH drift checks use a special sentinel min_ratio < 0 to distinguish them.
# A negative min_ratio means: assert hue_drift(fg_hex, bg_hex) < abs(min_ratio).

PALETTE_CHECKS = [
    # --- Light-surface assertions (all must be >=4.5:1) ---

    # Ember Copper canonical on Stone Mist (darkest per-surface target; passes all three light surfaces)
    ("Ember Copper canonical #9b5931 on Stone Mist #E8ECE8",
     "#9b5931", "#E8ECE8", 4.5),

    # Ember Copper per-surface: White
    ("Ember Copper #ac6336 on White #FFFFFF",
     "#ac6336", "#FFFFFF", 4.5),

    # Ember Copper per-surface: Rain Tint
    ("Ember Copper #a65f34 on Rain Tint #F5F7F6",
     "#a65f34", "#F5F7F6", 4.5),

    # Warning canonical on Stone Mist
    ("Warning canonical #8f601a on Stone Mist #E8ECE8",
     "#8f601a", "#E8ECE8", 4.5),

    # Warning per-surface: White
    ("Warning #9f6b1d on White #FFFFFF",
     "#9f6b1d", "#FFFFFF", 4.5),

    # Moss Grey canonical on Stone Mist
    ("Moss Grey canonical #606d66 on Stone Mist #E8ECE8",
     "#606d66", "#E8ECE8", 4.5),

    # Moss Grey per-surface: Rain Tint
    ("Moss Grey #67746d on Rain Tint #F5F7F6",
     "#67746d", "#F5F7F6", 4.5),

    # Success on Stone Mist (uncatalogued failure in PITFALLS.md; 4.20:1 raw, corrected #2d7753)
    ("Success #2d7753 on Stone Mist #E8ECE8",
     "#2d7753", "#E8ECE8", 4.5),

    # Danger on Stone Mist (uncatalogued failure in PITFALLS.md; 4.41:1 raw, corrected #b04848)
    ("Danger #b04848 on Stone Mist #E8ECE8",
     "#b04848", "#E8ECE8", 4.5),

    # --- Dark-surface assertions (all must be >=4.5:1 on #10161f) ---

    ("Stead Blue dark #5885a0 on #10161f",
     "#5885a0", "#10161f", 4.5),

    ("Dark primary button foreground #10161f on #5885a0",
     "#10161f", "#5885a0", 4.5),

    ("Ember Copper dark #ba6b3c on #10161f",
     "#ba6b3c", "#10161f", 4.5),

    ("Success dark #488d6b on #10161f",
     "#488d6b", "#10161f", 4.5),

    ("Danger dark #bf6464 on #10161f",
     "#bf6464", "#10161f", 4.5),

    ("Info dark #55859e on #10161f",
     "#55859e", "#10161f", 4.5),

    ("Moss Grey dark #75827b on #10161f",
     "#75827b", "#10161f", 4.5),

    # --- OKLCH drift assertions (must be <3 degrees) ---
    # Encoded as: description, hex_before, hex_after, -max_drift (negative sentinel)

    ("OKLCH drift: Ember Copper light canonical #B96A3A -> #9b5931 (must be <3 deg)",
     "#B96A3A", "#9b5931", -3.0),

    ("OKLCH drift: Warning light canonical #B57A21 -> #8f601a (must be <3 deg)",
     "#B57A21", "#8f601a", -3.0),

    ("OKLCH drift: Ember Copper dark #B96A3A -> #ba6b3c (must be <3 deg)",
     "#B96A3A", "#ba6b3c", -3.0),
]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    run_self_tests()

    failures = []
    passes = []

    for description, fg, bg, min_ratio in PALETTE_CHECKS:
        if min_ratio < 0:
            # OKLCH drift check: fg = hex_before, bg = hex_after
            max_drift = abs(min_ratio)
            drift = hue_drift(fg, bg)
            if drift < max_drift:
                result = f"PASS  drift={drift:.2f}deg  {description}"
                passes.append(result)
            else:
                result = f"FAIL  drift={drift:.2f}deg (>={max_drift:.1f}deg)  {description}"
                failures.append(result)
            print(result)
        else:
            # Contrast ratio check
            ratio = contrast_ratio(fg, bg)
            if ratio >= min_ratio:
                result = f"PASS  {ratio:.3f}:1  {description}"
                passes.append(result)
            else:
                result = f"FAIL  {ratio:.3f}:1 (<{min_ratio:.1f})  {description}"
                failures.append(result)
            print(result)

    n_total = len(PALETTE_CHECKS)
    if not failures:
        print(f"CONTRAST CHECK PASS ({n_total} checks)")
        return 0
    else:
        print(f"CONTRAST CHECK FAIL ({len(failures)} of {n_total} checks failed)")
        return 1


if __name__ == "__main__":
    sys.exit(main())
