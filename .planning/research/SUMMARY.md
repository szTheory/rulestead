# Research Synthesis — v2.0 "1.0 GA Release & Adoption"

**Milestone:** v2.0 — cut a real `1.0.0` of all three Hex packages (`rulestead`,
`rulestead_admin`, `open_feature_rulestead`), ship a 1.0-grade HexDocs front
door + adoption guides, and announce. **No new runtime features; public surface
locked as-is.**
**Synthesized:** 2026-06-17 from R1 RELEASE · R2 HEXDOCS · R3 GUIDES · R4 POSITIONING
**Overall confidence:** HIGH on mechanics, doc structure, content, and positioning
(verified against repo source + official ExDoc/release-please/Elixir docs + Oban/Req
exemplars); MEDIUM only on a few ecosystem-norm details flagged inline (ElixirForum
taxonomy, exact version ranges, social-card rasterization).

This is a **one-shot, no-surprises plan.** The four reports are mutually
coherent; where two implied different sequencing, this synthesis picks one and
says why. Read §1 first — those discoveries change the roadmap and are easy to
miss.

---

## 1. Must-not-miss discoveries (read these first)

These five findings are load-bearing. Missing any one ships a broken or
dishonest 1.0. They cut across all four reports and several are non-obvious.

### 1.1 `feat!:` will NOT produce `1.0.0` — you MUST use `"release-as": "1.0.0"` (R1)

`release-please-config.json` has `bump-minor-pre-major: true` **and**
`bump-patch-for-minor-pre-major: true`. Under those flags, a `feat:` bumps
**patch** (`0.1.7 → 0.1.8`) and a breaking `feat!:` bumps only **minor**
(`0.1.7 → 0.2.0`) — **nothing auto-promotes to `1.0.0`.** The only deterministic
mechanism is **`"release-as": "1.0.0"`** added to the **`rulestead`** package
block; `linked-versions` then propagates the same `1.0.0` to `rulestead_admin`.

- **Mandatory cleanup:** after the release PR merges, **remove `"release-as"`**
  or release-please re-proposes `1.0.0` forever. Bake this into the runbook.
- Post-1.0 the two `bump-*-pre-major` flags become **no-ops** (strict semver
  resumes automatically); leave them but note this so a future maintainer isn't confused.

### 1.2 `brandbook/` is missing from package `files:` → logo/README 404s (R2)

The ExDoc `logo`/`favicon` and the README header image all reference
`brandbook/assets/...`, but `mix.exs` `files:` (lines 81–83) does **not** include
`brandbook/`. Without adding `brandbook/assets/logo` (and `specimens` for the
README header) to `files:`, the published Hex tarball ships without the SVGs and
**HexDocs + hex.pm 404 the logo on launch day.** This is a release-blocker.
Verify with `mix hex.build` and inspect the tarball **before** the real publish.

### 1.3 Three public modules are `@moduledoc false` and won't render (R2)

`Rulestead.Context`, `Rulestead.Runtime`, and `Rulestead.Admin.Policy` are
listed **public/semver-locked** in `api_stability.md` but carry `@moduledoc false`
— ExDoc excludes them entirely. For a 1.0 that markets stability, a public-but-
invisible module is the worst trust signal. Fix = real `@moduledoc` (drafts in
R2 §2.1) + `@doc`/`@spec` on every public function. Also: `Rulestead.Runtime` is
absent from `groups_for_modules` (would land ungrouped), and
`Rulestead.Runtime.Snapshot` is *leaked* into a group despite being non-public —
remove it.

### 1.4 The version-truth sweep — 14 files lie about being `0.1.x` (R1, R2)

14 shipped files carry stale `0.1.x` / `~> 0.1` / "future `1.0` API freeze"
language that directly contradicts a 1.0 cut. The load-bearing ones: `README.md`,
`rulestead/README.md`, `rulestead_admin/README.md`, `guides/api_stability.md`
(the biggest single edit, R1-D7), `guides/introduction/upgrading.md`,
`MAINTAINING.md`. **Critically: the README "Two version lines" callout
(lines 7–10) must be deleted entirely** — the milestone *resolves* the ZeroVer
mismatch, so leaving the callout re-introduces the exact confusion the milestone
exists to kill. Grep the exact patterns (R1 §5.2); do not eyeball. Add a
CI **drift guard** (grep in `lint.sh`) so the sweep *stays* swept. Do **not**
touch `.planning/` or `prompts/` — their `0.1.x` references are historically accurate.

