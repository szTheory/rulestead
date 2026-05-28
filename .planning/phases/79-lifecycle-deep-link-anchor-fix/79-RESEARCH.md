# Phase 79 — Research: Lifecycle Deep-Link Anchor Fix

**Researched:** 2026-05-28  
**Phase:** 79 — Lifecycle Deep-Link Anchor Fix  
**Requirements:** DOC-02, INT-02

## RESEARCH COMPLETE

## Question

What must change to fix the broken getting-started → spine §6 lifecycle deep-link and prevent regression?

## Findings

### Root cause

- Spine heading: `## 6. Create your first flag (lifecycle required)` in `guides/introduction/phoenix-integration-spine.md` (line 131).
- GitHub/HexDocs slugify numbered headings with the number prefix: `#6-create-your-first-flag-lifecycle-required`.
- `getting-started.md` line 40 uses `#create-your-first-flag-lifecycle-required` (missing `6-` prefix) — link lands at page top, not §6.
- Historical plan `77-01-PLAN.md` documents the same wrong anchor in its callout template (reference only; not executed at runtime).

### Scope (minimal)

| File | Action |
|------|--------|
| `guides/introduction/getting-started.md` | Replace anchor with `#6-create-your-first-flag-lifecycle-required` |
| `.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-01-PLAN.md` | Align historical anchor in callout example |
| `rulestead/test/rulestead/intro_integration_spine_contract_test.exs` | Assert correct deep-link slug; refute broken slug |

### Out of scope

- `installation.md` — links spine file only, no §6 fragment (grep clean).
- New product APIs, spine content edits, `verify.phase76` task changes (already green).
- Phase 80 `VERIFICATION.md` backfill (separate phase).

### Contract test pattern (Phase 78)

Extend existing `IntroIntegrationSpineContractTest` — same `Path.expand` style, add test `"getting-started deep-links spine §6 with numbered heading slug"`:

```elixir
assert getting_started =~ "phoenix-integration-spine.md#6-create-your-first-flag-lifecycle-required"
refute getting_started =~ "phoenix-integration-spine.md#create-your-first-flag-lifecycle-required"
```

### Verification commands

```bash
grep '#6-create-your-first-flag-lifecycle-required' guides/introduction/getting-started.md
! grep 'phoenix-integration-spine.md#create-your-first-flag-lifecycle-required' guides/introduction/getting-started.md
cd rulestead && mix test test/rulestead/intro_integration_spine_contract_test.exs
cd rulestead && mix verify.phase76
```

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| Regression guard | ExUnit contract test on getting-started.md link fragment |
| Proof spine | `mix verify.phase76` (intro contract test already in union) |
| Manual | Optional: click link on GitHub preview after merge (not blocking) |

## Dependencies

- **Depends on Phase 78:** `intro_integration_spine_contract_test.exs` and `mix verify.phase76` exist.
- **Unblocks Phase 80:** DOC-02/INT-02 adopter flow proof can cite fixed anchor.

## Risks

| Risk | Mitigation |
|------|------------|
| Renderer slug drift (non-GitHub) | Anchor matches GitHub/HexDocs convention documented in audit |
| Over-broad refute breaks valid substrings | Refute exact broken fragment `phoenix-integration-spine.md#create-your-first-flag-lifecycle-required` |
