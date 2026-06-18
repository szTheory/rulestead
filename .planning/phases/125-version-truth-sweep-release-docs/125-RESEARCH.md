# Phase 125: Version-Truth Sweep + Release Docs - Research

**Researched:** 2026-06-18
**Domain:** Release-truth documentation sweep + fail-closed CI drift guard + release-please runbook authoring (Elixir/Hex monorepo)
**Confidence:** HIGH (every claim verified against live repo files this session)

## Summary

Phase 125 makes every **shipped** file tell the truth about the `1.x` line, adds a fail-closed
CI drift guard (`scripts/check_version_truth.py` wired into `scripts/ci/lint.sh`), and stages
the upgrade/major-bump/CHANGELOG release docs needed before the Phase 128 cut. CONTEXT.md
(D-01..D-10) is exceptionally well-specified and its file inventory is **accurate** — I verified
all 13 swept files line-for-line against the live tree and the criterion-1 grep reproduces the
exact hit set CONTEXT enumerated. This research **verifies** those locked decisions and fills the
six gaps the orchestrator flagged, surfacing **three CONTEXT inaccuracies** the planner must
correct.

The single most important correction: **CONTEXT-125 D-10 is wrong about there being two
`maintaining =~ "0.1.x"` asserts.** There is exactly **one** (`release_contract_test.exs:285`).
The complete set of contract-test asserts the sweep makes go-false is exactly the six lines
Phase-124 D-03 already enumerated (233, 234, 249, 254, 262, 285) **plus** the survivor at 265 —
seven `0.1.x`/"Two version lines" asserts total, of which only the demo assert (L265) survives.
Two further corrections (manifest is `0.1.7` not `0.1.0`; many out-of-scope `v0.1.0` strings exist
in guides) are detailed below.

**Primary recommendation:** Execute the sweep + contract-test re-anchor as a **single atomic
change** (the bidirectional guard forces lockstep — D-10), implement the drift guard with a Python
**negative-lookahead** regex (`~> 0\.1(?![.\d])`) mirroring the existing `check_brand_tokens.py`
structure, and scope both the sweep and the guard strictly to the **criterion-1 grep patterns**
(`0.1.x`, `~> 0.1`, `0.1.7`, `future…1.0`, `1.0 API freeze`, `Two version lines`) — explicitly
NOT the broader `v0.1.0` historical strings that pervade the guides.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A. File inventory — 13 shipped files (D-01):** Sweep these 13 files, replacing `~> 0.1`→`~> 1.0`,
`0.1.x`→`1.0`/`1.x`, deleting "future 1.0" / "1.0 API freeze" / "Two version lines" framing:
`README.md` (root; L6-10 callout deleted entirely, L40, L99-100, L194), `rulestead/README.md`
(L9, L11-12, L33), `rulestead_admin/README.md` (L9, L12-13, L22-23), `open_feature_rulestead/README.md`
(L29 own line + L14-15 prose; **L28 `{:open_feature, "~> 0.1.3"}` untouched**), `guides/cheatsheet.cheatmd`
(L8-9), `guides/introduction/getting-started.md` (L3, L6-8, L15, L21-22, L26),
`guides/introduction/phoenix-integration-spine.md` (L19-20), `guides/introduction/product-boundary.md`
(L20 heading, L28), `guides/introduction/installation.md` (L9, L11-12, L22, L35-36),
`guides/introduction/upgrading.md` (L3-4, L7-8, L10, L24, L30 + new section D-07),
`guides/flows/telemetry.md` (L4), `MAINTAINING.md` (L11-12, L167, L592 + new runbook D-07).

- **D-02:** `CONTRIBUTING.md` has zero stale hits but the guard must still cover it.
- **D-03:** `examples/demo/README.md` is NOT swept (outside criterion-1; contract test L265 asserts it).
- **D-04:** Three exclusion classes preserved verbatim: third-party pin (`open_feature_rulestead/README.md:28`),
  generated `rulestead/doc/`, historical refs (`.planning/`, `prompts/`, demo README).
- **D-05:** Ship guard as new `scripts/check_version_truth.py` wired into `scripts/ci/lint.sh`,
  fail-closed `exit 1`.
- **D-06:** Guard scans ONLY the criterion-1 shipped surface (root + 3 package READMEs + `guides/` +
  `MAINTAINING.md` + `CONTRIBUTING.md`); `~> 0.1` matched anchored so `~> 0.1.3` does NOT trip it;
  exclude `.planning/`, `prompts/`, `rulestead/doc/`, `examples/`, the open_feature third-party line.
- **D-07:** Additive sections (reframe in place): `upgrading.md` "Upgrading 0.1.x → 1.0" (zero code
  changes, dep-pin bump only, "promotion not rewrite"); `MAINTAINING.md` "## Cutting a major (X.0.0)"
  runbook (Release-As mechanism, publish sequence, deprecation-window checklist, mandatory post-cut
  `Release-As` removal).
- **D-08:** Runbook must state `open_feature_rulestead` is NOT release-please managed (manual publish,
  Phase 129); only `rulestead` + `rulestead_admin` are linked-versions.
- **D-09:** CHANGELOG preamble ships as staged `brandbook/CHANGELOG-PREAMBLE-1.0.md` (sibling to
  `brandbook/RELEASE-TEMPLATE.md`), NOT committed into the bot-managed CHANGELOGs.
- **D-10:** `release_contract_test.exs` asserts must be re-anchored in the same change (OVERRIDES
  Phase 124 D-03 for swept files). Re-anchor to positive `1.0`-truth strings, don't just delete.
  Survivor: `demo_readme =~ "0.1.x"` (L265).

