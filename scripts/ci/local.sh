#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
FAST=0

usage() {
  cat <<'EOF'
Usage: local.sh [--fast]

Runs the monorepo contributor gate locally (mirrors merge CI).

  --fast  Skip mounted companion proof and openfeature companion scopes
EOF
}

for arg in "$@"; do
  case "$arg" in
    --fast)
      FAST=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "${RULESTEAD_REPO}"

echo "==> lint"
bash scripts/ci/lint.sh

echo "==> core test scope"
bash scripts/ci/test.sh

if [[ "${FAST}" == "0" ]]; then
  echo "==> mounted companion proof"
  RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh

  echo "==> openfeature companion proof"
  RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh
else
  echo "==> skipping mounted/openfeature companion scopes (--fast)"
fi

echo "==> adopter contract"
(
  cd rulestead
  mix verify.adopter
)

echo "local contributor gate passed"
