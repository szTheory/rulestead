#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
MATRIX_ELIXIR="${MATRIX_ELIXIR:-}"
MATRIX_OTP="${MATRIX_OTP:-}"
TEST_SCOPE="${RULESTEAD_TEST_SCOPE:-${1:-all}}"
export MIX_ENV="${MIX_ENV:-test}"
MOUNTED_PROOF_RUNBOOK="${RULESTEAD_REPO}/MAINTAINING.md"

run_mix() {
  local package_dir="$1"
  shift

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    mix "$@"
  )
}

prepare_rulestead_test_db() {
  run_mix rulestead ecto.drop --force || true
  run_mix rulestead ecto.create
  run_mix rulestead ecto.migrate
}

ensure_phx_new() {
  if ! (cd "${RULESTEAD_REPO}/rulestead" && mix help phx.new >/dev/null 2>&1); then
    run_mix rulestead archive.install hex phx_new --force
  fi
}

run_mix_logged() {
  local package_dir="$1"
  local log_file="$2"
  shift 2

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    mix "$@"
  ) 2>&1 | tee -a "${log_file}"

  return "${PIPESTATUS[0]}"
}

mounted_failure_category() {
  local log_file="$1"

  if rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|can't continue due to errors on dependencies|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError|MatchError|FunctionClauseError|UndefinedFunctionError" "${log_file}"; then
    echo "mounted contract regression"
  else
    echo "unknown mounted-proof failure"
  fi
}

print_mounted_failure_guidance() {
  local category="$1"

  {
    echo
    echo "mounted_admin_contract failure category: ${category}"
    echo "Expected support boundary: mounted companion only; host app owns the router/session prerequisite contract."
    echo "Rerun: RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
    echo "Mounted proof suites:"
    echo "  - cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs"
    echo "  - cd rulestead && mix test test/rulestead/admin_contract_test.exs test/rulestead/admin_lifecycle_test.exs"

    if [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Setup expectation: install repo deps for both sibling packages before rerunning the mounted proof."
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: the mounted lifecycle, route, or permission contract regressed; inspect the raw failure output above."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

run_mounted_admin_contract() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead_admin "${log_file}" test \
    test/rulestead_admin/live/session_test.exs \
    test/rulestead_admin/integration/admin_mount_test.exs \
    test/rulestead_admin/live/flag_live/index_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_preview_test.exs \
    test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs; then
    if run_mix_logged rulestead "${log_file}" test \
    test/rulestead/admin_contract_test.exs \
    test/rulestead/admin_lifecycle_test.exs; then
      :
    else
      status=$?
    fi
  else
    status=$?
  fi

  if [[ "${status}" -ne 0 ]]; then
    print_mounted_failure_guidance "$(mounted_failure_category "${log_file}")"
    rm -f "${log_file}"
    return "${status}"
  fi

  rm -f "${log_file}"
}

run_openfeature_companion() {
  run_mix open_feature_rulestead deps.get
  run_mix open_feature_rulestead test \
    test/open_feature_rulestead/context_mapper_test.exs \
    test/open_feature_rulestead/provider_test.exs
}

print_reusable_targeting_failure_guidance() {
  local category="${1:-unknown}"

  {
    echo
    echo "reusable_targeting_deepening failure category: ${category}"
    echo "Expected support boundary: core owns domain/validation; mounted companion presents bounded operator workflows."
    echo "Rerun: RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh"
    echo "Remediation: cd rulestead && mix verify.phase56"

    if [[ "${category}" == "docs drift" ]]; then
      echo "Docs drift hint: release_contract_test.exs reusable-targeting block failed — sync README/MAINTAINING/package READMEs with asserts."
    elif [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Setup expectation: install repo deps and prepare the rulestead test database before rerunning."
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd rulestead && mix ecto.create && mix ecto.migrate"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: inspect contract regression output above for dependency, preview, or promotion failures."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

reusable_targeting_failure_category() {
  local log_file="$1"

  if rg -q "reusable targeting deepening support truth stays bounded" "${log_file}" 2>/dev/null; then
    echo "docs drift"
  elif rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError" "${log_file}"; then
    echo "contract regression"
  else
    echo "unknown reusable-targeting failure"
  fi
}

run_guarded_rollout_foundations() {
  run_mix rulestead deps.get
  prepare_rulestead_test_db
  run_mix rulestead test \
    test/rulestead/guardrails/contract_test.exs \
    test/rulestead/guardrails/decision_test.exs \
    test/rulestead/guarded_rollout_test.exs \
    test/rulestead/release_contract_test.exs \
    test/rulestead/mix/tasks/verify_release_publish_test.exs
  run_mix rulestead_admin deps.get
  run_mix rulestead_admin test \
    test/rulestead_admin/live/flag_live/rollouts_test.exs \
    test/rulestead_admin/live/flag_live/timeline_test.exs
}

run_reusable_targeting_deepening() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead "${log_file}" verify.phase56; then
      if run_mix_logged rulestead_admin "${log_file}" deps.get; then
        :
      else
        status=$?
      fi
    else
      status=$?
    fi
  else
    status=$?
  fi

  if [[ "${status}" -ne 0 ]]; then
    print_reusable_targeting_failure_guidance "$(reusable_targeting_failure_category "${log_file}")"
    rm -f "${log_file}"
    return "${status}"
  fi

  rm -f "${log_file}"
}

if [[ -n "${MATRIX_ELIXIR}" || -n "${MATRIX_OTP}" ]]; then
  echo "Running test lane for Elixir ${MATRIX_ELIXIR:-unknown} / OTP ${MATRIX_OTP:-unknown}"
fi

case "${TEST_SCOPE}" in
  all)
    run_mix rulestead deps.get
    ensure_phx_new
    bash "${RULESTEAD_REPO}/scripts/ci/install_contract.sh"
    prepare_rulestead_test_db
    run_mix rulestead test --warnings-as-errors --exclude install_integration
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
  guarded_rollout_foundations)
    echo "Running guarded rollout foundations proof bar"
    run_guarded_rollout_foundations
    ;;
  reusable_targeting_deepening)
    echo "Running reusable targeting deepening proof bar"
    run_reusable_targeting_deepening
    ;;
  *)
    echo "Unknown test scope: ${TEST_SCOPE}" >&2
    echo "Supported scopes: all, mounted_admin_contract, openfeature_companion, guarded_rollout_foundations, reusable_targeting_deepening" >&2
    exit 64
    ;;
esac