### Claude's Discretion
- Exact replacement prose for each swept line (reframe idiomatically, don't mechanically string-swap).
- Exact regex/fixed-string anchoring inside `check_version_truth.py` and its placement in `lint.sh`.
- Exact section wording/placement of upgrading.md + MAINTAINING.md additions and the new positive
  `1.0`-truth contract-test anchors.
- Exact wording of `brandbook/CHANGELOG-PREAMBLE-1.0.md`.

### Deferred Ideas (OUT OF SCOPE)
- The actual `Release-As: 1.0.0` cut / publish / post-cut removal — Phase 128 (REL-01, REL-04, REL-06).
  This phase only *documents* the runbook and *stages* the preamble.
- `open_feature_rulestead` manual `1.0.0` publish + dep swap — Phase 129 (REL-05).
- HexDocs front-door theming/logo (Phase 126), adoption guides (Phase 127).
- `.planning/` and `prompts/` historical `0.1.x` references — left untouched, historically accurate.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-02 | Version-truth sweep reframes the stale `0.1.x` files to 1.0 reality, deletes the README "two version lines" callout, adds a CI drift guard to `lint.sh`; `.planning/`/`prompts/` left untouched. | §Full File-by-File Sweep Map (authoritative 13-file line list, verified); §Drift-Guard Design (`check_version_truth.py` regex set + `lint.sh` wiring); §Contract-Test Surgery Map (lockstep re-anchor). |
| REL-03 | `1.0.0` CHANGELOG framed "promotion, not rewrite"; `upgrading.md` documents 0.1.x→1.0 (dep-pin bump only); `MAINTAINING.md` gains "Cutting a major" runbook. | §release-please Mechanics (runbook accuracy: Release-As, linked-versions, manual provider, no-op flags); §upgrading.md + MAINTAINING.md Structure (insertion points); §CHANGELOG Preamble Artifact (staged `brandbook/` file shape). |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version-truth prose sweep | Shipped docs (READMEs, `guides/`, `MAINTAINING.md`) | — | These are the public surface adopters read; the demo README & generated `doc/` are explicitly out of scope. |
| Drift prevention | CI / `scripts/` (Python guard in `lint.sh`) | — | Scripts-first CI per CLAUDE.md; matches the 8 existing `check_*.py` guards. |
| Doc↔code coherence | ExUnit (`release_contract_test.exs`) | — | Bidirectional guard asserts the real file strings; must move in lockstep with the sweep. |
| Release-runbook truth | `MAINTAINING.md` + staged `brandbook/` artifact | release-please config (read-only reference) | The runbook documents but does NOT execute the cut (Phase 128); the staged preamble lives outside the bot-managed CHANGELOGs. |

## Standard Stack

No external packages installed by this phase. Tooling is entirely repo-native.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Python 3 | system `python3` | `scripts/check_version_truth.py` drift guard | `[VERIFIED: scripts/ci/lint.sh]` — 8/9 existing guards are `python3 scripts/check_*.py`; this is the established posture. |
| `re` (stdlib) | bundled | Negative-lookahead anchoring for `~> 0.1` | `[VERIFIED]` Python `re` supports `(?![.\d])` lookahead; tested against the live `~> 0.1.3` line this session. |
| ExUnit | bundled w/ Elixir | `release_contract_test.exs` bidirectional guard | `[VERIFIED: rulestead/test/rulestead/release_contract_test.exs]` already the doc↔code enforcement mechanism. |
| release-please-action | `@v4` (pinned SHA `8b8fd2cc`) | Reference only — the runbook documents its mechanics | `[VERIFIED: .github/workflows/release-please.yml:36]` |

**Installation:** None. No `mix deps` change, no `pip install` (guard uses only stdlib `re`/`sys`).

**Package Legitimacy Audit:** N/A — phase installs zero external packages. (Skipping the audit table is correct here; the only "dependencies" referenced in swept text — `rulestead`, `rulestead_admin`, `open_feature`, `open_feature_rulestead` — are first-party or the already-vendored upstream pin, not new installs.)

## Architecture Patterns

### System Diagram (data flow)

```
                        ┌─────────────────────────────────────────┐
   shipped doc files ──▶│ SWEEP (atomic edit)                     │
   (13 files, D-01)     │  0.1.x → 1.0/1.x · ~> 0.1 → ~> 1.0      │
                        │  delete "Two version lines" callout     │
                        │  + upgrading.md §  + MAINTAINING.md §    │
                        └───────────────┬─────────────────────────┘
                                        │ (same commit — lockstep)
                        ┌───────────────▼─────────────────────────┐
   asserted strings ───▶│ RE-ANCHOR release_contract_test.exs     │
   (7 asserts, D-10)    │  flip 0.1.x asserts → positive 1.0 truth │
                        │  keep demo_readme L265 (survivor)        │
                        └───────────────┬─────────────────────────┘
                                        │
   ┌────────────────────────────────────┼──────────────────────────────┐
   ▼                                    ▼                                ▼
 GATE 1: criterion-1 grep       GATE 2: mix test            GATE 3: bash scripts/ci/lint.sh
 returns ZERO hits              release_contract_test green  → runs new check_version_truth.py
 (proves sweep complete)        (proves doc↔code coherent)     (proves drift guard wired, exit 0)

   staged artifacts (NOT gated by sweep, presence-checked):
     guides/introduction/upgrading.md  "Upgrading 0.1.x → 1.0" section
     MAINTAINING.md                    "## Cutting a major (X.0.0)" runbook
     brandbook/CHANGELOG-PREAMBLE-1.0.md  two-package preamble (NEW file)
```

### Pattern 1: Atomic sweep + contract-test re-anchor
**What:** The sweep and the `release_contract_test.exs` edit land in one change.
**When to use:** Always here — the test reads the real files (`File.read!`) and asserts strings the
sweep removes. Editing docs first leaves the suite red; editing the test first leaves a hole.
**Example:** See §Contract-Test Surgery Map for the exact 7-assert flip table.

### Pattern 2: Scripts-first fail-closed drift guard
**What:** A `scripts/check_*.py` returning `exit 1` on any forbidden pattern, invoked from `lint.sh`
after `cd "${RULESTEAD_REPO}"` (repo root, where guards use relative paths).
**When to use:** Whenever drift logic is non-trivial (the `~> 0.1.3` exclusion makes it non-trivial).
**Example:**
```python
# Source: structure mirrors scripts/check_brand_tokens.py (verified live)
#   - module docstring with "Usage (from repo root)"
#   - main() returns int; sys.exit(main())
#   - prints "VERSION TRUTH OK" on success, lists hits + returns 1 on drift
```

### Anti-Patterns to Avoid
- **Loose `~> 0\.1\b` regex:** `\b` matches between `1` and `.` in `~> 0.1.3`, false-positiving the
  legitimate third-party pin and reddening CI permanently. Use negative lookahead `(?![.\d])`.
- **Sweeping `v0.1.0` strings:** Out of criterion-1 scope (see §State of the Art). Mechanically
  replacing them is scope creep and risks breaking unrelated `release_contract_test.exs` text.
- **Editing `rulestead/CHANGELOG.md` / `rulestead_admin/CHANGELOG.md`:** release-please-managed
  (`changelog-path`); the bot regenerates them. Stage the preamble in `brandbook/` instead (D-09).
- **Hand-editing `rulestead/doc/`:** ExDoc regenerates it from `guides/`; edits get clobbered (D-04).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Doc↔code version coherence | A separate ad-hoc checker | Re-anchor existing `release_contract_test.exs` asserts | The bidirectional guard already exists and runs in CI; adding a parallel checker duplicates it. |
| Drift-guard scaffolding | A bespoke script shape | Copy `scripts/check_brand_tokens.py` structure | 8 sibling guards share an identical docstring/exit-code/messaging convention; match it for reviewability. |
| Anchored version match | Manual char-by-char string scanning | Python `re` with negative lookahead | stdlib handles `~> 0.1.3` exclusion in one expression. |
| CHANGELOG generation | Hand-writing release bullets | Leave to release-please; stage only the human preamble | The bot owns the generated section; only the "promotion not rewrite" preamble is hand-authored. |

**Key insight:** This phase is almost entirely *reuse* — the guard pattern, the contract test, the
brandbook staging home, and the release pipeline all already exist. The work is prose + one new
~40-line Python guard + lockstep test edits, not new infrastructure.

## Runtime State Inventory

> This is a doc/string sweep (rename-adjacent), so the inventory applies.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — phase touches no datastore, schema, or stored keys (release-truth milestone, no schema changes). | none |
| Live service config | `.release-please-manifest.json` = `{"rulestead":"0.1.7","rulestead_admin":"0.1.7"}` — but this is **read by release-please, not edited by this phase** (the `1.0.0` bump is Phase 128 via `Release-As`). The runbook must DOCUMENT this; do not edit the manifest now. | document only (D-07/D-08) |
| OS-registered state | None. | none |
| Secrets/env vars | None changed. (`RULESTEAD_ADMIN_HEX_RELEASE` / `HEX_API_KEY` are referenced by the pipeline but not touched here.) | none |
| Build artifacts | `rulestead/doc/` is generated from `guides/` — after the sweep, the next `mix docs` rebuilds it; **do not hand-edit `doc/`** (D-04). The `lint.sh` `mix docs --warnings-as-errors` step (L33) regenerates it in CI. | none (auto-regenerates) |

**Canonical question answered:** After every shipped file is swept, what runtime systems still
carry the old string? Only `.release-please-manifest.json` (`0.1.7`) and the generated `doc/` — both
are intentionally out of scope (manifest → Phase 128; `doc/` → auto-regenerated).

## Common Pitfalls

### Pitfall 1: The `~> 0.1.3` false positive (the landmine)
**What goes wrong:** A naive `~> 0\.1\b` or `~> 0\.1` substring match flags
`open_feature_rulestead/README.md:28` `{:open_feature, "~> 0.1.3"}` (the real published upstream
version), reddening CI forever and/or tempting an edit that bricks adopter `mix deps.get`.
**Why it happens:** `\b` is a zero-width boundary that exists between `1` and `.` in `0.1.3`.
**How to avoid:** Use negative lookahead: `re.search(r'~> 0\.1(?![.\d])', line)`. **Verified live**:
this pattern matches `~> 0.1"` (L29, L33) and `~> 0.1,` but does NOT match `~> 0.1.3` (L28).
**Warning signs:** Guard reports a hit in `open_feature_rulestead/README.md` — that file's only
legitimate forward-version line is L29 (which the sweep flips to `~> 1.0`, after which L28 is the
only `~> 0.1*` left and must NOT trip the guard).

### Pitfall 2: Over-counting the contract-test asserts (CONTEXT error)
**What goes wrong:** CONTEXT-125 D-10 says to flip "L285 **and** the second maintainer guidance test's
`maintaining =~ "0.1.x"`". **There is no second one.** Acting on this could send a planner hunting for
a phantom assert or mis-editing the maintainer-guidance test.
**Why it happens:** The maintainer-guidance test (L272-308) reads `maintaining` and the
public-release-truth test (L224-270) also reads `maintaining`, but only L285 asserts `0.1.x`.
**How to avoid:** Use the verified 7-assert table in §Contract-Test Surgery Map. `grep -n '0\.1\.x'`
on the test returns exactly: 233, 249, 254, 262, 265, 285 (six) + the "Two version lines" at 234.
**Warning signs:** Any plan referencing "two `maintaining` asserts" — correct it to one (L285).

### Pitfall 3: Sweeping `v0.1.0` historical strings (scope creep)
**What goes wrong:** `guides/` is saturated with `v0.1.0` references (cheatsheet L3, api_stability L519,
testing L3/L132, oban L3, ecto L3/L36, telemetry-recipe L9/L121, deployment L3, rulesets L46,
extending-rulestead ~10 hits, admin-ui L106, open_feature README L14). These are NOT criterion-1
patterns. Mechanically rewriting them inflates the diff and can break `release_contract_test.exs`
(e.g. L653 test title "locked v0.1.0 public function catalog").
**Why it happens:** `v0.1.0` *looks* like stale version language, but criterion-1 is specifically
`0.1.x` / `~> 0.1` / `future…1.0` / `1.0 API freeze` / `Two version lines` — NOT `v0.1.0`.
**How to avoid:** Sweep ONLY criterion-1 hits. Treat `v0.1.0` as out of scope unless a swept line
already contains it in a callout being deleted (e.g. the README callouts say `v1.0.0` GA + `0.1.x`).
The drift guard must NOT pattern on `v0.1.0`.
**Warning signs:** Diff touches `guides/recipes/testing.md`, `extending-rulestead.md`, or
`api_stability.md` — none of those are in the D-01 13-file list.

### Pitfall 4: Editing the manifest or CHANGELOGs now
**What goes wrong:** Bumping `.release-please-manifest.json` to `1.0.0` or writing into the package
CHANGELOGs collides with Phase 128 and the release-please bot's regeneration.
**How to avoid:** This phase documents and stages only. The `1.0.0` bump is `Release-As` (Phase 128).
**Warning signs:** Diff touches `.release-please-manifest.json`, `release-please-config.json`,
`rulestead/CHANGELOG.md`, or `rulestead_admin/CHANGELOG.md`.

## Code Examples

### Contract-test re-anchor (positive 1.0 truth, not bare delete)
```elixir
# Source: rulestead/test/rulestead/release_contract_test.exs (verified live)
# BEFORE (L233-234, public-release-truth test):
assert root_readme =~ "0.1.x"
assert root_readme =~ "Two version lines"
# AFTER (re-anchor to positive 1.0 truth — exact strings at Claude's discretion, must match swept prose):
assert root_readme =~ "1.0"            # or the chosen install-snippet/promotion phrase
# (the "Two version lines" assert is deleted because the callout is deleted — replace with a
#  positive guard such as `assert root_readme =~ "~> 1.0"` so version truth stays enforced)
```

### Drift guard skeleton (mirrors check_brand_tokens.py)
```python
#!/usr/bin/env python3
# Source: structure verified against scripts/check_brand_tokens.py
"""Version-truth drift guard: shipped docs must not reintroduce 0.1.x release language.

Usage (from repo root): python3 scripts/check_version_truth.py
Exits 0 + "VERSION TRUTH OK" on clean; exits 1 + lists hits on drift.
"""
import re, sys

FILES = [
    "README.md", "rulestead/README.md", "rulestead_admin/README.md",
    "open_feature_rulestead/README.md", "MAINTAINING.md", "CONTRIBUTING.md",
]  # plus every *.md / *.cheatmd under guides/  (glob it)

PATTERNS = [
    re.compile(r"0\.1\.x"),
    re.compile(r"0\.1\.7"),
    re.compile(r"future[^\n]*1\.0", re.I),
    re.compile(r"1\.0 API freeze"),
    re.compile(r"Two version lines"),
    re.compile(r"~> 0\.1(?![.\d])"),   # anchored: matches `~> 0.1"` NOT `~> 0.1.3`
]
# Per-file/line exception: open_feature_rulestead/README.md `{:open_feature, "~> 0.1.3"}`
# is already excluded by the lookahead; no extra carve-out needed.
```

## State of the Art

| Old (stale) language | Current (1.0 truth) | Where | Scope |
|----------------------|---------------------|-------|-------|
| `~> 0.1`, `0.1.x`, "Two version lines", "future 1.0", "1.0 API freeze" | `~> 1.0`, `1.0`/`1.x`, callout deleted | 13 shipped files | **IN scope (criterion-1)** |
| `{:open_feature, "~> 0.1.3"}` | unchanged | `open_feature_rulestead/README.md:28` | **OUT — real upstream pin (D-04)** |
| `v0.1.0` historical refs | unchanged | ~20 lines across `guides/` + open_feature README L14 | **OUT — not a criterion-1 pattern (Pitfall 3)** |
| `examples/demo/README.md` `0.1.x` | unchanged | demo README | **OUT — D-03, contract L265 survivor** |
| `.release-please-manifest.json` `0.1.7` | `1.0.0` | manifest | **OUT — Phase 128 via `Release-As`** |

**Deprecated/outdated assumptions in CONTEXT to correct:**
- D-10 "two `maintaining =~ "0.1.x"` asserts" → there is **one** (L285).
- D-07 references the manifest/bootstrap as `Release-As: 0.1.0` — the workflow's bootstrap reminder
  (release-please.yml:85) does echo `Release-As: 0.1.0`, but the **live manifest is already `0.1.7`**,
  so the runbook should frame `Release-As` generically (the bootstrap echo is historical; the major
  cut is `Release-As: 1.0.0` added to the `rulestead` block in `release-please-config.json`, then removed).

## Detailed Findings (the six orchestrator gaps)

### Gap 1 — Exact Contract-Test Surgery Map

`release_contract_test.exs` path consts (L8-18) read the real files via `File.read!`. The complete
set of asserts the sweep makes go-false (verified by `grep -n '0\.1\.x\|Two version lines'`):

| Line | Owning test (start line) | Current assert | Swept file makes it false? | Recommended re-anchor |
|------|--------------------------|----------------|----------------------------|-----------------------|
| 233 | public-release-truth (224) | `root_readme =~ "0.1.x"` | YES (root README callout deleted, L194 swept) | `root_readme =~ "1.0"` or the chosen promotion phrase |
| 234 | public-release-truth (224) | `root_readme =~ "Two version lines"` | YES (callout deleted, criterion 2) | **Delete + add positive** e.g. `root_readme =~ "~> 1.0"` (keep version truth enforced, don't leave a hole) |
| 249 | public-release-truth (224) | `runtime_readme =~ "0.1.x"` | YES (`rulestead/README.md` L9/L11-12 swept) | `runtime_readme =~ "1.0"` / `"~> 1.0"` |
| 254 | public-release-truth (224) | `admin_readme =~ "0.1.x"` | YES (`rulestead_admin/README.md` L9/L12-13 swept) | `admin_readme =~ "1.0"` / `"~> 1.0"` |
| 262 | public-release-truth (224) | `upgrading =~ "0.1.x"` | YES (`upgrading.md` L4/L8/L10/L24/L30 swept) | `upgrading =~ "Upgrading 0.1.x → 1.0"` heading OR `"~> 1.0"` (the new D-07 section heading literally contains `0.1.x → 1.0` — see note) |
| 265 | public-release-truth (224) | `demo_readme =~ "0.1.x"` | **NO — SURVIVOR** (demo README not swept, D-03) | **Keep unchanged** |
| 285 | maintainer-guidance (272) | `maintaining =~ "0.1.x"` | YES (`MAINTAINING.md` L11-12/L167/L592 swept) | `maintaining =~ "1.0"` / `"Cutting a major"` |

**Also note (don't break these — they already assert `v1.0.0` and stay true):** L232
`root_readme =~ "v1.0.0"`, L261 `upgrading =~ "v1.0.0"`, L283 `maintaining =~ "v1.0.0"`. The sweep
removes `0.1.x` but the docs already mention the `v1.0.0` GA date (2026-05-21) so these stay green —
keep them.

**CONTEXT correction (HIGH confidence):** D-10's "second maintainer guidance test's
`maintaining =~ "0.1.x"`" does **not exist**. Verified: `grep -n 'maintaining =~ "0.1.x"'` returns
exactly one hit (L285). The planner must treat the swept-assert set as the **seven rows above**
(six flips + one survivor), not eight.

**Re-anchor strategy nuance:** The D-07 upgrading.md section heading "Upgrading 0.1.x → 1.0"
literally contains the substring `0.1.x`. If the planner uses that heading, the L262
`upgrading =~ "0.1.x"` assert technically *stays true* by coincidence — but that is fragile and
semantically wrong (it would assert the heading, not version truth). **Recommendation:** re-anchor
L262 to a positive forward string like `upgrading =~ "~> 1.0"` and treat the heading match as
incidental, OR anchor explicitly to the heading `upgrading =~ "Upgrading 0.1.x → 1.0"`. Pick one and
make it deliberate; do not leave a bare `=~ "0.1.x"` that passes by accident.

### Gap 2 — Drift-Guard Regex Design

**Verified pattern set** (each tested against the live tree this session):

| Pattern | Python regex | Matches | Does NOT match |
|---------|--------------|---------|----------------|
| `0.1.x` | `0\.1\.x` | `0.1.x` | `0.1.0`, `v0.1.0` |
| `0.1.7` | `0\.1\.7` | `0.1.7` | — |
| future…1.0 | `future[^\n]*1\.0` (`re.I`) | "future `1.0` API freeze" | — |
| API freeze | `1\.0 API freeze` | the callout phrase | — |
| Two version lines | `Two version lines` | the callout heading | — |
| anchored `~> 0.1` | `~> 0\.1(?![.\d])` | `~> 0.1"`, `~> 0.1,`, `~> 0.1` + space | **`~> 0.1.3`** ← the critical exclusion |

