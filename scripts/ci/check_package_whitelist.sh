#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

run_dry_run() {
  local package_dir="$1"
  local output_file="$2"

  (
    cd "${RULESTEAD_REPO}/${package_dir}"
    mix hex.publish --dry-run
  ) | tee "${output_file}"
}

core_output="$(mktemp)"
admin_output="$(mktemp)"
trap 'rm -f "${core_output}" "${admin_output}"' EXIT

run_dry_run "rulestead" "${core_output}"
run_dry_run "rulestead_admin" "${admin_output}"

if rg -n "rulestead_admin/" "${core_output}" >/dev/null; then
  echo "core package dry-run output includes rulestead_admin/ content" >&2
  exit 1
fi

if rg -n "rulestead/" "${admin_output}" >/dev/null; then
  echo "admin package dry-run output includes rulestead/ content" >&2
  exit 1
fi

echo "package whitelist checks passed"
