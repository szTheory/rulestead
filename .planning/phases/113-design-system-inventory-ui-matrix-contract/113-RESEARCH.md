# Phase 113: Design-System Inventory + UI Matrix Contract - Research

**Researched:** 2026-06-13
**Domain:** Phoenix LiveView admin design-system inventory, UI matrix contract, and planning evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Treat Phase 113 as a contract/inventory phase. The deliverable is an implementation-ready taxonomy, state matrix, operator-lens map, fixture-data needs list, and acceptance gate definition for Phases 114-118, not code polish.
- **D-02:** Keep the contract grounded in the mounted admin as shipped today: actual `RulesteadAdmin.Components.*` modules, LiveView page markup, `rs-*` CSS classes, existing static fixtures, and current Playwright guard patterns.
- **D-03:** Do not add new public runtime APIs, schemas, release workflow changes, component libraries, palette/logo work, broad pixel-baseline infrastructure, FleetDesk brand changes, or `rulestead_admin` publish preparation.
- **D-04:** Inventory the design system in five buckets: foundations, primitives, composites, page patterns, and workflow states.
- **D-05:** Foundations include token categories, theme cascade, typography rhythm, spacing, breakpoints, radius, shadows/elevation, focus rings, reduced motion, responsive table behavior, logo usage, and token/logo/contrast guard scripts.
- **D-06:** Primitives include buttons, links, badges/status indicators, cards/sections, callouts/banners, stats/signals, tags, pagination, form controls, task links, detail grids, empty states, flash, command palette controls, environment/tenant controls, and table rows.
- **D-07:** Composites include mutation-confirm flows, audit/timeline/diff panels, rollout/guardrail/auto-advance panels, rule editor surfaces, audience dependency/impact panels, simulation/explain traces, governance/blast-radius panels, diagnostics summaries, schedule/webhook rows, and change-request rows.
- **D-08:** Page patterns include shell/header/rail/breadcrumb layout, home task launcher and attention band, flag inventory, flag detail subnav, rules workspace, simulate/explain/timeline/rollouts/kill routes, audience flows, audit, diagnostics, compare, schedule, webhooks, experiments, change requests, and permission-denied/read-only states.
- **D-09:** Distinguish reusable component modules from repeated raw `rs-*` LiveView markup. Repeated raw markup becomes either a later consolidation candidate for Phase 116 or an explicitly documented exception, but Phase 113 only inventories and classifies it.
- **D-10:** The UI matrix contract must require normal, dense, empty, loading, error, permission-denied/read-only, long-label/long-key, narrow-width/mobile, destructive-action, disabled/unavailable, and focus/keyboard states.
- **D-11:** The matrix contract must require light, dark, system-dark, desktop, mobile/narrow, and reduced-motion evidence dimensions where they affect component behavior or visual correctness.
- **D-12:** Use real admin components and representative fixed assigns in the future Phase 114 matrix. Static HTML fixtures remain useful for token/theme/contrast guard assertions, but they must not become the primary component contract because they can duplicate and drift from HEEx.
- **D-13:** Fixture-data needs should be named by state and operator outcome, not by decorative examples. Required data should cover happy path, dense data, empty data, loading/error, permission-denied, long values, destructive confirmation, missing host evidence, archived/read-only records, stale/blocked guardrail signals, and audit diff/raw-detail rows.
- **D-14:** Organize route clusters and examples around operator jobs-to-be-done: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding/happy paths, and destructive actions.
- **D-15:** Preserve the existing navigation mental model from `RulesteadAdmin.Navigation`: Overview, Build & release, Explain & diagnose, and Review & approve. The Phase 113 contract may map additional lenses, but it should not rename or restructure navigation as implementation.
- **D-16:** Treat destructive actions as a first-class lens. Kill switch, cleanup/archive, audience archive/delete, rollout risky jump, governed execution, and production typed-confirm paths need shared preview -> confirm -> audit expectations.
- **D-17:** Phase 114 should build a repo-native Phoenix/Playwright UI matrix that renders real admin component modules and seeded LiveView flows. Do not introduce JavaScript Storybook or PhoenixStorybook in v1.17 unless this contract later proves repo-native evidence insufficient.
- **D-18:** Keep v1.17 evidence to curated screenshots plus deterministic assertions: fixture health, no horizontal overflow, focus visibility, keyboard flow, selected ARIA roles, selected contrast pairs, reduced-motion behavior, and light/dark/system mode rendering.
- **D-19:** Preserve existing guard chain responsibilities: `check_synced_pair.py`, `check_brand_tokens.py`, `check_tokens_css.py`, `check_contrast.py`, `check_brandbook_html.py`, `check_logo_assets.py`, SVG budgets, and existing Playwright theme/brand evidence. Extend guards later only where they prevent real design-system drift.
- **D-20:** Do not add broad checked-in pixel baselines or external AI visual judging. Human review remains the qualitative layer; deterministic assertions and screenshot artifacts provide repeatable evidence.

