# Phase 74: API Stability Catalog Sync - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile `guides/api_stability.md` with the shipped post-GA public surface that adopters and `release_contract_test.exs` already rely on, and add bidirectional CI guards so catalog drift cannot recur silently (closes INV-API-01).

**In scope:** API-01, API-02, API-03, VER-03 — catalog prose, `product-boundary.md` Runtime semver posture, bidirectional release-contract drift guards.

**Out of scope:** New product APIs; `mix verify.phase74` / adopter verify changes (Phase 75); `STATE.md` investigation closure (Phase 75 AUD-01); widening governance/admin internals to public modules; generate-from-contract tooling.

</domain>

<decisions>
## Implementation Decisions

### Catalog sync strategy (API-01)
- **D-01:** **Manual catalog update** driven by existing `release_contract_test.exs` constants — do **not** build generate-from-contract tooling in this phase.
- **D-02:** Treat `release_contract_test.exs` module attributes (`@root_exports`, `@store_callbacks`, `@telemetry_events`, struct field lists, config key lists, error atom lists) as the **source of truth**; update `guides/api_stability.md` prose to match.
- **D-03:** Add missing post-GA surface to the written contract, including at minimum:
  - Root facade functions already in `@root_exports` but absent from the doc (e.g. `apply_audience_mutation`, `preview_audience_impact`, `list_audience_dependencies`)
  - Store callbacks and `Rulestead.Admin.Policy` callbacks matching test constants
  - `%Rulestead.Error{}` closed `:type` atoms including `:snapshot_not_found`
  - Host config top-level `:tenancy` and nested tenancy keys matching `Config.schema/0`

### Supported adopter facades (API-01 + API-03)
- **D-04:** Add a dedicated **"Supported adopter facades (post-GA)"** section — distinct from the v0.1.0 core "Stable `rulestead` Modules" list — so semver posture is honest without listing every `Rulestead.Runtime.*` implementation module.
- **D-05:** **`Rulestead.Runtime`** is a **supported adopter facade** with a **closed function catalog**: `evaluate/3`, `enabled?/3`, `get_value/4`, `get_variant/3`, `explain/3`, `diagnostics/1` (match `Rulestead.Runtime` exports). Internal modules (`Rulestead.Runtime.Cache`, `Rulestead.Runtime.Snapshot`, etc.) remain non-public.
- **D-06:** **`Rulestead.TestHelpers`** is the supported test facade; document its public helper surface per `guides/recipes/testing.md`. **`Rulestead.Fake`** is documented only as the implementation behind TestHelpers — not as a broad public module tree (`Rulestead.Fake.Control` etc. stay non-catalog).
- **D-07:** Revise or qualify the blanket line **"No other `Rulestead.*` modules are public"** so it does not contradict Runtime/TestHelpers support; core v0.1.0 module list stays closed, facades are additive.
- **D-08:** **`product-boundary.md`** gets an explicit Runtime semver paragraph: supported keyed lookup path for snapshot-cache Phoenix apps; behavior stable on `0.1.x`; implementation modules not semver-locked.

### Drift guards (API-02 + VER-03)
- **D-09:** Extend **`release_contract_test.exs`** with **bidirectional** guards:
  - **Code → doc** (extend existing): telemetry events, and new checks for root exports, store/policy callbacks, error types, config keys as needed
  - **Doc → code**: every item in test-maintained `@documented_*` lists appears in `api_stability.md` (substring or structured assert — avoid fragile full-markdown parsing beyond module/function names)
- **D-10:** Introduce test-maintained lists such as `@documented_supported_facades` (at minimum `Rulestead.Runtime`, `Rulestead.TestHelpers`) asserted present in the guide.
- **D-11:** Keep **Context quickstart honesty** in `release_contract_test.exs` (Phase 73) — do not duplicate in `post_ga_band_contract_test.exs` unless a doc-only assertion fits better there.
- **D-12:** Optional: add a **doc existence / cross-link** assertion to `post_ga_band_contract_test.exs` only if it keeps post-GA band closure scope readable; primary drift guards live in `release_contract_test.exs`.

### Execution shape
- **D-13:** Plan as **two vertical slices**:
  - **74-01** — Catalog prose: `guides/api_stability.md` + `guides/introduction/product-boundary.md` Runtime posture (API-01, API-03)
  - **74-02** — Contract tests: bidirectional drift guards (API-02, VER-03)
- **D-14:** Proof for this phase: `cd rulestead && mix test test/rulestead/release_contract_test.exs` (and full suite before merge). No new `mix verify.phase74` task (Phase 75).

