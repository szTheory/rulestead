# Brand Asset Budget

Phase 100 documents the live budget that `scripts/ci/lint.sh` already enforces.
Do not change these numbers in docs without changing the script in the same review.

| Asset type | Path | Limit | Enforced by |
|------------|------|-------|-------------|
| Logo SVG | `brandbook/assets/logo/*.svg` | 20 KB / 20480 bytes each | `scripts/ci/lint.sh` |
| Specimen SVG | `brandbook/assets/specimens/*.svg` | 50 KB / 51200 bytes each | `scripts/ci/lint.sh` |

## Policy

- Commit source SVGs for logos and specimens. Keep them text-diffable and reviewable.
- Do not embed raster data in SVGs. `base64`, `<image>`, and script content are not allowed in brand SVGs.
- Keep accessibility metadata in committed SVGs: `role="img"`, `title`, `desc`, and `aria-labelledby`.
- Do not commit font binaries (`.woff`, `.woff2`, `.ttf`, `.otf`) for the brand stack. Use the documented Sora, Inter, and IBM Plex Mono font stacks.
- Raster brand exports are generated on demand. The only raster exceptions allowed by policy are favicon exports (`favicon.ico`, `favicon.png`, `apple-touch-icon.png`) when they are generated from committed logo source and reviewed explicitly.
- Root `.gitattributes` marks source assets as text and binary export formats as binary so large assets are visible in review.

## Verification

Run the full lint gate from repo root:

```bash
bash scripts/ci/lint.sh
```

For a narrow size check:

```bash
shopt -s nullglob
for f in brandbook/assets/logo/*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  [ "$size" -le 20480 ] || { echo "logo over budget: $f $size"; exit 1; }
done
for f in brandbook/assets/specimens/*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  [ "$size" -le 51200 ] || { echo "specimen over budget: $f $size"; exit 1; }
done
echo "SVG SIZE BUDGET OK"
```

If an asset exceeds budget, simplify the SVG, remove redundant metadata, split the specimen,
or move generated exports out of the repository. Do not raise the budget for one-off exports.
