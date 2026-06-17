#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh
demo_prepare_compose_env

cleanup() {
  docker compose down --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

echo "[verify] starting compose-backed smoke verification"
DEMO_SMOKE_KEEP_STACK=1 scripts/demo/smoke.sh
demo_export_urls_from_compose

echo "[verify] installing frontend test dependencies"
(
  cd examples/demo/frontend
  rm -rf node_modules
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
  CI=true DEMO_BACKEND_URL="$DEMO_BACKEND_URL" DEMO_FRONTEND_URL="$DEMO_FRONTEND_URL" npm run test:e2e
) || {
  echo ""
  echo "[verify] Playwright failed."
  echo "  Frontend URL : ${DEMO_FRONTEND_URL}"
  echo "  Backend URL  : ${DEMO_BACKEND_URL}"
  echo "  Artifacts    : examples/demo/frontend/playwright-report/"
  echo "                 examples/demo/frontend/test-results/"
  echo "  Local report : cd examples/demo/frontend && npx playwright show-report"
  echo "  Local rerun  : cd examples/demo/frontend && npm run test:e2e"
  echo ""
  exit 1
}

echo "[verify] compose smoke and browser proof passed"