### Phase boundary (explicit non-goals)
- **D-15:** Do **not** add new Runtime or root-facade functions; catalog-only alignment.
- **D-16:** Do **not** catalog `Rulestead.Governance.*`, `Rulestead.Manifest.*`, guardrails internals, or admin LiveView modules as public API.
- **D-17:** Do **not** close INV-API-01 in `STATE.md` here — Phase 75 AUD-01 records closure with proof pointers.

### Claude's Discretion
- Exact assert mechanism for doc ↔ test sync (shared module attributes vs duplicated constants — prefer single source in test file)
- Whether `Rulestead.Fake` gets a one-line cross-reference under TestHelpers vs omitted entirely
- Wording of the post-GA facades section (table vs bullet catalog)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 74 goal and success criteria
- `.planning/REQUIREMENTS.md` — API-01, API-02, API-03, VER-03
- `.planning/STATE.md` — INV-API-01 status
- `.planning/MILESTONE-ARC.md` — v1.10.1 support-truth rationale
- `.planning/phases/73-context-and-maintainer-doc-truth/73-CONTEXT.md` — Phase 73 boundaries (D-12 non-goals)

### Contract and catalog
- `guides/api_stability.md` — primary semver catalog (edit target)
- `guides/introduction/product-boundary.md` — Runtime support posture (edit target)
- `rulestead/test/rulestead/release_contract_test.exs` — source-of-truth constants and drift guards
- `rulestead/test/rulestead/post_ga_band_contract_test.exs` — post-GA doc honesty (optional extension)

### Adopter paths and vocabulary
- `guides/introduction/getting-started.md` — Runtime quickstart
- `guides/flows/evaluation.md` — payload-first vs Runtime lookup
- `guides/recipes/testing.md` — TestHelpers + Fake test story
- `guides/flows/extending-rulestead.md` — Store/Policy/Router seams (unchanged scope)
- `guides/recipes/footguns.md` — Runtime vs payload-first footguns
- `MAINTAINING.md` — live public contract section (Phase 73)

### Code references
- `rulestead/lib/rulestead/runtime.ex` — Runtime facade exports
- `rulestead/lib/rulestead.ex` — root facade exports
- `rulestead/lib/rulestead/config.ex` — host schema including `:tenancy`
- `rulestead/lib/rulestead/error.ex` — closed `:type` atoms
- `rulestead/lib/rulestead/admin/policy.ex` — Policy callbacks

### Patterns from prior proof phases
- `.planning/milestones/v1.8.0-phases/64-proof-docs-and-support-truth/64-CONTEXT.md` — release_contract support-truth pattern
- `.planning/milestones/v1.10.0-phases/70-doc-contract-and-api-honesty/` — product-boundary + quickstart honesty precedent

### Engineering DNA
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — api_stability as first-class contract
- `prompts/rulestead-release-engineering-and-ci.md` — contract test discipline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `release_contract_test.exs` — `@root_exports`, `@store_callbacks`, `@telemetry_events`, `@config_*_keys`, struct field helpers — extend, do not replace
- `post_ga_band_contract_test.exs` — Runtime quickstart assertions; optional doc-only additions
- Phase 73 maintainer truth test — `"maintainer doc truth treats api_stability as live public contract"`

### Established Patterns
- Support-truth phases sync **test constants first**, then **api_stability prose**, then **bidirectional asserts** (Phases 60, 64, 68, 72, 73)
- `@moduledoc false` on Runtime does not mean unsupported — quickstart and product-boundary already teach it
- Telemetry guard is already **code → doc** (`for event <- @telemetry_events`); Phase 74 adds symmetric catalog coverage

### Integration Points
- Merge gate: full `mix test` includes `release_contract_test.exs`
- Post-GA band CI scope: `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- Phase 75 will extend `mix verify.adopter` and close INV-API-01 in STATE

### Known drift (pre-Phase-74)
- `api_stability.md` root function catalog shorter than `@root_exports`
- `api_stability.md` missing `:tenancy`, `:snapshot_not_found`, audience store/policy callbacks
- Doc claims no other `Rulestead.*` modules public while quickstart teaches `Rulestead.Runtime`

</code_context>

<specifics>
## Specific Ideas

- User confirmed all assumptions without correction — proceed with supported-facade model for Runtime/TestHelpers.
- Prefer minimal semver surface: facade function lists, not implementation module trees.

</specifics>

<deferred>
## Deferred Ideas

- **generate-from-contract CI tool** — out of scope; manual sync + test constants sufficient for v1.10.1
- **`mix verify.phase74` + STATE INV-API-01 closure** — Phase 75
- **Cataloging `Rulestead.Governance.*` / manifest modules** — not adopter-facing public API
- **v1.11 integration spine (Plug, supervision)** — separate milestone (INV-INTRO-01)

None — analysis stayed within phase scope aside from explicit deferrals above.

</deferred>

---

*Phase: 74-api-stability-catalog-sync*
*Context gathered: 2026-05-28*
