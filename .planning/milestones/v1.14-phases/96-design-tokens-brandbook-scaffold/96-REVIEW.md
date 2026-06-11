---
status: clean
phase: 96-design-tokens-brandbook-scaffold
reviewed: 2026-06-04
scope: scripts/check_brand_tokens.py, scripts/ci/lint.sh (additive), brandbook/tokens.json, brandbook/tokens.css
---

# Phase 96 — Code Review

**Verdict: CLEAN** (advisory, non-blocking). Reviewed the changed source surface.

## scripts/check_brand_tokens.py
- Faithful mirror of `check_synced_pair.py`: python3 stdlib only (`sys`, `re`, `json`); strips CSS comments with `re.sub(r"/\*.*?\*/", "", raw, flags=re.S)` BEFORE `css.find()` (Pitfall 3 guard); brace-depth walk extracts a `--rs-*` name→value dict from Block 1 (`.rs-shell,`).
- Compares `admin_css_mapping.light` case-insensitively (`#3A6F8F == #3a6f8f`) — correct for the mixed-case canonical hexes.
- Skips DTCG metadata keys (`if not name.startswith("--rs-"): continue`) — the auto-fix the executor applied; correct.
- `json.load(open(...))` gives free JSON-validity checking; raises on malformed input.
- Exit codes correct: 0 + `BRAND TOKENS SYNCED (N tokens)` on match; 1 + per-token diff on mismatch. Verified to exit **1** against the un-re-skinned admin CSS (the intended Phase-96 gate-green state).

### Minor (non-blocking, matches existing repo idiom)
- `open(CSS).read()` / `open(TOKENS_JSON)` without explicit close — identical to `check_synced_pair.py`; the process exits immediately, so no leak in practice. Not worth diverging from the established pattern.
- Mapping→CSS direction only (does not assert every CSS token is mapped). Correct for drift-detection purpose; the synced-pair check and Phase 98 cover the rest.

## scripts/ci/lint.sh
- Strictly additive: all 15 original lines preserved verbatim; appends `check_synced_pair.py` (closes the Pitfall-6 CI gap), `check_brand_tokens.py`, and a `nullglob` + `wc -c` SVG size-budget loop (no-op-safe when zero SVGs exist).
- **Known intended consequence:** the appended `python3 check_brand_tokens.py` runs unguarded under `set -euo pipefail`, so `lint.sh` (and CI) exits non-zero on this branch until Phase 98 re-skins `rulestead_admin.css`. This is the documented gate-zero design (ROADMAP Phase 96 goal: "the drift check demonstrably fails … before Phase 98"); CI goes green at Phase 98, before any merge to main. Honest call-out, not a defect.

## brandbook/tokens.json / tokens.css
- Valid DTCG 2025.10 JSON; `.rs-shell`/`[data-rulestead]` color scope only (no `:root` color); Tailwind excerpt commented-out and side-effect-free. No issues.

No fixes required.
