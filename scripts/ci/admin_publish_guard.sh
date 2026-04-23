#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
ROUTER_FILE="${RULESTEAD_REPO}/rulestead_admin/lib/rulestead_admin/router.ex"

if rg -n "Phases 6-7 of v0\\.1\\.0" "${ROUTER_FILE}" >/dev/null; then
  echo "refusing admin publish while ${ROUTER_FILE} still contains the Phase 1 stub" >&2
  exit 1
fi

echo "admin publish guard passed"
