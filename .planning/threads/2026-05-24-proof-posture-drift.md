# Thread: 2026-05-24 Proof Posture Drift

## Status

- **Closed (superseded)** — 2026-05-28
- Remaining doc-contract items tracked as INV-API-01 / INV-MAINT-01 in v1.10.1

## Summary

Original thread tracked support-truth drift before v1.3–v1.10 closure milestones. Most concrete blockers were addressed across:

- **v1.3.0** — adopter truth & proof closure
- **v1.4.0** — mounted companion proof reclosure
- **v1.10.0** — post-GA band truth (`mix verify.phase72`, product-boundary, release-contract guards)

## Closure evidence (2026-05-28)

| Original drift item | Current posture |
|---------------------|-----------------|
| Mounted proof bar | `mounted_admin_contract` CI scope green (37 tests) |
| OpenFeature companion | Bounded scope documented; v1.3+ proof path |
| Release messaging | README/installation document v1.0.0 GA vs Hex `0.1.x` |
| Schema/migration / admin test drift | Addressed in v1.3 parity work; re-open only if CI regresses |

## Remaining work (not this thread)

- **INV-API-01:** `api_stability.md` vs `release_contract_test` — v1.10.1
- **INV-MAINT-01:** MAINTAINING Phase 8 deferral wording — v1.10.1
- **INV-INTRO-01:** first-hour Phoenix integration docs — v1.11

See [`.planning/threads/2026-05-28-path-to-done-milestones.md`](2026-05-28-path-to-done-milestones.md).