**File include list (criterion-1 set):**
- `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `open_feature_rulestead/README.md`
- every `*.md` and `*.cheatmd` under `guides/` (glob — recursive)
- `MAINTAINING.md`, `CONTRIBUTING.md`

**Exclusion list (must NOT scan):**
- `.planning/`, `prompts/` (historical)
- `rulestead/doc/` (generated)
- `examples/` (demo README, D-03)
- the `open_feature_rulestead/README.md:28` third-party pin — **handled by the lookahead, no
  per-file carve-out needed** (confirmed: after the sweep flips L29 to `~> 1.0`, the only `~> 0.1*`
  left in that file is L28 `~> 0.1.3`, which the lookahead correctly skips).

**Implementation shape (mirror `scripts/check_brand_tokens.py`):** module docstring with
"Usage (from repo root)", `main()` returning `int`, `sys.exit(main())`, prints `VERSION TRUTH OK`
on success / lists `path:line: <hit>` and returns 1 on drift. Use `pathlib.Path("guides").rglob("*.md")`
+ `rglob("*.cheatmd")` for the guides glob.

**lint.sh wiring (D-05):** Insert one line in the Python-guard block (`lint.sh` L43-69, after the
`cd "${RULESTEAD_REPO}"` at L40), e.g. after the `check_logo_assets.py` line (L62):
```bash
# Version-truth drift: shipped docs must not reintroduce 0.1.x release language.
python3 "${RULESTEAD_REPO}/scripts/check_version_truth.py"
```
The guards already run from repo root (L40 `cd "${RULESTEAD_REPO}"`) so relative paths in the script
resolve correctly. `set -euo pipefail` (L2) makes any non-zero exit fail the lane (fail-closed).

### Gap 3 — release-please Mechanics for the MAINTAINING Runbook

Verified against `release-please-config.json`, `.release-please-manifest.json`, `release-please.yml`:

- **Linked packages:** `release-please-config.json` declares a `linked-versions` plugin
  (`groupName: rulestead-monorepo`) over `["rulestead", "rulestead_admin"]` ONLY.
  `open_feature_rulestead` is **absent** → NOT release-please managed → **manual publish (Phase 129)**.
  The runbook MUST say this explicitly (D-08).
- **`Release-As` lives in two possible places:** (a) the `release-please.yml:82-85` "Phase 1 bootstrap
  reminder" step currently echoes `Release-As: 0.1.0` (a commit-footer convention for the *first* PR);
  (b) the major cut adds `"release-as": "1.0.0"` into the `rulestead` block of
  `release-please-config.json` (per Phase 128 / REL-01 / STATE.md decision). The runbook should
  describe the config-block mechanism as the major-cut path.
- **Post-cut removal step (mandatory):** after the `1.0.0` PR merges, `"release-as": "1.0.0"` MUST be
  removed from `release-please-config.json` (STATE.md human checkpoint: "leave it and release-please
  re-proposes 1.0.0 forever"). The runbook must call this out as a hard step.
- **`bump-minor-pre-major: true` + `bump-patch-for-minor-pre-major: true`** (config L5-6): pre-1.0,
  these force `feat!:` → minor (`0.2.0`) not major, which is **why `Release-As: 1.0.0` is the only way
  to force 1.0.0**. Post-1.0 both flags are **no-ops** (they only affect `< 1.0.0` versioning). The
  runbook should document them as now-no-op (this is also Phase 128 REL-06, but the runbook describes
  the steady-state).
- **Manifest reality:** `.release-please-manifest.json` is currently `0.1.7`/`0.1.7` (NOT `0.1.0`).
  The runbook should reference the manifest generically, not as a fixed version.
- **Publish order:** `rulestead` first, then `rulestead_admin` (MAINTAINING.md:22, :178-179;
  publish-hex choreography). Provider (`open_feature_rulestead`) is strictly after `rulestead@1.0.0`
  is live (Phase 129; STATE.md gate `hex.pm/api/packages/rulestead/releases/1.0.0 == 200`).

**Runbook placement:** Insert "## Cutting a major (X.0.0)" near the existing release sections —
between `## Gated publish choreography` (MAINTAINING.md:165) and `## Manual recovery path` (L189),
OR right after `## Release Please flow` (L139). The deprecation-window checklist ties to the
Versioning & Deprecation Policy that Phase 124 added to `api_stability.md` (soft→hard `@deprecated`
→remove-on-major; STATE.md notes the `--warnings-as-errors` footgun for hard deprecation).

