#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

# Resolve the same COMPOSE_PROJECT_NAME / ports that up.sh chose, so teardown
# targets the correct per-branch project instead of the static `name:` default.
demo_prepare_compose_env

echo "[demo] stopping compose project ${COMPOSE_PROJECT_NAME}"

# Pass through extra flags, e.g. `scripts/demo/down.sh --volumes` to also drop
# the demo database/redis state.
docker compose down --remove-orphans "$@"
