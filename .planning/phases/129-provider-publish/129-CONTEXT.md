# Phase 129: Provider Publish - Context

**Gathered:** 2026-06-19 (assumptions mode + deep research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish `open_feature_rulestead` at `1.0.0` to hex.pm **manually**, strictly after
`rulestead@1.0.0` is live on Hex, with a fresh consumer able to resolve `rulestead ~> 1.0`
from Hex (not a path dep). Scope is the version bump + env-gated dep swap + packaging/docs
to make HexDocs render + a minimal CHANGELOG + post-publish verification.

`open_feature_rulestead` is deliberately **outside** the release-please/`publish-hex.yml`
linked-versions pipeline (it is absent from `release-please-config.json`; CI references it
only as a test scope). Keep it that way — this is a manually-published *satellite* adapter,
not a third package in the release machine.

**Out of scope:** redesigning the provider API; new automated published-Hex smoke
automation; brand-parity HexDocs theming; threading the provider into the verify-trio.
</domain>

<decisions>
## Implementation Decisions

### Version & Env-Gated Dep Swap
- **D-01:** Bump `open_feature_rulestead/mix.exs` `@version` from `0.1.0` → `1.0.0`. Commit the
  version + dep bump to `main` (manual; do NOT add the provider to `release-please-config.json`
  or `.release-please-manifest.json`).
- **D-02:** Add a `rulestead_dep/0` helper gated on `System.get_env("OPEN_FEATURE_RULESTEAD_HEX_RELEASE") == "1"`,
  structurally mirroring `rulestead_admin/mix.exs:47-53`. Default branch (all dev/CI/test) keeps
  `{:rulestead, path: "../rulestead"}`; the gated branch returns the Hex dep. Call it from `deps/0`,
  replacing the current hardcoded path line. Env var name follows the `<PACKAGE_UPCASE>_HEX_RELEASE`
  house convention.
- **D-03:** The published Hex constraint is **`{:rulestead, "~> 1.0"}`** (= `>= 1.0.0 and < 2.0.0`),
  **NOT** admin's `~> #{@version}`. This is a deliberate divergence from the admin pattern's
  *constraint* (the *structure* is still mirrored). Rationale: admin's tight `~> 1.0.0` pin is
  justified only by its linked-versions lockstep with core; the provider is an **unlinked satellite**
  floating against a stable post-1.0 semver core, so a loose major pin is the idiomatic, consumer-
  friendly choice (avoids forcing a no-op provider release when `rulestead@1.1.0` ships). Never
  interpolate the provider's own `@version` into the core constraint.

### Docs / HexDocs (lean — NO brand parity)
- **D-04:** Add `{:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}` to `deps/0`. **Mandatory** —
  `mix hex.publish` uploads docs only if ex_doc generates a `doc/` dir; without it the HexDocs page
  renders blank, failing success criterion 2.
- **D-05:** Add a **lean** `docs/0` block and `docs: docs()` to `project/0`: `main: "readme"`,
  `source_url: @source_url`, `homepage_url: @homepage_url`, `extras: ["README.md", "CHANGELOG.md"]`,
  one `groups_for_modules` ("OpenFeature Provider" → `OpenFeatureRulestead.Provider`,
  `OpenFeatureRulestead.ContextMapper`), and a `skip_undefined_reference_warnings_on` guard for
  refs starting `Rulestead.` / `OpenFeature.` (cross-package refs, mirroring how admin guards its
  own). **Deliberately NO** logo/favicon/`assets`/`before_closing_head_tag` theming and **no**
  `brandbook` symlink — matches the upstream `open_feature` SDK's lean docs; the brandbook does not
  mandate per-companion theming, and a 2-module adapter is a secondary surface.
- **D-06:** Set `source_ref: "open_feature_rulestead-v#{@version}"` and create a matching git tag
  `open_feature_rulestead-v1.0.0` at the publish commit. This follows the repo's existing
  `include-component-in-tag` convention (cf. tag `rulestead_admin-v1.0.0`) and makes HexDocs `[source]`
  links resolve to exactly the published provider source — avoiding the stale/404-source-link footgun
  that a bare `v1.0.0` (which points at the core's tag) or `main` would create.
- **D-07:** Fill the stub `@moduledoc` in `lib/open_feature_rulestead.ex` (short purpose + install
  snippet) and add a `@moduledoc` to `OpenFeatureRulestead.Provider`, so the HexDocs landing page
  isn't an empty stub.

### Packaging (package/0 + LICENSE + CHANGELOG)
- **D-08:** Tighten `package/0` to the siblings' shape, scaled down: explicit
  `files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)`; add a `Changelog` link
  `"#{@source_url}/blob/main/open_feature_rulestead/CHANGELOG.md"` (the `open_feature_rulestead/`
  path segment is **mandatory** — copy-pasting rulestead's path 404s); keep existing GitHub + HexDocs
  links; expand `description` slightly. **Omit `maintainers:`** — both siblings omit it; stay consistent.
- **D-09:** Create `open_feature_rulestead/LICENSE` by copying the repo-root MIT `LICENSE` verbatim
  (currently missing; required because the `files:` whitelist lists it).
- **D-10:** Create `open_feature_rulestead/CHANGELOG.md` — a hand-written keep-a-changelog single
  `1.0.0` entry in the siblings' "version truth / promotion, not a rewrite, zero breaking changes"
  voice, adapter-scoped, **plus an OpenFeature independent-versioning note** (the provider versions
  independently of the `open_feature` SDK and depends on `open_feature ~> 0.1.3`; shipping `1.0.0`
  while depending on `open_feature ~> 0.1.x` is idiomatic, not a contradiction). NOT release-please
  managed → no machine-generated conventional-commits section.
- **D-11:** `open_feature_rulestead/README.md` requires **no** version-truth edits — already honest
  (`v1.0.0`, install `{:open_feature_rulestead, "~> 1.0"}`); `scripts/check_version_truth.py` passes
  (the `{:open_feature, "~> 0.1.3"}` line is an exempted upstream third-party pin).

### Publish Mechanics (local, guarded — no new CI)
- **D-12:** Publish via **local `mix hex.publish`** run by the maintainer with
  `OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1` and `HEX_API_KEY` set. **No new `workflow_dispatch` job**;
  `publish-hex.yml` stays a two-package workflow and the provider stays absent from it and from
  `release-please-config.json`. Matches MAINTAINING.md's documented "separate manual step" and its
  explicit "not a three-package publish machine" posture.
- **D-13:** Add a scripts-first pre-publish guard (e.g. `scripts/ci/openfeature_publish_guard.sh`)
  plus a runbook in MAINTAINING.md's existing manual-step section. Mandatory ordered steps:
  (1) confirm `rulestead@1.0.0` is live on Hex (`curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0`);
  (2) `export OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1`; `cd open_feature_rulestead`; `mix deps.get` (refresh lock);
  (3) guard asserts env var == `1`, `rulestead` resolves as a **hex** dep (not `path:`), clean workspace,
  fresh `mix.lock`;
  (4) `mix hex.publish --dry-run` and **visually confirm `rulestead ~> 1.0` appears in the published
  dependency list**;
  (5) `mix hex.publish --yes`; then `unset OPEN_FEATURE_RULESTEAD_HEX_RELEASE`.
- **D-14 (loudest footgun):** Hex **silently drops** path deps from the published tarball instead of
  erroring (per Hex docs: non-Hex deps "will not be used during dependency resolution… neither will
  they be listed as dependencies"). So forgetting `OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1` does **not**
  fail the publish — it ships a `rulestead`-less, broken-for-every-consumer tarball that uploads
  cleanly. The `--dry-run` dependency-list inspection (D-13 step 4) is the non-negotiable catch.

### Verification (proportionate, manual, evidence-captured)
- **D-15:** After `open_feature_rulestead@1.0.0` is live, run two **manual local** proofs and capture
  evidence (lock excerpt, `deps.tree`, test summary, the live `hex.pm/api/.../1.0.0` 200 + HexDocs
  render) into `129-VERIFICATION.md`:
  - **Clause 1 (fresh consumer resolves from Hex, not path):** in a clean tmp dir, `mix new of_consumer`,
    set deps to `[{:open_feature, "~> 0.1.3"}, {:open_feature_rulestead, "~> 1.0"}]`, `mix deps.get` +
    `mix compile`; assert `mix.lock` / `mix deps.tree` shows `rulestead ~> 1.0` sourced from `:hex`
    (no `path:`).
  - **Clause 2 (companion tests pass against published core):** `cd open_feature_rulestead` and run
    `OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 mix deps.get && OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 mix test
    test/open_feature_rulestead/context_mapper_test.exs test/open_feature_rulestead/provider_test.exs`.
- **D-16:** "the `openfeature_companion` contract tests" (criterion 3) = the existing
  `RULESTEAD_TEST_SCOPE=openfeature_companion` lane (`scripts/ci/test.sh:124-129` → `context_mapper_test.exs`
  + `provider_test.exs`). It is **not** a separate or missing suite. These are pure unit tests proving
  provider↔core struct/API compatibility; they pass identically whether `rulestead` is path- or
  Hex-resolved.

### Claude's Discretion
- Exact wording of CHANGELOG prose and expanded `description`, exact guard-script internals, and the
  precise `groups_for_modules` label are left to the planner/executor within the shapes above.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 129 section (goal, gate, success criteria 1–4, REL-05)
- `rulestead_admin/mix.exs` — the `rulestead_dep/0` env-gated swap pattern to mirror (lines 47-53),
  `package()` `files:` (line 66), `docs()` block (lines 72-107)
- `rulestead/mix.exs` — reference `docs()` / `package()` shape (lines 78-95+)
- `open_feature_rulestead/mix.exs` — the change site (version, deps, package, +docs)
- `MAINTAINING.md` — the "separate manual step" provider-publish runbook (~lines 202-205, 251, 261,
  365-392) to update with the guard runbook
- `prompts/rulestead-release-engineering-and-ci.md` — release-engineering policy, anti-patterns,
  `verify.release_publish` fresh-consumer mental model
- `scripts/ci/test.sh` — `run_openfeature_companion` scope (lines 124-129)
- `LICENSE` (repo root, MIT) — source to copy into the provider
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`rulestead_admin/mix.exs:47-53`** — exact env-gated `rulestead_dep/0` pattern to clone (change
  env var name + constraint per D-03).
- **`rulestead/mix.exs` + `rulestead_admin/mix.exs`** — `docs()` / `package()` shapes to scale down.
- **Repo-root `LICENSE`** — verbatim copy source for the new provider LICENSE.
- **Siblings' `CHANGELOG.md`** — "promotion, not rewrite / version truth" voice to echo (adapter-scoped).
- **`scripts/ci/test.sh` `run_openfeature_companion`** — the existing companion test invocation reused
  for verification clause 2.
- **Core's `verify.release_publish` task** (described in the release-eng prompt) — the fresh-consumer
  `mix new` → Hex dep → `deps.get`/compile mental model reused for verification clause 1.

### Established Patterns
- `<PACKAGE_UPCASE>_HEX_RELEASE` env-gated path↔hex dep swap (accrue lineage).
- `include-component-in-tag` release tags (e.g. `rulestead_admin-v1.0.0`) → provider tag
  `open_feature_rulestead-v1.0.0`.
- "Version truth" / "trust parity" (no stale pre-1.0 claims; honest CHANGELOG + Changelog link).
- Scripts-first CI surfaces for non-trivial workflow logic (the guard script).
- Lean docs for a thin adapter (mirror upstream `open_feature` SDK, not the flagship's brand theming).

### Integration Points
- `open_feature_rulestead/mix.exs` is the sole change site: `@version`, `deps/0` (`rulestead_dep/0`,
  `ex_doc`), `package/0`, new `docs/0`.
- Provider depends on `rulestead` (path locally ↔ `~> 1.0` on Hex) and `open_feature ~> 0.1.3`.
- `publish-hex.yml` and `release-please-config.json` — provider stays **absent** from both.
- `scripts/check_version_truth.py` already tracks `open_feature_rulestead/README.md` (currently green).
</code_context>

<specifics>
## Specific Ideas

- **`mix.exs` `rulestead_dep/0` (D-02/D-03):**
  ```elixir
  defp rulestead_dep do
    if System.get_env("OPEN_FEATURE_RULESTEAD_HEX_RELEASE") == "1" do
      {:rulestead, "~> 1.0"}
    else
      {:rulestead, path: "../rulestead"}
    end
  end
  ```
- **`docs/0` (D-05/D-06):** lean block — `main: "readme"`, `source_ref: "open_feature_rulestead-v#{@version}"`,
  `source_url`, `homepage_url`, `extras: ["README.md", "CHANGELOG.md"]`, one `groups_for_modules`,
  `skip_undefined_reference_warnings_on` for `Rulestead.` / `OpenFeature.`. No logo/favicon/assets/theming.
- **`package/0` (D-08):** explicit `files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)`,
  `Changelog` link to `…/blob/main/open_feature_rulestead/CHANGELOG.md`, no `maintainers:`.
- **CHANGELOG (D-10):** keep-a-changelog, single `1.0.0`, version-truth voice + OpenFeature
  independent-versioning note.
</specifics>

<deferred>
## Deferred Ideas

- **Audit-trail CI publish for the provider** — if the maintainer later wants an audit trail, the cheap
  evolution is adding the provider as an optional input to the *existing* `publish-hex.yml`, not a new
  workflow. Explicitly a future choice, not Phase 129.
- **Brand-parity HexDocs theming for the provider** (logo, favicon, OG card, Stead Blue theme) — not
  needed for a thin adapter; deferred indefinitely.
- **Automated published-Hex smoke test for the provider** (`@tag :published_hex_smoke` mirror,
  `RULESTEAD_RUN_*` env, verify-trio threading, vendored OpenFeature conformance/Gherkin harness) —
  disproportionate for a manual satellite; verification stays manual (D-15). Defer unless a future
  milestone justifies it.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
