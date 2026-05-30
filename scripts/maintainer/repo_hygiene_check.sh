#!/usr/bin/env bash
set -euo pipefail

MODE="local"
RUN_MIX_CI=1
REMOTE="${RULESTEAD_HYGIENE_REMOTE:-origin}"
MAX_OPEN_DEPENDABOT_WARN=5

usage() {
  cat <<'EOF'
Usage: repo_hygiene_check.sh [--ci] [--skip-mix-ci]

Checks whether the Rulestead monorepo is in a disciplined release-prep state.

Modes:
  --ci           Run only repo-owned drift checks that GitHub can prove.
  --skip-mix-ci  Skip the local mix ci + verify.adopter contributor gate rerun.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --ci)
      MODE="ci"
      ;;
    --skip-mix-ci)
      RUN_MIX_CI=0
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

if ! command -v git >/dev/null 2>&1; then
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

declare -a RESULTS=()
PASS_COUNT=0
WARN_COUNT=0
BLOCK_COUNT=0

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"

  RESULTS+=("[$level] $label: $detail")

  case "$level" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    BLOCK) BLOCK_COUNT=$((BLOCK_COUNT + 1)) ;;
  esac
}

have_gh() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

package_version() {
  local package_dir="$1"
  sed -nE 's/.*@version[[:space:]]+"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' \
    "${package_dir}/mix.exs" | head -n 1
}

manifest_version() {
  local component="$1"
  jq -r --arg component "$component" '.[$component] // empty' .release-please-manifest.json 2>/dev/null
}

hex_latest_version() {
  local package_name="$1"
  curl -fsS "https://hex.pm/api/packages/${package_name}" 2>/dev/null \
    | jq -r '[.releases[].version] | max_by(split(".") | map(tonumber)) // empty' 2>/dev/null || true
}

open_release_please_pr_bad_bump() {
  have_gh || return 1
  local current="$1"
  local major minor patch title pr_major pr_minor
  IFS=. read -r major minor patch <<<"$current"

  while IFS= read -r title; do
    [[ -z "$title" ]] && continue
    [[ "$title" =~ release[[:space:]]+([0-9]+)\.([0-9]+)\.([0-9]+) ]] || continue
    pr_major="${BASH_REMATCH[1]}"
    pr_minor="${BASH_REMATCH[2]}"
    if [[ "$pr_major" -gt "$major" ]] || [[ "$pr_major" -eq "$major" && "$pr_minor" -gt "$minor" ]]; then
      echo "$title"
      return 0
    fi
  done < <(gh pr list --state open --limit 30 --json title,labels \
    --jq '.[] | select([.labels[].name] | index("autorelease: pending")) | .title' 2>/dev/null)

  return 1
}

repo_owned_checks() {
  local core_ver admin_ver manifest_core manifest_admin

  core_ver="$(package_version rulestead)"
  admin_ver="$(package_version rulestead_admin)"
  manifest_core="$(manifest_version rulestead)"
  manifest_admin="$(manifest_version rulestead_admin)"

  if [[ -n "$core_ver" && -n "$admin_ver" && "$core_ver" == "$admin_ver" ]]; then
    record_result "PASS" "linked package versions" "rulestead and rulestead_admin both at $core_ver"
  else
    record_result "BLOCK" "linked package versions" "rulestead=$core_ver rulestead_admin=$admin_ver"
  fi

  if [[ -n "$manifest_core" && -n "$manifest_admin" && "$manifest_core" == "$manifest_admin" && "$manifest_core" == "$core_ver" ]]; then
    record_result "PASS" "release manifest" "manifest matches both mix.exs files at $core_ver"
  else
    record_result "BLOCK" "release manifest" "manifest core=$manifest_core admin=$manifest_admin mix=$core_ver"
  fi

  if grep -Fq '"type": "linked-versions"' release-please-config.json &&
     grep -Fq '"release-type": "elixir"' release-please-config.json &&
     grep -Fq '"include-component-in-tag": true' release-please-config.json; then
    record_result "PASS" "release-please config" "linked-versions sibling-package policy is intact"
  else
    record_result "BLOCK" "release-please config" "release-please-config.json drifted from maintained policy"
  fi

  if grep -Fq 'publish-hex.yml' .github/workflows/release-please.yml &&
     grep -Fq 'gate-ci-green' .github/workflows/publish-hex.yml; then
    record_result "PASS" "publish workflow" "publish-hex.yml includes gated publish lane"
  else
    record_result "BLOCK" "publish workflow" "publish-hex.yml no longer matches the trusted release lane"
  fi

  if grep -Fq './scripts/maintainer/repo_hygiene_check.sh' MAINTAINING.md &&
     grep -Fq 'release_gate' MAINTAINING.md; then
    record_result "PASS" "maintainer docs" "MAINTAINING.md points to hygiene and release_gate"
  else
    record_result "BLOCK" "maintainer docs" "MAINTAINING.md is missing required hygiene references"
  fi

  if grep -Fq 'release_gate:' .github/workflows/ci.yml; then
    record_result "PASS" "release_gate job" "ci.yml defines the required release_gate terminal job"
  else
    record_result "BLOCK" "release_gate job" "ci.yml is missing the release_gate required lane"
  fi

  if [[ -f scripts/ci/local.sh && -x scripts/ci/local.sh ]]; then
    record_result "PASS" "local gate script" "scripts/ci/local.sh is present and executable"
  else
    record_result "BLOCK" "local gate script" "scripts/ci/local.sh is missing or not executable"
  fi
}

