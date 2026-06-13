# brandbook/

Source-controlled brand system for Rulestead v1.14+.

## Directory Index

| Path | Purpose | Status |
|------|---------|--------|
| [`brand-book.md`](brand-book.md) | Canonical brand book: identity, messaging, palette, typography, voice, layout, and guardrails. | Active |
| [index.html](index.html) | Generated, source-controlled HTML brand book for browser review. Regenerate with `scripts/gen_brandbook_html.py`; guarded by `scripts/check_brandbook_html.py`. | Active |
| [`tokens.json`](tokens.json) | Machine-readable design tokens in DTCG 2025.10 shape. | Active |
| [`tokens.css`](tokens.css) | Hand-authored CSS custom-property mirror for the shipped `--rs-*` token shape. | Active |
| [`COPY.md`](COPY.md) | Ready-to-paste GitHub, Hex.pm, README, landing, feature, and szTheory suite copy. | Active |
| [`VOICE.md`](VOICE.md) | Voice and microcopy reference for empty, error, and success states. | Active |
| [`RELEASE-TEMPLATE.md`](RELEASE-TEMPLATE.md) | Release-announcement scaffold in the maintainer tone. | Active |
| [`BUDGET.md`](BUDGET.md) | Generated HTML and SVG budget policy plus binary-export guardrails. | Active |
| [`docs/brand-usage.md`](docs/brand-usage.md) | Contributor guide for token sync, admin re-skin edits, and guard scripts. | Active |
| [`assets/logo/`](assets/logo/) | Final logo and mark SVG system: wordmark, tagline secondary, d-sigil mark, mono, favicon, social cards, light/dark variants. | Active |
| [`assets/specimens/`](assets/specimens/) | Reproducible SVG specimens for palette, typography, components, code block, README header, and social card. | Active |

## Admin Cascade Cross-Reference

[`../rulestead_admin/priv/static/css/rulestead_admin.css`](../rulestead_admin/priv/static/css/rulestead_admin.css)
contains the four shipped admin cascade blocks. Block 1 (`.rs-shell, [data-rulestead]`) and
Block 4 (`[data-theme="light"]`) are the light synced pair. Block 2 (`@media
(prefers-color-scheme: dark)`) and Block 3 (`[data-theme="dark"]`) are the dark synced pair.

`scripts/check_brand_tokens.py` compares `tokens.json` admin mappings against the admin CSS.
`scripts/check_synced_pair.py` keeps the paired cascade blocks byte-identical by token value.

## Maintenance Commands

Run from the repo root:

```bash
python3 scripts/gen_brandbook_html.py
python3 scripts/check_brandbook_html.py
python3 scripts/check_synced_pair.py
python3 scripts/check_brand_tokens.py
python3 scripts/check_tokens_css.py
bash scripts/ci/lint.sh
```

Expected current token output:

```text
BRAND TOKENS SYNCED (68 tokens)
```

## Source of Truth

The canonical brand book lives here: [`brand-book.md`](brand-book.md).
`../prompts/rulestead-brand-book.md` is a pointer only and should not be edited for brand changes.

`index.html` is generated from canonical brandbook sources and should not be
edited by hand. Change the source markdown, tokens, budget policy, or SVG assets, then run
`python3 scripts/gen_brandbook_html.py` and `python3 scripts/check_brandbook_html.py` from
the repo root.
