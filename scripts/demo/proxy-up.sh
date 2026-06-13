#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

demo_prepare_proxy_env

echo "[demo] starting compose project ${COMPOSE_PROJECT_NAME} in proxy mode"
echo "[demo] using proxy network ${DEMO_PROXY_NETWORK}"
echo "[demo] using backend host ${DEMO_BACKEND_HOST}"
echo "[demo] using frontend host ${DEMO_FRONTEND_HOST}"
echo "[demo] using proxy port ${DEMO_PROXY_HTTP_PORT}"

demo_start_proxy

docker compose \
  -f docker-compose.yml \
  -f docker-compose.proxy.yml \
  up -d --build

demo_print_urls
echo "[demo] Stop demo: scripts/demo/proxy-down.sh"
echo "[demo] Shared Traefik is left running for other local demos."
