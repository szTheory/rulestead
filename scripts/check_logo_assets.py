#!/usr/bin/env python3
"""Verify copied logo assets stay byte-for-byte aligned with brandbook sources."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]

PAIRS = [
    (
        "admin mark light",
        "brandbook/assets/logo/rs-mark.svg",
        "rulestead_admin/priv/static/images/rs-mark.svg",
    ),
    (
        "admin mark dark",
        "brandbook/assets/logo/rs-mark-dark.svg",
        "rulestead_admin/priv/static/images/rs-mark-dark.svg",
    ),
    (
        "admin fixture wordmark light",
        "brandbook/assets/logo/rs-wordmark.svg",
        "rulestead_admin/priv/static/images/rs-wordmark.svg",
    ),
    (
        "admin fixture wordmark dark",
        "brandbook/assets/logo/rs-wordmark-dark.svg",
        "rulestead_admin/priv/static/images/rs-wordmark-dark.svg",
    ),
    (
        "demo wordmark",
        "brandbook/assets/logo/rs-wordmark.svg",
        "examples/demo/backend/priv/static/images/logo.svg",
    ),
    (
        "demo favicon",
        "brandbook/assets/logo/rs-favicon.svg",
        "examples/demo/backend/priv/static/favicon.svg",
    ),
]

REQUIRED_SHELL_MARKERS = [
    "class=\"rs-shell__wordmark\"",
    "class=\"rs-shell__wordmark-line\"",
    "class=\"rs-shell__wordmark-active\"",
    "class=\"rs-shell__wordmark-muted\"",
    "class=\"rs-shell__wordmark-type\"",
]

REQUIRED_CSS_MARKERS = [
    "--logo-line:",
    "--logo-active:",
    "--logo-muted:",
    "--logo-type:",
    ".rs-shell__wordmark",
    ".rs-shell__fixture-wordmark",
]


def read_bytes(rel_path):
    path = ROOT / rel_path
    if not path.exists():
        raise FileNotFoundError(rel_path)
    return path.read_bytes()


def main():
    failures = []

    for label, source, target in PAIRS:
        try:
            if read_bytes(source) != read_bytes(target):
                failures.append(f"{label}: {target} differs from {source}")
        except FileNotFoundError as exc:
            failures.append(f"{label}: missing {exc}")

    shell = (ROOT / "rulestead_admin/lib/rulestead_admin/components/shell.ex").read_text()
    for marker in REQUIRED_SHELL_MARKERS:
        if marker not in shell:
            failures.append(f"admin shell missing marker: {marker}")

    css = (ROOT / "rulestead_admin/priv/static/css/rulestead_admin.css").read_text()
    for marker in REQUIRED_CSS_MARKERS:
        if marker not in css:
            failures.append(f"admin css missing marker: {marker}")

    if failures:
        for failure in failures:
            print(f"LOGO ASSET DRIFT: {failure}")
        sys.exit(1)

    print(f"LOGO ASSETS SYNCED ({len(PAIRS)} copies + shell markers)")


if __name__ == "__main__":
    main()
