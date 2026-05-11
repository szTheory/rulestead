# Phase 11 Discussion Log

**Date:** 2026-04-24
**Mode:** advisor-heavy discuss
**Phase:** 11 - Mounted Admin Governance and Schedule UI

## User direction

- Discuss all identified gray areas.
- Pull research and recommendation work forward using subagents.
- Bias toward cohesive, one-shot recommendations instead of bouncing each branch back as a user decision.
- Ask only when a choice is truly impactful.

## Areas discussed

### 1. Governance IA and routes

**Recommended options considered**
- Dedicated top-level governance inbox plus per-flag links
- Flag-detail-first review with backlinks
- Combined audit/schedule ops screen

**Locked decision**
- Add a dedicated change-request inbox and a dedicated schedule surface inside the existing mount path.
- Keep flag detail as a calm read surface with summary cards and deep links.

### 2. Change-request review screen shape

**Recommended options considered**
- Diff-first primary
- Approval-state-first primary
- Execution-readiness-first primary

**Locked decision**
- Make the readable diff primary.
- Keep approval state and execution readiness above the fold as compact summary cards or a summary strip.

### 3. Approval action model

**Recommended options considered**
- One review screen with progressive disclosure and explicit post-approval execution actions
- Separate review route then separate execute route
- Collapsed approve-and-execute flow

**Locked decision**
- Use one dedicated review route.
- Keep approval and execution as separate explicit actions on that same route.
- Reveal `Execute now` and `Schedule` only after approval is complete.

### 4. Schedule surface default

**Recommended options considered**
- Dense filterable list default with optional calendar later
- List plus secondary calendar summary
- Calendar-first default

**Locked decision**
- Make `/schedule` a dense, filterable operator list by default.
- Treat calendar as deferred or strictly secondary/read-oriented if it appears at all in Phase 11.

### 5. Flag-detail cross-links

**Recommended options considered**
- Compact cards only
- Compact cards plus top preview rows
- Rich inline governance pane

**Locked decision**
- Add compact summary cards with the top 1-3 preview rows and explicit route-backed links.
- Do not embed rich inline approval or scheduling workflows on flag detail.

## Cross-cutting synthesis

- Preserve the mounted sibling-package seam and current `?env=` model.
- Keep all heavy governance actions route-backed and explicit.
- Preserve `preview -> confirm -> audit`.
- Maintain honest actor wording: requested/approved/scheduled/executed remain distinct.
- Keep copy calm, operational, and unambiguous.

## Deferred

- Mount-path redesign for shorter governance URLs
- Calendar-first scheduling UX
- Inline governance workbench on flag detail
- Combined audit/ops center

---

*Generated during `$gsd-discuss-phase 11` on 2026-04-24*
