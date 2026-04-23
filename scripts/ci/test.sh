#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
MATRIX_ELIXIR="${MATRIX_ELIXIR:-}"
MATRIX_OTP="${MATRIX_OTP:-}"

run_mix() {
  local package_dir="$1"
  shift

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    mix "$@"
  )
}

if [[ -n "${MATRIX_ELIXIR}" || -n "${MATRIX_OTP}" ]]; then
  echo "Running test lane for Elixir ${MATRIX_ELIXIR:-unknown} / OTP ${MATRIX_OTP:-unknown}"
fi

run_mix rulestead deps.get
run_mix rulestead test --warnings-as-errors
run_mix rulestead_admin deps.get
run_mix rulestead_admin test --warnings-as-errors
