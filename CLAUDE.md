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
- `.planning/phases/01-repo-bootstrap/01-CONTEXT.md` for Phase 1 work
- `prompts/` anchor docs relevant to the current phase

## Working rules

- Treat `.planning/` as the active source of truth for roadmap and phase
  execution state.
- Treat `prompts/` as the pattern and policy reference set.
- Preserve the sibling-package layout. Do not collapse work into a single
  package shape for convenience.
- Do not create Phase 8-only docs early:
  `guides/api_stability.md`, `guides/cheatsheet.cheatmd`,
  `guides/flows/extending-rulestead.md`.
- `rulestead_admin` is intentionally a guarded stub until later phases. Do
  not introduce early publish flows that bypass that rule.

## Output expectations

- Prefer narrow, auditable changes.
- Keep root docs honest about the current phase.
- Use scripts-first CI surfaces where workflow logic gets non-trivial.
