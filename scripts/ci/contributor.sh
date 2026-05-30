#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../rulestead" && pwd)"

cd "${PACKAGE_DIR}"
export MIX_ENV="${MIX_ENV:-test}"

mix format --check-formatted
mix compile --warnings-as-errors
mix test --exclude install_integration
mix credo --strict
mix docs --warnings-as-errors