### 1.5 Idempotent publish + the manual `open_feature_rulestead` sequence (R1)

`publish-hex.yml` is **idempotent** (each job `curl`s `hex.pm/api/.../1.0.0` and
skips if present), so a partial publish (core ok, admin failed) safely resumes by
re-running with the same inputs. **`open_feature_rulestead` is outside
release-please** (currently `0.1.0`, `{:rulestead, path: "../rulestead"}`) and must
be published **manually, strictly after `rulestead@1.0.0` is live on Hex** — its
`~> 1.0` dep can't resolve before then. Use an env-gated dep swap mirroring the
existing admin `RULESTEAD_ADMIN_HEX_RELEASE` pattern (R1 §3.3) so local dev/CI keep
the path dep.

---

## 2. Unified decisions register

Merged across all four reports, deduped, conflicts resolved. Source key:
**R1**=RELEASE · **R2**=HEXDOCS · **R3**=GUIDES · **R4**=POSITIONING.

### Release mechanics & contract (R1)

| Decision | Recommendation | Why | Src |
|----------|----------------|-----|-----|
| Force `1.0.0` | `"release-as": "1.0.0"` on `rulestead`; linked-versions propagates to admin | `feat!:` only yields `0.2.0` under pre-major flags | R1-D1 |
| Cut auto-merge | Disable `release-pr-automerge` for the cut; hand-merge after eyeballing the diff | Irreversible + linked; cheap human gate | R1-D2 |
| `open_feature_rulestead` | Manual `mix hex.publish` **after** `rulestead@1.0.0` live; flip dep to `~> 1.0` (env-gated) | Outside release-please; dep can't resolve sooner | R1-D3 |
| CHANGELOG strategy | Keep release-please-generated, per-package; no root CHANGELOG, no Keep-a-Changelog | Don't fight the tool you already run | R1-D4 |
| `1.0.0` framing | "Promotion, not rewrite" preamble: explicit *zero breaking changes* | Matches FunWithFlags 1.0; prevents "what broke?" churn | R1-D5, R4-D5 |
| SemVer + deprecation | Elixir's soft→hard(`@deprecated`)→remove-on-major; telemetry events are contract | Idiomatic; adopters expect it | R1-D6 |
| Policy home | Rewrite `api_stability.md` top to "1.x" + add Versioning & Deprecation Policy | One canonical contract doc, already guarded by `release_contract_test.exs` | R1-D7 |
| `upgrading.md` | 0.1.x→1.0 = dep-pin bump, zero code change; reframe "two version lines" | Cut is intentionally zero-break | R1-D8 |
| `MAINTAINING.md` | Add "Cutting a major (X.0.0)" runbook (Release-As, deprecation window, 3-package sequence) | No major-bump path exists today | R1-D9 |
| Version-truth sweep | Grep + reframe 14 stale files; add CI drift guard | Stale `0.1.x` language contradicts the cut | R1-D10 |

### HexDocs front door (R2)

