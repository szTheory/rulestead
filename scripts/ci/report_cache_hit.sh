#!/usr/bin/env bash
set -euo pipefail

# Shared cache-hit reporter for ci.yml lint and test jobs.
# Argument $1 is the actions/cache `cache-hit` output value:
#   "true"  -> exact key hit
#   ""      -> restore-key (partial) hit (empty string)
#   "false" -> miss
# Behavior is byte-identical to the inline report blocks it replaces:
# guard on GITHUB_STEP_SUMMARY, then branch exact-hit vs partial/miss.

hit="${1:-}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  if [[ "${hit}" == "true" ]]; then
    echo "Cache: exact hit" >> "${GITHUB_STEP_SUMMARY}"
  else
    echo "Cache: miss or restore-key (partial) hit" >> "${GITHUB_STEP_SUMMARY}"
  fi
fi
