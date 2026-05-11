#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log_step() {
  printf "\n[verify_phase12_webhooks] %s\n" "$1"
}

log_step "running inbound and outbound webhook contract coverage in rulestead"
(
  cd "$ROOT_DIR/rulestead"
  mix test \
    test/rulestead/webhooks/inbound_contract_test.exs \
    test/rulestead/webhooks/inbound_http_test.exs \
    test/rulestead/webhooks/inbound_governance_test.exs \
    test/rulestead/webhooks/inbound_threat_model_test.exs \
    test/rulestead/webhooks/outbound_contract_test.exs \
    test/rulestead/webhooks/outbound_delivery_test.exs \
    test/rulestead/webhooks/outbound_threat_model_test.exs
)

log_step "running phase 12 webhook live view and accessibility suites in rulestead_admin"
(
  cd "$ROOT_DIR/rulestead_admin"
  mix test \
    test/rulestead_admin/live/webhook_live/index_test.exs \
    test/rulestead_admin/live/webhook_live/show_test.exs \
    test/rulestead_admin/live/webhook_live/accessibility_test.exs
)

log_step "running mounted phase 12 sibling-package proof"
(
  cd "$ROOT_DIR/rulestead_admin"
  mix test test/rulestead_admin/integration/admin_mount_phase12_webhooks_test.exs
)

log_step "phase 12 webhook verification complete"
