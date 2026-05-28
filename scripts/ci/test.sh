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

print_blast_radius_governance_failure_guidance() {
  local category="${1:-unknown}"

  {
    echo
    echo "blast_radius_governance failure category: ${category}"
    echo "Expected support boundary: core owns threshold/change-request contracts; mounted companion presents bounded governance UX."
    echo "Rerun: RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh"
    echo "Remediation: cd rulestead && mix verify.phase60"

    if [[ "${category}" == "docs drift" ]]; then
      echo "Docs drift hint: release_contract_test.exs blast-radius governance block failed — sync README/MAINTAINING/package READMEs with asserts."
    elif [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Setup expectation: install repo deps and prepare the rulestead test database before rerunning."
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd rulestead && mix ecto.create && mix ecto.migrate"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: inspect contract regression output above for threshold, change-request, or governance failures."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

blast_radius_governance_failure_category() {
  local log_file="$1"

  if rg -q "blast radius governance support truth stays bounded" "${log_file}" 2>/dev/null; then
    echo "docs drift"
  elif rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError" "${log_file}"; then
    echo "contract regression"
  else
    echo "unknown blast-radius-governance failure"
  fi
}

run_blast_radius_governance() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead_admin "${log_file}" deps.get; then
      if run_mix_logged rulestead "${log_file}" verify.phase60; then
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
    print_blast_radius_governance_failure_guidance "$(blast_radius_governance_failure_category "${log_file}")"
    rm -f "${log_file}"
    return "${status}"
  fi

  rm -f "${log_file}"
}

print_guarded_rollout_auto_advance_failure_guidance() {
  local category="${1:-unknown}"

  {
    echo
    echo "guarded_rollout_auto_advance failure category: ${category}"
    echo "Expected support boundary: core owns policy + orchestration; mounted companion presents bounded auto-advance UX."
    echo "Rerun: RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh"
    echo "Remediation: cd rulestead && mix verify.phase64"

    if [[ "${category}" == "docs drift" ]]; then
      echo "Docs drift hint: release_contract_test.exs guarded rollout auto-advance support truth block failed — sync README/MAINTAINING/package READMEs with asserts."
    elif [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Setup expectation: install repo deps and prepare the rulestead test database before rerunning."
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd rulestead && mix ecto.create && mix ecto.migrate"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: inspect contract regression output above for auto-advance policy, orchestration, or mounted workflow failures."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

guarded_rollout_auto_advance_failure_category() {
  local log_file="$1"

  if rg -q "guarded rollout auto-advance support truth stays bounded" "${log_file}" 2>/dev/null; then
    echo "docs drift"
  elif rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError" "${log_file}"; then
    echo "contract regression"
  else
    echo "unknown guarded-rollout-auto-advance failure"
  fi
}

run_guarded_rollout_auto_advance() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead_admin "${log_file}" deps.get; then
      if run_mix_logged rulestead "${log_file}" verify.phase64; then
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
    print_guarded_rollout_auto_advance_failure_guidance "$(guarded_rollout_auto_advance_failure_category "${log_file}")"
    rm -f "${log_file}"
    return "${status}"
  fi

  rm -f "${log_file}"
}

print_host_preview_evidence_failure_guidance() {
  local category="${1:-unknown}"

  {
    echo
    echo "host_preview_evidence failure category: ${category}"
    echo "Expected support boundary: core owns resolver + redaction; mounted companion presents bounded sample/impression evidence."
    echo "Rerun: RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh"
    echo "Remediation: cd rulestead && mix verify.phase68"

    if [[ "${category}" == "docs drift" ]]; then
      echo "Docs drift hint: release_contract_test.exs host preview evidence support truth block failed — sync README/MAINTAINING/package READMEs with asserts."
    elif [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Setup expectation: install repo deps and prepare the rulestead test database before rerunning."
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd rulestead && mix ecto.create && mix ecto.migrate"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: inspect contract regression output above for preview evidence resolver, governance boundary, or mounted workflow failures."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

host_preview_evidence_failure_category() {
  local log_file="$1"

  if rg -q "host preview evidence support truth stays bounded" "${log_file}" 2>/dev/null; then
    echo "docs drift"
  elif rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError" "${log_file}"; then
    echo "contract regression"
  else
    echo "unknown host-preview-evidence failure"
  fi
}

run_host_preview_evidence() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead_admin "${log_file}" deps.get; then
      if run_mix_logged rulestead "${log_file}" verify.phase68; then
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
    print_host_preview_evidence_failure_guidance "$(host_preview_evidence_failure_category "${log_file}")"
    rm -f "${log_file}"
    return "${status}"
  fi

  rm -f "${log_file}"
}

run_reusable_targeting_deepening() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead_admin "${log_file}" deps.get; then
      if run_mix_logged rulestead "${log_file}" verify.phase56; then
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

print_post_ga_band_closure_failure_guidance() {
  local category="${1:-unknown}"

  {
    echo
    echo "post_ga_band_closure failure category: ${category}"
    echo "Expected support boundary: post-v1.9 band truth — docs, release contract, and v1.9 proof superset."
    echo "Rerun: RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh"
    echo "Remediation: cd rulestead && mix verify.phase73"

    if [[ "${category}" == "docs drift" ]]; then
      echo "Docs drift hint: release_contract_test.exs post-GA band closure block failed — sync README/MAINTAINING with asserts."
    elif [[ "${category}" == "setup/prerequisite failure" ]]; then
      echo "Suggested setup:"
      echo "  - cd rulestead && mix deps.get"
      echo "  - cd rulestead && mix ecto.create && mix ecto.migrate"
      echo "  - cd ../rulestead_admin && mix deps.get"
    else
      echo "Remediation focus: inspect contract regression output for band-closure or v1.9 proof failures."
    fi

    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}

post_ga_band_closure_failure_category() {
  local log_file="$1"

  if rg -q "post-GA band closure support truth stays bounded" "${log_file}" 2>/dev/null; then
    echo "docs drift"
  elif rg -q \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif rg -q "test failed|failures|ExUnit\\.AssertionError" "${log_file}"; then
    echo "contract regression"
  else
    echo "unknown post-ga-band-closure failure"
  fi
}

run_post_ga_band_closure() {
  local log_file
  local status=0
  log_file="$(mktemp)"

  if run_mix_logged rulestead "${log_file}" deps.get; then
    prepare_rulestead_test_db
    if run_mix_logged rulestead_admin "${log_file}" deps.get; then
      if run_mix_logged rulestead "${log_file}" verify.phase73; then
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
    print_post_ga_band_closure_failure_guidance "$(post_ga_band_closure_failure_category "${log_file}")"
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
  blast_radius_governance)
    echo "Running blast radius governance proof bar"
    run_blast_radius_governance
    ;;
  guarded_rollout_auto_advance)
    echo "Running guarded rollout auto-advance proof bar"
    run_guarded_rollout_auto_advance
    ;;
  host_preview_evidence)
    echo "Running host preview evidence proof bar"
    run_host_preview_evidence
    ;;
  post_ga_band_closure)
    echo "Running post-GA band closure proof bar"
    run_post_ga_band_closure
    ;;
  *)
    echo "Unknown test scope: ${TEST_SCOPE}" >&2
    echo "Supported scopes: all, mounted_admin_contract, openfeature_companion, guarded_rollout_foundations, reusable_targeting_deepening, blast_radius_governance, guarded_rollout_auto_advance, host_preview_evidence, post_ga_band_closure" >&2
    exit 64
    ;;
esac