### Gap 4 — upgrading.md + MAINTAINING.md Current Structure

**`guides/introduction/upgrading.md`** (35 lines, full text read):
- L1 `# Upgrading`; L3-5 intro prose (swept: `0.1.x`/`~> 0.1`); L7-8 "Two version lines" callout
  (delete/reframe per D-07); L10-13 bullet list (L10 has `v0.1.x`); L15 `## What to review before
  upgrading`; L21 `## Public contract posture` (L24 `0.1.x`); L26 `## Practical rule` (L30 `v0.1.x`);
  L33-34 maintainers link.
- **Insertion point for the new "Upgrading 0.1.x → 1.0" section (D-07):** immediately after L5 intro,
  BEFORE the (reframed) callout — i.e. the new section is the first H2 a reader hits, stating zero
  code changes / dep-pin bump only / "promotion, not rewrite". The L3-8 callout is reframed (the
  `v1.0.0` GA + 2026-05-21 facts stay; the "0.1.x semver until a future 1.0 API freeze" framing goes).

**`MAINTAINING.md`** (624 lines). Relevant sections verified:
- `## Release posture` (L3) — L10-14 carry `0.1.x` (swept: reframe "current installable line is 0.1.x"
  to the 1.0 reality).
- `## Release Please flow` (L139) — linked-version description.
- `## Manual reruns and GitHub token caveat` (L154).
- `## Gated publish choreography` (L165) — L167 `0.1.x` (swept).
- `## Manual recovery path` (L189), `## Post-publish verification handoff` (L210).
- `## Timing expectations` (L586) — L592 `0.1.x` (swept).
- **Insertion point for "## Cutting a major (X.0.0)" (D-07):** after `## Gated publish choreography`
  (ends ~L188) and before `## Manual recovery path` (L189) — keeps all release-cut content contiguous.

