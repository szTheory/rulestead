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
