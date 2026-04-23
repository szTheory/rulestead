#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

run_dry_run() {
  local package_dir="$1"
  local output_file="$2"

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    if [[ "${package_dir}" == "rulestead_admin" ]]; then
      RULESTEAD_ADMIN_HEX_RELEASE=1 mix hex.build
    else
      mix hex.build
    fi
  ) | tee "${output_file}"
}

list_contents() {
  local package_dir="$1"
  local tarball_name="$2"

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    tar xOf "${tarball_name}" contents.tar.gz | tar tzf -
  )
}

core_output="$(mktemp)"
admin_output="$(mktemp)"
core_contents="$(mktemp)"
admin_contents="$(mktemp)"
trap 'rm -f "${core_output}" "${admin_output}" "${core_contents}" "${admin_contents}"' EXIT

run_dry_run "rulestead" "${core_output}"
run_dry_run "rulestead_admin" "${admin_output}"
list_contents "rulestead" "rulestead-0.1.0.tar" > "${core_contents}"
list_contents "rulestead_admin" "rulestead_admin-0.1.0.tar" > "${admin_contents}"

if rg -n "^rulestead_admin/" "${core_contents}" >/dev/null; then
  echo "core package dry-run output includes rulestead_admin/ content" >&2
  exit 1
fi

if rg -n "^rulestead/" "${admin_contents}" >/dev/null; then
  echo "admin package dry-run output includes rulestead/ content" >&2
  exit 1
fi

echo "package whitelist checks passed"
