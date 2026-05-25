# Thread: 2026-05-25 Mounted Companion Proof Gap

## Status

- Open
- Updated: 2026-05-25

## Summary

The repo's current bounded OpenFeature companion proof passes, but the documented mounted companion proof bar still fails at boot. This is the highest-leverage remaining adopter-trust gap before new differentiated milestone work.

## Concrete Drift

### 1. Mounted proof bar failure

- The documented command `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` fails from the repo root.
- Failure occurs while starting `Rulestead.Application`.

### 2. Runtime boot error

- The failing boot path raises `UndefinedFunctionError` for `Rulestead.Redis.enabled?/0`.
- Repo-local inspection confirms `rulestead/lib/rulestead/redis.ex` exists, so the issue is not “feature absent” but “proof/runtime/package boundary not actually coherent.”

### 3. Warning-heavy support posture

- The mounted proof lane currently emits warnings around unavailable notifier, Redis, and diagnostics-related modules during compilation.
- Even if some warnings are harmless internally, they weaken the claim that the mounted companion support surface is calm and ready.

### 4. Candidate-milestone drift

- Planning still treats reusable targeting as a future milestone wedge, but repo-local source and docs show reusable audiences are already shipped.
- Planning still treats guarded rollout as the immediate next move, but the mounted proof gap is a more immediate adopter blocker.

## Why It Matters

- A broken named proof bar undermines the product contract more directly than the absence of another differentiating feature.
- The mounted companion is part of the serious-adopter story, not just an internal demo path.
- Guarded rollout will land more credibly after the mounted proof surface is actually runnable again.

## Recommended Follow-On Work

- make mounted companion proof reclosure the next milestone wedge
- keep scope bounded to boot/runtime coherence, proof-bar recovery, and support-truth docs
- do not widen the work into admin redesign, observability-product drift, or unrelated new operator features
