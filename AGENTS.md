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

## GSD model routing (Cursor)

Project uses `model_profile: inherit` with Composer overrides for planner, plan-checker, verifier, and debugger (`composer-2.5-fast` in `.planning/config.json`). Executors and mappers use the Cursor session model.

- Before `/gsd-execute-phase`: select **Auto** in the Cursor model picker so bulk implementation subagents inherit Auto.
- Before `/gsd-discuss-phase` or `/gsd-plan-phase`: Composer in the UI is optional; planning agents use the Composer override regardless.

## Preferred behavior

- Make the smallest coherent change that satisfies the active plan.
- Avoid speculative features from future phases.
- Preserve reproducibility and CI readability.
