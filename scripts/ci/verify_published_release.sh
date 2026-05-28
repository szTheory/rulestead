#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

usage() {
  echo "usage: $0 <released-version>" >&2
}

require_cmd() {
  local cmd="$1"

  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "required command not found: ${cmd}" >&2
    exit 1
  fi
}

fetch_package_metadata() {
  local package_name="$1"
  local output_file="$2"
  local api_url="https://hex.pm/api/packages/${package_name}"
  local status

  status="$(curl -sS -o "${output_file}" -w "%{http_code}" "${api_url}" || true)"

  case "${status}" in
    200) ;;
    404)
      echo "published package ${package_name} is not visible on Hex yet: ${api_url}" >&2
      exit 1
      ;;
    *)
      echo "failed to query ${api_url}: HTTP ${status}" >&2
      exit 1
      ;;
  esac
}

assert_release_visible() {
  local package_name="$1"
  local version="$2"
  local metadata_file="$3"

  if ! jq -e --arg version "${version}" '.releases | any(.version == $version)' "${metadata_file}" >/dev/null; then
    echo "published package ${package_name} does not expose release ${version} on Hex yet" >&2
    exit 1
  fi
}

run_mix() {
  local task="$1"
  shift

  echo "==> mix ${task} $*"
  (
    cd "${RULESTEAD_REPO}/rulestead"
    MIX_ENV=test mix "${task}" "$@"
  )
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 1
fi

RELEASE_VERSION="$1"

if [[ -z "${RELEASE_VERSION}" ]]; then
  usage
  exit 1
fi

require_cmd curl
require_cmd jq
require_cmd mix

ensure_phx_new_archive() {
  if mix help phx.new >/dev/null 2>&1; then
    return 0
  fi

  echo "Installing phx_new archive for admin consumer fixture generation"
  mix local.hex --force
  mix archive.install hex phx_new --force
}

ensure_phx_new_archive

core_metadata="$(mktemp)"
admin_metadata="$(mktemp)"
trap 'rm -f "${core_metadata}" "${admin_metadata}"' EXIT

fetch_package_metadata "rulestead" "${core_metadata}"
fetch_package_metadata "rulestead_admin" "${admin_metadata}"
assert_release_visible "rulestead" "${RELEASE_VERSION}" "${core_metadata}"
assert_release_visible "rulestead_admin" "${RELEASE_VERSION}" "${admin_metadata}"

echo "verified Hex visibility for rulestead and rulestead_admin ${RELEASE_VERSION}"
run_mix verify.workspace_clean
run_mix verify.release_publish "${RELEASE_VERSION}"
run_mix verify.release_parity "${RELEASE_VERSION}"

echo "post-publish verification trio passed for ${RELEASE_VERSION}"
