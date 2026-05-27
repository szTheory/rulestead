# Phase 59: Mounted Governance Workflows - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 59-mounted-governance-workflows
**Areas discussed:** Above-threshold routing, CR handoff, evidence surfaces, partial visibility (all four — user requested full research synthesis)

---

## Above-threshold routing on confirm

| Option | Description | Selected |
|--------|-------------|----------|
| Block Apply only, no CR CTA | Remediation dead-end | |
| Replace CTA with Submit change request on confirm | Governed confirm, same route | ✓ |
| Dedicated governance proposal route | Fourth step | |
| Hybrid assess on preview + B on confirm | Early expectation + enforced confirm | ✓ (preview callout) |
| CR only after failed Apply | Reactive error UX | |

**User's choice:** Governed confirm (Option B + preview callout), per research synthesis — no user override; one-shot recommendation accepted.

**Notes:** Aligns with ADM-01, preview→confirm→audit, Phase 58 envelope. Rejects GrowthBook-style extra revision route.

---

## Proposal → change-request handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Governed confirm + redirect to CR show | A + E | ✓ |
| Interstitial proposal route | Extra step | |
| Post-submit to queue index | Hunt for row | |
| Post-submit to audience show | Ambiguous outcome | |

**User's choice:** Governed confirm + CR show deep link with explicit flash.

---

## Blast-radius evidence surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Shared GovernanceComponents.blast_radius_panel | Both surfaces, variants | ✓ |
| Extend impact_preview only | Mixed concerns | |
| CR-only panel | Fails ADM-02 audience surfaces | |

**User's choice:** New panel; indeterminate blocks both apply and CR submit on UI (matches Phase 58).

---

## Partial visibility (ADM-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Full / Partial / Denied tiers via existing redaction | Reuse DependencyVisibility + Redaction | ✓ |
| Allow CR submit when partial (hidden refs) | Unleash-style delegate | Deferred |
| Counts-only | False confidence | Rejected as sole pattern |
| Block all actions when partial | Fail-closed with Phase 58 | ✓ |

**User's choice:** Tiered display; partial → indeterminate → no CR submit (no core change in 59). Approve requires full tier.

---

## Claude's Discretion

- Panel markup, collapsible breach UI, optional below-threshold callout.

## Deferred Ideas

- Propose-with-partial-visibility CR submit (core + ADM-03-ext).
