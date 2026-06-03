#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

demo_prepare_compose_env

echo "[demo] starting compose project ${COMPOSE_PROJECT_NAME}"
echo "[demo] using backend host port ${DEMO_BACKEND_PORT}"
echo "[demo] using frontend host port ${DEMO_FRONTEND_PORT}"

docker compose up -d --build

demo_export_urls_from_compose
demo_print_urls
