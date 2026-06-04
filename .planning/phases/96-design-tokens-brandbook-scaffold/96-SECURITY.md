---
phase: 96
slug: design-tokens-brandbook-scaffold
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-04
---

# Phase 96 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Phase 96 created design-token config files (DTCG `tokens.json` + `tokens.css`
reference mirror), relocated and reconciled `brandbook/brand-book.md`, and added
a Python stdlib drift-check script (`scripts/check_brand_tokens.py`) plus an
additive `scripts/ci/lint.sh` extension. No network surface, no runtime
execution, no secrets. The threat register was authored at plan time across all
four PLAN files; this audit verified each mitigation exists in the
implementation.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo checkout → committed JSON/CSS | Source-controlled config; no network surface; no runtime execution | Brand palette hex literals + DTCG scalars (public) |
| git working tree → committed history | `git mv` preserves rename history; pointer stub prevents dangling refs | Brand-book markdown content |
| brand-book.md §12 hex content → downstream phases | Hex values locked by D-11 sign-off; encoded, not re-derived | Canonical hex palette (Phase 98 drift-check input) |
| check_brand_tokens.py → tokens.json + rulestead_admin.css | Reads two local files; no network; `json.load` raises on malformed JSON | Token mapping values; exit code is the signal |
| lint.sh → CI runner environment | Bash under `set -euo pipefail` on Ubuntu 24.04; no new packages | CI pass/fail signal |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-96-01 | Tampering | tokens.json admin_css_mapping | mitigate | Maps only hex-literal tokens (37 light + 31 dark; 0 `var()`/`rgba()`/shadow composites) so Phase 98 drift check cannot false-green | closed |
| T-96-02 | Tampering | tokens.css scope | mitigate | `:root` block contains no `--rs-primary` and no `#` color literal; scope comment present (tokens.css:14, 23–104) | closed |
| T-96-03 | Repudiation | admin_css_mapping.light values | accept | 37 values verbatim from D-11 signed-off palette; provenance via git + 95-PALETTE-RECONCILIATION.md §8 (see Accepted Risks) | closed |
| T-96-04 | Information Disclosure | tokens.json committed to repo | accept | No secrets; credential-pattern scan = 0 matches; all leaves are public hex/DTCG scalars (see Accepted Risks) | closed |
| T-96-05 | Denial of Service | malformed JSON in tokens.json | mitigate | `json.load()` (check_brand_tokens.py:50) raises JSONDecodeError → non-zero exit | closed |
| T-96-06 | Tampering | §12 hex replacements | mitigate | 5 old generic hexes absent; 5 new canonicals present in brand-book.md (`#2F7D57`/`#B44949` appear only in intentional Gap-2 White/RT notes) | closed |
| T-96-07 | Tampering | §8 tagline | mitigate | "Runtime decisions, made clear." count = 3 in brand-book.md (≥1) | closed |
| T-96-08 | Repudiation | git mv history | mitigate | `git log --follow brandbook/brand-book.md` = 3 commits (≥2; history preserved) | closed |
| T-96-09 | Tampering | binary blob in brandbook/ | mitigate | `file` reports brand-book.md, README.md, brand-usage.md as UTF-8 text; no binary content | closed |
| T-96-10 | Tampering | check_brand_tokens.py selector search | mitigate | `re.sub(r"/\*.*?\*/", "", raw, flags=re.S)` (line 54) precedes all `css.find()` calls | closed |
| T-96-11 | Denial of Service | check_brand_tokens.py silent no-op | mitigate | None path returns explicit error + `return 1` (lines 57–59); live run exits 1, not silent 0 | closed |
| T-96-12 | Tampering | lint.sh existing lines modified | mitigate | `#!/usr/bin/env bash` on line 1; `set -euo pipefail` count 1; `mix dialyzer` in head-16; additive-only, 15 original lines preserved | closed |
| T-96-13 | Denial of Service | SVG size-budget loop under set -euo pipefail | mitigate | `shopt -s nullglob` (lint.sh:25); `wc -c` used; 0 `stat` usage | closed |
| T-96-14 | Tampering | supply-chain import in check_brand_tokens.py | mitigate | Exactly 3 stdlib imports: `sys`, `re`, `json` (lines 11–13); no third-party | closed |
| T-96-SC | Tampering | npm/pip/cargo installs | mitigate | Zero external packages; `tech-stack.added: []` in all summaries; stdlib-only confirmed | closed |
| T-96-15 | Tampering | verification masking exit 1 as pass | mitigate | `BRAND_EXIT=$?` captured + `assert "$BRAND_EXIT" -eq 1`; live run confirms exit 1 is the asserted state | closed |
| T-96-16 | Repudiation | docs updated without full SC verification | mitigate | Wave 3 ordering (SC assertions before doc update); 96-04-SUMMARY documents SC-1..SC-5 ran before STATE/ROADMAP edits | closed |
| T-96-17 | Tampering | ROADMAP.md plans list left as Phase 95 placeholder | mitigate | ROADMAP.md Phase 96 block lists actual 96-01..96-04-PLAN entries with wave structure; `4/4` progress | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-96-01 | T-96-03 | The 37 `admin_css_mapping.light` values are encoded verbatim from the D-11 signed-off palette. Provenance is auditable via git history and 95-PALETTE-RECONCILIATION.md §8. Verified: `git log --follow brandbook/brand-book.md` = 3 commits; hex values trace to the reconciliation table. | gsd-security-auditor (verified) | 2026-06-04 |
| AR-96-02 | T-96-04 | `tokens.json` is committed to the repo by design. No secrets present; all values are public brand palette colors (hex literals) and DTCG dimension/shadow scalars. Verified: credential-pattern scan (api key / secret / password / token / bearer / private key) returned zero matches; all `admin_css_mapping` leaves are hex literals. | gsd-security-auditor (verified) | 2026-06-04 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-04 | 17 | 17 | 0 | gsd-security-auditor (ASVS L1) |

No unregistered threat flags surfaced. All four SUMMARY "Threat Surface Scan" sections report no new attack surface.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-04
