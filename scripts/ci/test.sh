#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
MATRIX_ELIXIR="${MATRIX_ELIXIR:-}"
MATRIX_OTP="${MATRIX_OTP:-}"
TEST_SCOPE="${RULESTEAD_TEST_SCOPE:-${1:-all}}"

run_mix() {
  local package_dir="$1"
  shift

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    mix "$@"
  )
}

run_mounted_admin_contract() {
  run_mix rulestead_admin deps.get
  run_mix rulestead_admin test \
    test/rulestead_admin/live/flag_live/form_test.exs \
    test/rulestead_admin/live/flag_live/index_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_preview_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs \
    test/rulestead_admin/integration/admin_mount_test.exs

  run_mix rulestead deps.get
  run_mix rulestead test \
    test/rulestead/admin_contract_test.exs \
    test/rulestead/admin_lifecycle_test.exs
}

run_openfeature_companion() {
  run_mix open_feature_rulestead deps.get
  run_mix open_feature_rulestead test \
    test/open_feature_rulestead/context_mapper_test.exs \
    test/open_feature_rulestead/provider_test.exs
}

if [[ -n "${MATRIX_ELIXIR}" || -n "${MATRIX_OTP}" ]]; then
  echo "Running test lane for Elixir ${MATRIX_ELIXIR:-unknown} / OTP ${MATRIX_OTP:-unknown}"
fi

case "${TEST_SCOPE}" in
  all)
    run_mix rulestead deps.get
    run_mix rulestead test --warnings-as-errors
    run_mix rulestead_admin deps.get
    run_mix rulestead_admin test --warnings-as-errors
    ;;
  mounted_admin_contract)
    echo "Running mounted lifecycle/admin contract proof bar"
    run_mounted_admin_contract
    ;;
  openfeature_companion)
    echo "Running OpenFeature companion provider proof bar"
    run_openfeature_companion
    ;;
  *)
    echo "Unknown test scope: ${TEST_SCOPE}" >&2
    echo "Supported scopes: all, mounted_admin_contract, openfeature_companion" >&2
    exit 64
    ;;
esac