local_checks() {
  local branch status_output core_ver hex_core hex_admin bad_rp dependabot_count latest_ci

  branch="$(git rev-parse --abbrev-ref HEAD)"
  record_result "PASS" "current branch" "$branch"

  status_output="$(git status --porcelain)"
  if [[ -z "$status_output" ]]; then
    record_result "PASS" "working tree" "clean"
  else
    record_result "BLOCK" "working tree" "dirty state detected; commit, stash, or discard local changes first"
  fi

  git fetch "$REMOTE" --prune >/dev/null 2>&1 || true

  if git show-ref --verify --quiet "refs/heads/main" && git show-ref --verify --quiet "refs/remotes/$REMOTE/main"; then
    local ahead behind
    read -r behind ahead <<<"$(git rev-list --left-right --count "$REMOTE/main...main")"

    if [[ "$behind" == "0" && "$ahead" == "0" ]]; then
      record_result "PASS" "main divergence" "local main matches $REMOTE/main"
    elif [[ "$behind" != "0" ]]; then
      record_result "BLOCK" "main divergence" "local main is behind $REMOTE/main by $behind commit(s)"
    else
      record_result "WARN" "main divergence" "local main is ahead of $REMOTE/main by $ahead commit(s)"
    fi
  else
    record_result "WARN" "main divergence" "could not compare local main to $REMOTE/main"
  fi

  core_ver="$(package_version rulestead)"
  hex_core="$(hex_latest_version rulestead)"
  hex_admin="$(hex_latest_version rulestead_admin)"

  if [[ -n "$hex_core" && -n "$hex_admin" && "$hex_core" == "$hex_admin" && "$hex_core" == "$core_ver" ]]; then
    record_result "PASS" "Hex publish parity" "Hex latest ($hex_core) matches manifest ($core_ver)"
  elif [[ -n "$hex_core" && -n "$hex_admin" && "$hex_core" == "$hex_admin" ]]; then
    record_result "WARN" "Hex publish parity" "Hex latest=$hex_core manifest=$core_ver (publish may be in flight)"
  else
    record_result "WARN" "Hex publish parity" "could not confirm Hex latest for both packages"
  fi

  if have_gh; then
    if bad_rp="$(open_release_please_pr_bad_bump "$core_ver")"; then
      record_result "BLOCK" "release please PR" "open Release PR proposes unexpected minor/major: $bad_rp"
    else
      record_result "PASS" "release please PR" "no maintenance-incompatible Release Please bump (patch PRs OK)"
    fi

    dependabot_count="$(gh pr list --state open --author 'app/dependabot' --json number --jq 'length' 2>/dev/null || echo 0)"
    if [[ "$dependabot_count" -le "$MAX_OPEN_DEPENDABOT_WARN" ]]; then
      record_result "PASS" "dependabot queue" "$dependabot_count open Dependabot PR(s)"
    else
      record_result "WARN" "dependabot queue" "$dependabot_count open Dependabot PRs (threshold $MAX_OPEN_DEPENDABOT_WARN)"
    fi

    latest_ci="$(gh run list --workflow ci.yml --branch main --limit 1 --json conclusion,status,url 2>/dev/null || true)"
    if [[ "$latest_ci" == *'"conclusion":"success"'* ]]; then
      record_result "PASS" "latest CI" "latest main CI workflow succeeded"
    elif [[ "$latest_ci" == *'"status":"in_progress"'* || "$latest_ci" == *'"status":"queued"'* ]]; then
      record_result "WARN" "latest CI" "main CI is still running"
    elif [[ -n "$latest_ci" && "$latest_ci" != "[]" ]]; then
      record_result "BLOCK" "latest CI" "latest main CI workflow is not green (check release_gate)"
    else
      record_result "WARN" "latest CI" "could not read recent main CI history"
    fi
  else
    record_result "WARN" "GitHub checks" "gh unavailable or unauthenticated; skipped PR and CI checks"
  fi

  if [[ "$RUN_MIX_CI" == "1" ]] && command -v mix >/dev/null 2>&1; then
    if (
      cd rulestead
      mix ci >/dev/null && mix verify.adopter >/dev/null
    ); then
      record_result "PASS" "mix ci" "local contributor gate passed"
    else
      record_result "BLOCK" "mix ci" "local contributor gate failed (mix ci or verify.adopter)"
    fi
  elif [[ "$RUN_MIX_CI" == "0" ]]; then
    record_result "WARN" "mix ci" "skipped by flag"
  else
    record_result "WARN" "mix ci" "mix not available; skipped"
  fi
}

repo_owned_checks

if [[ "$MODE" != "ci" ]]; then
  local_checks
fi

printf 'Rulestead repo hygiene report (%s)\n' "$MODE"
printf '%s\n' "${RESULTS[@]}"
printf 'Summary: %s PASS, %s WARN, %s BLOCK\n' "$PASS_COUNT" "$WARN_COUNT" "$BLOCK_COUNT"

if [[ "$BLOCK_COUNT" -gt 0 ]]; then
  echo "Result: not ready"
  exit 1
fi

if [[ "$WARN_COUNT" -gt 0 ]]; then
  echo "Result: proceed with caution"
  exit 0
fi

echo "Result: safe to start release prep"
