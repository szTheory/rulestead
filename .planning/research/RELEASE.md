# R1 — Hex 1.0 Release Mechanics, SemVer & Deprecation Policy

**Milestone:** v2.0 "1.0 GA Release & Adoption"
**Researched:** 2026-06-17
**Lens:** senior Elixir OSS release engineer + library maintainer + DevOps/SRE
**Scope:** release-cut + stability-contract mechanics only (no runtime features)
**Overall confidence:** HIGH on mechanics (verified against repo files + release-please/Elixir official docs); MEDIUM on a few ecosystem comparators (WebSearch-derived, attributed inline).

---

## Recommended decisions register

| # | Decision | Recommendation | One-line why |
|---|----------|----------------|--------------|
| D1 | How to force `1.0.0` (not `feat!`) | Set `"release-as": "1.0.0"` on the **`rulestead`** package in `release-please-config.json`; linked-versions propagates to `rulestead_admin`. | Under `bump-minor-pre-major`, a `feat!:` only yields `0.2.0` — `Release-As` is the only deterministic path to `1.0.0`. |
| D2 | Auto-merge during the cut | **Disable `release-pr-automerge` for the cut** (one-line guard or branch-rename), merge the release PR by hand after eyeballing the `@version`/CHANGELOG diff. | The cut is irreversible + linked; a human gate on the *PR merge* is cheap insurance even though Hex publish is already gated. |
| D3 | `open_feature_rulestead` sequencing | Manual `mix hex.publish` of `open_feature_rulestead@1.0.0` **after** `rulestead@1.0.0` is live on Hex; flip its dep to `{:rulestead, "~> 1.0"}` in the same commit. | It's outside release-please; its `~> 1.0` dep can't resolve until `rulestead` 1.0 is on Hex. |
| D4 | CHANGELOG strategy | **Keep release-please-generated, per-package** CHANGELOGs (already the live shape). Do **not** adopt hand-curated Keep-a-Changelog. **No** root monorepo CHANGELOG. | Switching formats now is churn with zero adopter value; the bot already owns the format and the two files. |
| D5 | `1.0.0` CHANGELOG framing | Frame as **"promotion, not rewrite"**: explicit *zero breaking changes*, "API was already stable, version now tells the truth." Hand-author a one-paragraph preamble above the bot's generated bullets. | Matches FunWithFlags' own 1.0 framing; sets correct adopter expectations and prevents "what broke?" support load. |
| D6 | Post-1.0 SemVer + deprecation policy | Adopt **Elixir's own model**: soft-deprecate (docs only) → hard-deprecate via `@deprecated` (alternative must exist ≥ a few minors) → remove only on next **major**. Telemetry events/metadata are part of the contract; additive keys are minor, removals/renames are major. | It's the idiomatic Elixir-ecosystem policy; adopters already understand it; `api_stability.md` already half-states it. |
| D7 | Where the policy lives | Rewrite the top of `guides/api_stability.md` from "`0.1.x` contract" to "`1.x` contract" and add a **Versioning & Deprecation Policy** section with a worked example + a deprecations table skeleton. | One canonical contract doc, already shipped in the Hex package and guarded by `release_contract_test.exs`. |
| D8 | `upgrading.md` for 0.1.x→1.0 | Near-trivial upgrade section: bump `~> 0.1` → `~> 1.0`, no code changes, plus the new stability promise. Keep the "two version lines" note but reframe it (the GitHub v-ledger now decouples from Hex semver). | The cut is intentionally zero-break; the upgrade guide should say exactly that and nothing scarier. |
| D9 | `MAINTAINING.md` major-bump runbook | Add a "Cutting a major (X.0.0)" runbook: `Release-As` mechanics, the deprecation-window checklist, the three-package sequence, and the verify-trio. | The current MAINTAINING.md documents the *0.1.x linked publish*; it has no major-bump path and no three-package choreography. |
| D10 | Version-truth sweep | Grep for `0.1.x` / `~> 0.1` / "future `1.0`" / "API freeze" / "0.1.7" across `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `guides/**`, `MAINTAINING.md`, `CONTRIBUTING.md`; reframe each as the shipped `1.x` line. | 14 files carry stale "0.1.x experimental / future 1.0" language that directly contradicts a 1.0 cut. |

These decisions are mutually coherent: D1+D2+D3 are the cut sequence; D4+D5 are how the cut is described; D6+D7+D8+D9 are the post-1.0 contract; D10 makes the repo tell the truth.

---

## 1. Post-1.0 SemVer + deprecation policy (for `guides/api_stability.md`)

### 1.1 The idiomatic Elixir model (adopt verbatim, scaled down)

Elixir's own [compatibility-and-deprecations policy](https://elixir.hexdocs.pm/compatibility-and-deprecations.html) is the canonical reference and what experienced Elixir adopters expect. Three phases (HIGH confidence — official docs):

1. **Soft deprecation** — annotate docs/CHANGELOG as deprecated; **no compiler warning**. The replacement ships and is documented.
2. **Hard deprecation** — add the `@deprecated "Use X instead"` attribute; the Mix compiler (via `mix xref`) emits a warning at every call site. Elixir's rule: *the replacement must have existed for at least three minor versions* before hard-deprecation. For a young 1.x library, **"at least one prior minor"** is a reasonable, honest down-scaling — state the exact window you commit to rather than copying "three" blindly.
3. **Removal** — only on a **major** bump. Deprecated-in-1.x ⇒ removable-in-2.x.

`@deprecated` mechanics (HIGH confidence — [Module docs](https://hexdocs.pm/elixir/Module.html), [Elixir forum](https://elixirforum.com/t/deprecation-warnings-and-warnings-as-errors/58543)):

```elixir
@deprecated "Use Rulestead.evaluate/3 instead"
def evaluate(flag_key, context), do: evaluate(flag_key, context, [])
```

> **Footgun (verified):** `mix compile --warnings-as-errors` (which `lint.sh` already runs) will turn a `@deprecated` warning in *your own* test/call sites into a hard CI failure. So when you hard-deprecate, you must simultaneously migrate every internal caller to the replacement, or the lint lane goes red. This is the single biggest deprecation footgun for this repo specifically — its `--warnings-as-errors` gate is stricter than most libraries'. Soft-deprecation (docs only) sidesteps this; reserve `@deprecated` for the minor where you've finished internal migration.

### 1.2 What counts as breaking (write this list into the contract)

The existing `api_stability.md` already enumerates the closed catalogs (modules, function arities, struct fields, `:reason`/`:domain`/`:type` atoms, telemetry events, config keys, the admin route family). Promote its "Versioning Posture" stub into an explicit table:

| Change | SemVer impact |
|--------|---------------|
| New public module/function/arity | **minor** |
| New optional config key, new struct field that defaults safely | **minor** |
| New telemetry event or **additive** metadata key | **minor** |
| New `:reason`/`:domain`/`:type`/`:env` atom **returned** by the library | **minor** (but document — see note) |
| Soft-deprecation (docs only) | **minor** |
| Hard-deprecation (`@deprecated` warning, replacement shipped) | **minor** |
| Removing/renaming a public function, arity, or module | **major** |
| Removing/renaming a struct field, or a `:reason`/`:domain`/`:type` atom the library *previously emitted* | **major** |
| Renaming/removing a telemetry event or a documented metadata key | **major** |
| Removing/renaming a config key, an admin route, or the `?env=` convention | **major** |
| Tightening a contract (e.g. raising where it used to return `{:error, _}`) | **major** |
| Bug fix that restores documented behavior | **patch** |

> **Atom-set nuance:** *adding* a `:reason`/`:type` atom is technically observable (a consumer's exhaustive `case` could MatchError). Elixir libraries conventionally treat additive result-atom growth as **minor** but **call it out in the CHANGELOG** so defensive consumers update their catch-alls. State this explicitly so you're not trapped into a major for every new error type. (MEDIUM confidence — ecosystem convention, not a written law.)

### 1.3 Telemetry stability — the one most libraries get wrong

Rulestead's telemetry catalog is *already* declared public in `api_stability.md`, and the project's own Key Decisions log shows it has historically *emitted additive aliases instead of renaming events* — exactly the right instinct. Codify it:

- The **event name list** and **documented metadata keys** are contract. Renaming `[:rulestead, :eval, :decide, :stop]` is a **major** break.
- **Additive** metadata keys are **minor** (consumers must ignore unknown keys — state this expectation explicitly so the burden is on the consumer, matching Oban/Phoenix telemetry norms).
- Measurements (`:duration`, counts) are contract; changing units is **major**.
- Redaction guarantees ("raw actor payloads/secrets are never in telemetry") are a **security contract** — weakening them is major *and* a security note.

Lesson from Oban (MEDIUM confidence — [Oban changelog](https://hexdocs.pm/oban/changelog.html)): Oban has soft-deprecated individual telemetry *fields* (e.g. `args`, `worker`) by dropping them from docs while still emitting them, then removing later. Mirror that: telemetry deprecation = "stop documenting + CHANGELOG note" first, remove at major.

### 1.4 Worked example (paste into the guide)

> **Worked example — deprecating `Rulestead.get_variant/2` in favor of `get_value/3`** (illustrative; real API is frozen as-is):
>
> - **v1.4.0 (soft):** `get_value/3` ships and is documented as the preferred API. `get_variant/2` docs gain a "> Deprecated: use `get_value/3`." admonition. No warning. CHANGELOG: *"Deprecated `Rulestead.get_variant/2` (soft) in favor of `get_value/3`."*
> - **v1.5.0 (hard):** `@deprecated "Use Rulestead.get_value/3"` added; `mix` warns at call sites. All internal callers already migrated (so `--warnings-as-errors` stays green). CHANGELOG entry + a row in the deprecations table.
> - **v2.0.0 (remove):** `get_variant/2` deleted. `upgrading.md` 1.x→2.0 lists the replacement. CHANGELOG: **(BREAKING)** removal.
>
> A consumer pinned at `{:rulestead, "~> 1.0"}` never breaks across the entire 1.x line — they only see warnings, and they choose when to act before opting into `~> 2.0`.

This worked example doubles as the proof that `~> 1.0` is a real promise.

---

## 2. CHANGELOG strategy

### 2.1 Current reality (decisive)

Both `rulestead/CHANGELOG.md` and `rulestead_admin/CHANGELOG.md` **already exist** and are **release-please-generated** — Conventional-Commit-grouped sections (`### Features`, `### Bug Fixes`, `### Documentation`) under `## [Unreleased]`, with scope prefixes like `**adoption-lab:**`. `release-please-config.json` points each package at its own `changelog-path`. **There is no root CHANGELOG and `release-please` is not configured to produce one** (the `"."` package isn't in the config).

### 2.2 Recommendation: keep generated, per-package, no root CHANGELOG (D4)

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **release-please-generated, per-package** (current) | Zero maintenance; bot owns it; matches tags `rulestead-vX.Y.Z`; commit discipline already enforced by `pr-title`/`amannn`. | Bullets are terse; ordering is commit-derived not curated. | **CHOSEN.** |
| Hand-curated Keep-a-Changelog (Added/Changed/Deprecated/Removed/Fixed/Security) | Richer, human-grouped; the literal "Deprecated"/"Removed" headings map perfectly onto the deprecation policy. | Requires discipline on every PR; *diverges* from the bot, causing merge churn; would need ripping out release-please's changelog generation. | Rejected — high cost, no adopter payoff for a solo maintainer. |
| Root monorepo CHANGELOG | Single timeline. | Duplicates the two package files; release-please linked-versions doesn't naturally produce a third aggregate; another drift surface. | Rejected. |

**Idiomatic check:** Both styles are common in Elixir. Ecto/Phoenix hand-curate (`CHANGELOG.md` with curated highlights); Req groups by component inline ([Req changelog](https://req.hexdocs.pm/changelog.html), not Keep-a-Changelog); FunWithFlags uses loose chronological bullets ([FunWithFlags CHANGELOG](https://preview.hex.pm/preview/fun_with_flags/show/CHANGELOG.md)). There is **no single mandated format** — the right move is *don't fight the tool you already run*. Generated-per-package is the lowest-friction idiomatic choice for an automated, solo-maintained monorepo.

**One enhancement to adopt from Keep-a-Changelog:** when you later deprecate/remove, write the Conventional Commit so the generated bullet carries the signal — e.g. `feat!: remove deprecated get_variant/2` produces a clearly-flagged breaking entry, and `docs(deprecate): soft-deprecate get_variant/2` lands under Documentation. You get Keep-a-Changelog's *intent* without its maintenance.

### 2.3 Framing the `1.0.0` entry — "promotion, not rewrite" (D5)

release-please will roll the existing `[Unreleased]` bullets into `## [1.0.0]`. **Hand-author a one-paragraph preamble** at the top of that section (release-please preserves manual prose around its generated bullets if you edit the release PR before merge). Recommended text:

> ## 1.0.0
>
> **Rulestead graduates to 1.0.** This is a *version-truth* release: the public API, RBAC model, telemetry contract, and admin mount seam have been stable and battle-tested across the internal v1.0–v1.18 development line. **There are no breaking changes** — code that compiled against `0.1.x` compiles unchanged against `1.0`. The only required action is bumping your dependency from `~> 0.1` to `~> 1.0`. From this release forward, `guides/api_stability.md` is the binding SemVer contract (see "Versioning & Deprecation Policy").

This mirrors FunWithFlags' actual 1.0 wording ("The API is now stable... This release doesn't introduce any breaking change... users should be able to upgrade without problems" — [verified](https://preview.hex.pm/preview/fun_with_flags/show/CHANGELOG.md)). It does two jobs: prevents "what do I have to change?" support churn, and explicitly hands the contract baton to `api_stability.md`.

`rulestead_admin/CHANGELOG.md` gets the same preamble (linked version), pointing to the same promise.

---

## 3. The release-please cut (ordered, opinionated)

### 3.1 The critical mechanic: `feat!:` will NOT give you 1.0.0 (D1)

**This is the single most important finding.** `release-please-config.json` has `"bump-minor-pre-major": true` **and** `"bump-patch-for-minor-pre-major": true`. Under those flags ([release-please docs](https://github.com/googleapis/release-please), [customizing.md](https://github.com/googleapis/release-please/blob/main/docs/customizing.md)):

- a normal `feat:` bumps **patch** (`0.1.7 → 0.1.8`),
- a breaking `feat!:` / `BREAKING CHANGE:` bumps only **minor** (`0.1.7 → 0.2.0`),
- **nothing** auto-promotes to `1.0.0` while version < 1.0.

So the cut is **not** "land a `feat!:` commit." The deterministic mechanism is **`Release-As`**. Two equivalent forms (HIGH confidence):

- **Config form (recommended):** add `"release-as": "1.0.0"` to the **`rulestead`** package block in `release-please-config.json`. The `linked-versions` plugin then forces `rulestead_admin` to the same `1.0.0` ([linked-versions forces version sync across the group](https://github.com/googleapis/release-please) — verified behavior). This is explicit, reviewable in the PR diff, and component-scoped.
- **Commit-footer form:** an (empty) commit with `Release-As: 1.0.0` in the body. Simpler but less obviously component-scoped in a linked monorepo; the config form is clearer for an auditable one-shot.

> **Cleanup step (verified footgun):** after the 1.0.0 release PR merges, **remove `"release-as"` from the config** (or release-please will keep proposing 1.0.0 forever). The release-please docs are explicit: *"once the release PR is merged you should either remove this or update it to a higher version."* Bake this into the runbook.

Once at `1.0.0`, `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` become **inert** (they only apply pre-1.0), so post-1.0 semver is automatically strict: `feat!:` → major, `feat:` → minor, `fix:` → patch. **You can leave those two flags in the config** (harmless post-1.0) — but the runbook should note they're now no-ops so a future maintainer isn't confused.

### 3.2 Disabling auto-merge for the cut (D2)

`release-pr-automerge.yml` auto-merges any `release-please--branches--main` PR once `release_gate` is green. For the 1.0 cut you want a **human eyeball on the version diff** (the `@version "1.0.0"` rewrite in both `mix.exs`, the CHANGELOG preamble, the manifest jump). Options:

| Option | How | Tradeoff | Verdict |
|--------|-----|----------|---------|
| **Temporary workflow guard** | Add `&& vars.RELEASE_AUTOMERGE != 'off'` (or a `[skip-automerge]` PR-title check) to the `automerge` job `if:`; set the repo variable `off` during the cut, restore after. | One-line, reversible, leaves an audit trail. | **CHOSEN.** |
| Disable the workflow in the Actions UI | Toggle `release-pr-automerge` off, re-enable after. | No code change, but invisible in git history and easy to forget to re-enable. | Acceptable fallback. |
| Rely solely on the Hex-publish gate | The `hex-publish` environment already needs manual approval. | True, but you'd be approving *after* the PR auto-merged and tags were cut — you can still abort at publish, but you've already mutated `main` + the manifest. Cleaner to gate the merge. | Not sufficient alone. |

The belt-and-suspenders posture: gate the **merge** (D2) *and* keep the existing `hex-publish` environment approval. Two human checkpoints for one irreversible, linked, triple-package event is correct.

### 3.3 Sequencing the `open_feature_rulestead` manual publish (D3)

`open_feature_rulestead` is **outside** release-please (not in the config/manifest), currently `@version "0.1.0"`, dep `{:rulestead, path: "../rulestead"}`. The order is forced by dependency resolution:

1. `rulestead@1.0.0` must be **live on Hex** first (so `~> 1.0` resolves).
2. Bump `open_feature_rulestead/mix.exs` to `@version "1.0.0"` **and** change its dep to `{:rulestead, "~> 1.0"}` (drop the path dep for the published artifact — mirror the `RULESTEAD_ADMIN_HEX_RELEASE` env-swap pattern, or just hard-set it since this package isn't built in the linked CI lanes the same way).
3. `mix hex.publish --dry-run` then `mix hex.publish --yes` from `open_feature_rulestead/`, **after** confirming `rulestead@1.0.0` is on Hex.

> **Decision to record:** keep the path dep for local dev/CI (the `openfeature_companion` test scope builds against `../rulestead`) and only swap to `~> 1.0` for the publish. The cleanest mirror of the existing admin pattern is an env-gated dep:
> ```elixir
> defp rulestead_dep do
>   if System.get_env("OPEN_FEATURE_RULESTEAD_HEX_RELEASE") == "1",
>     do: {:rulestead, "~> 1.0"},
>     else: {:rulestead, path: "../rulestead"}
>   end
> ```
> Set the env var only in the manual publish step.

### 3.4 Risks of the auto-publish-on-merge pipeline + idempotent recovery

The pipeline (verified from the workflows) is: merge release PR → `release-please.yml` cuts linked tags `rulestead-v1.0.0` / `rulestead_admin-v1.0.0` → `dispatch-publish` fires `publish-hex.yml` → `preflight` + `gate-ci-green` → **manual `hex-publish` approval** → `publish-core` (rulestead) → `publish-admin` (rulestead_admin) → `handoff-post-publish` dispatches `verify-published-release.yml`.

Risks specific to the 1.0 cut and their mitigations:

- **`feat!`/Release-As confusion** → wrong version cut. *Mitigation:* D1 config form + D2 human merge gate; the `preflight` step `grep -n "@version \"1.0.0\"" rulestead/mix.exs` hard-fails on mismatch.
- **`GITHUB_TOKEN` doesn't trigger follow-on workflows** (documented in MAINTAINING.md). The release-please bot push may not start `ci.yml`, so `gate-ci-green` waits up to ~15 min then fails. *Mitigation:* `release-please.yml`'s `dispatch-release-pr-ci` job + the automerge workflow's "Bootstrap CI on merge commit" step already handle this; if still stuck, `workflow_dispatch ci.yml` on the tagged ref manually.
- **Partial publish** (core succeeds, admin fails). *Mitigation:* publish-hex is **idempotent** — each publish job `curl`s `hex.pm/api/packages/<pkg>/releases/1.0.0` and **skips if already present**. So re-running `publish-hex.yml` with the same `core_tag`/`admin_tag`/`release_version` inputs safely resumes from the failed admin step. (Verified in `publish-hex.yml`.)
- **Linked-version drift** (siblings end on different versions). *Mitigation:* the daily `verify-published-release.yml` opens a rolling drift issue if `latest_stable_version` differs between the two packages.
- **Tag wrong** → MAINTAINING.md rule (keep it): *do not publish from an untagged commit; cut a corrected release.* `mix hex.publish` is effectively irreversible; reverting burns trust.

### 3.5 Post-publish verify-trio (already built — just run it)

After both siblings are live, run the canonical trio via the existing wrapper:

```bash
bash scripts/ci/verify_published_release.sh 1.0.0
# → mix verify.workspace_clean
# → mix verify.release_publish 1.0.0   (fresh mix new consumer compiles against Hex 1.0.0; HexDocs 1.0.0 reachable)
# → mix verify.release_parity 1.0.0    (Hex tarball == tagged source)
```

`handoff-post-publish` auto-dispatches `verify-published-release.yml` on `main`. **For `open_feature_rulestead`** (outside the trio), add a minimal manual verify: confirm `hex.pm/api/packages/open_feature_rulestead/releases/1.0.0` returns 200, HexDocs renders, and a fresh consumer with `{:open_feature_rulestead, "~> 1.0"}` resolves `rulestead ~> 1.0`.

### 3.6 The exact ordered checklist (artifact)

```
PRE-CUT (on a branch, normal PR, merged before the cut)
  [ ] D6/D7: rewrite guides/api_stability.md — "0.1.x" → "1.x" contract + add
            "Versioning & Deprecation Policy" section (§1.2 table, §1.4 worked example,
            deprecations table skeleton).
  [ ] D8: update guides/introduction/upgrading.md (0.1.x→1.0 = dep pin bump, zero code change).
  [ ] D9: add MAINTAINING.md "Cutting a major (X.0.0)" runbook (§4 below).
  [ ] D10: version-truth sweep — reframe all 14 stale "0.1.x / future 1.0 / API freeze" hits.
  [ ] Confirm release_contract_test.exs (api_stability bidirectional guard) still green after edits.
  [ ] cd rulestead && mix ci ; bash scripts/ci/local.sh   (full gate green)

THE CUT
  [ ] D2: disable release-pr-automerge (set repo var / toggle workflow off).
  [ ] D1: add "release-as": "1.0.0" to rulestead package in release-please-config.json; commit+merge to main.
  [ ] Wait for release-please.yml to open the "chore: release main" PR proposing 1.0.0 for BOTH packages.
  [ ] Review the release PR diff: @version "1.0.0" in both mix.exs, manifest 0.1.7→1.0.0 x2, CHANGELOG roll-up.
  [ ] Edit the release PR: add the "promotion, not rewrite" preamble to both CHANGELOGs (D5).
  [ ] Manually merge the release PR.
  [ ] Let release-please.yml cut tags rulestead-v1.0.0 / rulestead_admin-v1.0.0 and dispatch publish-hex.yml.
  [ ] In publish-hex.yml: review preflight + gate-ci-green output; APPROVE hex-publish environment.
  [ ] Confirm publish-core (rulestead) then publish-admin (rulestead_admin) both succeed.

POST-CUT (core line)
  [ ] handoff-post-publish auto-dispatches verify-published-release.yml; confirm green.
  [ ] (or local) bash scripts/ci/verify_published_release.sh 1.0.0   → trio green.
  [ ] Capture evidence: live hex.pm URLs, versioned HexDocs URL, fresh-consumer + phx.new mount proof.

OPEN_FEATURE_RULESTEAD (manual, AFTER rulestead@1.0.0 is live)
  [ ] Confirm hex.pm/api/packages/rulestead/releases/1.0.0 == 200.
  [ ] Bump open_feature_rulestead/mix.exs @version → "1.0.0"; dep → {:rulestead, "~> 1.0"} (env-gated swap).
  [ ] cd open_feature_rulestead && mix deps.get && mix test (openfeature_companion contract green).
  [ ] OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 mix hex.publish --dry-run ; then --yes.
  [ ] Verify: hex.pm release 200, HexDocs renders, fresh consumer resolves rulestead ~> 1.0.
  [ ] Commit the version+dep bump to main (so the repo matches the published artifact).

CLEANUP
  [ ] D1 cleanup: REMOVE "release-as": "1.0.0" from release-please-config.json (else it re-proposes 1.0.0).
  [ ] D2 cleanup: re-enable release-pr-automerge.
  [ ] Note in MAINTAINING.md: bump-minor-pre-major/bump-patch-for-minor-pre-major are now no-ops (post-1.0).
```

---

## 4. `upgrading.md` (0.1.x→1.0) + `MAINTAINING.md` major-bump runbook

### 4.1 Proposed `upgrading.md` 0.1.x→1.0 section (artifact)

```markdown
## Upgrading 0.1.x → 1.0

**1.0 is a version-truth release: no breaking changes.** The public API, RBAC,
telemetry, and admin mount seam were already stable across the internal
development line; `1.0` simply tells the truth on Hex.

Required change — bump your dependency pins:

```elixir
# before
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}   # if you mount the admin
# after
{:rulestead, "~> 1.0"},
{:rulestead_admin, "~> 1.0"}
# OpenFeature provider, if used:
{:open_feature_rulestead, "~> 1.0"}
```

Then `mix deps.update rulestead rulestead_admin open_feature_rulestead`. No code,
config, migration, telemetry, or admin-route changes are required.

**What `1.0` now guarantees:** from this release, `guides/api_stability.md` is the
binding SemVer contract. A `~> 1.0` pin will receive only backwards-compatible
minor/patch updates; breaking changes require a `2.0`. See
"Versioning & Deprecation Policy" in `api_stability.md`.
```

Also **reframe the existing "two version lines" note**: the GitHub milestone v-ledger now *decouples* from Hex semver — say "GitHub milestones track internal delivery; **Hex semver (starting at 1.0) is the public contract**" rather than the current "until a future 1.0 API freeze."

### 4.2 `MAINTAINING.md` major-bump runbook (artifact — add a section)

```markdown
## Cutting a major (X.0.0)

A major is the *only* place removals/renames/contract-tightening are allowed,
and only for features that have completed the deprecation window
(see api_stability.md "Versioning & Deprecation Policy").

Pre-cut checklist:
  [ ] Every removal in this major was soft- then hard-deprecated in a prior 1.x
      minor, with the replacement shipped first.
  [ ] All internal callers migrated off the removed API (so --warnings-as-errors stays green).
  [ ] api_stability.md catalogs + deprecations table updated; release_contract_test.exs green.
  [ ] guides/introduction/upgrading.md has an "Upgrading (X-1).y → X.0" section listing each
      removal and its replacement.

Forcing the version (release-please will NOT auto-jump majors the way it won't
pre-1.0; use Release-As for any deliberate version target):
  [ ] Add "release-as": "X.0.0" to the rulestead package in release-please-config.json
      (linked-versions propagates to rulestead_admin). Merge to main.
  [ ] (Optional) disable release-pr-automerge to hand-merge the release PR after review.
  [ ] Review the release PR: @version in both mix.exs, manifest bump, CHANGELOG roll-up;
      add a major preamble describing the breaks.
  [ ] Merge → tags rulestead-vX.0.0 / rulestead_admin-vX.0.0 → publish-hex dispatch.
  [ ] APPROVE hex-publish; publish-core then publish-admin.
  [ ] Manually publish open_feature_rulestead@X.0.0 AFTER rulestead@X.0.0 is live;
      set its dep to {:rulestead, "~> X.0"}.
  [ ] verify-published-release trio green; capture evidence.
  [ ] REMOVE "release-as" from config; re-enable automerge.

Note: bump-minor-pre-major / bump-patch-for-minor-pre-major are no-ops post-1.0;
post-1.0 semver is strict (feat! → major, feat → minor, fix → patch).
```

---

## 5. Version-truth sweep (D10)

### 5.1 What to grep for, and where it hides

Confirmed stale hits (HIGH confidence — grepped this repo). 14 files match the version-truth patterns; the load-bearing ones:

| File | Stale language (verified) | Reframe to |
|------|---------------------------|-----------|
| `README.md` (lines 8–9, 194) | "Hex packages use `0.1.x` semver (currently 0.1.x) until a future `1.0` API freeze"; "the `0.1.x` package line" | "Hex packages follow SemVer starting at `1.0`"; "the `1.x` package line" |
| `rulestead/README.md` (9, 12) | "Install `{:rulestead, "~> 0.1"}` (currently 0.1.x)"; "until a future `1.0`" | "`{:rulestead, "~> 1.0"}`"; drop the freeze clause |
| `rulestead_admin/README.md` (9, 13) | "`{:rulestead_admin, "~> 0.1"}` (currently 0.1.x)"; "until a future `1.0`" | "`~> 1.0`" |
| `guides/api_stability.md` (5, 9, 41, + whole framing) | "the `0.1.x` Hex package line"; "supported public surface for `0.1.x`"; "public on `0.1.x`" | "the `1.x` Hex package line"; "for `1.x`" — **this is D7, the biggest single edit** |
| `guides/introduction/upgrading.md` (4, 8, 10, 24, 30) | "packages on Hex are at `0.1.x`"; "until a future `1.0` API freeze"; "`v0.1.x` should preserve…"; "current `0.1.x` package line"; "boundary for `v0.1.x`" | the §4.1 rewrite |
| `MAINTAINING.md` (multiple) | "current installable sibling-package line on Hex is `0.1.x`"; "treat the `0.1.x` packages as the live consumer surface"; "expected release path for the current shipped `0.1.x` line" | "`1.x`" everywhere; add §4.2 major runbook |

Other matched guides (`getting-started.md`, `installation.md`, `product-boundary.md`, several `recipes/*` and `flows/*`) carry incidental `~> 0.1` install snippets or "0.1.x" mentions — sweep each.

### 5.2 Sweep approach (opinionated)

1. **Grep the exact patterns** (don't eyeball):
   ```bash
   grep -rn -e '0\.1\.x' -e '~> 0\.1\b' -e '0\.1\.7' -e 'future `1\.0`' \
            -e '1\.0 API freeze' -e 'ZeroVer' -e 'until a future' \
            README.md rulestead/README.md rulestead_admin/README.md \
            open_feature_rulestead/README.md guides/ MAINTAINING.md CONTRIBUTING.md
   ```
2. **Where it hides** (from experience + this repo): version-pin install snippets (`~> 0.1`), the "two version lines" admonition blocks (repeated verbatim across README + upgrading + package READMEs), the `api_stability.md` header framing, and MAINTAINING.md's "current shipped 0.1.x line" prose. The OpenFeature package README likely still implies `0.1.0`.
3. **Guard it going forward:** there is already a `release_contract_test.exs` + doc-link contract test pattern. Add a tiny **drift guard** (a test or `lint.sh` grep) that fails CI if `~> 0.1` or "future `1.0`" reappears in shipped docs — same posture as the existing brand/token drift guards. This makes the sweep *stay* swept.
4. **Don't touch `.planning/` or `prompts/`** for the public sweep — those are internal records; their "0.1.x" references are historically accurate. The sweep targets the *shipped* surface (README, guides in the Hex package, MAINTAINING).

---

## 6. Lessons from successful libraries (copy / avoid)

| Library | What they did RIGHT (copy) | Footgun (avoid) | Confidence |
|---------|----------------------------|-----------------|------------|
| **Elixir core** | Three-phase soft→hard→remove deprecation; deprecations table with Version/Feature/Replaced-by columns; removal only on major. | The literal "3 minor versions before hard-deprecation" is calibrated for a huge user base — scale the window honestly for a young 1.x, don't cargo-cult "3". | HIGH (official docs) |
| **FunWithFlags** (direct competitor, 1.x) | 1.0 framed explicitly as "API is now stable… no breaking change… upgrade without problems" — exactly the promotion-not-rewrite framing. | Loose chronological CHANGELOG with inconsistent "Possibly Breaking Changes" labels — be *consistent* with a `(BREAKING)` marker. | HIGH ([changelog](https://preview.hex.pm/preview/fun_with_flags/show/CHANGELOG.md)) |
| **Oban** | Telemetry-field soft-deprecation (drop from docs, keep emitting, remove later); migration version-gating with clear `mix ecto.migrate` instructions. | Don't let telemetry payloads silently change shape — Oban documents field deprecations precisely; do the same for the metadata-key catalog. | MEDIUM ([changelog](https://hexdocs.pm/oban/changelog.html)) |
| **Req** | Inline `**(BREAKING CHANGE)**` and `**Deprecate**` markers per changelog bullet; component-grouped entries. | Req is *still 0.x* despite huge adoption — a cautionary tale that "stay 0.x forever" erodes the trust signal. Rulestead is right to cut 1.0 once the API is genuinely frozen. | MEDIUM ([changelog](https://req.hexdocs.pm/changelog.html)) |
| **Ecto/Phoenix** | Hand-curated CHANGELOG highlights + dedicated `upgrading_to_X.md` guides per major; soft-deprecation warnings one minor before breaking. | These are large teams — their hand-curated CHANGELOG discipline is *not* worth replicating for a solo-maintained, bot-driven repo (D4). Copy their *upgrade-guide-per-major* habit, not their manual CHANGELOG. | MEDIUM (WebSearch) |
| **Cross-ecosystem (Rust/cargo-semver-checks, npm semver)** | Rust's `cargo-semver-checks` mechanically detects breaking API changes pre-publish; npm's `~`/`^` map cleanly to `~>`. | The lesson: a *mechanical* breaking-change check beats prose policy. Rulestead's `release_contract_test.exs` (api_stability bidirectional guard) is its `cargo-semver-checks` equivalent — keep investing there. | MEDIUM (WebSearch) |

---

## 7. Concrete artifacts the requirements/roadmap step can act on

- **§1.2 + §1.4** — drop-in "Versioning & Deprecation Policy" body for `guides/api_stability.md` (breaking-change table + worked example + telemetry rules). Add an empty **deprecations table** skeleton: `| Hard-deprecated (version) | Feature | Replaced by (version) | Removed in |`.
- **§2.3** — exact "promotion, not rewrite" CHANGELOG preamble for both packages.
- **§3.6** — the full ordered release-cut checklist (pre-cut → cut → post-cut → open_feature → cleanup).
- **§4.1** — drop-in `upgrading.md` "Upgrading 0.1.x → 1.0" section + the "two version lines" reframe.
- **§4.2** — drop-in `MAINTAINING.md` "Cutting a major (X.0.0)" runbook.
- **§5** — the grep command, the file-by-file reframe table, and a proposed CI drift guard.

### Config edit (D1), exact:

```jsonc
// release-please-config.json — rulestead package block, for the cut only
"rulestead": {
  "component": "rulestead",
  "release-type": "elixir",
  "package-name": "rulestead",
  "changelog-path": "rulestead/CHANGELOG.md",
  "include-component-in-tag": true,
  "release-as": "1.0.0"            // ADD for the cut; REMOVE after the release PR merges
}
```

### Roadmap phasing implication

A coherent phase order for the cut milestone:
1. **API-surface lock + stability contract** (D6/D7) — must land *before* the cut so `api_stability.md` says "1.x" when 1.0 ships.
2. **Version-truth sweep + upgrade/maintaining docs** (D8/D9/D10) — same PR wave; all doc edits before the cut, guarded by `release_contract_test.exs` + a new drift guard.
3. **HexDocs front door** (separate research R-other) — can land in parallel; not gating the cut mechanics.
4. **The release cut** (D1/D2/D3/D4/D5) — single, gated, human-merged event following §3.6.
5. **open_feature_rulestead manual publish** — strictly after step 4's `rulestead@1.0.0` is live.
6. **Announce + closeout** — after the verify-trio (and the open_feature verify) are green.

---

## Confidence assessment

| Area | Confidence | Notes |
|------|------------|-------|
| `Release-As` vs `feat!` for forcing 1.0.0 | HIGH | Confirmed against release-please docs + the repo's own `bump-minor-pre-major: true` config; this is the load-bearing finding. |
| Deprecation policy (soft/hard/`@deprecated`/remove-on-major) | HIGH | Elixir official compatibility-and-deprecations + Module docs. |
| `--warnings-as-errors` × `@deprecated` footgun | HIGH | Inferred directly from repo's `lint.sh`/`mix compile --warnings-as-errors` + documented compiler behavior. |
| CHANGELOG strategy (keep generated) | HIGH | Both CHANGELOGs read + release-please-config inspected; current shape is decisive. |
| Publish pipeline idempotency + recovery | HIGH | Read verbatim from `publish-hex.yml` (curl-skip-if-present) and MAINTAINING.md recovery path. |
| linked-versions × Release-As propagation | MEDIUM-HIGH | linked-versions forces group sync (docs confirm); recommend the config form on `rulestead` and verifying the proposed PR bumps both before merge. |
| Ecosystem comparators (Ecto/Phoenix/Req/Oban/FunWithFlags) | MEDIUM | FunWithFlags 1.0 framing + Req/Oban changelog patterns verified via fetch; Ecto/Phoenix CHANGELOG habits via WebSearch. |

## Open questions / verify-at-execution

- Confirm, on the actual release PR, that `linked-versions` + `release-as` on `rulestead` propagates `1.0.0` to `rulestead_admin` (vs. needing `release-as` on both). The PR diff will show it before merge — that's the safe checkpoint; if admin doesn't bump, add `release-as` to the admin block too.
- Confirm release-please preserves the hand-added CHANGELOG preamble across PR re-runs (it preserves prose around generated bullets, but verify on the open PR before merge).
- `open_feature_rulestead` has no CHANGELOG and is outside the verify-trio — decide whether to add a minimal `CHANGELOG.md` + a one-line published-version smoke for it (recommended for trust parity, low cost).

Sources:
- [Elixir compatibility and deprecations](https://elixir.hexdocs.pm/compatibility-and-deprecations.html)
- [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html)
- [Module / @deprecated docs](https://hexdocs.pm/elixir/Module.html)
- [release-please README & customizing.md](https://github.com/googleapis/release-please)
- [release-please manifest-releaser docs](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
- [FunWithFlags CHANGELOG](https://preview.hex.pm/preview/fun_with_flags/show/CHANGELOG.md)
- [Req CHANGELOG](https://req.hexdocs.pm/changelog.html)
- [Oban CHANGELOG](https://hexdocs.pm/oban/changelog.html)
- [Elixir School: Automating releases with Release Please](https://elixirschool.com/blog/managing-releases-with-release-please)
