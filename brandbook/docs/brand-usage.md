# Brand Token Usage

## Check script

Run from repo root:

    python3 scripts/check_brand_tokens.py

The script reads `brandbook/tokens.json` (`admin_css_mapping.light`) and compares each `--rs-*` value against Block 1 (`.rs-shell, [data-rulestead]`) of `rulestead_admin/priv/static/css/rulestead_admin.css`. It uses the same comment-strip + brace-walk algorithm as `check_synced_pair.py`.

**Expected Phase 96 output (exit 1 — intentional):**

```
BRAND TOKEN DRIFT DETECTED
  --rs-accent: tokens.json=#9b5931  css=#9a3f12
  --rs-critical: tokens.json=#B44949  css=#b91c1c
  --rs-error: tokens.json=#B44949  css=#b91c1c
  --rs-primary: tokens.json=#3A6F8F  css=#2563eb
  --rs-primary-hover: tokens.json=#2d5f7c  css=#1d4ed8
  --rs-success: tokens.json=#2d7753  css=#15803d
  --rs-warning: tokens.json=#8f601a  css=#b45309
```

**Expected Phase 98 output (exit 0 — after re-skin):**

```
BRAND TOKENS SYNCED (37 tokens)
```

## Intentional CI failure (Phase 96 → Phase 98)

The token drift check **intentionally exits 1** against the current admin CSS. This is by design — it proves the guard mechanism works before Phase 98 re-skins the admin CSS to make it pass.

**Do NOT fix this failure by:**
- Removing `check_brand_tokens.py` from `scripts/ci/lint.sh`
- Editing `rulestead_admin.css` in Phase 96 or Phase 97

Phase 98 re-skins `rulestead_admin.css` Blocks 1–4 to match the mineral canonicals in `brandbook/tokens.json`. That is the correct fix.

## Synced-pair rule

`rulestead_admin.css` has four cascade blocks:

| Block | Selector | Theme |
|-------|----------|-------|
| Block 1 | `.rs-shell, [data-rulestead]` | Light (explicit default) |
| Block 2 | `@media (prefers-color-scheme: dark)` | Dark (system preference) |
| Block 3 | `[data-theme="dark"]` | Dark (explicit pin) |
| Block 4 | `[data-theme="light"]` | Light (explicit pin) |

**Blocks 1 and 4 are a SYNCED PAIR** (light values — must be byte-identical).
**Blocks 2 and 3 are a SYNCED PAIR** (dark values — must be byte-identical).

When you edit a token value in one block of a pair, you **MUST update the partner block** to the same value before committing. Phase 98 must update both Block 1 and Block 4 for light changes, and both Block 2 and Block 3 for dark changes.

Run the synced-pair guard to verify dark blocks are in sync:

    python3 scripts/check_synced_pair.py

This check is composable with `check_brand_tokens.py` — both are wired into `scripts/ci/lint.sh`.

## Adding a new token

**Step 1 — Decide invariant vs. variant.**

- **Invariant** tokens do not vary by theme (font families, spacing, radius, control heights, z-index, motion durations). Add to the `:root` block in `rulestead_admin.css` and `tokens.css`. Add an entry in the `invariant` group in `tokens.json`.
- **Variant** (color) tokens differ between light and dark. Add to all four cascade blocks in `rulestead_admin.css` and to the corresponding light/dark block in `tokens.css`. Add entries in both the `light` and `dark` groups in `tokens.json`.

**Step 2 — Add to tokens.json.**

Add the token as a DTCG 2025.10 leaf (`$value`, optional `$type`, optional `$description`) under the appropriate group.

**Step 3 — Update `admin_css_mapping`.**

If the new token is a hex-literal variant, add it to `admin_css_mapping.light` and/or `admin_css_mapping.dark` in `tokens.json`. Do NOT add `var()` or `rgba()` tokens — the drift check does string comparison only.

**Step 4 — Verify.**

Run `python3 scripts/check_brand_tokens.py` to confirm the new token is detected if its CSS value does not yet match.

## Admin CSS cross-reference

[`rulestead_admin/priv/static/css/rulestead_admin.css`](../../rulestead_admin/priv/static/css/rulestead_admin.css) — the four cascade blocks plus the invariant `:root` block. Block 1 (`.rs-shell, [data-rulestead]`, approximately lines 224–303) is the `check_brand_tokens.py` comparison target. Blocks 1 and 4 are the light synced pair; Blocks 2 and 3 are the dark synced pair.
