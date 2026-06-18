# Phase 125: Version-Truth Sweep + Release Docs - Pattern Map

**Mapped:** 2026-06-18
**Files analyzed:** 18 (1 new executable, 1 new staged artifact, 1 test modify, 1 lint wiring modify, 13 doc sweeps + 2 additive doc sections)
**Analogs found:** 4 strong analogs covering all net-new/structural work / 18

> The only net-new executable code is `scripts/check_version_truth.py`. Everything else is
> either a prose sweep (no code analog), an in-file additive section (analog = the file's own
> existing sections), a one-line shell insertion, or a test re-anchor (analog = the assert style
> already in that test). This map gives the planner a concrete, copy-ready skeleton for the guard
> and exact excerpts for the structural edits.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/check_version_truth.py` (NEW) | CI guard (utility/script) | file-I/O scan + fail-closed exit | `scripts/check_logo_assets.py` (glob+exit shape) + `scripts/check_brand_tokens.py` (docstring/messaging convention) | role+flow exact |
| `scripts/ci/lint.sh` (MODIFY) | CI orchestration (config) | request-response (invoke) | the existing `python3 "${RULESTEAD_REPO}/scripts/check_*.py"` block (L43-69) | exact |
| `rulestead/test/.../release_contract_test.exs` (MODIFY) | test | transform (string assert re-anchor) | same file, assert style at L232-291 | exact |
| `brandbook/CHANGELOG-PREAMBLE-1.0.md` (NEW) | release-staging artifact (doc) | file-I/O (staged text) | `brandbook/RELEASE-TEMPLATE.md` | role-match (sibling staging artifact) |
| `guides/introduction/upgrading.md` (MODIFY + new §) | doc | transform (prose) | the file's own existing H2 sections | exact (self) |
| `MAINTAINING.md` (MODIFY + new runbook §) | doc | transform (prose) | the file's own `## Release Please flow` / `## Gated publish choreography` sections | exact (self) |
| 11 remaining swept docs (MODIFY) | doc | transform (prose) | none needed — mechanical string reframe | n/a (prose) |

---

## Pattern Assignments

### `scripts/check_version_truth.py` (NEW — CI guard, file-I/O scan + fail-closed)

**Primary analog:** `scripts/check_logo_assets.py` (the cleanest repo-root-resolution + glob + `sys.exit(1)` shape).
**Convention analog:** `scripts/check_brand_tokens.py` (the `main() -> int` + `sys.exit(main())` + "Usage (from repo root)" docstring + `UPPERCASE OK`/`DRIFT` messaging convention).

There are two established shapes among the 8 sibling guards. Copy this hybrid:
- **Repo-root resolution** — copy from `check_logo_assets.py:8` (`ROOT = Path(__file__).resolve().parents[1]`). This makes the script work regardless of CWD; `lint.sh` also `cd`s to repo root first (L40), so relative paths resolve either way. Prefer `ROOT /` to be robust.
- **Glob over `guides/`** — `Path.rglob` per RESEARCH Gap 2.
- **`main()` returns `int`, `sys.exit(main())`** — copy from `check_brand_tokens.py:53,109-110`.
- **Success/failure messaging** — copy the `BRAND TOKENS SYNCED (N)` / `BRAND TOKEN DRIFT DETECTED` + per-line listing convention from `check_brand_tokens.py:99-106`. Use `VERSION TRUTH OK` / `VERSION TRUTH DRIFT`.

**Imports pattern** (from `check_logo_assets.py:1-9` + `check_brand_tokens.py:15-17`):
```python
#!/usr/bin/env python3
"""Version-truth drift guard: shipped docs must not reintroduce 0.1.x release language.

Usage (from repo root):
    python3 scripts/check_version_truth.py
Exits 0 and prints "VERSION TRUTH OK (N files clean)" on success; exits 1 and lists
path:line: <hit> on drift.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
```

**Fail-closed exit pattern** (mirror `check_logo_assets.py:68-93` collect-then-report, but return `int` per `check_brand_tokens.py:99-106`):
```python
def main():
    hits = []
    for rel in iter_target_files():           # see file-list pattern below
        path = ROOT / rel
        for n, line in enumerate(path.read_text().splitlines(), start=1):
            for pat in PATTERNS:
                if pat.search(line):
                    hits.append(f"{rel}:{n}: {line.strip()}")

    if hits:
        print("VERSION TRUTH DRIFT DETECTED")
        for h in hits:
            print(f"  {h}")
        return 1

    print("VERSION TRUTH OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

**File-list / glob pattern** (criterion-1 set per CONTEXT D-06 + RESEARCH Gap 2 — explicit fixed list + recursive `guides/` glob; do NOT scan `.planning/`, `prompts/`, `rulestead/doc/`, `examples/`):
```python
FIXED_FILES = [
    "README.md",
    "rulestead/README.md",
    "rulestead_admin/README.md",
    "open_feature_rulestead/README.md",
    "MAINTAINING.md",
    "CONTRIBUTING.md",   # D-02: zero hits today, but guard must cover it for future drift
]

