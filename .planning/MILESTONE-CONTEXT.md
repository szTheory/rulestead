# Milestone Context: v2.0 — 1.0 GA Release & Adoption

> Staged by the 2026-06-17 milestone-step assessment + scoping pass for `/gsd-new-milestone` to
> consume. See `.planning/threads/2026-06-17-1.0-release-posture-and-done-assessment.md`.

## Milestone

**Name:** v2.0 — 1.0 GA Release & Adoption

**Goal:** Publish a real, semver-stable `1.0.0` of all three packages on Hex with a 1.0-grade front
door (HexDocs + adoption guides + announce), telling the truth about the platform's actual maturity.
**No new runtime features** — this corrects a ZeroVer trust mismatch (published `0.1.7` despite an
API-frozen, governance-rich, battle-tested platform).

## Locked decisions (maintainer, 2026-06-17)

1. **All three packages publish at `1.0.0` together** — `rulestead`, `rulestead_admin` (linked in
   release-please), and `open_feature_rulestead` (currently `0.1.0`, NOT in release-please → an
   explicitly-sequenced **manual** publish step; its dep becomes `rulestead ~> 1.0`).
2. **Hex semver is THE public contract going forward.** This GSD milestone is named **v2.0** to mark
   the significant external cut; the internal v-ledger is subordinate/decoupled. This milestone ends
   the dual-track naming confusion (internal "v1.0.0 GA" ≠ Hex `1.0.0`).
3. **Lock the existing public surface as-is** — the API audit found no real warts; no "last clean
   break" renames (that would be overbuild).

## Target features (suggested phases — roadmapper assigns final numbers, continuing from 123)

Docs land **before** the cut so the published 1.0 HexDocs ships complete.

1. **API-surface lock & stability contract** (`API-*`)
   - Reconcile `guides/api_stability.md` against actual code.
   - Give `Rulestead.Context`, `Rulestead.Runtime`, `Rulestead.Admin.Policy` real `@moduledoc`s (all
     three are `@moduledoc false` today yet listed public → won't render on HexDocs); add
     `Rulestead.Runtime` to `groups_for_modules` in `rulestead/mix.exs`.
   - Audit `@doc`/`@spec` coverage on every listed-public symbol; confirm no accidental public
     surface; telemetry event names stable; dialyzer clean on the public surface.
   - Author the **post-1.0 SemVer + deprecation policy** in `api_stability.md` (`@deprecated`,
     deprecate-in-minor / remove-in-next-major window, with a worked example).

2. **HexDocs front door** (`DOC-*` / `DX-*`)
   - Add the brandbook logo to the `docs:` block; reorder `extras:` to the real onboarding flow.
   - Add a **"Why Rulestead?"** positioning extra (reuse `brandbook/brand-book.md` + COPY/VOICE).
   - Refine module groups (incl. the now-rendering public modules); README badges (Hex version /
     docs / license) + social card. Brand-faithful, principle of least surprise, clean light/dark.

3. **Adoption guides** (`DOC-*`)
   - `guides/recipes/troubleshooting.md` — top 5–8 adopter failure patterns, surfacing the existing
     `guides/recipes/footguns.md`.
   - `guides/recipes/integrations-cookbook.md` — Stripe-tier → reusable audience; evaluation
     telemetry → Segment/analytics; staging → prod promotion via change request. Grounded in the
     canonical personas (Alex/Tova/Priya/Sam/Shiori).

4. **Release cut — all three → `1.0.0`** (`REL-*`)
   - Version-truth sweep (remove all "0.1.x experimental" language across README/guides).
   - `1.0.0` CHANGELOG entries (zero-breaking-change framing); fill `guides/introduction/upgrading.md`
     for 0.1.x→1.0 (near-trivial: dep pin bump + the stability promise).
   - `MAINTAINING.md` major-bump runbook.
   - **Disable release-PR auto-merge for the cut**; stage the `feat!:` bump on a branch; merge
     deliberately → release-please publishes `rulestead` + `rulestead_admin`; then the
     **explicitly-sequenced manual publish of `open_feature_rulestead` 1.0.0**; post-publish verify
     trio green.

5. **Announce & closeout** (`ADOPT-*` / `VER-*`)
   - ElixirForum post + GitHub release from `brandbook/RELEASE-TEMPLATE.md`; milestone audit; confirm
     HexDocs renders the new front door.

**Dependency order:** 1 → (2, 3 parallel) → 4 (cut bundles docs) → 5 (announce after live + verified).

## "Done enough" (exit criteria)
- hex.pm shows `rulestead`, `rulestead_admin`, `open_feature_rulestead` all at **1.0.0**.
- `api_stability.md` is the real 1.0 contract; the three public modules render on HexDocs; SemVer +
  deprecation policy documented.
- `1.0.0` CHANGELOG entries + filled `upgrading.md`; version-truth swept (no "0.1.x experimental").
- HexDocs front door has logo, "Why Rulestead?", reordered extras, badges.
- `troubleshooting.md` + `integrations-cookbook.md` shipped.
- ElixirForum/GitHub announce posted; post-publish verify trio green; `MAINTAINING.md` major-bump runbook.

## Out of scope / overbuild watch
- **BRD-05 standalone marketing site — deferred.** HexDocs + ElixirForum is the idiomatic,
  higher-leverage front door for an Elixir lib.
- Skip: interactive rule builder, blog/CMS, email funnel, video tutorials, client SDKs, stats engine,
  comparison microsite.
- All v2 feature wedges stay trigger-gated: GOV-02-ext → ROL-08 → ADM-06.
- **No runtime API/schema changes; no "last clean break" renames** (none warranted).

## Key context to carry in
- **Pipeline:** auto-publish-on-merge — sequence the bump carefully; disable release-PR auto-merge
  for the cut. `open_feature_rulestead` is outside release-please (manual publish).
- **Reuse, don't reinvent:** `brandbook/{VOICE,COPY,RELEASE-TEMPLATE}.md` + logo assets.
- **Ground guides** in `prompts/rulestead-personas-jtbd-and-onboarding.md`.
- **Positioning:** "best Elixir-native feature-management runtime + best self-hostable Phoenix-first
  control plane" — NOT "LaunchDarkly for Elixir."
- **API audit result:** no warts; the 0.1.x→1.0 delta for adopters is near-zero (a dep pin bump).