### Gap 5 — CHANGELOG Preamble Artifact

- **CHANGELOGs are release-please-managed:** `release-please-config.json` sets
  `changelog-path: rulestead/CHANGELOG.md` and `rulestead_admin/CHANGELOG.md`. Both files currently
  have a `## [Unreleased]` section with bot-generated `### Features / ### Bug Fixes / ### Documentation`
  bullets (verified). Editing them collides with regeneration → **do NOT commit the preamble there (D-09)**.
- **Staging precedent confirmed:** `brandbook/RELEASE-TEMPLATE.md` exists (1616 bytes, verified) and
  is the established "ready-but-unapplied release text" home. The new file
  `brandbook/CHANGELOG-PREAMBLE-1.0.md` is its sibling.
- **Recommended content shape for `brandbook/CHANGELOG-PREAMBLE-1.0.md`** (two-package, "promotion not
  rewrite"): a short Markdown snippet meant to be pasted ABOVE release-please's generated `1.0.0`
  bullets during the Phase 128 release PR. Suggested structure:
  ```markdown
  ## 1.0.0 — Promotion, not rewrite

  `rulestead` and `rulestead_admin` graduate to `1.0.0`. This is the same
  battle-tested code, now honestly versioned — **zero breaking changes**.

  - No public API changes; the surface in `guides/api_stability.md` is unchanged.
  - Upgrade is a dependency-pin bump only: `~> 0.1` → `~> 1.0`. See
    `guides/introduction/upgrading.md`.
  - Both sibling packages move together (linked versions).
  ```
  Keep it operator-consequence-first (matching RELEASE-TEMPLATE.md microcopy rules L51-56) and
  explicitly two-package (the cut bumps both `rulestead` and `rulestead_admin`). Note: the actual
  `1.0.0` bullets come from release-please; this artifact is the human preamble only.

### Gap 6 — Full File-by-File Sweep Map (authoritative)

Reproduced the criterion-1 grep live. **Every hit, every file** (CONTEXT D-01 inventory is accurate —
no missed files; confirmed nothing else under `guides/` has criterion-1 hits beyond the listed set):

| File | Line(s) | Current content | Action |
|------|---------|-----------------|--------|
| `README.md` | 7-10 | "Two version lines" callout (`v1.0.0` GA / `0.1.x` semver / future `1.0` / `~> 0.1`) | **DELETE entirely** (criterion 2) |
| `README.md` | 40 | `{:rulestead, "~> 0.1"}` | → `~> 1.0` |
| `README.md` | 99-100 | `{:rulestead, "~> 0.1"}`, `{:rulestead_admin, "~> 0.1"}` | → `~> 1.0` |
| `README.md` | 194 | "the `0.1.x` package line." | → `1.0`/`1.x` reframe |
| `rulestead/README.md` | 9 | `Install {:rulestead, "~> 0.1"} (currently 0.1.x on Hex).` | → `~> 1.0` / drop "currently 0.1.x" |
| `rulestead/README.md` | 11-13 | "Two version lines" callout | **DELETE/reframe** |
| `rulestead/README.md` | 33 | `{:rulestead, "~> 0.1"}` | → `~> 1.0` |
| `rulestead_admin/README.md` | 9 | `{:rulestead_admin, "~> 0.1"} … (currently 0.1.x` | → `~> 1.0` / drop "currently 0.1.x" |
| `rulestead_admin/README.md` | 12-13 | "Two version lines" callout | **DELETE/reframe** |
| `rulestead_admin/README.md` | 22-23 | `~> 0.1` × 2 | → `~> 1.0` |
| `open_feature_rulestead/README.md` | 14-15 | prose "remains on the installable `0.1.0` line" | reframe to 1.0 (D-01 prose). **Note: `0.1.0` not `0.1.x` — criterion-1 grep does NOT flag it; D-01 explicitly lists L14-15.** |
| `open_feature_rulestead/README.md` | 29 | `{:open_feature_rulestead, "~> 0.1"}` (own pkg) | → `~> 1.0` |
| `open_feature_rulestead/README.md` | **28** | `{:open_feature, "~> 0.1.3"}` | **DO NOT TOUCH (D-04)** |
| `guides/cheatsheet.cheatmd` | 8-9 | `~> 0.1` × 2 | → `~> 1.0`. (L3 `v0.1.0` is OUT of scope — Pitfall 3.) |
| `guides/introduction/getting-started.md` | 3 | "current `0.1.x` package line" | → `1.0` reframe |
| `guides/introduction/getting-started.md` | 6-8 | "Two version lines" callout | **DELETE/reframe** |
| `guides/introduction/getting-started.md` | 15, 21-22 | `~> 0.1` × 3 | → `~> 1.0` |
| `guides/introduction/getting-started.md` | 26 | "from the `0.1.x` sibling packages" | → `1.0` reframe |
| `guides/introduction/phoenix-integration-spine.md` | 19-20 | `~> 0.1` × 2 | → `~> 1.0` |
| `guides/introduction/product-boundary.md` | 20 | heading `### Runtime semver (0.1.x)` | → `(1.x)` |
| `guides/introduction/product-boundary.md` | 28 | "stable for `0.1.x` patch releases." | → `1.x` reframe |
| `guides/introduction/installation.md` | 9 | "line on Hex is **`0.1.x`** (`~> 0.1`)" | → `1.0` |
| `guides/introduction/installation.md` | 11-12 | "Two version lines" callout | **DELETE/reframe** |
| `guides/introduction/installation.md` | 22, 35-36 | `~> 0.1` × 3 | → `~> 1.0` |
| `guides/introduction/upgrading.md` | 3-4 | "current installable packages on Hex are at `0.1.x` (`~> 0.1`)" | reframe + new D-07 section |
| `guides/introduction/upgrading.md` | 7-8 | "Two version lines" callout | **DELETE/reframe** |
| `guides/introduction/upgrading.md` | 10 | "Patch releases in `v0.1.x`" | → `1.x` (note: `v0.1.x` IS a criterion-1 `0.1.x` match) |
| `guides/introduction/upgrading.md` | 24 | "current `0.1.x` package line." | → `1.0`/`1.x` |
| `guides/introduction/upgrading.md` | 30 | "boundary for `v0.1.x`." | → `1.x` |
| `guides/flows/telemetry.md` | 4 | "additive-only for the rest of `v0.1.x`." | → `1.x` (criterion-1 `0.1.x` match) |
| `MAINTAINING.md` | 11-12 | "line on Hex is **`0.1.x`** … treat the `0.1.x` packages" | → `1.0` reframe |
| `MAINTAINING.md` | 167 | "release path for the current shipped `0.1.x` line is:" | → `1.0`/`1.x` |
| `MAINTAINING.md` | 592 | "The current `0.1.x` package line is aligned" | → `1.0`/`1.x` |
| `CONTRIBUTING.md` | — | **ZERO hits** (D-02) | guard covers it, no edit |

**Stragglers check (orchestrator gap 6):** ran `find guides -type f` — the only files under `guides/`
with criterion-1 hits are `cheatsheet.cheatmd`, `introduction/{getting-started, phoenix-integration-spine,
product-boundary, installation, upgrading}.md`, and `flows/telemetry.md`. **No additional `guides/`
subdir file has criterion-1 hits.** (Many `guides/` files have `v0.1.0` — explicitly out of scope.)
CONTEXT D-01 missed nothing in-scope.

## Validation Architecture

> nyquist_validation: no `.planning/config.json` found at repo root with an explicit `false`, so
> treated as enabled. This phase is doc/script/test — validation is grep + ExUnit + the lint lane.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir); Python guard via `lint.sh` |
| Config file | `rulestead/test/test_helper.exs` (standard); `scripts/ci/lint.sh` for the guard lane |
| Quick run | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| Full suite | `bash scripts/ci/lint.sh` (runs `mix docs --warnings-as-errors` + all `check_*.py` guards) |

