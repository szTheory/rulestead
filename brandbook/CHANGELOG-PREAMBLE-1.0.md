# 1.0.0 CHANGELOG Preamble (staged)

Staged release-PR text — paste this **above** release-please's generated `1.0.0`
bullets during the major-cut release PR. It is intentionally **not** committed into
`rulestead/CHANGELOG.md` or `rulestead_admin/CHANGELOG.md`; those are release-please
managed and the bot regenerates them. This file is the human preamble only and lives
beside `RELEASE-TEMPLATE.md` until it is pasted.

---

## 1.0.0 — Promotion, not rewrite

`rulestead` and `rulestead_admin` graduate to `1.0.0` together (linked versions).
This is the **same battle-tested code** that has been running in production — now
honestly versioned. **Zero breaking changes.**

- **No public API changes.** The supported surface documented in
  `guides/api_stability.md` is unchanged — nothing moved, renamed, or changed
  behavior.
- **Upgrade is a dependency-pin bump only.** Point your `mix.exs` at the `1.x` line
  (`~> 1.0`) and run `mix deps.get`. No call-site audit, config change, or host-app
  integration work is required. See `guides/introduction/upgrading.md`.
- **Both sibling packages move together.** `rulestead` and `rulestead_admin` are
  linked versions and graduate in lockstep; `rulestead` publishes first, then
  `rulestead_admin`.

The `1.0.0` tag is a statement of confidence, not a migration event: the version
number is catching up to code that was already stable.
