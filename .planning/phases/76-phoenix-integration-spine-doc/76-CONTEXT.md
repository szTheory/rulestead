# Phase 76: Phoenix Integration Spine Doc - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Author a **first-hour Phoenix integration spine** and wire it from intro docs — without editing `evaluation.md` Runtime sections (Phase 77), release-contract guards (Phase 78), or any runtime/admin product code.

**In scope:** INT-01, INT-02, INT-03 — new spine doc, lifecycle-required flag create in spine, cross-links from README / getting-started / installation.

**Out of scope:** `guides/flows/evaluation.md` Runtime API expansion (DOC-01, Phase 77); intro lifecycle callouts outside spine wiring (DOC-02, Phase 77); `rulestead/README.md` API ordering (DOC-03, Phase 77); `release_contract_test` / `mix verify.phase76` (Phase 78); admin UI changes.

</domain>

<decisions>
## Implementation Decisions

### Spine doc shape (INT-01)
- **D-01:** Add **`guides/introduction/phoenix-integration-spine.md`** as the canonical first-hour path — do not fold the full spine into `getting-started.md` (keep getting-started as a shorter hub that links outward).
- **D-02:** Spine sections in order (numbered steps):
  1. **Dependencies + install** — pointer to `installation.md` (`mix rulestead.install`, migrate); no duplicate install prose beyond one paragraph.
  2. **Runtime supervision (OTP)** — explain that `:rulestead` starts `Rulestead.Application` → `Rulestead.Runtime.Supervisor` + snapshot cache; **do not** claim `mix rulestead.install` injects host `application.ex` children (installer does not — evidence: `rulestead/lib/rulestead/install.ex`).
  3. **Host config** — show `config/rulestead.exs` shape from install golden (`rulestead/fixtures/install_golden/tree/config/rulestead.exs`): store, repo, `:host` plug/live_view/runtime keys.
  4. **Plug boundary** — `plug Rulestead.Plug` in endpoint (golden: `install_golden/tree/lib/host_app_web/endpoint.ex`); link to `guides/recipes/context-propagation.md` for LiveView/Oban (no duplication).
  5. **First evaluation** — `Rulestead.Runtime.enabled?/3` (or `get_variant/3`) using `conn.assigns[:rulestead_context]`; one sentence that payload-first `Rulestead.evaluate/3` is the pure/test path (link `evaluation.md`).
  6. **Optional admin** — one paragraph + link to admin mount in golden router / `rulestead_admin/README.md`.

### Lifecycle on flag create (INT-02)
- **D-03:** Dedicated spine subsection **"Create your first flag (lifecycle required)"** with admin UI or store API example showing **`owner` + `expected_expiration`** on create — copy tone from `guides/flows/flag-lifecycle.md` § birth (host-owned owner, not Rulestead directory).
- **D-04:** Explicit honesty line: lifecycle fields are **required at creation**; owner ref is opaque host metadata; link `../flows/flag-lifecycle.md` for full lifecycle story — do not duplicate archive/cleanup flows.

### Intro doc wiring (INT-03)
- **D-05:** **`getting-started.md`** — after install section, add prominent link: "Phoenix first-hour path → [Phoenix Integration Spine](phoenix-integration-spine.md)"; trim or shorten §3–§4 if redundant with spine (keep a minimal payload-first snippet OR defer Runtime example to spine — planner chooses minimal diff).
- **D-06:** **`installation.md`** — "What happens next" lists spine as step 1 before evaluation.md.
- **D-07:** **Root `README.md`** — quickstart section links spine for Phoenix integrators (one line near install/evaluate); do not remove payload-first honesty from README.

### Code examples and tone
- **D-08:** Examples use **`attributes:`** in `Rulestead.Context.new/1` only (CTX-02 carry-forward); environment key `"production"` or `"dev"` consistent with getting-started.
- **D-09:** Use **install golden** and **context-propagation.md** as source-of-truth for Plug/config snippets — avoid inventing config keys not in `Rulestead.Config.defaults/0`.
- **D-10:** Title/subtitle frame **~15-minute first success** aligned with `prompts/rulestead-personas-jtbd-and-onboarding.md` Alex JTBD — not a second product tutorial.