### Phase Requirements → Test Map (each success criterion is mechanically verifiable)
| Criterion | Behavior | Test type | Automated command | Held-out check |
|-----------|----------|-----------|-------------------|----------------|
| SC-1 | Zero criterion-1 hits in shipped surface | grep gate | `grep -rn '0\.1\.x\|~> 0\.1[^.0-9]\|0\.1\.7\|future.*1\.0\|1\.0 API freeze\|Two version lines' README.md rulestead/README.md rulestead_admin/README.md open_feature_rulestead/README.md guides/ MAINTAINING.md CONTRIBUTING.md` → 0 lines | A reviewer re-runs the grep; should also confirm `open_feature_rulestead/README.md:28 ~> 0.1.3` still present (preserved). |
| SC-2 | "Two version lines" callout deleted | grep gate | `grep -rn "Two version lines" README.md rulestead/README.md rulestead_admin/README.md guides/` → 0 | Visual confirm the README callout block (root L6-10) is gone. |
| SC-3 | Drift guard wired + fail-closed | lint lane | `bash scripts/ci/lint.sh` exit 0; inject `~> 0.1` into a guide → guard exits 1 | Adversarial: add `~> 0.1.3` line → guard must STAY green (lookahead proof). |
| SC-4 | upgrading.md has "Upgrading 0.1.x → 1.0" section | presence | `grep -q "Upgrading 0.1.x → 1.0" guides/introduction/upgrading.md` + `grep -qi "promotion" guides/introduction/upgrading.md` | Confirm "zero code changes / dep-pin bump" language present. |
| SC-5 | MAINTAINING.md "Cutting a major" runbook | presence | `grep -q "## Cutting a major" MAINTAINING.md` + checks for `Release-As`, manual-provider note, post-cut removal | Confirm the runbook says open_feature is manual (D-08) and names the post-cut `Release-As` removal. |
| SC-6 | CHANGELOG preamble staged | presence | `test -f brandbook/CHANGELOG-PREAMBLE-1.0.md` + `grep -qi "promotion" brandbook/CHANGELOG-PREAMBLE-1.0.md` | Confirm two-package + zero-breaking-changes framing; confirm NOT written into the bot CHANGELOGs. |
| (lockstep) | Contract test green after re-anchor | ExUnit | `cd rulestead && mix test test/rulestead/release_contract_test.exs` → 0 failures | Confirm L265 demo assert unchanged; confirm no bare `=~ "0.1.x"` left passing by accident. |

