# Brand Token Usage

This guide explains how the brand tokens stay synchronized with the shipped admin cascade.
Run all commands from the repository root.

## Current Guard State

Phase 98 re-skinned the admin CSS to the mineral palette. The token drift check is now green:

```bash
python3 scripts/check_brand_tokens.py
```

Expected output:

```text
BRAND TOKENS SYNCED (68 tokens)
```

The script reads `brandbook/tokens.json` (`admin_css_mapping.light` and
`admin_css_mapping.dark`) and compares each mapped `--rs-*` value against
`rulestead_admin/priv/static/css/rulestead_admin.css`. It uses the same comment-strip and
brace-walk approach as `check_synced_pair.py`.

## Synced-Pair Rule

`rulestead_admin.css` has four cascade blocks:

| Block | Selector | Theme |
|-------|----------|-------|
| Block 1 | `.rs-shell, [data-rulestead]` | Light explicit default |
| Block 2 | `@media (prefers-color-scheme: dark)` | Dark system preference |
| Block 3 | `[data-theme="dark"]` | Dark explicit pin |
| Block 4 | `[data-theme="light"]` | Light explicit pin |

Blocks 1 and 4 are the light synced pair. Blocks 2 and 3 are the dark synced pair.

When you edit a token value in one block of a pair, update the partner block in the same
change. Then run:

```bash
python3 scripts/check_synced_pair.py
```

Expected output:

```text
SYNCED PAIR IDENTICAL (56 tokens)
SYNCED PAIR IDENTICAL (light: 57 tokens)
```

## New-Contributor Path

1. Read [`../brand-book.md`](../brand-book.md) for brand intent and usage policy.
2. Read [`../tokens.json`](../tokens.json) for canonical token values.
3. If the change is theme-insensitive, edit the invariant `:root` token in the admin CSS,
   `tokens.css`, and `tokens.json`.
4. If the change is color/theme-sensitive, edit all four admin cascade blocks plus the
   corresponding light/dark sections in `tokens.css` and `tokens.json`.
5. If the token is a hex-literal admin token, update `admin_css_mapping.light` and/or
   `admin_css_mapping.dark`.
6. Run the verification commands below before committing.

## Adding a New Token

Invariant tokens do not vary by theme: font families, spacing, radius, control heights,
z-index, and motion durations. Add them to the admin CSS `:root` block, `tokens.css`, and
the `invariant` group in `tokens.json`.

Variant tokens differ by theme. Add them to all four admin cascade blocks, the light/dark
sections in `tokens.css`, and the corresponding groups in `tokens.json`.

Only add plain hex-literal values to `admin_css_mapping`. Do not add `var()`, `rgba()`, or
computed values to the mapping because the drift check compares literal strings.

## Verification

Run the narrow guards:

```bash
python3 scripts/check_synced_pair.py
python3 scripts/check_brand_tokens.py
python3 scripts/check_tokens_css.py
```

Run the full scripts-first lint gate:

```bash
bash scripts/ci/lint.sh
```

The full lint gate includes the synced-pair guard, brand-token drift check, tokens.css mirror
check, and SVG size-budget loop.

## Admin CSS Cross-Reference

[`../../rulestead_admin/priv/static/css/rulestead_admin.css`](../../rulestead_admin/priv/static/css/rulestead_admin.css)
contains the four cascade blocks plus the invariant `:root` block. Block 1 is the primary
`check_brand_tokens.py` light comparison target; Block 3 is the dark comparison target.
