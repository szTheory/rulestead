#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

log_step() {
  printf "\n[verify_phase13_operational] %s\n" "$1"
}

log_step "checking governance migration is discoverable by Ecto"
(
  cd "${RULESTEAD_REPO}/rulestead"
  migrations_output="$(MIX_ENV=test mix ecto.migrations)"
  printf "%s\n" "$migrations_output"
  printf "%s\n" "$migrations_output" | grep -q "20260424000100"
)

log_step "running Phase 13 operational verification suites in rulestead_admin"
(
  cd "${RULESTEAD_REPO}/rulestead_admin"
  mix test \
    test/rulestead_admin/live/flag_live/show_test.exs \
    test/rulestead_admin/live/flag_live/simulate_test.exs \
    test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs \
    test/rulestead_admin/live/governance_route_contract_test.exs
)

log_step "Phase 13 operational verification passed"
