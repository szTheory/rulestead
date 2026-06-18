#!/usr/bin/env bash
# Phase 126 visual-render gate — automates 126-UAT checks 2 & 3 (core + admin
# "visual render") with zero human UAT.
#
# RATIONALE: HexDocs is a STATIC ExDoc site. The human checks ("logo loads with
# no 404, favicon resolves, sidebar/links tinted Stead Blue, dark mode applies
# via body.dark, og:image points to the right host") reduce to deterministic
# filesystem + HTML facts:
#   * "no 404" == every asset the generated HTML references exists on disk under
#     doc/ (the exact bytes the CDN will serve).
#   * "Stead Blue tint / dark mode" == the injected <style> carries the
#     --main Stead-Blue value plus a body.dark{} block that re-defines it.
#   * "parity" == core and admin inject a byte-identical palette block.
# Literal rendered pixel colour is ExDoc applying our CSS vars — out of scope for
# this tier (no headless browser); the vars + selectors being present is the
# contract we own.
#
# Pattern mirrors scripts/ci/check_logo_bytes.sh (RULESTEAD_REPO resolution,
# set -euo pipefail, explicit pass/fail echoes). Self-contained: builds docs for
# each package so it is correct regardless of prior lane state.
#
# Usage: bash scripts/ci/check_docs_render.sh
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

fail() {
  echo "check_docs_render.sh: $*" >&2
  exit 1
}

# Extract the injected palette <style> block (the one carrying searchBarFocusColor)
# from a generated page. Used for the core<->admin parity assertion.
extract_palette() {
  awk '
    /<style>/ { buf=""; cap=1 }
    cap       { buf = buf $0 "\n" }
    /<\/style>/ {
      if (cap && buf ~ /searchBarFocusColor/) { printf "%s", buf; exit }
      cap=0
    }
  ' "$1"
}

# Per-package render assertions.
#   $1 = package dir (rulestead | rulestead_admin)
#   $2 = expected og:image host segment (rulestead | rulestead_admin)
check_package() {
  local pkg="$1" og_pkg="$2"
  local pkg_path="${RULESTEAD_REPO}/${pkg}"
  local doc="${pkg_path}/doc"
  local readme="${doc}/readme.html"

  echo "==> building docs for ${pkg}"
  (
    cd "${pkg_path}"
    mix deps.get >/dev/null
    mix docs >/dev/null
  )

  [[ -f "${readme}" ]] || fail "${pkg}: ${readme} not generated"

  # 1. No-404: every assets/* reference across every generated page must resolve
  #    to a real file under doc/ (page URLs are doc-root relative).
  local ref
  while IFS= read -r ref; do
    [[ -z "${ref}" ]] && continue
    [[ -e "${doc}/${ref}" ]] || fail "${pkg}: HTML references ${ref} but ${doc}/${ref} is missing (would 404)"
  done < <(grep -rhoE '(href|src)="assets/[^"#?]*"' "${doc}"/*.html \
             | sed -E 's/.*="(assets\/[^"]*)"/\1/' | sort -u)
  echo "    ${pkg}: referenced assets all resolve (no 404)"

  # 2. Logo + favicon are wired (the brand front door).
  grep -qE '<img[^>]*src="assets/logo\.svg"' "${readme}" \
    || fail "${pkg}: logo <img src=assets/logo.svg> not found in readme.html"
  grep -qE '<link[^>]*rel="icon"[^>]*href="assets/favicon\.svg"' "${readme}" \
    || fail "${pkg}: favicon <link rel=icon href=assets/favicon.svg> not found in readme.html"
  echo "    ${pkg}: logo + favicon wired"

  # 3. Stead Blue (#3A6F8F) tint present in the injected palette.
  grep -qE -- '--main:[[:space:]]+hsl\(203, 42%, 39%\)' "${readme}" \
    || fail "${pkg}: Stead Blue --main: hsl(203, 42%, 39%) not present in injected style"
  grep -qE -- '--searchBarFocusColor:[[:space:]]*#3A6F8F' "${readme}" \
    || fail "${pkg}: --searchBarFocusColor: #3A6F8F not present in injected style"
  echo "    ${pkg}: Stead Blue tint present"

  # 4. Dark mode wired via body.dark re-defining the palette.
  grep -qE -- 'body\.dark[[:space:]]*\{' "${readme}" \
    || fail "${pkg}: body.dark { } block not present (dark mode not wired)"
  grep -qE -- '--main:[[:space:]]+hsl\(202, 29%, 49%\)' "${readme}" \
    || fail "${pkg}: dark-mode --main value not present in body.dark palette"
  echo "    ${pkg}: dark mode (body.dark) wired"

  # 5. og:image advertises the correct host AND the advertised raster exists on
  #    disk at 1200x630 (so the post-publish CDN URL will resolve).
  grep -qE "og:image\"[[:space:]]*content=\"https://hexdocs\.pm/${og_pkg}/assets/rs-social-card\.png\"" "${readme}" \
    || fail "${pkg}: og:image does not advertise https://hexdocs.pm/${og_pkg}/assets/rs-social-card.png"
  [[ -f "${doc}/assets/rs-social-card.png" ]] \
    || fail "${pkg}: advertised og:image asset doc/assets/rs-social-card.png missing"
  file "${doc}/assets/rs-social-card.png" | grep -q '1200 x 630' \
    || fail "${pkg}: og:image rs-social-card.png is not 1200x630"
  echo "    ${pkg}: og:image host correct + 1200x630 raster on disk"

  echo "check_docs_render.sh: ${pkg} render gate OK"
}

check_package "rulestead" "rulestead"
check_package "rulestead_admin" "rulestead_admin"

# 6. Parity (126-UAT check 3): the injected palette block must be byte-identical
#    across both packages — the only sanctioned difference is the og:* meta host,
#    which lives outside this block.
core_palette="$(extract_palette "${RULESTEAD_REPO}/rulestead/doc/readme.html")"
admin_palette="$(extract_palette "${RULESTEAD_REPO}/rulestead_admin/doc/readme.html")"
[[ -n "${core_palette}" ]] || fail "could not extract core palette block for parity check"
if [[ "${core_palette}" != "${admin_palette}" ]]; then
  echo "check_docs_render.sh: core vs admin palette diverged:" >&2
  diff <(printf '%s' "${core_palette}") <(printf '%s' "${admin_palette}") >&2 || true
  exit 1
fi
echo "check_docs_render.sh: core<->admin palette parity OK"

echo "check_docs_render.sh: all docs render gates passed"
