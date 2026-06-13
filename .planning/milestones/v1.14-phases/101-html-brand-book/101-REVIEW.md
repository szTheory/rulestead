---
phase: 101-html-brand-book
review: "101"
status: clean
depth: standard
files_reviewed: 7
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
resolved_findings:
  warning: 3
  commit: ce91124
reviewed_at: 2026-06-06
resolved_at: 2026-06-06
---

# Phase 101 Code Review

Standard-depth review of the scoped Phase 101 HTML brand book files.

## Scope Reviewed

- `scripts/gen_brandbook_html.py`
- `scripts/check_brandbook_html.py`
- `scripts/ci/lint.sh`
- `brandbook/index.html`
- `brandbook/BUDGET.md`
- `brandbook/README.md`
- `examples/demo/frontend/tests/brandbook.spec.ts`

## Resolution Status

All review warnings were fixed in `ce91124` (`fix(101): resolve brandbook review warnings`).
See `101-REVIEW-FIX.md` for verification evidence.

## Original Findings

### WR-101-01 - Warning - Wrapped ordered-list items render as broken/restarted lists

References:
- `scripts/gen_brandbook_html.py:260`
- `brandbook/index.html:1050`
- `brandbook/index.html:1051`
- `brandbook/index.html:1052`

`render_markdown()` only treats lines matching `^\d+\.\s+` as ordered-list items and stops when it sees an indented continuation line. The source guide's six-step "New-Contributor Path" list has wrapped continuation lines, so the generated HTML closes the list after step 3, emits continuation text as standalone paragraphs, and restarts later items as separate one-item ordered lists.

Impact: the visible maintenance guidance is harder to follow, and assistive technology receives incorrect list semantics. The Playwright spec only checks visibility, so this regression can pass browser evidence.

Recommended fix: teach the markdown renderer to append indented continuation lines to the active list item, or add a focused generated-HTML assertion for the six-step list before relying on this source excerpt.

### WR-101-02 - Warning - Markdown hrefs can become unsafe active links and the checker skips all schemes

References:
- `scripts/gen_brandbook_html.py:152`
- `scripts/gen_brandbook_html.py:155`
- `scripts/check_brandbook_html.py:146`
- `scripts/check_brandbook_html.py:149`

Markdown links from source docs are escaped, but their `href` values are not scheme-restricted. The checker then skips any URI with a scheme, which means future source text such as `javascript:...`, `data:...`, or an unintended `file:` link would pass the static link guard.

Impact: this weakens the file:// safety posture for a generated HTML artifact. The current generated page does not contain those unsafe hrefs, but the guard would not catch them if introduced later.

Recommended fix: explicitly reject `javascript:`, `data:`, and `file:` hrefs in both the generator/checker path, and require local non-fragment links to resolve inside the repository root.

### WR-101-03 - Warning - Inline SVG safety checks miss event-handler and active-URI vectors

References:
- `scripts/gen_brandbook_html.py:97`
- `scripts/gen_brandbook_html.py:390`
- `scripts/gen_brandbook_html.py:439`
- `scripts/check_brandbook_html.py:47`

The SVG guard blocks a narrow marker list (`base64`, `<image`, `<script`, `<foreignObject>`), but it does not reject SVG event attributes (`onload=`, `onclick=`), active URI values (`href="javascript:..."`, `xlink:href="javascript:..."`), or CSS `url(javascript:...)` patterns before inlining the asset.

Impact: committed SVGs reviewed in this pass do not contain those patterns, but a future SVG could pass the guard and become executable inline markup in `brandbook/index.html`.

Recommended fix: parse SVG attributes with an allowlist or add explicit reject rules for event attributes and unsafe URI schemes before ID prefixing; mirror the same assertions in `scripts/check_brandbook_html.py`.

## Tests Reviewed

- `python3 -m py_compile scripts/gen_brandbook_html.py scripts/check_brandbook_html.py` - exit 0.
- `python3 scripts/check_brandbook_html.py` - exit 0; `BRANDBOOK HTML SYNCED (133765 bytes)`.
- `cd examples/demo/frontend && npm run test:e2e -- brandbook.spec.ts` - exit 0; Playwright reported `6 passed`.
- `bash scripts/ci/lint.sh` - exit 0; final outputs included `BRANDBOOK HTML SYNCED (133765 bytes)` and `SVG SIZE BUDGET OK`.

## Residual Risks

- `scripts/check_brandbook_html.py` maps `.doc-excerpt` link bases by render order rather than by a durable source marker. This is acceptable for the current output, but future excerpt additions should add an explicit source attribute to avoid false positives or false negatives.
- The custom Markdown renderer intentionally supports a small subset. More source-doc constructs should either gain tests before use or move through a real parser if the stdlib-only constraint changes.
- The Playwright brandbook spec is intentionally targeted and not wired into `scripts/ci/lint.sh`; browser coverage remains a manual/narrow evidence lane.