### the agent's Discretion

- Choose the exact document/file shape for the Phase 113 inventory artifact, provided it is easy for Phase 114 and later phases to consume.
- Prefer compact table-driven contracts over prose-only notes.
- If a helper script is needed for component functions or `rs-*` selectors, keep it repo-local, deterministic, and documentation-oriented.

### Deferred Ideas (OUT OF SCOPE)

- Repo-native UI matrix implementation is Phase 114.
- Breakpoint/token/focus/reduced-motion/table hardening is Phase 115.
- Primitive/composite consolidation and polish is Phase 116.
- Page-flow IA changes are Phase 117.
- Milestone-wide screenshot/guardrail closeout is Phase 118.
- PhoenixStorybook, JavaScript Storybook, broad pixel-baseline visual regression, external AI visual judging, forced-colors/high-contrast OS mode, v2 product wedges, and `rulestead_admin` publish preparation remain out of scope for v1.17 unless a later explicit roadmap change says otherwise.
</user_constraints>

<project_constraints>
## Project Constraints

- Respect the current phase boundary from `.planning/ROADMAP.md`.
- Keep Phase 8-only docs absent.
- Do not publish or prepare to publish the `rulestead_admin` stub.
- Keep edits aligned with the linked-version, two-package release design.
- Make the smallest coherent change that satisfies the active plan.
- Avoid speculative features from future phases.
- Preserve reproducibility and CI readability.
</project_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
| --- | --- | --- | --- |
| Component taxonomy artifact | Planning docs | Mounted admin source | Phase 113 produces a contract from existing source; it does not alter runtime code. |
| UI matrix state contract | Planning docs | Future Phoenix/Playwright matrix | Phase 114 owns implementation; Phase 113 names required state and evidence dimensions. |
| Operator lens map | Planning docs | `RulesteadAdmin.Navigation` and LiveView routes | Existing navigation remains the mental model; the contract maps routes to operator outcomes. |
| Fixture-data needs | Planning docs | Future demo/fixture seed data | Phase 113 names needed data cases by state and operator outcome. |
| Acceptance gates | Planning docs | Existing guard scripts and Playwright patterns | Phase 113 defines gates; later phases extend guards only for real drift classes. |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 113 needs no new library research. The standard approach is a source-backed planning contract that turns current Phoenix component modules, LiveView routes, CSS token classes, static fixtures, and Playwright evidence into a follow-on implementation map. The future UI matrix should render real Phoenix components with fixed assigns; Phase 113 only defines what that matrix must include.

The strongest existing anchors are `RulesteadAdmin.Components.OperatorComponents`, `ConfirmComponents.mutation_confirm/1`, `RulesteadAdmin.Navigation`, `Shell.page/1`, `scripts/ci/lint.sh`, and `examples/demo/frontend/tests/brand-ui-evidence.spec.ts`. Those sources already encode the component vocabulary, operator navigation model, guard-chain posture, and route/theme/viewport evidence loop.

