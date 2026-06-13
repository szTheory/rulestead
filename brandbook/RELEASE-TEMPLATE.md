# Release Announcement Template

Use this for GitHub releases, changelog summaries, and maintainer announcements. Keep the tone
technical, transparent, and operator-aware.

## Headline

Rulestead `<version>`: `<operator-facing outcome>`

## Summary

`<One or two sentences. Say what changed, who it helps, and why it matters in production.>`

## What Changed

- `<Capability or fix>` - `<direct workflow impact>`
- `<Capability or fix>` - `<direct workflow impact>`
- `<Capability or fix>` - `<direct workflow impact>`

## Operator Impact

- `<What gets safer, clearer, easier to inspect, or easier to recover from>`
- `<Any behavior that changes for mounted admin users, release operators, or support teams>`

## Upgrade Notes

- `<Dependency or migration step, if any>`
- `<Config or host-app integration step, if any>`
- `<No action required, if true>`

## Compatibility

- Runtime package: `rulestead <version>`
- Admin companion: `rulestead_admin <version>`
- Elixir: `<supported range>`
- Phoenix / LiveView notes: `<if relevant>`

## Verification

- `<CI command or release gate>`
- `<Demo or adoption-lab proof, if relevant>`
- `<Hex visibility check, if relevant>`

## Links

- Changelog: `<link>`
- HexDocs: `<link>`
- Migration guide: `<link, if relevant>`

## Microcopy Rules

- Start with the operator consequence, not the implementation detail.
- State what changed and what did not change.
- Avoid hype, apology, and vague success language.
- Use "safe rollout", "ordered rules", "deterministic evaluation", "local evaluation",
  "multivariate values", and "lifecycle hygiene" when they are accurate.
