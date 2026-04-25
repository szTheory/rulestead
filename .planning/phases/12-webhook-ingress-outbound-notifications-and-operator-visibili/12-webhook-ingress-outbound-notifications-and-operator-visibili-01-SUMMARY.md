---
phase: 12
plan: 01
subsystem: webhook-ingress
tags: [webhooks, ingress, receipts, replay-protection, plugs]
dependency_graph:
  requires: ["Phase 11 mounted operator UI", "Phase 10 scheduled execution", "Phase 09 governance contracts"]
  provides: ["durable inbound webhook receipts", "canonical inbound webhook envelope", "HTTP-edge verification boundary"]
  affects: ["rulestead/lib/rulestead/webhooks/*", "rulestead/lib/rulestead/store/*", "rulestead/priv/repo/migrations/*"]
tech_stack:
  added: ["Ecto migration", "Ecto schema", "Plug", "ExUnit"]
  patterns: ["canonical envelope", "fail-closed ingress", "replay-claim persistence"]
key_files:
  created:
    - rulestead/priv/repo/migrations/20260424194710_create_rulestead_webhook_receipts_and_replay_claims.exs
    - rulestead/lib/rulestead/webhooks/inbound_receipt.ex
    - rulestead/lib/rulestead/webhooks/inbound_event.ex
    - rulestead/lib/rulestead/webhooks/replay_claim.ex
    - rulestead/lib/rulestead/webhooks/verifier.ex
    - rulestead/lib/rulestead/webhooks/ingress_plug.ex
    - rulestead/lib/rulestead/plug.ex
  modified:
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/test/rulestead/webhooks/inbound_contract_test.exs
    - rulestead/test/rulestead/store/command_webhook_test.exs
    - rulestead/test/rulestead/webhooks/inbound_http_test.exs
decisions:
  - Persist every inbound attempt in durable receipts instead of inferring operator history from downstream mutation logs.
  - Fail closed at the Plug edge with `401` on verification failure and keep verification separate from authorization.
metrics:
  duration: "~20m"
  completed_date: "2026-04-25"
---

# Phase 12-01: Durable Webhook Ingress Contract Summary

Durable inbound webhook receipts, replay-claim persistence, and a canonical verification boundary for later Phase 12 normalization work.

## What changed

- Added `webhook_receipts` and `webhook_replay_claims` persistence.
- Modeled `Rulestead.Webhooks.InboundReceipt`, `ReplayClaim`, and `InboundEvent`.
- Added `Rulestead.Webhooks.Verifier` plus a library-owned ingress Plug that fail-closes on bad signatures.
- Extended store command and store callback surfaces for inbound webhook reads/writes.
- Covered the boundary with focused contract and HTTP tests.

## Verification

Ran:

```bash
cd rulestead && mix test test/rulestead/webhooks/inbound_contract_test.exs test/rulestead/store/command_webhook_test.exs test/rulestead/webhooks/inbound_http_test.exs
```

Result: passed.

## Deviations from Plan

None.

## Self-Check

### Files

- FOUND: `.planning/phases/12-webhook-ingress-outbound-notifications-and-operator-visibili/12-webhook-ingress-outbound-notifications-and-operator-visibili-01-SUMMARY.md`

### Commits

- FOUND: `9816d0c`
- FOUND: `fabf380`

## Self-Check: PASSED
