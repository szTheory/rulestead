# CLAUDE.md

## Repo intent

Rulestead is an Elixir-native feature flag, experimentation, and remote
config system with a sibling-package layout:

- `rulestead/` for the core runtime package
- `rulestead_admin/` for the optional admin UI package

## Read first

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `guides/introduction/product-boundary.md` for in-scope / deferred surfaces
- `prompts/` anchor docs relevant to the current phase

## Working rules

- Treat `.planning/` as the active source of truth for roadmap and phase
  execution state.
- Treat `prompts/` as the pattern and policy reference set.
- Preserve the sibling-package layout. Do not collapse work into a single
  package shape for convenience.
- Post-GA band (v1.1–v1.9) is feature-complete; v1.10 closes support truth only.
- v2 work (ADM-06, ROL-08, GOV-02-ext) requires an explicit new milestone.
- Do not create Phase 8-only docs early:
  `guides/cheatsheet.cheatmd`, `guides/flows/extending-rulestead.md`.
- `rulestead_admin` is a mounted companion — not a standalone control plane.

## Output expectations

- Prefer narrow, auditable changes.
- Keep root docs honest about the current phase.
- Use scripts-first CI surfaces where workflow logic gets non-trivial.
