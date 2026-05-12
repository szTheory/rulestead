#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
RUN_PHASE7_PREFLIGHT=1
PHASE7_SLICE=(
  test/rulestead_admin/router_test.exs
  test/rulestead_admin/live/session_test.exs
  test/rulestead_admin/live/flag_live/simulate_test.exs
  test/rulestead_admin/live/flag_live/rollouts_test.exs
  test/rulestead_admin/live/flag_live/kill_test.exs
  test/rulestead_admin/live/flag_live/timeline_test.exs
  test/rulestead_admin/live/audit_live/index_test.exs
  test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs
  test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs
  test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs
)

if [[ "${1:-}" == "--skip-phase7" ]]; then
  RUN_PHASE7_PREFLIGHT=0
  shift
fi

if [[ "$#" -eq 0 ]]; then
  echo "usage: $0 [--skip-phase7] job=result [job=result...]" >&2
  exit 1
fi

for pair in "$@"; do
  job_name="${pair%%=*}"
  job_result="${pair#*=}"

  if [[ "${job_result}" != "success" ]]; then
    echo "${job_name} did not succeed: ${job_result}" >&2
    exit 1
  fi
done

if [[ "${RUN_PHASE7_PREFLIGHT}" == "1" ]]; then
  echo "re-running Phase 7 sibling-package admin slice from 07-11 before publish"
  (
    cd "${RULESTEAD_REPO}/rulestead_admin"
    mix deps.get
    mix test "${PHASE7_SLICE[@]}"
  )
fi

echo "release gate passed"
