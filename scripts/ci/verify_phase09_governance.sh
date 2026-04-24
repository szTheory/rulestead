#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

log_step() {
  printf "\n[verify_phase09_governance] %s\n" "$1"
}

log_step "running Phase 09 governance safety contract suites in rulestead"
(
  cd "${RULESTEAD_REPO}/rulestead"
  mix test \
    test/rulestead/governance/change_request_contract_test.exs \
    test/rulestead/store/command_governance_test.exs \
    test/rulestead/audit_event_governance_test.exs \
    test/rulestead/admin_governance_policy_test.exs \
    test/rulestead/governance_facade_contract_test.exs \
    test/rulestead/store/governance_adapter_contract_test.exs \
    test/rulestead/governance_safety_contract_test.exs \
    test/rulestead/governance_threat_model_test.exs
)

log_step "running mounted admin smoke slice in rulestead_admin (router + session only)"
log_step "Phase 07 simulate_test.exs remains an explicit tracked gap and is not claimed by this verifier"
(
  cd "${RULESTEAD_REPO}/rulestead_admin"
  mix test \
    test/rulestead_admin/router_test.exs \
    test/rulestead_admin/live/session_test.exs
)

log_step "Phase 09 governance verification passed"
