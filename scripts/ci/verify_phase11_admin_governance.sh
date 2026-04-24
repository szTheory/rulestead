#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log_step() {
  printf "\n[verify_phase11_admin_governance] %s\n" "$1"
}

log_step "running governance facade contract coverage in rulestead"
(
  cd "$ROOT_DIR/rulestead"
  mix test test/rulestead/governance_facade_contract_test.exs
)

log_step "running phase 11 change-request, schedule, and accessibility suites in rulestead_admin"
(
  cd "$ROOT_DIR/rulestead_admin"
  mix test \
    test/rulestead_admin/live/change_request_live/index_test.exs \
    test/rulestead_admin/live/change_request_live/show_test.exs \
    test/rulestead_admin/live/change_request_live/accessibility_test.exs \
    test/rulestead_admin/live/schedule_live/index_test.exs \
    test/rulestead_admin/live/schedule_live/show_test.exs \
    test/rulestead_admin/live/schedule_live/accessibility_test.exs \
    test/rulestead_admin/live/flag_live/show_test.exs
)

log_step "running mounted phase 11 sibling-package proof"
(
  cd "$ROOT_DIR/rulestead_admin"
  mix test test/rulestead_admin/integration/admin_mount_phase11_test.exs
)

log_step "phase 11 governance verification complete"
