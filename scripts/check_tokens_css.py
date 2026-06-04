#!/usr/bin/env python3
"""Mirror-drift check: brandbook/tokens.css vs brandbook/tokens.json admin_css_mapping.

brandbook/tokens.css is a hand-authored REFERENCE MIRROR of the design tokens. Its
source of truth is brandbook/tokens.json's admin_css_mapping (light + dark). This guard
verifies the mirror has not drifted from that source. Unlike check_brand_tokens.py (which
intentionally exits 1 against the un-re-skinned admin cascade), this check is green now
and stays green — it protects the mirror against future drift during Phase 98's re-skin.

Mirrors check_brand_tokens.py: strip comments first (Pitfall 3 guard — the Tailwind
excerpt and block headers live inside /* */ comments), brace-walk extraction, case-
insensitive hex compare, per-token sorted diff, exit codes. Checks BOTH light and dark.

Usage (from repo root):
    python3 scripts/check_tokens_css.py
Exits 0 and prints "TOKENS.CSS MIRROR SYNCED (N tokens)" on success; exits 1 on mismatch.
"""
import sys
import re
import json

TOKENS_JSON = "brandbook/tokens.json"
TOKENS_CSS = "brandbook/tokens.css"

# (mode key in admin_css_mapping, css block selector to brace-walk)
MODES = [
    ("light", ".rs-shell,"),
    ("dark", '.rs-shell[data-theme="dark"],'),
]


def extract_css_decls(css, sel):
    """Locate selector in comment-stripped css, brace-walk to extract --rs-* declarations dict.

    Note: caller must strip comments first before passing css here (Pitfall 3: tokens.css
    embeds block-header comments and a commented-out Tailwind excerpt that mention these
    selectors and hex values — without stripping, css.find() / parsing matches inside the
    comment, not the actual block). val.strip() normalizes the aligned-spacing in the
    dark block (e.g. `--rs-primary:       #5885a0`).
    """
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
    result = {}
    for line in css[j + 1 : k].splitlines():
        line = line.strip()
        if line.startswith("--rs-") and ":" in line:
            name, _, val = line.partition(":")
            result[name.strip()] = val.strip().rstrip(";")
    return result


def main():
    tokens = json.load(open(TOKENS_JSON))  # raises json.JSONDecodeError on malformed JSON — free validity check
    admin_mapping = tokens["admin_css_mapping"]

    raw = open(TOKENS_CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first (Pitfall 3 guard)

    mismatches = []
    matched = 0
    for mode, sel in MODES:
        mapping = admin_mapping[mode]
        css_decls = extract_css_decls(css, sel)

        if css_decls is None:
            print(f"ERROR: {mode} block selector '{sel}' not found in {TOKENS_CSS}")
            return 1

        for name, expected in sorted(mapping.items()):
            if not name.startswith("--rs-"):
                continue  # skip DTCG metadata keys like $description
            css_val = css_decls.get(name)
            if css_val is None:
                mismatches.append(f"  [{mode}] {name}: tokens.json={expected}  css=<missing>")
            elif css_val.lower() != expected.lower():  # case-insensitive: #3A6F8F == #3a6f8f
                mismatches.append(f"  [{mode}] {name}: tokens.json={expected}  css={css_val}")
            else:
                matched += 1

    if not mismatches:
        print(f"TOKENS.CSS MIRROR SYNCED ({matched} tokens)")
        return 0

    print("TOKENS.CSS MIRROR DRIFT DETECTED")
    for m in mismatches:
        print(m)
    return 1


if __name__ == "__main__":
    sys.exit(main())
