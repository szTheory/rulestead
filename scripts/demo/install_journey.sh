#!/usr/bin/env bash
# Fresh-install adopter journey: mix rulestead.install → migrate → runtime probe.
# Reuses the golden-diff installer contract (rulestead/fixtures/install_golden/).
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"

echo "[install-journey] Path B — fresh Phoenix host wiring (no FleetDesk UI)"
echo "[install-journey] Delegating to scripts/ci/install_contract.sh"

bash "${ROOT_DIR}/scripts/ci/install_contract.sh"

echo "[install-journey] fresh-install adopter journey passed"
