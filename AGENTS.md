# AGENTS.md

## Project frame

Rulestead is being built as a sibling-package monorepo:

- `rulestead/`
- `rulestead_admin/`

## Ground truth

Agents should consult:

- `.planning/` for roadmap, state, requirements, and phase-specific context
- `prompts/` for anchor docs and inherited engineering DNA

## Execution constraints

- Respect the current phase boundary from `.planning/ROADMAP.md`.
- Keep Phase 8-only docs absent until the roadmap says they ship.
- Do not publish or prepare to publish the `rulestead_admin` stub.
- Keep edits aligned with the linked-version, two-package release design.

## Preferred behavior

- Make the smallest coherent change that satisfies the active plan.
- Avoid speculative features from future phases.
- Preserve reproducibility and CI readability.
