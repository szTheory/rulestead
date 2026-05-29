#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

cleanup() {
  docker compose down --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

echo "[verify] starting compose-backed smoke verification"
DEMO_SMOKE_KEEP_STACK=1 scripts/demo/smoke.sh

echo "[verify] installing frontend test dependencies"
(
  cd examples/demo/frontend
  npm ci
)

echo "[verify] installing Playwright browser dependencies"
(
  cd examples/demo/frontend

  if [ "$(uname -s)" = "Linux" ]; then
    npx playwright install --with-deps chromium
  else
    npx playwright install chromium
  fi
)

echo "[verify] running FleetDesk adoption lab browser proof (kill switch + journeys)"
(
  cd examples/demo/frontend
  npm run test:e2e
)

echo "[verify] compose smoke and browser proof passed"