**Primary recommendation:** Plan three docs-only execution slices: source-backed inventory, UI matrix/operator-lens contract, and acceptance/traceability gates with requirement completion.
</research_summary>

<standard_stack>
## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
| --- | --- | --- | --- |
| Phoenix.Component | existing repo dependency | Real admin components and HEEx component contracts | Future matrix must render actual component functions, not duplicate static markup. |
| Phoenix LiveView | existing repo dependency | Mounted admin routes and stateful workflows | Route clusters and workflows are LiveView-owned. |
| Scoped `rs-*` CSS tokens | repo-owned | Admin visual language, theme, focus, motion, responsive behavior | Existing guard scripts already enforce token drift and scope. |
| Playwright | existing demo frontend dependency | Screenshot and deterministic browser evidence | Existing brand evidence uses route/theme/viewport loops and overflow checks. |
| Python guard scripts | stdlib scripts | Token, logo, contrast, brandbook, and SVG budget checks | They are already wired into `scripts/ci/lint.sh`. |

### Supporting

| Tool | Purpose | When to Use |
| --- | --- | --- |
| `rg` | Inventory component functions, routes, and `rs-*` class usage | Source-backed documentation checks and lightweight assertions. |
| `mix format --check-formatted` | Elixir formatting gate | Only relevant in later phases that touch Elixir code. |
| `npm run test:e2e` | Browser matrix/evidence | Phase 114+ when a matrix or workflow screenshot target exists. |

### Installation

No package installation is needed for Phase 113. All planned artifacts are Markdown and use existing repo tools.
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### System Architecture Diagram

```
Existing admin source
  -> component/function inventory
  -> taxonomy + raw markup exception ledger
  -> UI matrix state and operator lens contract
  -> acceptance gates for Phases 114-118
```

### Recommended Project Structure

```
.planning/phases/113-design-system-inventory-ui-matrix-contract/
  113-DESIGN-SYSTEM-INVENTORY.md
  113-UI-MATRIX-CONTRACT.md
  113-ACCEPTANCE-GATES.md
```

### Pattern 1: Source-backed inventory

**What:** Each row should name a bucket, source file, component or pattern, required states, operator lens, current evidence, gap/exception, and follow-on phase.
**When to use:** For `DSM-01` and D-04 through D-09.
**Verified source anchors:** `OperatorComponents` lines 6-249, `ConfirmComponents` lines 28-91, `Shell.page/1` lines 8-170, and `Navigation.groups/3` lines 32-90. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/operator_components.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/confirm_components.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/navigation.ex]

### Pattern 2: Existing evidence loop

**What:** Evidence should use route/theme/viewport loops plus deterministic assertions such as no horizontal overflow.
**When to use:** For matrix and acceptance gate design, not for broad pixel baselines.
**Verified source anchors:** `brand-ui-evidence.spec.ts` declares desktop/mobile viewports, light/dark/system-dark themes, admin route surfaces, and `expectNoHorizontalOverflow(page)`. [VERIFIED: examples/demo/frontend/tests/brand-ui-evidence.spec.ts]

### Pattern 3: Guard chain preservation

**What:** Normal lint already runs token sync, token mirror, contrast, brandbook, logo, and SVG budget checks.
**When to use:** Acceptance gates should preserve these responsibilities and only extend them in later phases for real drift classes.
**Verified source anchors:** `scripts/ci/lint.sh` lines 20-58 run the six Python guard scripts and SVG budgets. [VERIFIED: scripts/ci/lint.sh]

### Anti-Patterns to Avoid