### Sampling Rate
- **Per task commit:** the relevant grep gate + `mix test test/rulestead/release_contract_test.exs`.
- **Per wave merge:** `bash scripts/ci/lint.sh` (the full guard lane incl. the new guard + `mix docs`).
- **Phase gate:** SC-1 grep = 0 hits AND `release_contract_test.exs` green AND `lint.sh` exit 0 AND the
  three presence-assertions (SC-4/5/6) pass.

### Wave 0 Gaps
- [ ] `scripts/check_version_truth.py` — NEW file (covers SC-3); no existing test scaffolds it, but it
  is self-validating via `lint.sh`. Add a quick adversarial manual check (inject `~> 0.1` and `~> 0.1.3`)
  during the task to prove the lookahead.
- [ ] No new ExUnit file needed — re-anchor existing `release_contract_test.exs` asserts in place.

*(Existing test + lint infrastructure covers all phase requirements; the only new artifact is the guard.)*

## Project Constraints (from CLAUDE.md)

- **Scripts-first CI surfaces where workflow logic gets non-trivial** → the drift guard is a
  `scripts/check_version_truth.py` (D-05), not an inline grep.
- **Prefer narrow, auditable changes** → sweep only criterion-1 hits; do NOT touch out-of-scope
  `v0.1.0` strings or the demo README.
