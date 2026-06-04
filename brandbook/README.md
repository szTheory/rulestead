# brandbook/

Directory index for the Rulestead brand system (v1.14+).

| File | Purpose | Status |
|------|---------|--------|
| [`brand-book.md`](brand-book.md) | Canonical brand book — identity, palette, typography, voice | Active |
| [`tokens.json`](tokens.json) | Machine-readable design tokens (DTCG 2025.10) | Active |
| [`tokens.css`](tokens.css) | CSS custom-property reference mirror (`--rs-*` shape) | Active |
| [`docs/brand-usage.md`](docs/brand-usage.md) | Re-skin guide + `check_brand_tokens.py` usage | Active |

## Coming in later phases

- `assets/logo/` — Logo and mark SVGs (Phase 97)
- `VOICE.md` — Extended voice and copy guide (Phase 100)
- `RELEASE-TEMPLATE.md` — Release communication template (Phase 100)
- `BUDGET.md` — Brand asset budget and approval guide (Phase 100)

This `README.md` will be replaced with a full directory index in Phase 100.

## Admin cascade cross-reference

[`rulestead_admin/priv/static/css/rulestead_admin.css`](../rulestead_admin/priv/static/css/rulestead_admin.css) — four cascade blocks (Blocks 1–4) and the invariant `:root` block. Block 1 (`.rs-shell, [data-rulestead]`) is the `check_brand_tokens.py` comparison target.
