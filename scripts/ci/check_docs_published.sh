#!/usr/bin/env bash
# Phase 126 published-docs gate — automates 126-UAT checks 1 & 4 with zero human
# UAT. Runs from scripts/ci/verify_published_release.sh (daily verify-published-
# release cron + workflow_dispatch), so it only fires once the resolve step has
# confirmed both sibling packages are live on Hex.
#
#   Check 1 — admin Hex-release docs gate: the exact human command
#     `RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors` from
#     rulestead_admin/. With the flag set, :rulestead resolves from Hex (not the
#     ../rulestead path), so this can only pass after core is published — which
#     is the whole reason it was deferred to human UAT.
#
#   Check 4 — OG / social-card unfurl: deterministic proxy. A third-party
#     renderer (Twitter/Slack drawing the card) is not automatable without those
#     services; what IS provable is that the URL the docs ADVERTISE in og:image
#     actually RESOLVES on the CDN as a 1200x630 PNG, and that logo/favicon
#     resolve too. That advertise<->resolve loop is the meaningful unfurl fact.
#
# Pattern mirrors scripts/ci/verify_published_release.sh (RULESTEAD_REPO root,
# set -euo pipefail, curl idioms, explicit pass/fail echoes).
#
# Usage: bash scripts/ci/check_docs_published.sh <released-version>
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"
RELEASE_VERSION="${1:-}"

fail() {
  echo "check_docs_published.sh: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_cmd curl
require_cmd file
require_cmd mix

# --- Check 1: admin Hex-release-mode docs gate -------------------------------
echo "==> admin Hex-release docs gate (RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors)"
(
  cd "${RULESTEAD_REPO}/rulestead_admin"
  RULESTEAD_ADMIN_HEX_RELEASE=1 mix deps.get
  RULESTEAD_ADMIN_HEX_RELEASE=1 mix docs --warnings-as-errors
)
echo "check_docs_published.sh: admin Hex-release docs gate passed"

# --- Check 4: live OG / asset resolution per host ----------------------------
assert_url_200() {
  local url="$1" expect_ct="$2" headers
  # -L follows redirects: hexdocs.pm/<pkg>/... now 301s to the per-package
  # canonical subdomain (<pkg>.hexdocs.pm), so the final 200 + content-type
  # only appear after following the redirect.
  headers="$(curl -fsSLI "${url}" 2>/dev/null)" \
    || fail "${url} did not resolve (non-2xx or unreachable)"
  if [[ -n "${expect_ct}" ]]; then
    printf '%s' "${headers}" | grep -iqE "^content-type:[[:space:]]*${expect_ct}" \
      || fail "${url} content-type is not ${expect_ct}"
  fi
  echo "    200 OK: ${url}"
}

assert_png_1200x630() {
  local url="$1" tmp
  tmp="$(mktemp)"
  curl -fsSL "${url}" -o "${tmp}" || { rm -f "${tmp}"; fail "could not download ${url}"; }
  file "${tmp}" | grep -q '1200 x 630' || { rm -f "${tmp}"; fail "${url} is not a 1200x630 PNG"; }
  rm -f "${tmp}"
  echo "    1200x630 PNG: ${url}"
}

verify_host() {
  local pkg="$1"
  local base="https://hexdocs.pm/${pkg}"
  local card="${base}/assets/rs-social-card.png"

  echo "==> OG/asset resolution for ${pkg}"

  # advertise<->resolve loop: the published page must advertise the og:image we
  # expect, and that URL must actually resolve.
  local remote_readme og_url
  remote_readme="$(curl -fsSL "${base}/readme.html")" || fail "cannot fetch ${base}/readme.html"
  og_url="$(printf '%s' "${remote_readme}" \
    | grep -oE 'og:image"[[:space:]]*content="[^"]*"' | head -1 \
    | sed -E 's/.*content="([^"]*)"/\1/')"
  [[ "${og_url}" == "${card}" ]] \
    || fail "${pkg}: published og:image (${og_url:-none}) != expected ${card}"

  assert_url_200 "${card}" "image/png"
  assert_png_1200x630 "${card}"
  assert_url_200 "${base}/assets/logo.svg" "image/svg"
  assert_url_200 "${base}/assets/favicon.svg" "image/svg"

  echo "check_docs_published.sh: ${pkg} OG/asset resolution OK"
}

verify_host "rulestead"
verify_host "rulestead_admin"

echo "check_docs_published.sh: published docs gates passed${RELEASE_VERSION:+ for ${RELEASE_VERSION}}"