def iter_target_files():
    yield from FIXED_FILES
    for p in sorted(ROOT.joinpath("guides").rglob("*.md")):
        yield str(p.relative_to(ROOT))
    for p in sorted(ROOT.joinpath("guides").rglob("*.cheatmd")):
        yield str(p.relative_to(ROOT))
```

**Pattern set — the load-bearing part** (CONTEXT D-06 / RESEARCH Gap 2; the `(?![.\d])` lookahead is the landmine guard — it matches `~> 0.1"` / `~> 0.1,` but NOT the legitimate third-party `~> 0.1.3` in `open_feature_rulestead/README.md:28`):
```python
PATTERNS = [
    re.compile(r"0\.1\.x"),
    re.compile(r"0\.1\.7"),
    re.compile(r"future[^\n]*1\.0", re.I),
    re.compile(r"1\.0 API freeze"),
    re.compile(r"Two version lines"),
    re.compile(r"~> 0\.1(?![.\d])"),   # anchored: matches `~> 0.1"` NOT `~> 0.1.3`
]
```
No per-file carve-out is needed for `open_feature_rulestead/README.md:28` — the lookahead handles it (RESEARCH Gap 2, verified live). After the sweep flips L29 to `~> 1.0`, L28 `~> 0.1.3` is the only `~> 0.1*` left in that file and the lookahead correctly skips it.

**Why both analogs, not one:** `check_logo_assets.py` gives the lean `Path`-rooted scan-and-collect; `check_brand_tokens.py` gives the `main()->int` / `sys.exit(main())` / docstring-with-usage / `UPPERCASE OK` convention that 8/8 guards share. The new guard should be `chmod +x` (most siblings are `-rwxr-xr-x`); `lint.sh` invokes via `python3 ...` so the bit is cosmetic but matches convention.

---

### `scripts/ci/lint.sh` (MODIFY — add one guard invocation)

**Analog:** the existing Python-guard block, `lint.sh:43-69` (8 identical `python3 "${RULESTEAD_REPO}/scripts/check_*.py"` lines, each with a leading comment).

**Insertion pattern** (copy the comment-then-invoke shape; RESEARCH Gap 2 recommends after the `check_logo_assets.py` line at L62, but anywhere in the L43-69 block works since `cd "${RULESTEAD_REPO}"` at L40 already set repo root):
```bash
# Version-truth drift: shipped docs must not reintroduce 0.1.x release language.
python3 "${RULESTEAD_REPO}/scripts/check_version_truth.py"
```
`set -euo pipefail` (L2) makes any non-zero exit fail the lane — this is what makes the guard fail-closed. No other lint.sh change.

---

### `rulestead/test/rulestead/release_contract_test.exs` (MODIFY — re-anchor 6 asserts, keep 1 survivor)

**Analog:** the assert style in the same file. Path consts at L8-18 (`File.read!` into locals); the target asserts live in two tests: `public release docs...` (L224-270) and `maintainer guidance...` (L272-308).

**Current assert style** (L232-265, verbatim — this is what to re-anchor):
```elixir
assert root_readme =~ "v1.0.0"           # L232 — KEEP (already 1.0 truth)
assert root_readme =~ "0.1.x"            # L233 — FLIP → "1.0" / "~> 1.0"
assert root_readme =~ "Two version lines" # L234 — DELETE assert, REPLACE with positive (e.g. `=~ "~> 1.0"`)
...
assert runtime_readme =~ "0.1.x"         # L249 — FLIP → "1.0" / "~> 1.0"
...
assert admin_readme =~ "0.1.x"           # L254 — FLIP → "1.0" / "~> 1.0"
...
assert upgrading =~ "v1.0.0"             # L261 — KEEP
assert upgrading =~ "0.1.x"              # L262 — FLIP → "~> 1.0" (deliberate; NOT the heading-by-accident)
...
assert demo_readme =~ "0.1.x"            # L265 — SURVIVOR, KEEP (demo README not swept, D-03)
```

**Second test** (L283-285):
```elixir
assert maintaining =~ "v1.0.0"           # L283 — KEEP
assert maintaining =~ "2026-05-21"       # L284 — KEEP
assert maintaining =~ "0.1.x"            # L285 — FLIP → "1.0" / "Cutting a major"
```

**Re-anchor rule (RESEARCH Gap 1 + Pitfall 2):**
- Flip 6 asserts: L233, L234, L249, L254, L262, L285 to positive `1.0`-truth substrings that the sweep actually introduces in the same file (verify by running the test after the sweep).
- L234 must be **deleted + replaced** with a positive guard (e.g. `assert root_readme =~ "~> 1.0"`), not just deleted — keep version truth enforced, no hole.
- L262: do NOT leave a bare `=~ "0.1.x"` that passes by coincidence on the new `"Upgrading 0.1.x → 1.0"` heading. Anchor deliberately to `~> 1.0` (or explicitly to the full heading string).
- **CONTEXT D-10 over-counts:** there is exactly ONE `maintaining =~ "0.1.x"` (L285), NOT two. `grep -n 'maintaining =~ "0.1.x"'` returns one hit. Do not hunt for a phantom second assert in the maintainer-guidance test.
- L232/L261/L283 (`v1.0.0`) and L284 (`2026-05-21`) already assert 1.0 truth — leave them green.
- Survivor: L265 `demo_readme =~ "0.1.x"` stays unchanged (demo README is out of sweep scope, D-03).

---

### `brandbook/CHANGELOG-PREAMBLE-1.0.md` (NEW — staged release artifact)

**Analog:** `brandbook/RELEASE-TEMPLATE.md` (the established "ready-but-unapplied release text" home — sibling staging artifact).

**Tone/structure to inherit** (from `RELEASE-TEMPLATE.md:50-56` Microcopy Rules): operator-consequence-first, "state what changed and what did not change", no hype. This is a short two-package Markdown snippet meant to be pasted ABOVE release-please's generated `1.0.0` bullets during the Phase 128 release PR. It is NOT committed into `rulestead/CHANGELOG.md` / `rulestead_admin/CHANGELOG.md` (those are bot-managed; D-09).

**Recommended shape** (RESEARCH Gap 5 — "promotion, not rewrite", explicit zero breaking changes, dep-pin bump only, two-package linked-versions):
```markdown
## 1.0.0 — Promotion, not rewrite

