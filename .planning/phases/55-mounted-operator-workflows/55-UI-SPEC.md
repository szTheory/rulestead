---
phase: 55
slug: mounted-operator-workflows
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-27
reviewed_at: 2026-05-27
---

# Phase 55 — UI Design Contract

> Visual and interaction contract for mounted operator workflows (audiences, explain traces, compare dependency findings). Generated for `rulestead_admin` LiveView surfaces. Host apps inject CSS that maps `rs-*` classes and `data-tone` attributes to these tokens.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Phoenix LiveView; not React/shadcn) |
| Preset | not applicable |
| Component library | Phoenix.Component + existing `RulesteadAdmin.Components.*` (`Shell`, `FlagComponents`, `OperatorComponents`, `AudienceComponents`, `AudienceTraceComponents`) |
| Icon library | none in-package (text + semantic badges only; host may add icons via layout) |
| Font | Inter (body/labels), Sora (page titles via host), IBM Plex Mono (`<code>`, fingerprints, keys) |

**Stack alignment:** Matches `rulestead_admin` HEEx components and `data-tone` semantics already used in Phases 46–54. No new CSS framework in this phase.

---

## Spacing Scale

Declared values (multiples of 4; map to host CSS for `rs-*` gaps/padding):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline code padding, badge internal gap |
| sm | 8px | Table cell padding, chip gaps |
| md | 16px | Default card padding (`rs-card`), form field spacing |
| lg | 24px | Section breaks between cards on a page |
| xl | 32px | Shell header padding, summary grid gaps |
| 2xl | 48px | Page-level top margin below shell header |
| 3xl | 64px | Reserved; not used in Phase 55 |

Exceptions:

| Value | Usage | Justification |
|-------|-------|---------------|
| 44px min | Primary submit buttons on confirm routes | Touch/keyboard target (WCAG 2.5.5); outer hit area only |

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 400 | 1.4 |
| Heading | 20px | 600 | 1.2 |
| Display | 28px | 600 | 1.2 |

**Usage mapping**

| Element | Role |
|---------|------|
| `rs-shell__title` | Display |
| `rs-shell__kicker`, `rs-shell__summary`, card `<h2>` | Label / Heading |
| Card body, tables, forms | Body |
| `<code>`, fingerprints, env/tenant keys | IBM Plex Mono 14px (inherits Label size) |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#0f1419` | Page background, `rs-shell` surface |
| Secondary (30%) | `#1a2332` | `rs-card`, tables, sidebar policy panel |
| Accent (10%) | `#4a7fd4` | Controlled blue — see reserved list |
| Destructive | `#c45c3e` | Archive confirm, fail-closed delete preview, `data-tone="critical"` banners |

**Accent reserved for (only these):**

- Primary route action on confirm pages: `Apply update`, `Apply archive` (submit buttons)
- Active environment chip in `rs-shell__env-link[data-current="true"]`
- Permalink “Copy explain link” / “Run explain” primary control on explain page
- Linked audience key in used-by table when visible (not redacted rows)

**Semantic tones via `data-tone` (no extra palette):**

| Tone | When |
|------|------|
| `neutral` | Default cards, policy state |
| `info` | Preview basis, fingerprint metadata |
| `warning` | Drift/stale preview callouts, hidden reference counts |
| `critical` | Policy denied, stale compare, fail-closed delete |

**60/30/10 rule:** Shell + page chrome = dominant; cards/tables = secondary; accent never fills card backgrounds or table rows.

---

## Visual Hierarchy

Per-screen focal point (first scan target):

| Screen | Focal point | Secondary |
|--------|-------------|-----------|
| `/audiences` | Audience key column (monospace links) | Status + reference summary on detail |
| `/audiences/:key` | Used-by table (`AudienceComponents.used_by_table`) | Impact preview card + lifecycle stats |
| `/audiences/:key/edit/preview` | Impact preview fingerprint + affected references | Link to confirm |
| `/audiences/:key/edit/confirm` | Reason textarea + `Apply update` | Fingerprint + scope chips |
| `/audiences/:key/archive/preview` | Archive consequences summary | Confirm link |
| `/audiences/:key/archive/confirm` | `Apply archive` + reason | Preview evidence |
| `/audiences/:key/delete/preview` | Fail-closed explanation (no delete CTA) | Back link |
| `/:key/explain` | Evaluation outcome + audience trace steps | Permalink field group |
| `/:key/rules` | Active rule card being edited | Audience library sidebar |
| `/:key/simulate` | Variant distribution / trace output | Audience trace section |
| `/compare`, `/compare/:key` | Compare findings / audience dependency list | Scoped env+tenant labels |

**Accessibility:** Icon-only actions are out of scope for Phase 55; every control has visible text. Tables use `<th>` scope; alerts use `role="alert"` / `role="status"`.

---

## Copywriting Contract

### Global rules

- Voice: calm, infrastructure-grade, no hype. State problem + next step.
- Never put raw traits, email, IP, or PII in URLs, labels, or empty states.
- Buttons use verb + noun. Avoid “Submit”, “OK”, “Save”, “Cancel” alone.

### Audience library (`/audiences`)

| Element | Copy |
|---------|------|
| Page kicker | `Reusable targeting` |
| Page summary | `Shared audience definitions referenced across flags. Open a row for used-by detail and governed mutations.` |
| Empty state heading | `No audiences in this scope` |
| Empty state body | `Create audiences through your authoring path or switch environment/tenant if you expected definitions here.` |
| Primary CTA (row) | `Open audience` (link text on key) |

### Audience detail (`/audiences/:key`)

