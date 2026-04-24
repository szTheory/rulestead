#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
CONFIG_FILE="${RULESTEAD_REPO}/release-please-config.json"
MANIFEST_FILE="${RULESTEAD_REPO}/.release-please-manifest.json"
REMOTE_URL="${RULESTEAD_RELEASE_PLEASE_REPO_URL:-$(git -C "${RULESTEAD_REPO}" config --get remote.origin.url || true)}"

normalize_repo_url() {
  local raw_url="$1"

  raw_url="${raw_url#git@github.com:}"
  raw_url="${raw_url#https://github.com/}"
  raw_url="${raw_url#http://github.com/}"
  raw_url="${raw_url%.git}"

  printf '%s\n' "${raw_url}"
}

if ! rg -n '"rulestead": "0\.0\.0"' "${MANIFEST_FILE}" >/dev/null; then
  echo "release-please bootstrap manifest must seed rulestead at 0.0.0" >&2
  exit 1
fi

if ! rg -n '"rulestead_admin": "0\.0\.0"' "${MANIFEST_FILE}" >/dev/null; then
  echo "release-please bootstrap manifest must seed both packages at 0.0.0" >&2
  exit 1
fi

if ! rg -n 'Release-As: 0.1.0' "${RULESTEAD_REPO}/.github/workflows/release-please.yml" >/dev/null; then
  echo "release-please bootstrap guidance must include Release-As: 0.1.0" >&2
  exit 1
fi

if ! rg -n 'publish-hex\.yml' "${RULESTEAD_REPO}/.github/workflows/release-please.yml" >/dev/null; then
  echo "release-please workflow must hand off to publish-hex automation" >&2
  exit 1
fi

if ! rg -n 'workflow_run|workflow_dispatch' "${RULESTEAD_REPO}/.github/workflows/publish-hex.yml" >/dev/null; then
  echo "publish workflow must support automated handoff from release-please" >&2
  exit 1
fi

if ! rg -n 'environment:' "${RULESTEAD_REPO}/.github/workflows/publish-hex.yml" >/dev/null; then
  echo "publish workflow must require an explicit approval environment before publish" >&2
  exit 1
fi

if ! rg -n 'needs:\s*\n\s*-\s*preflight\s*\n\s*-\s*publish-core' "${RULESTEAD_REPO}/.github/workflows/publish-hex.yml" >/dev/null; then
  echo "publish workflow must keep admin publish behind preflight and core publish" >&2
  exit 1
fi

if ! rg -n 'simulate_test\.exs|07-11|Phase 7' "${RULESTEAD_REPO}/scripts/ci/release_gate.sh" >/dev/null; then
  echo "release gate must re-run the Phase 7 sibling-package admin slice" >&2
  exit 1
fi

if ! rg -n 'manual recovery|post-publish verification|hex-publish|rulestead_admin' "${RULESTEAD_REPO}/MAINTAINING.md" >/dev/null; then
  echo "MAINTAINING.md must document approval, recovery, and post-publish handoff" >&2
  exit 1
fi

if [[ -z "${REMOTE_URL}" ]]; then
  echo "set RULESTEAD_RELEASE_PLEASE_REPO_URL or configure git remote.origin.url before running release-please dry-run" >&2
  exit 1
fi

dry_run_output="$(mktemp)"
trap 'rm -f "${dry_run_output}"' EXIT

repo_url="$(normalize_repo_url "${REMOTE_URL}")"

npx --yes release-please@16.18.0 manifest-pr \
  --config-file="${CONFIG_FILE}" \
  --manifest-file="${MANIFEST_FILE}" \
  --repo-url="${repo_url}" \
  --target-branch=main \
  --dry-run | tee "${dry_run_output}"

rg -n 'release-please|0\.0\.0|rulestead|rulestead_admin' "${dry_run_output}" >/dev/null