| Decision | Recommendation | Src |
|----------|----------------|-----|
| Render 3 hidden modules | Real `@moduledoc` on `Context`, `Runtime`, `Admin.Policy` | R2-D1 |
| Module groups (5) | Core API · Runtime (cached lookup) · Behaviours & Seams · Store Adapters · Telemetry & Config | R2-D2/D3 |
| `extras:` order | Onboarding funnel: Why → Install → Getting Started → Spine → concepts → flows → recipes; promote `api_stability.md` to its own group | R2-D4 |
| `groups_for_extras` (6) | Introduction · Guides (label, not "Flows") · Recipes · API & Stability · Contributing | R2-D5 |
| `logo:` | `../brandbook/assets/logo/rs-mark.svg` (square, for 48px slot) | R2-D6 |
| `favicon:` | `../brandbook/assets/logo/rs-favicon.svg` | R2-D7 |
| Theming | `before_closing_head_tag` re-tints ExDoc CSS vars (mineral palette); respect ExDoc light/dark; **no theme JS**; minimal CSS | R2-D8 |
| `assets:` | `%{"../brandbook/assets/logo" => "assets"}` to ship card/marks | R2-D9 |
| `source_ref` | Keep `"v#{@version}"` (auto-resolves to `v1.0.0`) | R2-D10 |
| `main:` | Keep `main: "readme"`; README is the landing | R2-D11 |
| "Why Rulestead?" extra | New `guides/introduction/why-rulestead.md`, first in Introduction; NOT a README dupe | R2-D12, R4 §2 |
| Doc coverage | Every `api_stability.md` symbol gets `@doc` + `@spec`; doctests only where pure; treat ExDoc undefined-ref warnings as a release gate | R2-D13 |
| `@moduledoc false` discipline | Anything not in `api_stability.md` stays hidden + "internal" comment | R2-D14 |
| README badges (5) | Hex version · HexDocs · CI · License · (Elixir version) | R2-D15, R4-D9 |
| Social card | `rs-social-card.svg` as GitHub social preview (rasterize to PNG) + OG image via head tag | R2-D16 |
| `rulestead_admin` docs | Same logo/favicon/theming + real `@moduledoc` on `RulesteadAdmin.Router` + admin flow guides | R2-D17 |

### Adoption guides (R3)

| Decision | Recommendation | Src |
|----------|----------------|-----|
| `troubleshooting.md` | **7 symptom-indexed patterns**, format Symptom → Cause → Fix → Verify | R3-D1/D2 |
| vs `footguns.md` | Distinct, cross-linked, NOT merged (how-to vs explanation) | R3-D3 |
| `integrations-cookbook.md` | **4 recipes** (Stripe-tier audience · eval-telemetry→Segment · staging→prod CR promotion · Oban-gated job) | R3-D4 |
| Recipe template | Goal → Personas/JTBD → Prereqs → Steps → Verification → Gotchas → Related | R3-D5 |
| IA placement | Both land in existing Recipes group; cookbook early, troubleshooting last; no new group | R3-D6 |
| 15-min path | **Untouched** — neither guide is on the golden path; link forward only | R3-D7 |
| Anti-scope | Recipes use only shipped public seams; honest boundary line per recipe | R3-D10 |

### Positioning & announce (R4)

| Decision | Recommendation | Src |
|----------|----------------|-----|
| One-liner | "Elixir-native feature-management runtime AND self-hostable Phoenix control plane" — never "X for Elixir" | R4-D1 |
| "Why" framing axis | Frame against *in-house build* + *outgrowing booleans*, NOT named vendors | R4-D2 |
| vs FunWithFlags | The layer *above* booleans; ship migration path as proof of respect; never "better than" | R4-D3 |
| vs SaaS (LD/Unleash/Flagsmith) | Self-hostable + Phoenix-native + host-owned; borrow governance vocab, never price/parity | R4-D4 |
| 1.0 honesty | "Promotion, not debut" — API-frozen, battle-tested, version finally tells the truth | R4-D5 |
| ElixirForum post | Single post in Libraries (`announcement` tag); tl;dr + real snippet + honest story + open invite; maintainer replies in-thread | R4-D6 |
| GitHub release notes | `brandbook/RELEASE-TEMPLATE.md` verbatim; operator-consequence-first; 3 packages, one note | R4-D7 |
| Timing | Cut + publish + verify-trio-green + HexDocs renders **before** posting to ElixirForum | R4-D8, R1 §3.5 |
| Tagline | "Runtime decisions, made clear." everywhere; don't invent new ones | R4-D10 |
| What NOT to claim | No "production-ready as if new", no counts, no "fastest", no "drop-in LD replacement", no AI/growth verbs | R4-D11 |

**Resolved cross-report tensions:**
- **README badge order** — R2 and R4 both list the same 5 badges; adopt R4's
  order (Hex version · HexDocs · CI · License · Elixir version) with R2's exact
  markdown.
