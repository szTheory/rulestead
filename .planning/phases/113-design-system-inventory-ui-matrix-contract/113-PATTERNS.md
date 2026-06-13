# Phase 113: Design-System Inventory + UI Matrix Contract - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 5 planned docs/tracking files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md` | planning artifact | source inventory | `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md` plus component modules | exact |
| `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md` | planning artifact | contract matrix | `.planning/milestones/v1.16-phases/107-brand-ui-audit-ui-spec/107-UI-SPEC.md` | role-match |
| `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-ACCEPTANCE-GATES.md` | planning artifact | verification contract | `.planning/milestones/v1.16-phases/112.1-close-gap-bui-05-bui-06-dynamic-fleetdesk-launcher-url-and-e/112.1-VERIFICATION.md` | role-match |
| `.planning/REQUIREMENTS.md` | tracking doc | requirement status | existing v1.17 traceability table | exact |
| `.planning/ROADMAP.md`, `.planning/STATE.md` | tracking docs | phase progress | current v1.17 phase/progress sections | exact |

## Pattern Assignments

### `113-DESIGN-SYSTEM-INVENTORY.md` (planning artifact, source inventory)

**Analog:** `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md`

**Decision-source pattern** (lines 19-30):

```markdown
- D-04 inventories five buckets: foundations, primitives, composites, page patterns, workflow states.
- D-05 through D-09 define bucket contents and raw `rs-*` classification.
```

**Component source pattern**:

```elixir
# rulestead_admin/lib/rulestead_admin/components/operator_components.ex
attr(:title, :string, required: true)
attr(:body, :string, required: true)
attr(:tone, :string, default: "neutral")

def banner(assigns) do
  ~H"""
  <section class="rs-banner" data-tone={@tone} aria-label={@aria_label}>
```

Apply this pattern by naming component modules/functions and their `rs-*` classes instead of abstract component names.

**Navigation source pattern**:

```elixir
# rulestead_admin/lib/rulestead_admin/navigation.ex
@groups [
  {"Build & release", [...]},
  {"Explain & diagnose", [...]},
  {"Review & approve", [...]}
]
```

Use the navigation grouping as the primary operator-lens source. Add audiences, rollouts, audit, onboarding, and destructive actions as lenses without renaming the shipped rail.

---

### `113-UI-MATRIX-CONTRACT.md` (planning artifact, contract matrix)

**Analog:** `.planning/milestones/v1.16-phases/107-brand-ui-audit-ui-spec/107-UI-SPEC.md`

**Behavior contract pattern** (lines 7-14):

```markdown
## Required Behaviors

- Rulestead lockup is visible on admin/demo/fixture surfaces at usable sizes in light, dark, and system modes.
- Evidence uses broad screenshots/assertions across route clusters, theme modes, and desktop/mobile widths.
```

Apply this pattern by stating required states and evidence dimensions as observable behaviors, then mapping each state to representative fixed assigns or seeded flows for Phase 114.

**Evidence loop pattern**:

```typescript
const viewports = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

const themes = [
  { name: "light", colorScheme: "light", storedTheme: "light" },
  { name: "dark", colorScheme: "light", storedTheme: "dark" },
  { name: "system-dark", colorScheme: "dark", storedTheme: null },
];
```

Use this as the matrix evidence shape for Phase 114 and later, not as a Phase 113 implementation task.

---

### `113-ACCEPTANCE-GATES.md` (planning artifact, verification contract)

**Analog:** `.planning/milestones/v1.16-phases/112.1-close-gap-bui-05-bui-06-dynamic-fleetdesk-launcher-url-and-e/112.1-VERIFICATION.md`

**Command outcome pattern** (lines 5-13):

```markdown
| Command | Outcome | Evidence |
| --- | --- | --- |
| `...` | PASS | Exact evidence summary. |
```

Apply this pattern with Phase 113 source assertion commands and explicit DSM-01/DSM-03 coverage.

**Decision coverage pattern** (lines 17-32):

```markdown
| Decision | Verification |
| --- | --- |
| D-01 | Concrete artifact or command evidence. |
```

Use D-01 through D-20, plus DSM-01 and DSM-03, so execution cannot mark the phase complete without traceability.

**Guard chain pattern**:

```bash
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"
python3 "${RULESTEAD_REPO}/scripts/check_contrast.py"
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"
python3 "${RULESTEAD_REPO}/scripts/check_logo_assets.py"
```

Reference the current guard chain as a preserved responsibility, not a Phase 113 edit target.

---

### `.planning/REQUIREMENTS.md` (tracking doc, requirement status)

**Analog:** existing v1.17 rows

Use the current requirement row format and only mark `DSM-01` and `DSM-03` complete after the inventory, matrix contract, and acceptance gates artifacts exist and pass their source assertions.

---

### `.planning/ROADMAP.md` and `.planning/STATE.md` (tracking docs, phase progress)

**Analog:** current Phase 113 roadmap and state sections

Preserve the v1.17 sequential dependency map. Update Phase 113 plan count/progress and current position only after the Phase 113 acceptance gates document records coverage.

## Shared Patterns

### Source Truth
**Source:** `113-CONTEXT.md`, `rulestead_admin/lib/rulestead_admin/components/*.ex`, `rulestead_admin/lib/rulestead_admin/live/**/*.ex`
**Apply to:** All Phase 113 deliverables

Each claim should cite a source file or a follow-on phase. Do not invent components or states that are not grounded in the current mounted admin or locked context.

### Scope Boundary
**Source:** `113-CONTEXT.md` D-03 and deferred section
**Apply to:** All plans

Do not modify runtime code, CSS, tests, packages, schemas, release workflows, FleetDesk branding, Phase 8-only docs, or `rulestead_admin` publish posture in Phase 113 execution.

### Evidence Posture
**Source:** `brand-ui-evidence.spec.ts`, `scripts/ci/lint.sh`, `113-CONTEXT.md` D-18 through D-20
**Apply to:** UI matrix and acceptance-gate docs

Keep evidence to curated screenshots plus deterministic assertions. Preserve existing guard scripts. Avoid broad pixel baselines and external AI visual judging.

## No Analog Found

None. All planned docs have existing GSD planning, UI-spec, verification, and tracking-document analogs.

## Metadata

**Analog search scope:** `.planning/`, `rulestead_admin/lib/rulestead_admin`, `rulestead_admin/priv/static`, `examples/demo/frontend/tests`, `scripts/ci`
**Files scanned:** component modules, LiveView modules, route/navigation modules, guard scripts, Playwright evidence specs, Phase 107/112.1 planning artifacts
**Pattern extraction date:** 2026-06-13
