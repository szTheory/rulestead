# Phase 57: Blast-Radius Threshold Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 57-blast-radius-threshold-contract
**Mode:** assumptions + multi-agent research synthesis
**Areas analyzed:** Evaluation mechanism, protected-env gate, scoring model, fail-closed inputs, phase boundary, config posture

---

## Research Sources

| Source | Focus |
|--------|-------|
| Codebase analyzer | Fake/Ecto apply pipeline, ImpactPreview, DependencyValidator patterns |
| Industry patterns agent | LaunchDarkly, Unleash, Flagsmith, Split, Optimizely, Terraform, GitHub |
| Elixir patterns agent | Pure modules, Governance vs Targeting namespaces, error shapes |
| Prompts / planning docs | GOV requirements, engineering DNA, admin UX, security fail-closed |

---

## Assumptions Presented → Locked Decisions

### Pure threshold module (Fake + Ecto)
| Assumption | Confidence | Selected |
|------------|------------|----------|
| `Rulestead.Governance.BlastRadiusThreshold` pure module, shared by Fake/Ecto | Confident | **D-01** |

**User correction:** None — research confirmed Ecto.Changeset / DependencyValidator precedent over GenServer.

---

### Protected-environment gate
| Assumption | Confidence | Selected |
|------------|------------|----------|
| Use `Compare.protected_target?/1`, not caller boolean alone | Likely | **D-02** |

**Industry:** Unleash env-scoped CR; LD strictest-env-wins. **Footgun avoided:** admin never setting `protected_shared_targeting?`.

---

### Scoring model
| Assumption | Confidence | Selected |
|------------|------------|----------|
| Reference count primary; rollout/lifecycle hints only; defaults: update ≤2 refs, archive with refs → above | Unclear → **resolved** | **D-03** |

**Alternatives considered:**
- Weighted rollout score → rejected (false blocks on `available?: false`, violates GOV-02 simplicity)
- Reference-only with no archive rule → rejected (archive of shared audience is high-impact regardless of count)
- Observability counts → out of scope

**Default thresholds:** `max_reference_count: 2` for `update` in protected env; `archive` + `reference_count > 0` → above.

---

### Fail-closed inputs
| Assumption | Confidence | Selected |
|------------|------------|----------|
| `:indeterminate` blocks apply; never assume zero blast radius | Confident | **D-04** |

**Industry:** Terraform deny on missing plan; Unleash blocks direct edit when CR on. **Footgun:** Flagsmith post-approval drift (addressed in Phase 58 execute re-check).

---

### Phase 57 vs 58 boundary
| Assumption | Confidence | Selected |
|------------|------------|----------|
| No `:apply_audience_mutation` in `governed_actions` until Phase 58 | Confident | **D-07** |

---

### Configuration
| Assumption | Confidence | Selected |
|------------|------------|----------|
| Module defaults + opts; defer NimbleOptions config | Likely | **D-08** |

---

## Corrections Made

No user corrections — recommendations synthesized from research per "one-shot coherent set" request.

---

## External Research Highlights

### Adopt
- Preview fingerprint binding (Terraform speculative plan / Optimizely lock-while-pending)
- Structured breach reasons with observed vs limit (Spacelift/Terraform policy messages)
- Below-threshold direct apply in protected env (GOV-03 — Unleash still allows small changes conceptually via permissions; Rulestead encodes via numeric contract)
- Fail-closed on missing preview/dependency data

### Avoid
- Observability-backed auto-approve thresholds
- Parallel governance workflow outside change requests
- Opaque `requires_confirmation` without breach evidence
- Post-approval mutation without fingerprint re-check (Phase 58)
- New error types without api_stability discipline

---