| Element | Copy |
|---------|------|
| Page kicker | `Audience detail` |
| Used-by denied | `Dependency list unavailable — you do not have permission to view audience dependencies in this scope.` |
| Hidden references | `At least {N} references are hidden by your permissions.` |
| Redacted row | `Hidden reference` (optional suffix `(policy denied)`) |
| Empty used-by | `No authored references in this environment and tenant scope.` |
| Preview update link | `Preview update` |
| Preview archive link | `Preview archive` |
| Preview delete link | `Preview delete attempt` |

### Audience edit preview / confirm

| Element | Copy |
|---------|------|
| Edit preview kicker | `Audience preview` |
| Edit preview summary | `Review impact evidence before confirming an audience update.` |
| Edit confirm kicker | `Audience confirm` |
| Edit confirm summary | `Apply an audience update only after reviewing preview evidence and entering a reason.` |
| Primary CTA | `Apply update` |
| Reason label | `Reason (required)` |
| Missing preview | `Run impact preview before confirming.` |
| Missing reason | `Reason is required.` |
| Drift banner title | `Preview refreshed` |
| Drift banner body | `Authored state changed since preview — review the latest impact evidence.` |
| Back link | `Back to preview` |

### Audience archive preview / confirm

| Element | Copy |
|---------|------|
| Archive preview kicker | `Archive preview` |
| Archive confirm kicker | `Archive confirm` |
| Archive confirm summary | `Archive only after preview evidence and an operator reason are recorded.` |
| Primary CTA | `Apply archive` |
| Destructive confirmation | Operator must type reason (min 1 non-whitespace char); no typed key phrase in v1.6.0 |

### Audience delete preview (fail-closed)

| Element | Copy |
|---------|------|
| Page kicker | `Delete preview` |
| Page summary | `Delete is not supported. This preview shows the fail-closed outcome operators would see.` |
| Body | `Audience delete is not available in mounted admin. Use archive when you need to retire an audience.` |
| Primary CTA | none (only `Back to audience`) |

### Flag explain (`/:key/explain`)

| Element | Copy |
|---------|------|
| Page kicker | `Decision explainer` |
| Page summary | `Support-safe permalink for why a flag evaluated the way it did, including reusable audience steps.` |
| Primary CTA | `Run explain` |
| Permalink helper | `Share this URL with support — it includes flag, environment, tenant, and targeting key only.` |
| Empty trace | `No audience steps — rules on this flag do not reference reusable audiences.` |
| Audience matched | `matched` |
| Audience missed | `missed` |
| Missing audience | `missing from snapshot` |
| Archived audience | `archived` |

**Permalink query params (allowed):** `env`, `tenant`, `targeting_key`, `session_id`, `request_id` — never traits.

### Rules workspace audience affordances

| Element | Copy |
|---------|------|
| Audience library title | `Audience library` |
| Missing reference on rule | `Audience not found in snapshot — pick another audience or remove the reference before publish.` |
| Link to audience | `View audience {key}` |

### Simulate audience trace

| Element | Copy |
|---------|------|
| Section title | `Audience targeting` |
| No audience on rule | `no reusable audience on this rule` |

### Environment compare dependency findings

| Element | Copy |
|---------|------|
| Section title | `Audience dependencies for this flag` |
| Empty findings | `No audience dependency findings for this flag in the current compare.` |
| Stale compare banner title | `Staleness conflict` |
| Stale compare banner body | `This preview is stale. Re-run compare before any later governed apply handoff.` |
| Blocker row pattern | `{Severity} {code} — {message} · audience {link}` |

**Explicitly no copy for:** Apply/Publish on compare (preview-only per D-16).

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party | none | not applicable |

Phase 55 does not introduce shadcn or third-party UI registries. Presentation stays in HEEx + host CSS.

---

## Component Inventory (Phase 55)

Reuse; do not fork styling:

| Component | Phase 55 use |
|-----------|----------------|
| `Shell.page` | All LiveViews |
| `OperatorComponents.policy_state` | Audience index, explain, compare |
| `OperatorComponents.banner` | Drift, stale compare |
| `OperatorComponents.status_list` | Compare findings |
| `OperatorComponents.trace_panel` | Compare token metadata |
| `FlagComponents.section_card` | Audience list wrapper, confirm forms |
| `FlagComponents.callout` | Drift on edit/archive preview |
| `AudienceComponents.used_by_table` | Audience detail |
| `AudienceComponents.impact_preview` | Edit/archive preview |
| `AudienceTraceComponents.audience_trace_steps` | Explain, simulate, rules |

New factoring (`AudienceComponents` extensions) must keep `rs-card` / `rs-banner` classes and table semantics above.

---

## Interaction Contracts

### Preview → confirm → audit (audiences)

1. **Preview route** loads `Rulestead.preview_audience_impact/3`; displays fingerprint, scope, affected references.
2. **Confirm route** requires `preview_fingerprint` + `preview_schema_version` query params from core preview (D-06).
3. **Stale/missing preview** redirects to preview with `?drifted=true` and drift copy (D-07).
4. **Apply** calls `Rulestead.apply_audience_mutation/1` with reason; success flash: `Audience update applied.` / `Audience archived.`

### Policy-aware dependency display (D-08–D-10)

- Rows never show redacted flag keys; use `Hidden reference` placeholder.
- Every visible row includes `environment_key` and `tenant_key` columns.
- Summary line uses `Shared.dependency_summary/1` patterns.

### Explain permalinks (D-11)

- `push_patch` updates URL on run; no traits in query string.
- Trace panel lists rule key + audience key + status word only.

### Compare (D-14–D-16)

- Render `compare.dependency_findings` with links to `/audiences/:key` and flag routes.
- No inline Apply/Publish buttons on compare pages.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-27
