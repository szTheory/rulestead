#!/usr/bin/env python3
"""Verify the rulestead_admin dark-theme SYNCED PAIR is byte-identical.

The dark token set is declared twice — in the `@media (prefers-color-scheme: dark)`
block and the explicit `.rs-shell[data-theme="dark"]` block (plain CSS has no @apply).
They MUST stay identical. This script strips CSS comments first, because the token
section's header comment documents those very selectors and would otherwise make the
plain-text find() match inside the comment.

Usage (from repo root):
    python3 scripts/check_synced_pair.py
Exits 0 and prints "SYNCED PAIR IDENTICAL (N tokens)" on success; exits 1 on mismatch.
"""
import sys
import re

CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"


def decls(css, sel):
    i = css.find(sel)
    if i < 0:
        return None
    j = css.find("{", i)
    depth = 0
    k = j
    while k < len(css):
        if css[k] == "{":
            depth += 1
        elif css[k] == "}":
            depth -= 1
            if depth == 0:
                break
        k += 1
    return sorted(
        line.strip()
        for line in css[j + 1 : k].splitlines()
        if line.strip().startswith("--rs-")
    )


def main():
    raw = open(CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first
    media = decls(css, "@media (prefers-color-scheme: dark)")
    attr = decls(css, '.rs-shell[data-theme="dark"]')
    if media and media == attr:
        print(f"SYNCED PAIR IDENTICAL ({len(media)} tokens)")
        return 0
    print("SYNCED PAIR MISMATCH")
    if media is not None and attr is not None:
        only_media = [t for t in media if t not in attr]
        only_attr = [t for t in attr if t not in media]
        for t in only_media:
            print("  only in @media:", t)
        for t in only_attr:
            print("  only in [data-theme=dark]:", t)
    return 1


if __name__ == "__main__":
    sys.exit(main())
