#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}/rulestead"
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
mix compile --no-optional-deps --warnings-as-errors
RULESTEAD_REPO="${RULESTEAD_REPO}" "${RULESTEAD_REPO}/scripts/ci/check_package_whitelist.sh"
mix dialyzer --format github

# Synced-pair guard: Block 2/3 (dark) must be byte-identical in rulestead_admin.css
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"

# Brand token drift: tokens.json admin_css_mapping.light vs rulestead_admin.css Block 1.
# Intentionally exits 1 until Phase 98 re-skins rulestead_admin.css to the mineral palette.
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"

# Tokens.css mirror drift: the brandbook/tokens.css reference mirror (light + dark blocks)
# must stay in sync with tokens.json admin_css_mapping. Green now; guards against drift
# during Phase 98's re-skin.
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"

# SVG size budget: logo ≤20KB, specimens ≤50KB. No-op when dirs don't exist (Phases 97/99).
shopt -s nullglob
for f in "${RULESTEAD_REPO}/brandbook/assets/logo/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 20480 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 20480)"
    exit 1
  fi
done
for f in "${RULESTEAD_REPO}/brandbook/assets/specimens/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 51200 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 51200)"
    exit 1
  fi
done
echo "SVG SIZE BUDGET OK"
