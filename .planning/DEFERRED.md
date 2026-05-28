# Deferred Work (v2 backlog)

Items intentionally **not** in the v1.x post-GA band. Reopen only when trigger conditions are met.

| ID | Capability | Trigger to prioritize | Guardrails |
|----|------------|----------------------|------------|
| **ADM-06** | Draft-only targeting presets | Adopter commits to high flag/audience volume; repeated authoring duplication pain | Draft-only; no live inheritance or propagation |
| **ROL-08** | Guardrail baseline comparison | Teams run guarded rollouts in prod and need “healthy vs what baseline?” beyond pass/fail | Host-supplied baselines; fail-closed; no stats engine |
| **GOV-02-ext** | Host-configurable blast-radius threshold profiles | Multi-tenant SaaS needs per-env/tenant thresholds beyond v1.7 defaults | Reference-count only; reuse change-request envelope |

**Default v2 order when multiple triggers fire:** GOV-02-ext → ROL-08 → ADM-06 (safety → rollout depth → ergonomics).

**Band status:** v1.10.0 declares the v1.1–v1.9 post-GA feature band **complete**. v1.10.x is patches and support truth only unless a v2 milestone is explicitly opened.
