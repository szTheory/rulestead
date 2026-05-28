# Phase 73: Context And Maintainer Doc Truth - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Finish `Rulestead.Context` `traits:` → `attributes` back-compat and align public quickstart + maintainer docs with shipped contract reality — without syncing the full `api_stability.md` catalog, adding `mix verify.phase73`, or changing post-GA module lists (Phases 74–75).

**In scope:** CTX-01, CTX-02, DOC-01 — Context promotion, quickstart `attributes:` teaching, `MAINTAINING.md` no longer defers live `api_stability.md`, release-contract guards for quickstart and maintainer truth.

**Out of scope:** API-01–03 and api_stability catalog reconciliation (Phase 74); `mix verify.phase73` / adopter delegate (Phase 75); `product-boundary.md` Runtime semver posture (Phase 74); v1.10.1 milestone audit closure (Phase 75).

</domain>

<decisions>
## Implementation Decisions

### Context `traits:` back-compat (CTX-01)
- **D-01:** Keep **silent promotion** in `Rulestead.Context.new/1`: `:traits` and `"traits"` merge into `:attributes`; explicit `:attributes` wins on key conflicts via `Map.merge(from_traits, from_attributes)`.
- **D-02:** No public `traits` field on `%Rulestead.Context{}` — back-compat input alias only, not a second canonical field.
- **D-03:** Unit tests in `context_test.exs` cover traits-only input and attributes-over-traits conflict resolution.

### Quickstart doc honesty (CTX-02)
- **D-04:** **Quickstart** for the `traits: %{` release-contract guard means **root `README.md`** and **`guides/introduction/getting-started.md`** only — the paths adopters hit in the 15-minute path.
- **D-05:** Public quickstart examples teach `attributes:` in `Rulestead.Context.new/1` (or struct literals); no `traits: %{...}` in those docs.
- **D-06:** **Do not** extend the quickstart guard to internal/admin vocabulary: admin simulate form `traits` field → `attributes`, impact-preview `sample_evidence` maps, telemetry redaction `%{traits: ...}` keys, or contract-test fixture maps remain valid where they are not adopter-facing quickstart copy.

### Release-contract enforcement (CTX-02 + DOC-01)
- **D-07:** Keep (or land) `release_contract_test.exs` test **"quickstart Context.new examples use attributes not traits for evaluation inputs"** — asserts `attributes:` present and refutes `traits: %{` in root README + getting-started.
- **D-08:** Add a **maintainer doc truth** block in `release_contract_test.exs` mirroring Phase 64/72 support-truth style:
  - `MAINTAINING.md` must **not** list `guides/api_stability.md` under deferred Phase 8 artifacts
  - `MAINTAINING.md` must describe `guides/api_stability.md` as the **live** public contract (with drift guarded by release contract / Phase 74 catalog work)

### MAINTAINING.md rewrite (DOC-01)
- **D-09:** **Remove** the "Deferred Phase 8 artifacts / Do not create these early" section entirely.
- **D-10:** Replace with a short **"Public surface contract (live)"** section listing:
  - `guides/api_stability.md` — primary semver public-surface contract
  - `guides/flows/extending-rulestead.md` — documented extension seams
  - `guides/cheatsheet.cheatmd` — operator quick reference
  - Note that catalog completeness and generate-from-contract discipline are Phase 74 (INV-API-01), not Phase 73.
- **D-11:** Close **INV-MAINT-01** when DOC-01 + D-08 ship; record in Phase 75 audit (AUD-01) with proof pointers.

### Phase boundary (explicit non-goals)
- **D-12:** Do **not** edit `guides/api_stability.md` module/event catalogs (API-01), telemetry/struct drift unions (API-02), or `Rulestead.Runtime` support posture in `product-boundary.md` (API-03) in this phase.
- **D-13:** Do **not** add `mix verify.phase73` or change `mix verify.adopter` delegation (VER-01/02) — Phase 75.

### Execution shape
- **D-14:** Plan as **two vertical slices**:
  - **73-01** — Land Context promotion + `context_test.exs` (fold uncommitted CTX-01 work if still local)
  - **73-02** — MAINTAINING rewrite + release-contract quickstart/maintainer guards (DOC-01, CTX-02 enforcement)

