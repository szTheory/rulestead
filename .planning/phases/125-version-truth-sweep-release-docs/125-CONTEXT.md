# Phase 125: Version-Truth Sweep + Release Docs - Context

**Gathered:** 2026-06-18 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every **shipped** file tell the truth about the `1.x` line — no stale `0.1.x` /
`~> 0.1` / "future 1.0" / "1.0 API freeze" / "Two version lines" language anywhere in the
public surface — add a fail-closed CI drift guard, and hand adopters/maintainers the
upgrade and major-bump docs they need *before* the cut. The actual `1.0.0` Hex release
happens later (Phase 128); this phase only makes the on-disk surface honest and stages the
release-PR CHANGELOG preamble.

**Requirements:** REL-02, REL-03.

**Hard scope guards (from milestone v2.0):**
- Release-truth milestone — **no new runtime APIs, no schema changes, no renames**.
- Does NOT cut the release (Phase 128), do HexDocs front-door theming/logo (Phase 126),
  or write adoption guides (Phase 127).
- `.planning/` and `prompts/` are **out of scope** — their `0.1.x` references are
  historically accurate and must be left untouched.
</domain>

<decisions>
## Implementation Decisions

### A. File inventory — 13 shipped files (LOCKED)
- **D-01:** Sweep these 13 files, replacing `~> 0.1`→`~> 1.0`, `0.1.x`→`1.0`/`1.x`, and
  deleting "future 1.0" / "1.0 API freeze" / "Two version lines" framing:
  - `README.md` (root) — L6-10 callout (**delete entirely**, criterion 2); L40, L99-100
    install snippets; L194 "the `0.1.x` package line".
  - `rulestead/README.md` — L9, L12 (callout), L33 (install snippet).
  - `rulestead_admin/README.md` — L9, L13 (callout), L22-23 (install snippets).
  - `open_feature_rulestead/README.md` — L29 (**own** line `~> 0.1`→`~> 1.0`) + L14-15
    prose; **L28 `{:open_feature, "~> 0.1.3"}` untouched** (third-party, see D-04).
  - `guides/cheatsheet.cheatmd` — L8-9.
  - `guides/introduction/getting-started.md` — L3, L7-8, L15, L21-22, L26.
  - `guides/introduction/phoenix-integration-spine.md` — L19-20.
  - `guides/introduction/product-boundary.md` — L20 heading `### Runtime semver (0.1.x)`, L28.
  - `guides/introduction/installation.md` — L9, L12, L22, L35-36.
  - `guides/introduction/upgrading.md` — L3-4, L7-8, L10, L24, L30 (plus new section, D-06).
  - `guides/flows/telemetry.md` — L4 ("additive-only for the rest of `v0.1.x`").
  - `MAINTAINING.md` — L11-12, L167, L592 (plus new runbook, D-07).
- **D-02:** `CONTRIBUTING.md` has **zero** stale hits — it is a criterion-1 grep target but
  needs no edits. The new CI guard must still cover it so future drift is caught.
- **D-03:** `examples/demo/README.md` (`current 0.1.x Hex package line`) is **NOT** swept —
  it is outside criterion-1's file list and `release_contract_test.exs:265` asserts its
  `0.1.x` string. Leaving it is invisible to the criterion-1 grep (different path).

### B. Exclusion classes — preserve verbatim (LOCKED)
- **D-04:** Three exclusion classes stay verbatim:
  1. **Third-party dep pin** — only `open_feature_rulestead/README.md:28`
     `{:open_feature, "~> 0.1.3"}` (the real published version of the upstream `open_feature`
     lib). Editing it bricks adopter `mix deps.get`.
  2. **Generated `rulestead/doc/`** — never hand-edited; ExDoc rebuilds it from the root
     `guides/` (mix.exs extras source `../guides/...`), so guide edits propagate on the next
     `mix docs`. Hand-editing `doc/` is wasted and gets clobbered.
  3. **Historical references** — `.planning/`, `prompts/`, and the demo README (D-03).

### C. Drift guard — scripts-first `check_version_truth.py` (LOCKED)
- **D-05:** Ship the guard as a **new `scripts/check_version_truth.py`** wired into
  `scripts/ci/lint.sh` alongside the existing 8 `check_*.py` guards (run from repo root,
  fail-closed `exit 1` on any hit). This matches the dominant lint.sh posture (8/9 guards are
  Python scripts; only the SVG-budget block is inline bash) and the CLAUDE.md "scripts-first
  CI surfaces where workflow logic gets non-trivial" rule. The exclusion nuance (D-04) makes
  it non-trivial enough to warrant a script over an inline grep.