`rulestead` and `rulestead_admin` graduate to `1.0.0`. This is the same
battle-tested code, now honestly versioned — **zero breaking changes**.

- No public API changes; the surface in `guides/api_stability.md` is unchanged.
- Upgrade is a dependency-pin bump only: `~> 0.1` → `~> 1.0`. See
  `guides/introduction/upgrading.md`.
- Both sibling packages move together (linked versions).
```
Note: this file legitimately contains `0.1` and `~> 0.1` in upgrade-instruction context, but it lives in `brandbook/` which the guard does NOT scan — no conflict with `check_version_truth.py`.

---

### `guides/introduction/upgrading.md` (MODIFY — sweep + new "Upgrading 0.1.x → 1.0" §)

**Analog:** the file's own existing H2 structure (`## What to review before upgrading` L15, `## Public contract posture` L21, `## Practical rule` L26).

**Insertion point** (RESEARCH Gap 4): new H2 immediately after the L5 intro, BEFORE the (reframed) callout — so it is the first section a reader hits. Content: zero code changes, dep-pin bump only (`~> 0.1` → `~> 1.0`), "promotion, not rewrite" framing. The L3-8 stale callout is reframed (keep the `v1.0.0` GA / 2026-05-21 facts; drop the "0.1.x semver until a future 1.0 API freeze" framing). Sweep L3-4, L8, L10, L24, L30 per the sweep map.

**Contract-test coupling:** the L262 anchor must match a string in the swept output (see test section above).

---

### `MAINTAINING.md` (MODIFY — sweep + new "## Cutting a major (X.0.0)" runbook §)

**Analog:** the file's own existing release sections — `## Release Please flow` (L139), `## Gated publish choreography` (L165). Mirror their heading + prose + numbered/checklist style.

