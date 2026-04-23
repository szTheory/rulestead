#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

if [[ "$#" -eq 0 ]]; then
  echo "usage: $0 job=result [job=result...]" >&2
  exit 1
fi

for pair in "$@"; do
  job_name="${pair%%=*}"
  job_result="${pair#*=}"

  if [[ "${job_result}" != "success" ]]; then
    echo "${job_name} did not succeed: ${job_result}" >&2
    exit 1
  fi
done

echo "release gate passed"