- **D-06 (guard scope):** Scan **only** the criterion-1 shipped doc surface — root +
  3 package READMEs + `guides/` + `MAINTAINING.md` + `CONTRIBUTING.md`. Patterns:
  `0.1.x`, `0.1.7`, `future ... 1.0`, `1.0 API freeze`, `Two version lines`, and `~> 0.1`
  **as a fixed/anchored match that does NOT match `~> 0.1.3`** (e.g. require a closing
  `"`/`}`/whitespace, not a loose `\b` — `~> 0.1.3` would slip a naive `~> 0\.1\b`).
  Explicitly exclude `.planning/`, `prompts/`, `rulestead/doc/`, `examples/`, and the
  `open_feature_rulestead/README.md` third-party line.

### D. upgrading.md + MAINTAINING.md content (LOCKED)
- **D-07:** Additive sections that reframe in place, not restructures:
  - `upgrading.md` — an **"Upgrading 0.1.x → 1.0"** section near the top stating **zero code
    changes, only a dep-pin bump** (`~> 0.1`→`~> 1.0`), with explicit **"promotion, not
    rewrite"** framing; the stale L3-8 callout is reframed, not just deleted.
  - `MAINTAINING.md` — a **"## Cutting a major (X.0.0)"** runbook near the existing release
    sections (`## Release Please flow`, `## Gated publish choreography`), covering: the
    `Release-As` mechanism, the package publish sequence, a deprecation-window checklist, and
    the **mandatory post-cut removal of `Release-As` from `.github/workflows/release-please.yml`**
    (currently the bootstrap reminder echoes `Release-As: 0.1.0` at ~L85; the major cut
    overrides via `Release-As: 1.0.0`, then must remove it or the pipeline re-proposes the
    same version forever).
- **D-08 (runbook accuracy nuance):** `release-please-config.json` lists only `rulestead` +
  `rulestead_admin` (linked-versions). `open_feature_rulestead` is **NOT** release-please
  managed — it is a separate **manual** publish (Phase 129). The runbook must say so
  explicitly rather than imply release-please cuts all three.

### E. CHANGELOG preamble artifact + contract-test collision (LOCKED — the landmine)
- **D-09:** The pre-authored "promotion, not rewrite" CHANGELOG preamble (criterion 6) ships
  as a **staged artifact `brandbook/CHANGELOG-PREAMBLE-1.0.md`** (sibling to the existing
  `brandbook/RELEASE-TEMPLATE.md`), a two-package text snippet to be pasted above
  release-please's generated bullets during the Phase 128 release PR. It is **NOT** committed
  into `rulestead/CHANGELOG.md` / `rulestead_admin/CHANGELOG.md` — those are release-please
  managed (`changelog-path` in `release-please-config.json`); editing them collides with the
  bot's regeneration. A `.planning/` home is wrong (excluded surface + would be archived away
  from the Phase 128 executor); `brandbook/` is the established release-staging home.
