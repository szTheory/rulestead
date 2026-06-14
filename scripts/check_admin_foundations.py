#!/usr/bin/env python3
"""Source guard for Rulestead admin foundation invariants.

Checks deterministic facts only:
  - contract sections required by Phase 115 exist
  - every noncanonical @media width literal in admin CSS is documented
  - reduced-motion and focus exception source markers are present

Usage:
    python3 scripts/check_admin_foundations.py
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
CSS_PATH = ROOT / "rulestead_admin/priv/static/css/rulestead_admin.css"
CONTRACT_PATH = ROOT / ".planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md"

REQUIRED_CONTRACT_SECTIONS = [
    "## Scope",
    "## Breakpoint Contract",
    "## Noncanonical Breakpoint Exceptions",
    "## Scalar Token Contract",
    "## Focus Contract",
    "## Reduced Motion Contract",
    "## Radius, Pill, Elevation, And Emphasis Rules",
    "## Dense Technical Content Rules",
    "## Verification Commands",
]

CANONICAL_MEDIA = {
    "40rem",
    "48rem",
    "60rem",
    "75rem",
    "47.99rem",
}

CANONICAL_FEATURE_MEDIA = {
    "prefers-color-scheme: dark",
    "prefers-reduced-motion: no-preference",
    "prefers-reduced-motion: reduce",
}

MEDIA_RE = re.compile(r"@media\s*\(([^{}]+?)\)\s*{")
WIDTH_RE = re.compile(r"(?:min|max)-width\s*:\s*([0-9]+(?:\.[0-9]+)?(?:rem|px))")

REQUIRED_CSS_MARKERS = [
    "@media (prefers-reduced-motion: reduce)",
    "cmdk: inside modal",
    "--rs-focus-ring",
]


def read_text(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        return None


def normalize_condition(condition):
    return " ".join(condition.split())


def undocumented_media_widths(css, contract):
    failures = []
    for match in MEDIA_RE.finditer(css):
        condition = normalize_condition(match.group(1))
        widths = WIDTH_RE.findall(condition)

        if not widths:
            if not any(feature in condition for feature in CANONICAL_FEATURE_MEDIA):
                failures.append(f"undocumented feature media query: {condition}")
            continue

        for literal in widths:
            if literal in CANONICAL_MEDIA:
                continue
            if f"`{literal}`" not in contract:
                failures.append(f"@media width {literal} is missing from foundation contract")

    return failures


def main():
    failures = []

    css = read_text(CSS_PATH)
    contract = read_text(CONTRACT_PATH)

    if css is None:
        failures.append(f"missing CSS file: {CSS_PATH.relative_to(ROOT)}")
        css = ""
    if contract is None:
        failures.append(f"missing contract file: {CONTRACT_PATH.relative_to(ROOT)}")
        contract = ""

    for section in REQUIRED_CONTRACT_SECTIONS:
        if section not in contract:
            failures.append(f"contract missing required section: {section}")

    for marker in REQUIRED_CSS_MARKERS:
        if marker not in css:
            failures.append(f"admin CSS missing required marker: {marker}")

    failures.extend(undocumented_media_widths(css, contract))

    if failures:
        print("ADMIN FOUNDATION DRIFT DETECTED")
        for failure in failures:
            print(f"  {failure}")
        return 1

    print("ADMIN FOUNDATIONS OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
