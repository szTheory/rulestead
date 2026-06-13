#!/bin/bash
# render_studio.sh — Phase 102 Tournament Studio headless Chrome render helper
#
# THROWAWAY Phase 102 tooling. Not a brand deliverable.
# Rendered PNGs are git-ignored (.planning/phases/102-.../studio-render-*.png).
#
# Chrome binary: /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
#
# Usage:
#   bash render_studio.sh
#
# Output:
#   .planning/phases/102-logo-delta-audit-tournament-studio/studio-render-YYYYMMDD-HHMMSS.png
#
# Notes:
#   - Marks in 102-studio.html are outlined <path> elements (no font dependency)
#   - Chrome is launched in the background; a poll loop waits for the output file
#   - Chrome PID is killed after the file appears (prevents lingering processes)
#   - --force-device-scale-factor=2 for retina-quality output

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STUDIO_HTML="${SCRIPT_DIR}/102-studio.html"
OUT_PNG="${SCRIPT_DIR}/studio-render-$(date +%Y%m%d-%H%M%S).png"
TMPDIR_CHROME="$(mktemp -d)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --no-first-run \
  --user-data-dir="$TMPDIR_CHROME" \
  --hide-scrollbars \
  --force-color-profile=srgb \
  --default-background-color=FFFFFFFF \
  --force-device-scale-factor=2 \
  --virtual-time-budget=10000 \
  --screenshot="$OUT_PNG" \
  --window-size=1600,900 \
  "file://$STUDIO_HTML" 2>/dev/null &

CHROME_PID=$!

# Poll for the output file (up to 15 seconds)
for i in $(seq 1 30); do
  [ -f "$OUT_PNG" ] && break
  sleep 0.5
done

# Clean up Chrome process and temp dir
kill "$CHROME_PID" 2>/dev/null || true
rm -rf "$TMPDIR_CHROME"

if [ -f "$OUT_PNG" ]; then
  echo "Rendered: $OUT_PNG"
else
  echo "ERROR: render failed — $OUT_PNG not created"
  exit 1
fi