### Phase boundary (explicit non-goals)
- **D-11:** No changes to `release_contract_test.exs` or verify tasks (Phase 78).
- **D-12:** No `evaluation.md` edits naming `Rulestead.Runtime` APIs (Phase 77) — spine may mention Runtime; evaluation doc alignment is separate.

### Execution shape
- **D-13:** Plan as **one primary doc plan** (76-01 spine + cross-links) unless planner splits cross-link edits for reviewability.

### Claude's Discretion
- Exact spine filename anchor slug if planner prefers `integration-spine.md` over `phoenix-integration-spine.md` (keep `phoenix-` prefix unless link churn is costly)
- Whether getting-started §3 payload-first block stays verbatim or becomes a single-line deferral to spine + evaluation.md
- Admin create example: UI walkthrough vs minimal `Rulestead.Store`/`Fake` snippet for non-UI readers

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 76 goal and success criteria
- `.planning/REQUIREMENTS.md` — INT-01, INT-02, INT-03
- `.planning/MILESTONE-ARC.md` — v1.11 integration spine rationale
- `.planning/threads/2026-05-28-path-to-done-milestones.md` — INV-INTRO-01 exit criteria

### Host integration (primary)
- `prompts/rulestead-host-app-integration-seam.md` — installer UX, config layering, host-owned identity
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — 15-minute Alex path
- `rulestead/lib/rulestead/install.ex` — what install actually injects
- `rulestead/fixtures/install_golden/tree/config/rulestead.exs` — config shape
- `rulestead/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex` — Plug injection
- `rulestead/fixtures/install_golden/tree/lib/host_app_web/router.ex` — admin mount

### Existing guides (link targets, minimal duplication)
- `guides/recipes/context-propagation.md` — Plug → LiveView → Oban
- `guides/flows/flag-lifecycle.md` — owner + expected_expiration at birth
- `guides/introduction/getting-started.md` — hub to update
- `guides/introduction/installation.md` — hub to update
- `README.md` — root quickstart link

### Prior phase patterns
- `.planning/phases/73-context-and-maintainer-doc-truth/73-CONTEXT.md` — quickstart honesty, release-contract scope discipline
- `.planning/phases/75-proof-umbrella-and-milestone-closure/75-CONTEXT.md` — deferred v1.11 boundary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Install golden tree** — authoritative post-install file shapes for config, endpoint, router
- **`Rulestead.Plug`** — `rulestead/lib/rulestead/plug.ex`; assigns `:rulestead_context`
- **`Rulestead.Application`** — supervises `Rulestead.Runtime.Supervisor`, not host `Application` children
- **`guides/recipes/context-propagation.md`** — already documents Plug options matching install defaults

### Established Patterns
- **Docs-only milestone** — no `lib/` changes; guards land Phase 78
- **Separate spine doc** — matches v1.10 product-boundary + footguns pattern (focused guides, cross-linked)
- **Payload-first vs Runtime** — getting-started already has both; spine elevates Runtime path for Phoenix hour-one

### Integration Points
- Edit: `guides/introduction/phoenix-integration-spine.md` (new), `getting-started.md`, `installation.md`, `README.md`
- Do not edit: `evaluation.md`, `release_contract_test.exs`, `mix verify.*` (later phases)

</code_context>

<specifics>
## Specific Ideas

- Close INV-INTRO-01 narrative in Phase 77–78; Phase 76 delivers the spine artifact and intro cross-links only.
- Supervision step should teach **OTP application startup**, not fictional `children` injection into host `application.ex`.

</specifics>

<deferred>
## Deferred Ideas

- **evaluation.md Runtime section** — Phase 77 (DOC-01)
- **release-contract intro spine guard** — Phase 78 (VER-01)
- **mix verify.phase76** — Phase 78 (VER-02)
- **Demo compose walkthrough expansion** — out of scope unless user requests; `examples/demo` stays secondary to spine

</deferred>

---

*Phase: 76-phoenix-integration-spine-doc*
*Context gathered: 2026-05-28*
