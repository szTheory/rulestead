# Phase 76 Research: Phoenix Integration Spine Doc

**Researched:** 2026-05-28
**Scope:** Docs-only — no `lib/` changes

## Findings

### What install actually wires

| Surface | Injected by `mix rulestead.install`? | Source |
|---------|--------------------------------------|--------|
| `config/rulestead.exs` | Yes | `Rulestead.Install.ConfigWriter` |
| `plug Rulestead.Plug` in endpoint | Yes | `Rulestead.Install` after telemetry plug |
| Admin router mount | Yes (if admin enabled) | `install.ex` |
| Oban middleware | Conditional | When `config :app, Oban` exists |
| Host `application.ex` children | **No** | OTP `:rulestead` app starts `Rulestead.Application` |

### Supervision story (accurate copy)

`:rulestead` application children (from `rulestead/lib/rulestead/application.ex`):

- Optional Redis children
- `Rulestead.Admin.StaleTracker`
- `Rulestead.Analytics.Batcher`
- `{Rulestead.Runtime.Supervisor, runtime_options}`

### Spine doc gaps vs current intro

| Gap (INV-INTRO-01) | Current state | Phase 76 fix |
|--------------------|---------------|--------------|
| Supervision path | footguns mentions "supervision docs" vaguely | Spine §2 OTP app |
| Config + Plug sequence | context-propagation exists but not first-hour ordered | Spine §3–4 |
| Lifecycle at create | flag-lifecycle.md deep; quickstart silent | Spine § lifecycle subsection |
| Runtime first eval | getting-started has Runtime block but not ordered path | Spine §5 primary |

### Lifecycle field names (for examples)

Use store-aligned names from `rulestead/lib/rulestead/store/command.ex`:

- `owner_ref` (or `owner` in admin forms — spine should show `owner_ref` as canonical)
- `expected_expiration` (Date)

### getting-started trim recommendation

Keep payload-first `Rulestead.evaluate/3` block in getting-started (README parity / VER-03 carry-forward) but add spine link **above** §3 and shorten Runtime subsection to 2 lines + spine link (avoids duplicate maintenance).

### Verification (Phase 78, not 76)

Manual proof for this phase:

```bash
grep -l phoenix-integration-spine guides/introduction/*.md README.md
# spine exists; getting-started + installation link to it
```

## Risks

| Risk | Mitigation |
|------|------------|
| Invented config keys | Copy from `install_golden/tree/config/rulestead.exs` only |
| Claiming application.ex injection | Explicit D-02 / RESEARCH table |
| `traits:` in examples | Use `attributes:` only (CTX-02) |

## Plan recommendation

Single plan **76-01**: author spine + cross-links in one PR-sized change.