- **Treat `.planning/` and `prompts/` as out of scope** → excluded from sweep AND guard (D-04).
- **Preserve the sibling-package layout** → no package restructure; both CHANGELOGs stay bot-managed.
- **Keep root docs honest about the current phase** → STATE.md/ROADMAP updates on phase completion.
- **Post-GA band (v1.1–v1.9) feature-complete; v2 work requires explicit milestone** → no runtime
  APIs, schema, or renames this phase (release-truth only).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The new positive contract-test anchors (e.g. `=~ "~> 1.0"`) will match the chosen swept prose | Gap 1 | LOW — planner picks the exact string at discretion; just ensure the asserted substring actually appears in the final swept file. |
| A2 | `python3` `re` negative lookahead is available in the CI runner's Python 3 | Gap 2 | LOW — lookahead is in Python 2.x+ `re`; ubuntu-24.04 ships 3.12. `[VERIFIED]` syntactically this session. |
| A3 | `pathlib.rglob` over `guides/` is the right glob breadth for the guard | Gap 2 | LOW — confirmed `guides/` is the only doc subtree in scope; `examples/`/`doc/` excluded by not being globbed. |
| A4 | The deprecation-window checklist content ties to Phase-124's api_stability policy | Gap 3 | LOW — STATE.md confirms the policy exists; runbook references it, doesn't redefine it. |

**All other claims are `[VERIFIED]` against live files this session.**

## Open Questions

1. **Exact positive re-anchor strings for L233/234/249/254/262/285.**
   - What we know: must be substrings present in the final swept files; "Two version lines" (L234) must
     be replaced, not just deleted, to keep version truth enforced.
   - What's unclear: the precise prose (Claude's discretion per CONTEXT).
   - Recommendation: anchor each to `~> 1.0` or `1.0` install/promotion language that the sweep
     introduces on the same file; verify by running the test after the sweep.

2. **Whether the upgrading.md "Upgrading 0.1.x → 1.0" heading should be the L262 anchor.**
   - What we know: the heading literally contains `0.1.x`, so a `=~ "0.1.x"` assert would pass by
     coincidence.
   - Recommendation: re-anchor L262 deliberately (to the heading OR to `~> 1.0`), not leave a passing-
     by-accident `0.1.x` assert. Flagged in Pitfall 2 / Gap 1.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `python3` | drift guard | ✓ (assumed; 8 existing guards already run) | system | none needed |
| Elixir/`mix` | contract test, `lint.sh` | ✓ (repo is an Elixir project) | per `.tool-versions` | none needed |
| `grep` | SC-1/SC-2 gates | ✓ | system | none needed |

**No missing dependencies.** (Did not shell-probe versions — the existing `lint.sh` already invokes
all of these in CI, so availability is established by the working pipeline.)

## Sources

### Primary (HIGH confidence — read live this session)
- `rulestead/test/rulestead/release_contract_test.exs` — full read; assert lines mapped via grep.
- `scripts/ci/lint.sh` — guard chain + `cd` posture + `set -euo pipefail`.
- `scripts/check_brand_tokens.py` — guard structure/exit-code/messaging convention.
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`
  — linked-versions, manifest `0.1.7`, `Release-As` bootstrap echo, no-op flags.
- `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `open_feature_rulestead/README.md`,
  `guides/introduction/upgrading.md`, `MAINTAINING.md` (release sections), `brandbook/RELEASE-TEMPLATE.md`,
  `rulestead/CHANGELOG.md`, `rulestead_admin/CHANGELOG.md` — all read for swept lines / staging shape.
- Criterion-1 grep + `v0.1.0` grep + anchored-regex test — run live against the tree.
- `.planning/phases/124-api-surface-lock-stability-contract/124-CONTEXT.md` D-03 — exact assert lines.
- `.planning/{STATE,ROADMAP,REQUIREMENTS}.md`, `125-CONTEXT.md`, `./CLAUDE.md`.

### Secondary / Tertiary
- None — this phase required no external/web sources; all claims grounded in repo files.

## Metadata

**Confidence breakdown:**
- File-by-file sweep map: HIGH — reproduced the criterion-1 grep; CONTEXT D-01 verified accurate.
- Contract-test surgery: HIGH — every assert line confirmed via grep; CONTEXT D-10 over-count corrected.
- Drift-guard regex: HIGH — anchored lookahead tested against the live `~> 0.1.3` line.
- release-please runbook facts: HIGH — verified against the three config/workflow files.
- Replacement prose / exact anchor strings: deferred to planner (Claude's discretion per CONTEXT).

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable — doc/config surface; re-verify line numbers if files change before planning)
