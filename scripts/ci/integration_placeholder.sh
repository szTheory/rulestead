#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}"

scripts/demo/verify.sh
