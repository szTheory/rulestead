#!/bin/bash
# render_a_sheet.sh — Phase 103 Axis A scratch render (copies the Phase 102 harness pattern).
# THROWAWAY tooling. Rendered PNGs are git-ignored.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHEET_HTML="${SCRIPT_DIR}/round2-sheet.html"
OUT_PNG="${SCRIPT_DIR}/round2-render-$(date +%Y%m%d-%H%M%S).png"
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
  --window-size=1100,2450 \
  "file://$SHEET_HTML" 2>/dev/null &

CHROME_PID=$!
for i in $(seq 1 30); do
  [ -f "$OUT_PNG" ] && break
  sleep 0.5
done
kill "$CHROME_PID" 2>/dev/null || true
rm -rf "$TMPDIR_CHROME"

if [ -f "$OUT_PNG" ]; then
  echo "Rendered: $OUT_PNG"
else
  echo "ERROR: render failed — $OUT_PNG not created"
  exit 1
fi
