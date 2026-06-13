#!/usr/bin/env python3
"""Token-drift check: brandbook/tokens.json admin_css_mapping vs rulestead_admin.css Blocks 1 + 3.

Mirrors check_synced_pair.py: strip comments first (Pitfall 3 guard), brace-walk extraction,
per-token sorted diff, exit codes.

Checks:
  - Block 1 (.rs-shell, default light) vs admin_css_mapping.light
  - Block 3 (.rs-shell[data-theme="dark"]) vs admin_css_mapping.dark  (D-05b additive)

Usage (from repo root):
    python3 scripts/check_brand_tokens.py
Exits 0 and prints "BRAND TOKENS SYNCED (N tokens)" on success; exits 1 on mismatch.
"""
import sys
import re
import json

TOKENS_JSON = "brandbook/tokens.json"
CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"


def extract_css_decls(css, sel):
    """Locate selector in comment-stripped css, brace-walk to extract --rs-* declarations dict.

    Note: caller must strip comments first before passing css here (Pitfall 3: the
    rulestead_admin.css header comment documents all four block selectors — without
    stripping, css.find() matches inside the comment, not the actual block).
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
    mapping = tokens["admin_css_mapping"]["light"]

    raw = open(CSS).read()
    css = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)  # strip comments first (Pitfall 3 guard)
    css_decls = extract_css_decls(css, ".rs-shell,")

    if css_decls is None:
        print("ERROR: Block 1 selector '.rs-shell,' not found in CSS")
        return 1

    mismatches = []
    matched = 0
    for name, expected in sorted(mapping.items()):
        if not name.startswith("--rs-"):
            continue  # skip DTCG metadata keys like $description
        css_val = css_decls.get(name)
        if css_val is None:
            mismatches.append(f"  {name}: tokens.json={expected}  css=<missing>")
        elif css_val.lower() != expected.lower():  # case-insensitive: #3A6F8F == #3a6f8f
            mismatches.append(f"  {name}: tokens.json={expected}  css={css_val}")
        else:
            matched += 1

    # D-05b: Block 3 dark diff — folded into the same mismatches list as the light diff above.
    # Note: --rs-success-border target is #166634 (tokens.json); CSS currently has #166534
    # (one-digit transposition — highest-risk diff, Pitfall 1 in RESEARCH.md).
    mapping_dark = tokens["admin_css_mapping"]["dark"]
    css_dark = extract_css_decls(css, '.rs-shell[data-theme="dark"],')

    if css_dark is None:
        print('ERROR: Block 3 selector \'.rs-shell[data-theme="dark"],\' not found in CSS')
        return 1

    for name, expected in sorted(mapping_dark.items()):
        if not name.startswith("--rs-"):
            continue  # skip DTCG metadata keys like $description
        css_val = css_dark.get(name)
        if css_val is None:
            mismatches.append(f"  [dark] {name}: tokens.json={expected}  css=<missing>")
        elif css_val.lower() != expected.lower():  # case-insensitive comparison (D-04a)
            mismatches.append(f"  [dark] {name}: tokens.json={expected}  css={css_val}")
        else:
            matched += 1

    if not mismatches:
        print(f"BRAND TOKENS SYNCED ({matched} tokens)")
        return 0

    print("BRAND TOKEN DRIFT DETECTED")
    for m in mismatches:
        print(m)
    return 1


if __name__ == "__main__":
    sys.exit(main())
