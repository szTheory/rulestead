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

# D-10: assert real logo SVG bytes are present in the core hex tarball.
# This gate will fail until plan 05 adds the brandbook/assets/logo/*.svg glob
# to core files: — that is expected behaviour (the gate proves the manifest).
bash "${PACKAGE_DIR}/../scripts/ci/check_logo_bytes.sh"
