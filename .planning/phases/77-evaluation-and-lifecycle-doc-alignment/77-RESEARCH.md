# Phase 77 Research: Evaluation And Lifecycle Doc Alignment

**Researched:** 2026-05-28
**Scope:** Docs-only — no `lib/` changes

## Findings

### Runtime public API (from `rulestead/lib/rulestead/runtime.ex`)

| Function | Arity | Args |
|----------|-------|------|
| `Rulestead.Runtime.evaluate/3` | 3 | `environment_key, flag_key, context` |
| `Rulestead.Runtime.enabled?/3` | 3 | same |
| `Rulestead.Runtime.get_value/4` | 4 | `environment_key, flag_key, context, default` |
| `Rulestead.Runtime.get_variant/3` | 3 | same as enabled |
| `Rulestead.Runtime.explain/3` | 3 | same |

All accept `context` as `%Rulestead.Context{}` or map/keyword normalizable via `Context.normalize/1`.

### evaluation.md gap (DOC-01)

| Section | Current | Phase 77 fix |
|---------|---------|--------------|
| Core Calls | Lists only `Rulestead.*` payload-first | Keep as-is (canonical) |
| Pure vs Runtime | 12 lines, no Runtime function names | Add Runtime subsection + examples |
| Examples | Only payload-first | Add `Runtime.enabled?/3` fence |

### Intro lifecycle gap (DOC-02)

| Doc | Phase 76 state | Phase 77 fix |
|-----|----------------|--------------|
| phoenix-integration-spine.md | §6 lifecycle complete | No edit unless link fix |
| getting-started.md | Links spine; no standalone callout | Add callout block (D-05) |
| installation.md | Spine link mentions lifecycle | Add explicit callout (D-06) |

### README gap (DOC-03)

Current `## Runtime entrypoints` lists only root `Rulestead.enabled?/2` etc. Footguns and spine teach Runtime-first for Phoenix. README should mirror footguns ordering.

### Verification (manual — Phase 78 adds contract tests)

```bash
grep -q 'Rulestead.Runtime.enabled?' guides/flows/evaluation.md
grep -qE 'owner_ref|expected_expiration' guides/introduction/getting-started.md guides/introduction/installation.md
grep -q 'Rulestead.Runtime' rulestead/README.md
```

## Risks

| Risk | Mitigation |
|------|------------|
| Implying `Rulestead.enabled?(conn, key)` works | Footguns + examples use payload OR Runtime triple |
| Duplicating spine | evaluation.md links spine; no full Plug repeat |
| README churn breaks release-contract | Phase 78 owns guards; grep-only proof here |

## Plan recommendation

Single plan **77-01**: evaluation.md + intro callouts + README in one wave.

## Validation Architecture

| Dimension | Strategy |
|-----------|----------|
| Automated | `grep`/`test -f` on edited paths after each task |
| Manual | Read evaluation.md Runtime section for payload-first primacy |
| Phase proof | Grep trio above; no `mix test` required (docs-only) |
| Regression owner | Phase 78 `release_contract_test` |