- Duplicating static HEEx as the primary component contract; it can drift from real component modules.
- Starting Phase 114 matrix routes or Phase 115 CSS hardening while writing Phase 113 docs.
- Renaming the navigation mental model instead of mapping it.
- Treating broad pixel baselines or external visual AI judging as required evidence.
- Marking DSM-01 or DSM-03 complete without a source-backed artifact and deterministic source assertions.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
| --- | --- | --- | --- |
| Component docs | JavaScript Storybook or PhoenixStorybook now | Repo-native contract now; future Phoenix/Playwright matrix in Phase 114 | D-17 keeps Storybook out of v1.17 unless repo-native evidence proves insufficient. |
| Visual regression | Checked-in baseline screenshots for every route | Curated screenshots plus deterministic assertions | D-18 and D-20 avoid broad pixel maintenance. |
| Component source truth | Static HTML copies of HEEx | Real `RulesteadAdmin.Components.*` modules and fixed assigns | D-12 requires real components for the future matrix. |
| Guard extensions | New broad guard framework | Existing guard scripts, extended only for real drift classes | D-19 preserves CI readability and existing guard ownership. |
| Inventory automation | Fragile generated docs that rewrite large files | `rg`-backed source assertions and compact Markdown tables | The phase is documentation-oriented; a helper is optional and must be deterministic. |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Static fixture drift
**What goes wrong:** The matrix contract points to static HTML as the authoritative component example.
**Why it happens:** Static fixtures are easy to inspect and already exist.
**How to avoid:** Treat static fixtures as low-level token/theme/contrast evidence only; real components must be the future matrix source.
**Warning signs:** Matrix rows cite `design-system.html` without a corresponding `RulesteadAdmin.Components.*` or LiveView source.

### Pitfall 2: Partial state coverage
**What goes wrong:** Normal/empty/error examples ship but permission-denied, long-label, narrow-width, destructive, disabled, and focus states are missed.
**Why it happens:** Happy-path component inventories look complete.
**How to avoid:** The matrix contract must enumerate D-10 and D-11 states explicitly and verify them by source assertion.
**Warning signs:** No rows for permission-denied/read-only, long-key, mobile/narrow, reduced-motion, or typed confirm flows.

### Pitfall 3: Scope leakage into later phases
**What goes wrong:** Docs work turns into route implementation, CSS tuning, primitive consolidation, or Playwright harness code.
**Why it happens:** The contract naturally points at implementation gaps.
**How to avoid:** Every artifact row should have a follow-on phase column instead of implementing the fix now.
**Warning signs:** Phase 113 modifies `rulestead_admin/lib`, `rulestead_admin/priv/static/css`, test specs, package files, release workflows, or publish metadata.

### Pitfall 4: Raw `rs-*` overcounting
**What goes wrong:** Token names and CSS declarations get misclassified as repeated LiveView markup.
**Why it happens:** A blind class grep mixes CSS definition sites, token names, static fixtures, and HEEx call sites.
**How to avoid:** Split source categories: component module, LiveView call site, static fixture, CSS definition, token literal.
**Warning signs:** The raw markup ledger does not distinguish source file type or follow-on classification.
</common_pitfalls>

<code_examples>
## Code Examples and Source Anchors

