#!/usr/bin/env python3
"""Verify the rulestead_admin SYNCED PAIRS are byte-identical (dark + light).

The dark token set is declared twice — in the `@media (prefers-color-scheme: dark)`
block (Block 2) and the explicit `.rs-shell[data-theme="dark"]` block (Block 3).
The light token set is also declared twice — in the `.rs-shell,` default block (Block 1)
and the explicit `.rs-shell[data-theme="light"]` block (Block 4).
All synced pairs MUST stay identical. This script strips CSS comments first, because the
token section's header comment documents those very selectors and would otherwise make the
plain-text find() match inside the comment.

Usage (from repo root):
    python3 scripts/check_synced_pair.py
Exits 0 and prints both "SYNCED PAIR IDENTICAL" lines on success; exits 1 on any mismatch.
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

    # D-05 Block 2≡3 dark-pair check (existing)
    media = decls(css, "@media (prefers-color-scheme: dark)")
    attr = decls(css, '.rs-shell[data-theme="dark"]')
    if media and media == attr:
        print(f"SYNCED PAIR IDENTICAL ({len(media)} tokens)")
    else:
        print("SYNCED PAIR MISMATCH")
        if media is not None and attr is not None:
            only_media = [t for t in media if t not in attr]
            only_attr = [t for t in attr if t not in media]
            for t in only_media:
                print("  only in @media:", t)
            for t in only_attr:
                print("  only in [data-theme=dark]:", t)
        return 1

    # D-05a Block 1≡4 light-pair check (additive — does not change dark-pair logic above)
    light_default = decls(css, ".rs-shell,")
    light_pinned = decls(css, '.rs-shell[data-theme="light"]')
    if light_default and light_default == light_pinned:
        print(f"SYNCED PAIR IDENTICAL (light: {len(light_default)} tokens)")
    else:
        print("SYNCED PAIR MISMATCH (light)")
        if light_default is not None and light_pinned is not None:
            only_default = [t for t in light_default if t not in light_pinned]
            only_pinned = [t for t in light_pinned if t not in light_default]
            for t in only_default:
                print("  only in .rs-shell default:", t)
            for t in only_pinned:
                print("  only in [data-theme=light]:", t)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