- **"Why Rulestead?" sourcing** — R2 owns the file/placement/outline; R4 owns the
  narrative content. One canonical extra, condensed for the forum tl;dr (R4 §7).
  No second source.
- **Sequencing of HexDocs vs the cut** — R1 treats HexDocs as parallel/non-gating
  for the cut *mechanics*; R4 makes a rendered front door a *gate before announce*.
  Both are right and non-conflicting: **docs work lands before the cut (so the
  published tarball is complete), and the announce waits for the rendered front
  door.** See §4.

---

## 3. Recommendations by target feature area

The five milestone target features, each with the concrete artifacts the reports
produced.

### 3.1 API-surface lock & stability contract (R1 + R2)

- **Render the 3 hidden modules** (R2 §2.1 has drop-in `@moduledoc` drafts in
  brand voice) + `@doc`/`@spec` audit on every `api_stability.md` symbol.
- **Rewrite `api_stability.md`** top from "0.1.x" to "1.x" and add the
  **Versioning & Deprecation Policy** section: the breaking-change table (R1 §1.2),
  the worked deprecation example (R1 §1.4), telemetry-stability rules (R1 §1.3),
  and an empty deprecations-table skeleton.
- **Footgun:** `mix compile --warnings-as-errors` (in `lint.sh`) turns a future
  `@deprecated` into a hard CI failure — internal callers must migrate in the same
  minor. Soft-deprecation (docs only) sidesteps it. Document this in the policy.
- Keep `release_contract_test.exs` green after edits (it bidirectionally guards
  `api_stability.md` ↔ code).

### 3.2 HexDocs front door (R2)

- Apply the **5 module groups** and **6 extras groups**; reorder `extras:` to the
  onboarding funnel; promote `api_stability.md` + `upgrading.md` into "API & Stability".
- Set `logo`/`favicon`/`assets` (R2 §1.4) — **and add `brandbook/assets/logo`(+`specimens`)
  to `files:`** (the §1.2 release-blocker).
- Inject the **minimal** `before_closing_head_tag` (R2 §1.5): re-tint `:root`/`.dark`
  CSS vars to the mineral palette, brand `:focus-visible` ring, OG-image meta. No
  custom stylesheet, no theme JS — near-stock chrome ages best.
- Mirror logo/favicon/theming to `rulestead_admin/mix.exs` + a real `@moduledoc`
  on `RulesteadAdmin.Router`.
- README: delete the "two version lines" callout, add the centered hero
  (wordmark + tagline + badge row, R2 §4), bump all pins to `~> 1.0`.

### 3.3 Adoption guides (R3)

- **`troubleshooting.md`** — 7 patterns (install/migration · payload-vs-keyed-runtime
  · snapshot boot race · context propagation · RBAC 403 · change-request block ·
  OpenFeature/Redis stale), each Symptom → Cause → Fix → Verify, cross-linking
  `footguns.md` for the "why". Full outline with stubs in R3 Part 1.
- **`integrations-cookbook.md`** — 4 recipes on the fixed template, each with a
  Verification close and an honest boundary line. Full stubs in R3 Part 2.
- Both slot into the existing Recipes group (cookbook early, troubleshooting last);
  the 15-minute path is untouched. Voice: blame-free, "what did NOT happen, what
  to do next" (R3 Part 4 say-this/not-this tables).

### 3.4 Release cut (R1)

- Follow the **exact ordered checklist in R1 §3.6** (pre-cut docs → cut → post-cut
  verify → open_feature → cleanup). Artifacts ready to paste: the `release-as`
  config edit (R1 §7), the "promotion, not rewrite" CHANGELOG preamble (R1 §2.3),
  the `upgrading.md` 0.1.x→1.0 section (R1 §4.1), the `MAINTAINING.md` major-bump
  runbook (R1 §4.2).
- Two human gates for one irreversible event: hand-merge the release PR (D2) **and**
  the existing `hex-publish` environment approval.
- Post-publish: run the **verify-trio** (`scripts/ci/verify_published_release.sh 1.0.0`)
  — already built; just run it. Add a minimal manual verify for `open_feature_rulestead`.

### 3.5 Announce & closeout (R4)

