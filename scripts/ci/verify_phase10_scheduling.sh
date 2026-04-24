#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

log_step() {
  printf "\n[verify_phase10_scheduling] %s\n" "$1"
}

log_step "checking scheduled execution migration is discoverable in rulestead"
(
  cd "${RULESTEAD_REPO}/rulestead"
  ls priv/repo/migrations | grep -q "create_rulestead_scheduled_executions_and_attempts"
)

log_step "running scheduled execution command and adapter contract suites in rulestead"
(
  cd "${RULESTEAD_REPO}/rulestead"
  mix test \
    test/rulestead/store/command_scheduled_execution_test.exs \
    test/rulestead/store/scheduled_execution_adapter_contract_test.exs
)

log_step "running scheduled execution facade, conflict, and audit suites in rulestead"
(
  cd "${RULESTEAD_REPO}/rulestead"
  mix test \
    test/rulestead/scheduled_execution_facade_contract_test.exs \
    test/rulestead/scheduled_execution_conflict_test.exs \
    test/rulestead/scheduled_execution_audit_contract_test.exs
)

log_step "running scheduled execution oban seam and threat model suites in rulestead"
(
  cd "${RULESTEAD_REPO}/rulestead"
  mix test \
    test/rulestead/oban_scheduled_execution_test.exs \
    test/rulestead/scheduled_execution_threat_model_test.exs
)

log_step "Phase 10 scheduling verification passed"
