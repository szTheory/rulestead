#!/usr/bin/env bash
# Fast adoption-lab backend proof: seeds, personas API, explain API, admin mount.
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "${ROOT_DIR}/examples/demo/backend"

export MIX_ENV="${MIX_ENV:-test}"

mix deps.get --only test
mix ecto.create --quiet 2>/dev/null || true
mix ecto.migrate -r Rulestead.Repo \
  --migrations-path ../../../rulestead/priv/repo/migrations \
  --quiet
mix test test/rulestead_demo/demo_seed_smoke_test.exs --warnings-as-errors

echo "[adoption-lab] backend seed smoke passed"