- **GitHub release** from `RELEASE-TEMPLATE.md` with the filled content in R4 §4
  (headline, "no behavior changes" line doing real work).
- **ElixirForum post** — single Libraries post, `announcement` tag, the draft
  structure in R4 §3 (tl;dr → real `Rulestead.evaluate/3` snippet → honest maturity
  story → proof bullets → honest scope → respectful FunWithFlags note → links →
  open invite). Maintainer watches the thread 24–72h.
- **Closeout = the front door is provably live + honest** (R4 §6 gate chain):
  trio resolvable, verify green, HexDocs renders the new shape (logo, "Why",
  3 modules visible), badges resolve, release + post cross-linked, milestone audit
  captures evidence — **zero new runtime APIs.**

---

## 4. Dependency-ordered build sequence

The canonical phase order. The hard rule: **all doc/contract work lands BEFORE
the cut** (so the published tarball is complete and honest), the **cut is a single
gated human-merged event**, the **manual provider publish is strictly after**, and
the **announce waits for a green verify-trio + a rendered HexDocs front door.**

```
PHASE A — Contract & doc truth  (BEFORE the cut; can largely run in parallel)
  A1  API-surface lock: render the 3 @moduledoc-false modules; @doc/@spec audit;
      api_stability.md -> "1.x" + Versioning & Deprecation Policy.   [R1 §1, R2 §2]
  A2  Version-truth sweep: reframe 14 files; DELETE README "two version lines"
      callout; add CI drift guard.                                   [R1 §5]
  A3  upgrading.md 0.1.x->1.0; MAINTAINING.md major-bump runbook.    [R1 §4]
  A4  HexDocs front door: 5 module groups, 6 extras groups, logo/favicon/assets,
      add brandbook to files:, theming head-tag, README hero+badges,
      rulestead_admin docs parity.                                   [R2]
  A5  Adoption guides: troubleshooting.md (7) + integrations-cookbook.md (4);
      wire into extras.                                              [R3]
  A6  "Why Rulestead?" extra (canonical positioning narrative).      [R2-D12, R4 §2]
  -> Gate: cd rulestead && mix ci ; bash scripts/ci/local.sh green;
          release_contract_test.exs green; `mix hex.build` tarball CONTAINS the
          logo SVGs (proves §1.2 fixed).

PHASE B — The cut  (single gated human-merged event)
  B1  Disable release-pr-automerge (repo var / toggle).             [R1-D2]
  B2  Add "release-as": "1.0.0" to rulestead block; merge to main.  [R1-D1]
  B3  Review the release PR diff (both @version, manifest, CHANGELOG roll-up);
      VERIFY linked-versions bumped BOTH packages; add the "promotion, not
      rewrite" preamble to both CHANGELOGs; hand-merge.             [R1-D5]
  B4  Approve the hex-publish environment; confirm publish-core then publish-admin.
  -> Gate: handoff dispatches verify-published-release.yml; trio green.  [R1 §3.5]

PHASE C — Provider publish  (STRICTLY after rulestead@1.0.0 is live)
  C1  Confirm hex.pm rulestead 1.0.0 == 200.
  C2  Bump open_feature_rulestead -> 1.0.0, dep -> {:rulestead, "~> 1.0"} (env-gated).
  C3  Publish; verify hex 200 + HexDocs renders + fresh consumer resolves rulestead ~> 1.0.
  C4  (decide) add a minimal CHANGELOG to open_feature_rulestead.   [R1 open Q]

PHASE D — Announce & closeout  (after verify-trio green + HexDocs renders)
  D1  GitHub release from RELEASE-TEMPLATE.                         [R4 §4]
  D2  Eyeball HexDocs front door (logo, "Why", 3 modules, badges resolve).  [R4 §6]
  D3  ElixirForum post linking only confirmed-live artifacts.       [R4 §3]
  D4  Milestone audit + evidence capture; maintainer-presence window 24-72h.

CLEANUP  (immediately after the merge in Phase B / end of milestone)
  X1  REMOVE "release-as" from config (else it re-proposes 1.0.0).  [R1-D1]
  X2  Re-enable release-pr-automerge.                               [R1-D2]
  X3  Note bump-*-pre-major flags are now no-ops post-1.0.          [R1 §3.1]
```

