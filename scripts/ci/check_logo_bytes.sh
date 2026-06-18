#!/usr/bin/env bash
# D-10: Tarball logo-bytes CI assertion.
#
# Asserts that the core package tarball contains REAL SVG bytes for
# brandbook/assets/logo/rs-mark.svg — not a 0-byte or 13-byte dangling-symlink
# text file. This gate must run before any `mix hex.publish` so a broken or
# non-materialised symlink fails the build, not production.
#
# ORDERING NOTE: this gate passes ONLY after plan 05 adds the
# `brandbook/assets/logo/*.svg` glob to core `files:`. Until then it is expected
# to fail — that is intentional. The failure proves the manifest is not yet wired.
#
# Pattern mirrors scripts/ci/check_package_whitelist.sh (same RULESTEAD_REPO
# root resolution and mix hex.build + tar inspection idiom).
#
# Usage: bash scripts/ci/check_logo_bytes.sh
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

core_output="$(mktemp)"
trap 'rm -f "${core_output}"' EXIT

(
  cd "${RULESTEAD_REPO}/rulestead"
  mix hex.build
) | tee "${core_output}"

core_tarball="$(grep -Eo 'Saved to [^[:space:]]+' "${core_output}" | tail -1 | awk '{print $3}')"

if [[ -z "${core_tarball}" ]]; then
  echo "check_logo_bytes.sh: failed to detect tarball name from hex.build output" >&2
  exit 1
fi

# Extract the logo SVG from the tarball and assert it contains real SVG bytes.
# A dangling symlink produces a 0-byte or 13-byte text file; real bytes contain
# the SVG root element with the mark's canonical viewBox attribute.
extracted="$(
  cd "${RULESTEAD_REPO}/rulestead"
  tar xOf "${core_tarball}" contents.tar.gz | tar xzO brandbook/assets/logo/rs-mark.svg
)" || {
  echo "check_logo_bytes.sh: brandbook/assets/logo/rs-mark.svg not found in tarball — broken symlink or missing files: glob?" >&2
  exit 1
}

if ! echo "${extracted}" | grep -q 'viewBox="0 0 62 62"'; then
  echo "check_logo_bytes.sh: logo SVG missing/empty in tarball — broken symlink?" >&2
  exit 1
fi

echo "check_logo_bytes.sh: logo SVG bytes verified in tarball"
