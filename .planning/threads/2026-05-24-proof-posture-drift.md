# Thread: 2026-05-24 Proof Posture Drift

## Status

- Open
- Updated: 2026-05-24

## Summary

The repo is stronger than the planning docs suggest in product breadth, but weaker than they suggest in proof coherence. This thread tracks the concrete drift that should be closed before new differentiated milestone work.

## Concrete Drift

### 1. Public release messaging drift

- `.planning/PROJECT.md` records `v1.0.0` GA shipped on 2026-05-21.
- `README.md`, `rulestead/README.md`, and `rulestead_admin/README.md` still say the first public Hex release is planned after `v0.6.0`.

### 2. Runtime schema / migration drift

- `rulestead/lib/rulestead/flag.ex` embeds `ownership` and `lifecycle`.
- failing runtime tests insert those fields through the Ecto schema.
- `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs` and `20260424210000_add_phase6_admin_lifecycle_fields.exs` do not create matching `flags` columns for those embeds.

### 3. Admin product-surface drift

- accessibility test expects `flag[expected_expiration]`, but the rendered lifecycle form currently exposes `flag[review_by]`.
- rollout permission test expects a propose/save path that the rendered viewer state no longer exposes.

### 4. OpenFeature bridge proof gap

- `open_feature_rulestead` is present as a package surface, but `mix test` currently stops on unavailable dependencies instead of giving an adopter-proof result.

## Why It Matters

- This is support-truth debt, not just internal cleanup.
- A serious adopter will trust a boring, coherent library more than a broader library with conflicting docs and red proof surfaces.
- Guarded rollout and reusable targeting both become harder to justify if the repo cannot currently prove its own release posture cleanly.

## Recommended Follow-On Work

- treat this as the first milestone wedge before new differentiated capability
- keep scope bounded to docs, install truth, migrations/schema parity, and verification honesty
- do not widen the work into product redesign or new operator features
