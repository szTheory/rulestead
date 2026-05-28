# Phase 78 Research: Doc Contract Guards And Milestone Closure

**Researched:** 2026-05-28
**Scope:** Contract tests + verify.phase76 + milestone closure — no new docs content

## Findings

### Shipped artifacts to guard (Phases 76–77)

| Artifact | Key strings for contract |
|----------|-------------------------|
| `phoenix-integration-spine.md` | `Rulestead.Runtime`, `Rulestead.Plug`, `owner_ref`, `expected_expiration`, `flag-lifecycle` |
| `getting-started.md` | `phoenix-integration-spine`, `owner_ref`, `expected_expiration` |
| `installation.md` | `phoenix-integration-spine`, `owner_ref`, `expected_expiration` |
| `README.md` | `phoenix-integration-spine` |

### verify.phase76 union (VER-02)

**Source:** `verify.phase73.ex` — 32 core paths + 14 admin paths.

**v1.11 delta:** One net-new path:

- `test/rulestead/intro_integration_spine_contract_test.exs`

**Pattern:** Copy `@phase73_core_tests` verbatim; append intro test; never delegate to `verify.phase73`.

### release_contract_test.exs

Post-GA band closure test (L634–659) asserts `mix verify.phase73`. Phase 78-02 bumps to `phase76` alongside MAINTAINING/README.

Optional v1.11 block can assert integration-spine narrative (`mix verify.phase76`, `phoenix-integration-spine`) without duplicating every intro string (dedicated test owns file guards).

### INV-INTRO-01 closure

**Open since:** v1.10.1 audit ("Optional v1.11 integration spine remains open").

**Close when:** intro contract test green + `mix verify.phase76` green + STATE + v1.11 audit.

## Risks

| Risk | Mitigation |
|------|------------|
| phase76 delegates to phase73 (double run) | Code review: only `Mix.Task.run("test", paths)` |
| Contract too brittle on prose | Assert stable tokens (API names, field names, paths) not full paragraphs |
| Historical docs still say phase73 as current | 78-02 matrix bump; keep phase73 in v1.10.1 archive sections only |

## Plan recommendation

Three plans **78-01 / 78-02 / 78-03** mirroring Phase 75 waves.

## Validation Architecture

| Dimension | Strategy |
|-----------|----------|
| Automated | `mix test intro_integration_spine_contract_test.exs`; `mix verify.phase76` |
| Manual | Skim v1.11 audit trust spine |
| Phase proof | `mix verify.adopter` delegates to phase76 |
| Regression owner | intro contract test in phase76 union |

## RESEARCH COMPLETE