### Claude's Discretion
- Exact assert strings in the new maintainer truth test block (as long as Phase 8 deferral of `api_stability.md` is impossible to reintroduce silently)
- Whether `rulestead/README.md` gets an optional `Context.new(attributes: ...)` example (not required for D-04 scope; add only if planning finds adopter confusion)
- Wording of the live public-surface section in MAINTAINING (collapsible detail vs always-visible)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 73 goal and success criteria
- `.planning/REQUIREMENTS.md` — CTX-01, CTX-02, DOC-01
- `.planning/STATE.md` — INV-CTX-01, INV-MAINT-01 status
- `.planning/MILESTONE-ARC.md` — v1.10.1 support-truth rationale

### Context and quickstart
- `rulestead/lib/rulestead/context.ex` — `promote_traits_to_attributes/1`
- `rulestead/test/rulestead/context_test.exs` — promotion and conflict tests
- `README.md` — root quickstart
- `guides/introduction/getting-started.md` — first-success path
- `guides/flows/evaluation.md` — canonical evaluate/context contract

### Maintainer and public contract
- `MAINTAINING.md` — replace Phase 8 deferral section (DOC-01 target)
- `guides/api_stability.md` — live public contract (do not defer)
- `guides/flows/extending-rulestead.md` — extension guide (shipped)
- `guides/cheatsheet.cheatmd` — operator reference (shipped)
- `rulestead/test/rulestead/release_contract_test.exs` — quickstart + maintainer drift guards

### Patterns from prior proof phases
- `.planning/milestones/v1.8.0-phases/64-proof-docs-and-support-truth/64-CONTEXT.md` — release_contract support-truth block pattern
- `.planning/milestones/v1.10.0-phases/70-doc-contract-and-api-honesty/` — post-GA doc honesty precedent (if plans exist)

### Engineering DNA
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — api_stability as first-class contract
- `prompts/rulestead-domain-language-field-guide.md` — attributes vs traits vocabulary
- `CLAUDE.md` — Phase 8-only docs rule superseded by shipped guides

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Context.new/1` + `promote_traits_to_attributes/1` — CTX-01 implementation largely present in working tree
- `release_contract_test.exs` — quickstart payload-first and post-GA band closure blocks as templates for D-08
- `context_test.exs` — traits promotion tests ready to land with code

### Established Patterns
- Support-truth phases (60, 64, 72) extend `release_contract_test.exs` with bounded doc assertions across README + MAINTAINING
- Per-phase verify tasks are flat unions — Phase 73 intentionally has **no** new verify task (deferred to 75)
- `@moduledoc false` on `Rulestead.Context` — public contract is keyword shape at `new/1`, not struct field docs

### Integration Points
- Quickstart path: README → getting-started → evaluation.md → `Rulestead.Runtime`
- Maintainer path: MAINTAINING → api_stability.md → release_contract_test
- Admin simulate still maps form `traits` → `attributes` internally (`rulestead_admin/.../simulate.ex`) — out of quickstart guard scope

</code_context>

<specifics>
## Specific Ideas

- Fold any uncommitted CTX-01 / CTX-02 work from the v1.10.1 assessment thread as the Phase 73 code deliverable rather than re-implementing.
- MAINTAINING "Deferred Phase 8" section is actively harmful now — all three listed files exist and ship in Hex package files.

</specifics>

<deferred>
## Deferred Ideas

- **api_stability catalog sync / generate-from-contract** — Phase 74 (INV-API-01)
- **`mix verify.phase73` + adopter delegate** — Phase 75 (VER-01/02)
- **`Rulestead.Runtime` explicit semver posture** — Phase 74 API-03 / product-boundary
- **Package README `Context.new` example** — optional; only if planner finds gap vs D-04
- **v1.11 integration spine (Plug, supervision, lifecycle)** — separate milestone (INV-INTRO-01)

None — analysis stayed within phase scope aside from explicit deferrals above.

</deferred>

---

*Phase: 73-context-and-maintainer-doc-truth*
*Context gathered: 2026-05-28*
