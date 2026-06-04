# Phase 92: IA / Home Refinement - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Decisions sourced from the user-approved plan (P6) + the running-admin reality (home is already a live triage screen from prior IA work). Autonomous, hands-off.

<domain>
## Phase Boundary

Refine the home/overview orientation surface and global navigation so "what needs me now / where do I go next" is obvious for the operator/support/SRE personas (uk.gov-style task-first clarity), and so both surfaces are fully legible and on-brand in BOTH themes. This is REFINEMENT of the existing IA (home_live already has "Needs you now" + "What's live & moving" + a task launcher; nav already uses task-rhythm groups Build&release / Explain&diagnose / Review&approve) — NOT a rebuild.

**In scope:**
- Verify + tighten the home/overview (`home_live/index.ex`) and global nav/rail/header (`navigation.ex`, `shell.ex`) for clarity and both-theme legibility: heading hierarchy, attention-card prominence, scannability, empty states, and that every surface uses the consolidated tokens (so it re-themes correctly).
- Apply any token/spacing/typography consolidation the design system now affords (e.g. consistent section headers, attention-card tone usage, primary-task affordances) — reuse Phase 87-91 tokens, no one-offs.
- Fix any IA/clarity gaps found when viewing the real rendered home + nav in both themes (e.g. low-contrast on dark, unclear affordance, hierarchy that doesn't lead the eye to "what needs me").
- Keep the established task-rhythm IA + the home triage structure; improve, don't replace.

**OUT OF SCOPE:** per-screen polish of the ~31 detail screens (Phase 93 — 92 is ONLY home/overview + global nav), motion (94), token-value changes (87/91 own; exception: a deliberate light-mode AA fix like the accent badge may be coordinated with 93), new features/screens, changing the nav grouping taxonomy (it's already good).
</domain>

<decisions>
## Implementation Decisions

### Approach
- Treat home + nav as the "front door": the landing surface must orient all three personas fast. Confirm the existing "Needs you now" (kill switches, pending change requests, failed/quarantined schedules, archive-ready) reads as the clear priority, the "What's live & moving" gives situational awareness, and the task launcher routes to JTBD. Tighten hierarchy/contrast where the real render shows weakness.
- All changes token-driven (Phase 87-91 system); both themes must pass the Phase 91 contrast gate concept (no new sub-AA pairs).
- Mobile-first responsive preserved.

### Verification (real screens)
- Verified against the ISOLATED demo instance built from this branch (separate ports; main :4000 untouched) — screenshot home + nav in BOTH themes; confirm legibility + clarity. The Phase 91 design-system contrast spec stays green.

### Claude's Discretion
- Specific hierarchy/spacing/affordance tweaks (guided by what the real both-theme render reveals).
- Whether any small shared component (e.g. attention card, section header) warrants a tokenized refinement vs leaving as-is.
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead_admin/lib/rulestead_admin/live/home_live/index.ex` — the live triage home (async "Needs you now", "What's live & moving", task launcher rendered from Navigation). Already substantial.
- `rulestead_admin/lib/rulestead_admin/navigation.ex` — single nav source (task-rhythm groups), drives rail + ⌘K + home launcher (can't drift).
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — header (incl. the new Phase-90 theme control), rail, breadcrumbs.
- `rulestead_admin/priv/static/css/rulestead_admin.css` — consolidated tokens (87-91); `.rs-attention__*`, `.rs-task-link`, `.rs-banner`, `.rs-summary-grid`, etc.
- Phase 91 design-system contrast gate + fixture; the isolated demo for real-screen screenshots.

### Established Patterns
- Task-rhythm nav; Navigation as single source; StatusTone for tones; both-theme token cascade.

### Integration Points
- home_live/index.ex (orientation content + hierarchy), navigation.ex (if any grouping copy/summary tweaks), shell.ex (header/rail), rulestead_admin.css (home/nav-specific rules — all token-driven).
</code_context>

<specifics>
## Specific Ideas
- uk.gov-style: lead with the user's task, plain language, clear next steps, strong hierarchy, no clutter. The home should answer "what needs me / where do I go" within one glance.
- Verify on the real isolated demo: home + each nav group in both themes; confirm the Phase 90 theme control is reachable + legible in the header in both themes; confirm attention cards' tones (critical/warning) are legible on dark.
</specifics>

<deferred>
## Deferred Ideas
- The ~31 detail screens → Phase 93. Motion → 94. Accent-badge light AA fix → coordinate with 93 (A11Y-01).
</deferred>
