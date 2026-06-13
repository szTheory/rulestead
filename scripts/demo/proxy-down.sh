#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

demo_prepare_proxy_env

echo "[demo] stopping proxy-mode compose project ${COMPOSE_PROJECT_NAME}"

docker compose \
  -f docker-compose.yml \
  -f docker-compose.proxy.yml \
  down --remove-orphans "$@"

if [ "${DEMO_PROXY_DOWN_TRAEFIK:-0}" = "1" ]; then
  echo "[demo] stopping Traefik proxy ${DEMO_PROXY_PROJECT_NAME}; only use this if no other local demo depends on it"
  docker compose \
    -p "$DEMO_PROXY_PROJECT_NAME" \
    -f scripts/demo/traefik-compose.yml \
    down --remove-orphans
else
  echo "[demo] shared Traefik proxy left running (${DEMO_PROXY_PROJECT_NAME})"
fi
