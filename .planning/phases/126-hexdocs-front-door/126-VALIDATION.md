---
phase: 126
slug: hexdocs-front-door
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 126 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase ships **docs/config + branding** — proof is ExDoc builds + shell/tarball
> assertions, not ExUnit deltas. The existing `release_contract_test.exs` must stay green.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExDoc build + shell assertions (no ExUnit deltas this phase) |
| **Config file** | `rulestead/mix.exs` `docs/0`, `rulestead_admin/mix.exs` `docs/0` |
| **Quick run command** | `cd rulestead && mix docs --warnings-as-errors` |
| **Full suite command** | `bash scripts/ci/contributor.sh` + `bash scripts/ci/check_package_whitelist.sh` |
| **Estimated runtime** | ~60–120 seconds (docs build + tarball inspect) |

---

## Sampling Rate

- **After every task commit:** Run `cd rulestead && mix docs --warnings-as-errors` (the autolink
  gate — catches the D-23 undefined-reference footguns fast; run in `rulestead_admin/` for admin tasks).
- **After every plan wave:** Run `mix hex.build` + the D-10 logo-bytes tarball assertion on the touched package.
- **Before `/gsd-verify-work`:** Both packages `mix docs --warnings-as-errors` green + `check_package_whitelist.sh`
  green + D-10 logo-bytes assertion green + `release_contract_test.exs` green.
- **Max feedback latency:** ~120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 126-DOC02 | TBD | TBD | DOC-02 | — | tarball ships real logo SVG bytes (no 404) | tarball assert | `cd rulestead && mix hex.build` → extract `brandbook/assets/logo/rs-mark.svg` → `grep -q 'viewBox="0 0 62 62"'` | ❌ W0 (D-10 script) | ⬜ pending |
| 126-DOC02b | TBD | TBD | DOC-02 | — | `brandbook/assets/logo` in `files:`; CI whitelist not tripped | CI gate | `bash scripts/ci/check_package_whitelist.sh` → "package whitelist checks passed" | ✅ | ⬜ pending |
| 126-DOC01 | TBD | TBD | DOC-01 | — | 6 module groups + 6 extras groups + funnel order | grep/AST + render | grep `rulestead/mix.exs` for 6 `groups_for_modules` + 6 `groups_for_extras` keys; `mix docs` → assert `why-rulestead` first Introduction extra | ✅ | ⬜ pending |
| 126-DOC01b | TBD | TBD | DOC-01 | — | no dangling module ref; autolink clean | autolink gate | `mix docs --warnings-as-errors` (zero undefined-ref) + assert `Rulestead.Rule` absent from `mix.exs` | ✅ | ⬜ pending |
| 126-DOC03 | TBD | TBD | DOC-03 | — | head-tag re-tints `--main*` + OG meta, no JS | grep | grep `mix.exs` `before_closing_head_tag` for `--main:`, `body.dark`, `og:image.*\.png`; assert no `<script>` / no custom stylesheet | ✅ | ⬜ pending |
| 126-DOC04 | TBD | TBD | DOC-04 | — | `why-rulestead.md` exists, renders, not a README copy | file + diff + render | `test -f guides/introduction/why-rulestead.md` + assert not byte-identical to README + first Introduction extra in sidebar | ❌ W0 (new file) | ⬜ pending |
| 126-DOC05 | TBD | TBD | DOC-05 | — | README hero + 5 clickable badges + `~> 1.0` | grep | grep `README.md` for `rs-wordmark-tagline.svg`, 5 badge `<a href>`s (hexpm/v, hex-docs, ci.yml, hexpm/l, elixir), `~> 1.0`; assert no `~> 0.1` | ✅ | ⬜ pending |
| 126-DOC05b | TBD | TBD | DOC-05 | — | social card rasterized to 1200×630 PNG | file + dimension | `test -f brandbook/assets/logo/rs-social-card.png` + assert 1200×630 | ❌ W0 (rasterize) | ⬜ pending |
| 126-DOC06 | TBD | TBD | DOC-06 | — | admin parity: logo/favicon/theming + real Router `@moduledoc` + flow guides | grep + autolink gate | grep `rulestead_admin/mix.exs` for logo/favicon/`before_closing_head_tag`/`admin-ui.md`/`explainability.md`/`Public Admin Seam`; assert `router.ex` not `@moduledoc false`; `cd rulestead_admin && mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 126-REG | TBD | TBD | (regression) | — | frozen contract unchanged | ExUnit | `release_contract_test.exs` green (both packages) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs are placeholders until the planner assigns plan/wave numbers.*

---

## Wave 0 Requirements

- [ ] `scripts/ci/` — D-10 logo-bytes tarball content assertion (extend `check_package_whitelist.sh` or a sibling script): build, extract `brandbook/assets/logo/rs-mark.svg`, assert real SVG bytes (`<svg ... viewBox="0 0 62 62">`), fail the build on a missing/dangling symlink.
- [ ] `guides/introduction/why-rulestead.md` — new positioning extra (DOC-04).
- [ ] `brandbook/assets/logo/rs-social-card.png` — rasterized 1200×630 social card (DOC-05; SVG is already pure `<path>`, so `npx @resvg/resvg-js` suffices — no flatten, no headless Chrome).
- [ ] No ExUnit additions; no framework install (ExDoc + existing CI present).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual brand pass (logo resolves, favicon shows, mineral tint in light+dark, on-brand focus ring, social-card unfurl) | DOC-02/03/05 | Rendered HexDocs + OG unfurl can't be fully asserted by shell; UI hint = yes (A3) | `cd rulestead && mix docs`, open `doc/index.html`: confirm logo loads (no 404), favicon, link/sidebar tint in light AND dark (toggle), focus ring on-brand AA, then preview the social card at 1200×630 |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify command or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the D-10 assertion script + the new-file/rasterize MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter (after planner maps task IDs)

**Approval:** pending
</content>
