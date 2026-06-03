#!/usr/bin/env bash
# Bounded 15-minute adopter proof path: demo stack smoke + post-GA band verify.
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "${ROOT_DIR}"

. scripts/demo/compose-env.sh
demo_prepare_compose_env

echo "[proof] 1/2 — compose-backed demo smoke (see scripts/demo/verify.sh for full browser proof)"
DEMO_SMOKE_KEEP_STACK=1 scripts/demo/smoke.sh

echo "[proof] 2/2 — post-GA band closure merge gate (rulestead + mounted admin contract subset)"
(
  cd rulestead
  mix deps.get --only test
  mix verify.adopter
)

echo "[proof] post-GA adopter proof path passed"