| Source | Verified Pattern |
| --- | --- |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | Phoenix component primitives declare `attr/3`, `slot/2`, and render scoped `rs-*` classes. |
| `rulestead_admin/lib/rulestead_admin/components/confirm_components.ex` | `mutation_confirm/1` is the canonical preview -> confirm -> audit form shape for destructive/governed mutations. |
| `rulestead_admin/lib/rulestead_admin/components/shell.ex` | `Shell.page/1` owns shell, brand, context controls, navigation, theme control, breadcrumbs, and flash frame. |
| `rulestead_admin/lib/rulestead_admin/navigation.ex` | Navigation groups are Overview, Build & release, Explain & diagnose, and Review & approve. |
| `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | Evidence loops over theme cases and viewports, captures screenshots, and asserts no horizontal overflow. |
| `scripts/ci/lint.sh` | CI guard chain already covers synced tokens, brand tokens, token mirror, contrast, brandbook HTML, logo assets, and SVG budgets. |
</code_examples>

<package_legitimacy_audit>
## Package Legitimacy Audit

No package-manager install tasks are required or allowed for Phase 113.

| Package | Ecosystem | Status | Rationale |
| --- | --- | --- | --- |
| none | none | N/A | Phase 113 writes planning docs only and reuses existing repo tools. |
</package_legitimacy_audit>

<security_notes>
## Security Notes

Phase 113 changes planning artifacts only. It does not introduce runtime input handling, authentication, authorization, persistence, public APIs, schemas, release workflow changes, or package installs.

Relevant security posture for the plan:
- Preserve permission-denied/read-only as required matrix states.
- Preserve destructive-action preview -> confirm -> audit expectations.
- Preserve existing guard chain and do not weaken CI checks.
- Treat `rulestead_admin` publish preparation as out of scope.
</security_notes>

<validation_architecture>
## Validation Architecture

Phase 113 verification should use source assertions because the deliverables are Markdown contracts:

1. Assert the inventory artifact exists and contains the five taxonomy buckets plus real source module names.
2. Assert the matrix contract exists and contains every required D-10 state plus D-11 evidence dimensions.
3. Assert the acceptance gates artifact exists and references DSM-01, DSM-03, guard scripts, and downstream Phases 114-118.
4. Assert `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` are updated only at final traceability closeout.
5. Assert no runtime, package, release workflow, schema, CSS, or publish-prep files changed in Phase 113 execution.
</validation_architecture>

<open_questions>
## Open Questions (RESOLVED)

1. **Should Phase 113 create implementation code?** RESOLVED: No. D-01 and D-03 make this a contract/inventory phase only.
2. **Should the future matrix use Storybook?** RESOLVED: No for v1.17. D-17 keeps the future harness repo-native Phoenix/Playwright unless the contract later proves it insufficient.
3. **Should broad pixel baselines be part of acceptance?** RESOLVED: No. D-18 and D-20 keep evidence to curated screenshots, deterministic assertions, and human review.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)

- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md` - locked Phase 113 decisions and boundaries.
- `.planning/ROADMAP.md` - Phase 113 goal and DSM-01/DSM-03 requirement mapping.
- `.planning/REQUIREMENTS.md` - v1.17 requirement descriptions.
- `rulestead_admin/lib/rulestead_admin/components/*.ex` - current component module inventory.
- `rulestead_admin/lib/rulestead_admin/live/**/*.ex` - mounted admin route/page usage.
- `rulestead_admin/lib/rulestead_admin/navigation.ex` - operator navigation grouping.
- `rulestead_admin/priv/static/css/rulestead_admin.css` - scoped token and class system.
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` - current Playwright screenshot/assertion pattern.
- `scripts/ci/lint.sh` - current guard chain.

### External

- None. No external package or current internet research was needed because the phase is repo-specific and documentation-only.
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Phoenix LiveView mounted admin design-system documentation.
- Ecosystem: Existing repo dependencies and guard scripts only.
- Patterns: Component inventory, route clusters, matrix evidence dimensions, acceptance gates.
- Pitfalls: Scope leakage, static fixture drift, missing rare states, raw class overcounting.

**Confidence breakdown:**
- Standard stack: HIGH - all tools are already in repo.
- Architecture: HIGH - current source and roadmap define ownership.
- Pitfalls: HIGH - directly derived from v1.13-v1.16 decisions and Phase 113 context.
- Code examples: HIGH - all source anchors are local files.

**Research date:** 2026-06-13
**Valid until:** End of v1.17, unless Phase 114 changes the matrix implementation strategy.
</metadata>

---

*Phase: 113-design-system-inventory-ui-matrix-contract*
*Research completed: 2026-06-13*
*Ready for planning: yes*