**Insertion point** (RESEARCH Gap 3/4): new `## Cutting a major (X.0.0)` after `## Gated publish choreography` (ends ~L188) and before `## Manual recovery path` (L189) — keeps release-cut content contiguous. Runbook must cover (D-07/D-08):
- The `Release-As` mechanism (config-block `"release-as": "1.0.0"` in `release-please-config.json` `rulestead` block as the major-cut path; the `release-please.yml:85` bootstrap echo is historical).
- Package publish sequence (`rulestead` first, then `rulestead_admin`).
- Deprecation-window checklist (ties to Phase-124 `api_stability.md` soft→hard→remove policy).
- **Mandatory post-cut removal** of `"release-as": "1.0.0"` from `release-please-config.json` (else the bot re-proposes 1.0.0 forever).
- **D-08 accuracy:** `open_feature_rulestead` is NOT release-please managed — it is a separate manual publish (Phase 129). State this explicitly; only `rulestead` + `rulestead_admin` are linked-versions.

Sweep L11-12, L167, L592. Contract-test L285 anchor must match swept/added MAINTAINING text.

---

### 11 remaining swept docs (MODIFY — mechanical prose reframe, no code analog)

`README.md` (root), `rulestead/README.md`, `rulestead_admin/README.md`, `open_feature_rulestead/README.md`, `guides/cheatsheet.cheatmd`, `guides/introduction/getting-started.md`, `guides/introduction/phoenix-integration-spine.md`, `guides/introduction/product-boundary.md`, `guides/introduction/installation.md`, `guides/flows/telemetry.md`.

No code analog needed — these are prose edits. Per-line actions are fully enumerated in RESEARCH §Gap 6 (the authoritative file-by-file sweep map). Pattern notes:
- **Callout admonition syntax:** the "Two version lines" callouts are Markdown blockquote-style callouts — delete entirely (root README L6-10, criterion 2) or reframe in the package READMEs/guides. Match the file's existing callout syntax when reframing.
- **Preserve verbatim (D-04):** `open_feature_rulestead/README.md:28` `{:open_feature, "~> 0.1.3"}` — NEVER touch (real upstream pin; editing bricks adopter `mix deps.get`).
- **Out of scope (Pitfall 3):** do NOT sweep `v0.1.0` historical strings — they are not criterion-1 patterns and pervade `guides/`.

---

## Shared Patterns

### Fail-closed scripts-first CI guard
**Source:** `scripts/check_brand_tokens.py` (convention) + `scripts/check_logo_assets.py` (scan shape) + `scripts/ci/lint.sh:43-69` (wiring).
**Apply to:** `scripts/check_version_truth.py` + its `lint.sh` invocation.
- `main()` returns `int`; `sys.exit(main())`.
- Collect all hits, then report (don't bail on first) — `check_logo_assets.py:68-93`.
- `UPPERCASE OK (...)` on success / `UPPERCASE DRIFT DETECTED` + indented per-item list on failure — `check_brand_tokens.py:99-106`.
- Module docstring includes literal `Usage (from repo root):` line — all 8 siblings do.
- Wire into the `lint.sh` Python-guard block (L43-69) with a one-line `#` comment above the `python3 "${RULESTEAD_REPO}/scripts/..."` invocation; `set -euo pipefail` makes it fail-closed.

### Bidirectional doc↔code lockstep
**Source:** `rulestead/test/rulestead/release_contract_test.exs` (path consts L8-18, `File.read!` + `=~` asserts).
**Apply to:** the sweep + test re-anchor must land in ONE atomic change. The test reads real files and asserts strings the sweep removes — editing docs first reds the suite; editing the test first leaves a hole. Re-anchor (don't bare-delete) to positive `1.0`-truth substrings present in the swept output.

### Release-staging artifact home
**Source:** `brandbook/RELEASE-TEMPLATE.md` (microcopy rules L50-56).
**Apply to:** `brandbook/CHANGELOG-PREAMBLE-1.0.md` — `brandbook/` is the established home for ready-but-unapplied release text; keeps it out of the bot-managed CHANGELOGs (D-09) and the guard's scan set.

---

## No Analog Found

None. Every structural/executable artifact has a strong in-repo analog. The 11 mechanical
prose sweeps need no analog (string reframes enumerated in RESEARCH §Gap 6).

---

## Metadata

**Analog search scope:** `scripts/check_*.py` (8 files listed), `scripts/ci/lint.sh`, `brandbook/`, `rulestead/test/rulestead/release_contract_test.exs`.
**Files scanned (read this session):** `check_brand_tokens.py`, `check_logo_assets.py`, `lint.sh`, `RELEASE-TEMPLATE.md`, `release_contract_test.exs` (L1-20, L224-313).
**Key verification:** confirmed exactly ONE `maintaining =~ "0.1.x"` assert (L285) — CONTEXT D-10's "two" over-count is corrected, matching RESEARCH Pitfall 2.
**Pattern extraction date:** 2026-06-18
