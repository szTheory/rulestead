#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}/rulestead"
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
mix compile --no-optional-deps --warnings-as-errors
RULESTEAD_REPO="${RULESTEAD_REPO}" "${RULESTEAD_REPO}/scripts/ci/check_package_whitelist.sh"
mix dialyzer --format github