**What can run in parallel:** Phase A items A1–A6 are largely independent (one
doc PR wave) and **can all land before the cut in any order**, with one ordering
constraint — A1 (api_stability "1.x" rewrite) and A2 (sweep) should be reviewed
together so `release_contract_test.exs` + the new drift guard stay green. Phase A
docs are **not gated by** the cut mechanics, but the cut **is gated by** Phase A
completing (so the tarball is honest). Phases B -> C -> D are strictly serial by
dependency resolution and trust.

---

## 5. Open questions / execution-time checkpoints

Consolidated from all four reports. None are blockers; each has a safe checkpoint.

**Release mechanics (R1):**
- Confirm on the actual release PR that `release-as` on `rulestead` +
  `linked-versions` propagates `1.0.0` to **`rulestead_admin`**; if admin doesn't
  bump, add `release-as` to its block too. (Checkpoint: the PR diff, before merge.)
- Confirm release-please preserves the hand-added CHANGELOG preamble across PR re-runs.
- Decide whether to add a minimal `CHANGELOG.md` to `open_feature_rulestead`
  (recommended for trust parity, low cost — it's outside the verify-trio).
- `GITHUB_TOKEN` may not trigger follow-on `ci.yml`; if `gate-ci-green` stalls,
  `workflow_dispatch ci.yml` on the tagged ref (existing mitigation in MAINTAINING).

**HexDocs (R2):**
- Confirm `Rulestead.Telemetry` and `Rulestead.Config` are NOT `@moduledoc false`
  (both listed public — apply the D1 fix if hidden).
- Decide whether `Rulestead.Tenancy` is intended public (referenced in config
  schema but not the stable-modules list) — group it or drop it.
- Confirm `Rulestead.Runtime.diagnostics/1` arity vs the root `diagnostics/0`
  delegate; document the exact frozen arity, don't invent one.
- After first `mix docs`, verify monorepo **source links** resolve (the package
  root is `rulestead/` but `source_url` is repo root); add `source_url_pattern`
  only if they 404.
- Confirm the CI workflow filename for the README CI badge.
- Rasterize `rs-social-card.svg` -> 1200x630 PNG for GitHub's social-preview slot
  (GitHub wants PNG/JPG; existing brand tooling renders SVG->PNG).

**Guides (R3):**
- Confirm exact `mix rulestead.*` compare/promote command names for recipe R3
  against shipped tasks before finalizing steps (use placeholders until verified).
- Confirm the OpenFeature provider init snippet against the published
  `open_feature_rulestead` shape.
- Verify cross-link anchor slugs (`footguns.md#...`) match ExDoc's generated
  anchors after the 1.0 render.

**Positioning/announce (R4):**
- Re-confirm the live ElixirForum category name + first-post etiquette at post time
  (community taxonomy drifts; MEDIUM confidence).
- Pin the exact supported Elixir/OTP/Phoenix range for the RELEASE-TEMPLATE
  Compatibility block from the actual repo.

---

## Confidence assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Release mechanics (Release-As, idempotent publish, sequencing) | HIGH | Verified vs repo config/workflows + release-please docs |
| Deprecation policy + `--warnings-as-errors` footgun | HIGH | Elixir official docs + repo `lint.sh` |
| HexDocs config (ExDoc options, groups, theming) | HIGH | Official ExDoc docs + Req/Ash exemplars + repo brandbook |
| `files:` / hidden-module / source-link gotchas | HIGH | Read directly from repo source |
| Adoption-guide structure + content | HIGH | Repo source-of-truth + Oban/Diátaxis idiom |
| Positioning + announce | HIGH | Locked positioning + brand book + verified Oban/Req threads |
| ElixirForum taxonomy, version ranges, social-card raster | MEDIUM | Community lore / pin at execution time |

**Bottom line:** the plan is decisive and internally consistent. The only real
risks are the five §1 discoveries — all of which have concrete, repo-verified
fixes and explicit pre-cut gates. Execute Phase A fully before touching the cut,
keep the calm/exact brand voice in every shipped word, and announce only when the
front door is provably live and honest.