- **D-10 (contract-test lockstep — OVERRIDES Phase 124 D-03 for swept files):**
  `release_contract_test.exs` is a **bidirectional guard** that reads the real files. The
  sweep flips strings it currently asserts, so these MUST be updated in the **same change**:
  - `root_readme =~ "0.1.x"` (L233) → re-anchor to the new `1.0`/promotion language.
  - `root_readme =~ "Two version lines"` (L234) → **delete the assert** (criterion 2 removes
    the callout) — but re-anchor to a *positive* `1.0`-truth assertion so the guard still
    enforces version truth (do not just delete and leave a hole).
  - `runtime_readme =~ "0.1.x"` (L249), `admin_readme =~ "0.1.x"` (L254),
    `upgrading =~ "0.1.x"` (L262), `maintaining =~ "0.1.x"` (L285 **and** the second
    "maintainer guidance" test's `maintaining =~ "0.1.x"`) → all re-anchor to `1.0`.
  - **Survivor:** `demo_readme =~ "0.1.x"` (L265) stays — the demo README is not swept (D-03).
  - Phase 124 D-03 deliberately preserved the `0.1.x` README/upgrading/demo asserts, but its
    rationale was scoped to *124 not editing those files*. Phase 125 edits them, so the
    preservation no longer holds for the swept set — only the demo assert survives.

### Claude's Discretion
- Exact replacement prose for each swept line (keep install snippets and callouts idiomatic;
  reframe, don't mechanically string-swap where a sentence needs rewording).
- Exact regex/fixed-string anchoring inside `check_version_truth.py` (must satisfy D-06's
  `~> 0.1.3` protection) and its precise placement in `lint.sh`.
- Exact section wording/placement of the upgrading.md and MAINTAINING.md additions and the
  new positive `1.0`-truth contract-test anchors (D-10).
- Exact wording of `brandbook/CHANGELOG-PREAMBLE-1.0.md`.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 125 section (L80-97): the 6 fixed success criteria.
- `.planning/REQUIREMENTS.md` — REL-02, REL-03.
- `.planning/phases/124-api-surface-lock-stability-contract/124-CONTEXT.md` — adjacent locked
  decisions; note D-03 there is **overridden for the swept files** by D-10 here.
- `rulestead/test/rulestead/release_contract_test.exs` — bidirectional doc↔code guard; path
  consts L8-15; the `0.1.x`/"Two version lines" asserts at ~L233-285 plus the second
  "maintainer guidance" test's `maintaining =~ "0.1.x"` (D-10). Survivor: `demo_readme` L265.
- `scripts/ci/lint.sh` — the release gate (`mix compile/docs --warnings-as-errors`, dialyzer
  at ~L31-37) + the guard chain (~L43-69 Python guards, ~L74-86 inline SVG-budget block);
  the new `check_version_truth.py` wires in here (D-05).
- `.github/workflows/release-please.yml` — `Release-As: 0.1.0` bootstrap reminder (~L85); the
  MAINTAINING runbook's post-cut removal step targets this (D-07).
- `release-please-config.json` + `.release-please-manifest.json` — linked-versions config
  (only `rulestead` + `rulestead_admin`; `open_feature_rulestead` absent → manual, D-08);
  `changelog-path` proves the CHANGELOGs are bot-managed (D-09).
- `guides/introduction/upgrading.md`, `MAINTAINING.md` — current structure for the additive
  sections (D-07).
- `brandbook/RELEASE-TEMPLATE.md` — the established release-staging neighbor for the new
  `brandbook/CHANGELOG-PREAMBLE-1.0.md` (D-09).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/lint.sh` already runs 8 `scripts/check_*.py` fail-closed drift guards — the new
  `check_version_truth.py` follows the exact same wiring/posture (D-05).
- `brandbook/RELEASE-TEMPLATE.md` already exists as a staged release artifact, establishing
  `brandbook/` as the home for ready-but-unapplied release text (D-09).
- ExDoc regenerates `rulestead/doc/` from the root `guides/` (mix.exs `../guides/...` extras),
  so editing guides once propagates to the rendered docs — no double-editing (D-04).

### Established Patterns
- `release_contract_test.exs` is a **bidirectional** guard (124's D-01 pattern): docs and
  asserted strings move together. Any doc-string the test asserts must be updated in lockstep
  (D-10).
- CI drift guards are fail-closed and scripts-first (CLAUDE.md), scoped to the shipped surface
  and excluding `.planning/`/`prompts/`/generated/example paths.
- `0.1.x` appears in two distinct meanings: (a) Rulestead's OWN forward version line (swept to
  `1.0`) vs (b) historical/third-party references (preserved). The whole phase hinges on this
  distinction.

### Integration Points
- `lint.sh` ← new `check_version_truth.py` (D-05/D-06).
- `release-please.yml` `Release-As` reminder ← MAINTAINING runbook's removal step (D-07).
- `release-please-config.json` (2 packages) vs the manual `open_feature_rulestead` publish ←
  runbook accuracy (D-08).
- `release_contract_test.exs` ← swept README/upgrading/MAINTAINING strings (D-10).
</code_context>

<specifics>
## Specific Ideas

- "Promotion, not rewrite" is the through-line framing for both the upgrading.md section and
  the CHANGELOG preamble: a `1.0.0` that is the *same* battle-tested code, just honestly
  versioned — explicit **zero breaking changes**, only a dep-pin bump.
- The drift guard must protect the single legitimate `~> 0.1.3` third-party pin — a loose
  `~> 0\.1\b` pattern would false-positive and red CI permanently. Use a fixed/anchored match.
- Re-anchor (don't just delete) the contract-test asserts to positive `1.0`-truth strings so
  the bidirectional guard keeps enforcing version truth after the sweep.
</specifics>

<deferred>
## Deferred Ideas

- The actual `Release-As: 1.0.0` cut, auto-merge disable, hand-merge, publish, and post-cut
  `release-as` removal — Phase 128 (REL-01, REL-04, REL-06). This phase only *documents* the
  runbook and *stages* the preamble.
- `open_feature_rulestead` manual `1.0.0` publish + dep swap — Phase 129 (REL-05).
- HexDocs front-door theming/logo/`files:` (Phase 126) and adoption guides (Phase 127).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
</content>
</invoke>
