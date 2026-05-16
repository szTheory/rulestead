# Phase 13: Operational Carryover Closure and Milestone Verification - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs` | test | simulation | `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs` | exact |
| `scripts/ci/verify_phase13_operational.sh` | script | batch | `scripts/ci/verify_phase09_governance.sh` | exact |
| `scripts/ci/verify_published_release.sh` / `.github/workflows/verify-published-release.yml` | script | batch | `scripts/ci/verify_published_release.sh` | exact |
| `.planning/milestones/v0.1.0-ROADMAP.md` | docs | tracking | `.planning/milestones/v0.1.0-ROADMAP.md` | exact |

## Pattern Assignments

### `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs` (test, simulation)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs`

The focus is closing the "simulation helper verification gap" related to actor-aware seeding (OPS-01). The test helper pattern in `rulestead_admin` typically handles setting up state, putting the application environment, and ensuring environments/flags/rulesets are properly seeded with actor-aware commands.

**Actor-Aware Seeding Pattern** (lines 142-167):
```elixir
  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      # ... ruleset structure ...
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
             )
  end
```

**State Setup Pattern** (lines 20-27):
```elixir
  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    now = ~U[2026-04-23 16:00:00Z]

    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
```

---

### `scripts/ci/verify_phase13_operational.sh` (script, batch)

**Analog:** `scripts/ci/verify_phase09_governance.sh`

This script verifies the resolution of Phase 13 operational items, organizing verification by logging distinct steps and changing into the appropriate sub-packages to run `mix test`.

**Verification Script Pattern** (lines 1-13):
```bash
#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

log_step() {
  printf "\n[verify_phase09_governance] %s\n" "$1"
}

log_step "checking governance migration is discoverable by Ecto"
(
  cd "${RULESTEAD_REPO}/rulestead"
  migrations_output="$(MIX_ENV=test mix ecto.migrations)"
```

---

### `scripts/ci/verify_published_release.sh` (script, batch)

**Analog:** `scripts/ci/verify_published_release.sh`

For live `0.1.0` published-release evidence capture (OPS-02), this script fetches hex metadata and invokes workspace/publish/parity checks.

**Published Release Evidence Capture Pattern** (lines 66-74):
```bash
fetch_package_metadata "rulestead" "${core_metadata}"
fetch_package_metadata "rulestead_admin" "${admin_metadata}"
assert_release_visible "rulestead" "${RELEASE_VERSION}" "${core_metadata}"
assert_release_visible "rulestead_admin" "${RELEASE_VERSION}" "${admin_metadata}"

echo "verified Hex visibility for rulestead and rulestead_admin ${RELEASE_VERSION}"
run_mix verify.workspace_clean
run_mix verify.release_publish "${RELEASE_VERSION}"
run_mix verify.release_parity "${RELEASE_VERSION}"
```

---

### `.planning/milestones/v0.1.0-ROADMAP.md` (docs, tracking)

**Analog:** `.planning/milestones/v0.1.0-ROADMAP.md`

Past milestones are closed and audited in ROADMAP files, containing an overview, accomplishments list, phase completion checklists, and summary sections indicating deferred issues.

**Milestone Audit Closure Pattern** (lines 173-181):
```markdown
## Milestone Summary

**Decimal Phases:** None

**Key Decisions:**
- Keep the project as linked sibling packages from day one...

**Issues Resolved:**
- Closed the runtime hot-path, snapshot publication...
```

**Deferred Items Tracking Pattern** (lines 187-191):
```markdown
**Issues Deferred:**

- Phase 7 sibling-package verification gap: the simulation test helper still seeds rulesets without actor metadata...
- Live Hex publish evidence: both package APIs returned `404` during the final verification wave...
```

## Shared Patterns

### Command Execution in Verification Scripts
**Source:** `scripts/ci/verify_phase09_governance.sh`
**Apply to:** Any new verification scripts for Phase 13
```bash
(
  cd "${RULESTEAD_REPO}/rulestead_admin"
  mix test \
    test/rulestead_admin/router_test.exs \
    test/rulestead_admin/live/session_test.exs
)
```

## Metadata

**Analog search scope:** `rulestead_admin/test/**/*.exs`, `scripts/ci/*.sh`, `.github/workflows/*.yml`, `.planning/milestones/*.md`
**Files scanned:** 6 (read directly via absolute paths)
**Pattern extraction date:** 2024-05-24
