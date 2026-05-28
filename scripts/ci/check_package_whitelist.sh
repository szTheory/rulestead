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

extract_tarball_name() {
  local output_file="$1"

  grep -Eo 'Saved to [^[:space:]]+' "${output_file}" | tail -1 | awk '{print $3}'
}

run_dry_run "rulestead" "${core_output}"
run_dry_run "rulestead_admin" "${admin_output}"

core_tarball="$(extract_tarball_name "${core_output}")"
admin_tarball="$(extract_tarball_name "${admin_output}")"

if [[ -z "${core_tarball}" || -z "${admin_tarball}" ]]; then
  echo "failed to detect hex.build tarball names from dry-run output" >&2
  exit 1
fi

list_contents "rulestead" "${core_tarball}" > "${core_contents}"
list_contents "rulestead_admin" "${admin_tarball}" > "${admin_contents}"

if grep -q "^rulestead_admin/" "${core_contents}"; then
  echo "core package dry-run output includes rulestead_admin/ content" >&2
  exit 1
fi

if grep -q "^rulestead/" "${admin_contents}"; then
  echo "admin package dry-run output includes rulestead/ content" >&2
  exit 1
fi

echo "package whitelist checks passed"
