#!/usr/bin/env bash
set -euo pipefail

# Pre-publish assertion guard for open_feature_rulestead.
#
# This script is a PRE-FLIGHT ASSERTION ONLY — publishing is a separate human step.
# It exists to prevent the D-14 silent path-dep drop footgun:
#   Hex silently drops path deps from the published tarball instead of erroring.
#   Forgetting OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 uploads a rulestead-less,
#   broken-for-every-consumer package that publishes cleanly without any error.
#
# Usage (from repo root):
#   export OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1
#   cd open_feature_rulestead && mix deps.get && cd ..
#   bash scripts/ci/openfeature_publish_guard.sh

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
PROVIDER_DIR="${RULESTEAD_REPO}/open_feature_rulestead"
LOCK_FILE="${PROVIDER_DIR}/mix.lock"

# --- Assertion 1: env gate ---
# Without OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 the dep resolves as a path: dep,
# which Hex silently drops from the tarball — shipping a broken package to every consumer.
if [ "${OPEN_FEATURE_RULESTEAD_HEX_RELEASE:-}" != "1" ]; then
  echo "openfeature publish guard FAILED: OPEN_FEATURE_RULESTEAD_HEX_RELEASE is not set to \"1\"." >&2
  echo "" >&2
  echo "  Forgetting this env var causes Hex to silently DROP the rulestead dependency" >&2
  echo "  from the published tarball. The package uploads without error but is broken" >&2
  echo "  for every consumer (the D-14 path-drop footgun)." >&2
  echo "" >&2
  echo "  Set the env var and re-run mix deps.get before publishing:" >&2
  echo "    export OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1" >&2
  echo "    cd open_feature_rulestead && mix deps.get && cd .." >&2
  exit 1
fi

# --- Assertion 2: rulestead resolves as a HEX dep (not path:) in mix.lock ---
# A path-resolved rulestead produces NO mix.lock entry at all — path deps emit zero
# lock entries. An absent hex entry is exactly the silent-path-drop condition (D-14).
# The mix.lock must contain: "rulestead": {:hex, :rulestead,
if [ ! -f "${LOCK_FILE}" ]; then
  echo "openfeature publish guard FAILED: ${LOCK_FILE} does not exist." >&2
  echo "  Run: cd open_feature_rulestead && mix deps.get" >&2
  exit 1
fi

if ! grep -q '"rulestead": {:hex, :rulestead,' "${LOCK_FILE}"; then
  echo "openfeature publish guard FAILED: rulestead does NOT resolve as a Hex dep in ${LOCK_FILE}." >&2
  echo "" >&2
  echo "  Expected to find: \"rulestead\": {:hex, :rulestead," >&2
  echo "  This means rulestead is still resolving as a path: dep (or is missing entirely)." >&2
  echo "  A path dep is silently dropped from the Hex tarball — the D-14 footgun." >&2
  echo "" >&2
  echo "  Ensure OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1 is exported, then re-run:" >&2
  echo "    cd open_feature_rulestead && mix deps.get" >&2
  exit 1
fi

# --- Assertion 3: mix.lock is non-empty and provider workspace is reasonably clean ---
# Assert a fresh, non-empty lock file exists for the provider.
if [ ! -s "${LOCK_FILE}" ]; then
  echo "openfeature publish guard FAILED: ${LOCK_FILE} is empty." >&2
  echo "  Run: cd open_feature_rulestead && mix deps.get" >&2
  exit 1
fi

# Warn if there are unexpected uncommitted changes in the provider directory.
DIRTY=$(git -C "${RULESTEAD_REPO}" status --porcelain "${PROVIDER_DIR}" 2>/dev/null || true)
if [ -n "$DIRTY" ]; then
  echo "openfeature publish guard WARNING: open_feature_rulestead has uncommitted changes:" >&2
  echo "$DIRTY" >&2
  echo "  Review the above before publishing. Proceeding." >&2
fi

echo "openfeature publish guard passed"
