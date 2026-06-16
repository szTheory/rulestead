#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"

cd "${RULESTEAD_REPO}/rulestead"

elixir_ver="$(elixir --version 2>/dev/null || true)"
mix_ver="$(mix --version 2>/dev/null || true)"

echo "Running lint lane"
[[ -n "${elixir_ver}" ]] && echo "${elixir_ver}"
[[ -n "${mix_ver}" ]] && echo "${mix_ver}"
true

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  elixir_ver_line="$(printf '%s\n' "${elixir_ver}" | head -1)"
  : "${elixir_ver_line:=elixir not found}"
  : "${mix_ver:=mix not found}"
  {
    echo "## Lint lane"
    echo ""
    echo "**Versions:** ${elixir_ver_line} / ${mix_ver}"
    echo ""
    echo "**Rerun:** \`bash scripts/ci/lint.sh\`"
  } >> "${GITHUB_STEP_SUMMARY}"
fi

mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
mix compile --no-optional-deps --warnings-as-errors
RULESTEAD_REPO="${RULESTEAD_REPO}" "${RULESTEAD_REPO}/scripts/ci/check_package_whitelist.sh"
mix dialyzer --format github

# Restore CWD to repo root — guard scripts use relative paths (rulestead_admin/..., brandbook/...)
cd "${RULESTEAD_REPO}"

# Synced-pair guard: Block 2/3 (dark) must be byte-identical in rulestead_admin.css
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"

# Brand token drift: tokens.json admin_css_mapping vs the re-skinned admin CSS.
# Green after Phase 98; guards future palette drift.
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"

# Tokens.css mirror drift: the brandbook/tokens.css reference mirror (light + dark blocks)
# must stay in sync with tokens.json admin_css_mapping. Green now; guards against drift
# after future token edits.
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"

# Static contrast targets from the brand palette and semantic foreground pairs.
python3 "${RULESTEAD_REPO}/scripts/check_contrast.py"

# Generated HTML brand book drift and size budget.
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"

# Logo asset drift: copied admin/demo assets must stay byte-identical with
# brandbook sources, and the real shell must retain the theme-aware classes.
python3 "${RULESTEAD_REPO}/scripts/check_logo_assets.py"

# Admin foundations: documented breakpoints, reduced-motion floor, and focus markers.
python3 "${RULESTEAD_REPO}/scripts/check_admin_foundations.py"

# Design-system evidence posture: generated screenshots stay artifacts and
# forbidden visual-baseline tooling stays out of the normal guard chain.
python3 "${RULESTEAD_REPO}/scripts/check_design_system_evidence.py"

# SVG size budget: logo <=20KB, specimens <=50KB.
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
