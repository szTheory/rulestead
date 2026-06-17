# Phase 122: Browser/Demo/Integration Determinism - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 3 (all modifications, no new files)
**Analogs found:** 3 / 3

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `examples/demo/frontend/playwright.config.ts` | config | request-response | Itself (21 lines, fully read) | exact — surgical key additions only |
| `scripts/demo/verify.sh` | utility/script | event-driven (failure branch) | `scripts/demo/smoke.sh` (failure-output idiom) | role-match |
| `.github/workflows/ci.yml` | config (CI YAML) | request-response | Existing `integration-placeholder` job + `lint` job (`if: always()` step) | exact — same job, appending one step |

---

## Pattern Assignments

### `examples/demo/frontend/playwright.config.ts` (config, test runner)

**Analog:** Itself — file is 21 lines and was read in full. No other Playwright config exists in the repo.

**Current file shape** (lines 1-21):
```typescript
import { defineConfig } from "@playwright/test";

const frontendUrl = process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000";
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: false,
  use: {
    baseURL: frontendUrl,
    trace: "on-first-retry",
  },
  metadata: {
    frontendUrl,
    backendUrl,
  },
});
```

**D-01 target state** — executor MUST produce exactly this:
```typescript
import { defineConfig } from "@playwright/test";

const frontendUrl = process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000";
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: false,
  reporter: [["html", { open: "never" }], ["list"]],
  use: {
    baseURL: frontendUrl,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  metadata: {
    frontendUrl,
    backendUrl,
  },
});
```

**Executor notes:**
- `reporter:` is inserted at line 13 (after `fullyParallel`, before `use:`). This is the idiomatic position in `defineConfig` — top-level options before the `use:` block.
- Inside `use:`, `trace:` is changed in place (line 15). `screenshot:` and `video:` are inserted after it.
- `metadata:` block stays untouched (lines 17-20).
- Lines 3-4 (env reads) and line 10 (`retries: 0`) are UNCHANGED. Do not add `webServer:`.
- Double-quoted strings are used throughout the current file — maintain that style. The RESEARCH.md target uses double-quotes consistently.

---

### `scripts/demo/verify.sh` (utility/script, failure-output ergonomics)

**Analog:** `scripts/demo/smoke.sh` — specifically the `|| { dump_failure_logs; exit 1 }` idiom used at lines 69-72, 76-78, 80-83, 92-95 of `smoke.sh`.

**House failure-output pattern from `smoke.sh`** (lines 69-72):
```bash
docker compose up -d --build || {
  dump_failure_logs
  exit 1
}
```

And at lines 76-83:
```bash
wait_for_health backend 60 || {
  dump_failure_logs
  exit 1
}
wait_for_health frontend 60 || {
  dump_failure_logs
  exit 1
}
```

**`echo` style from `smoke.sh`** — bracketed prefix, stderr for errors (lines 17-21 of smoke.sh):
```bash
dump_failure_logs() {
  echo "[smoke] dumping compose logs after failure" >&2
  docker compose ps >&2 || true
  docker compose logs --no-color backend frontend postgres redis >&2 || true
}
```

**Existing `verify.sh` failure site** (lines 38-42 — the section to replace):
```bash
echo "[verify] running FleetDesk adoption lab browser proof (kill switch + journeys)"
(
  cd examples/demo/frontend
  CI=true DEMO_BACKEND_URL="$DEMO_BACKEND_URL" DEMO_FRONTEND_URL="$DEMO_FRONTEND_URL" npm run test:e2e
)
```

**D-04 target replacement** (lines 38-42 become lines 38-51):
```bash
echo "[verify] running FleetDesk adoption lab browser proof (kill switch + journeys)"
(
  cd examples/demo/frontend
  CI=true DEMO_BACKEND_URL="$DEMO_BACKEND_URL" DEMO_FRONTEND_URL="$DEMO_FRONTEND_URL" npm run test:e2e
) || {
  echo ""
  echo "[verify] Playwright failed."
  echo "  Frontend URL : ${DEMO_FRONTEND_URL}"
  echo "  Backend URL  : ${DEMO_BACKEND_URL}"
  echo "  Artifacts    : examples/demo/frontend/playwright-report/"
  echo "                 examples/demo/frontend/test-results/"
  echo "  Local report : cd examples/demo/frontend && npx playwright show-report"
  echo "  Local rerun  : cd examples/demo/frontend && npm run test:e2e"
  echo ""
  exit 1
}
```

**Executor notes:**
- The subshell `( ... )` is preserved verbatim. Only `|| { ... }` is appended — this is the house idiom from `smoke.sh`.
- `exit 1` inside the `|| {}` block propagates to the outer shell, which fires the existing `trap cleanup EXIT` (line 14 of `verify.sh`) — Docker teardown is not disrupted.
- The success echo at line 44 (`echo "[verify] compose smoke and browser proof passed"`) is UNCHANGED.
- `[verify]` prefix in brackets matches the script's existing echo style (lines 16, 20, 27, 38).
- Artifact paths are repo-root-relative (matching what D-05 uploads from `$GITHUB_WORKSPACE`).
- `verify.sh` uses `#!/usr/bin/env bash` + `set -euo pipefail` (lines 1-2) — the `|| {}` form is safe with `set -e` because the `exit 1` inside the block re-raises the failure explicitly.

---

### `.github/workflows/ci.yml` (config/CI YAML, artifact upload step)

**Analog 1 — Pinned third-party action style.** The repo's convention is established by every existing `uses:` line in `ci.yml`:

```yaml
uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
uses: erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1
uses: dorny/paths-filter@6852f92c20ea7fd3b0c25de3b5112db3a98da050 # v3
uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
uses: actions/cache/restore@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
uses: actions/cache/save@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
```

Convention: `uses: owner/action@<40-char-sha> # vX.Y.Z` — full commit SHA, version tag in inline comment, no spaces around `@`.

**Analog 2 — `if:` on a step within the same job.** The `lint` job has a step with `if: always()` (lines 125-129):
```yaml
      - name: Save Dialyzer PLT
        if: always()
        uses: actions/cache/save@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
        with:
          path: rulestead/priv/plts
          key: ${{ runner.os }}-plt-${{ hashFiles('rulestead/mix.lock', '.tool-versions') }}
```

Step shape: `- name:` → `if:` → `uses:` → `with:`. Same indentation (6 spaces for step keys, 8 spaces for `with:` sub-keys) throughout `ci.yml`.

**Existing `integration-placeholder` job** (lines 188-200) where the step is appended:
```yaml
  integration-placeholder:
    name: integration (FleetDesk adoption lab)
    needs: changes
    if: needs.changes.outputs.docs-only != 'true'
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
      - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
        with:
          node-version: "22"
      - name: Run FleetDesk adoption lab (compose + Playwright)
        run: scripts/ci/integration_placeholder.sh
```

**D-05 step to append after line 200:**
```yaml
      - name: Upload Playwright report and test artifacts
        if: failure()
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2
        with:
          name: playwright-report-${{ github.run_id }}
          path: |
            examples/demo/frontend/playwright-report/
            examples/demo/frontend/test-results/
          retention-days: 7
          if-no-files-found: ignore
```

**Executor notes:**
- Indentation: 6 spaces for `- name:`, `if:`, `uses:`, `with:`. 10 spaces for `with:` sub-keys (`name:`, `path:`, `retention-days:`, `if-no-files-found:`). This matches the existing job's step indentation exactly.
- The SHA `ea165f8d65b6e75b540449e92b4886f43607fa02` corresponds to `actions/upload-artifact@v4.6.2`. The RESEARCH.md flags this as MEDIUM confidence (WebFetch-sourced). The implementer should verify: `curl -s https://api.github.com/repos/actions/upload-artifact/releases/latest | jq '.tag_name'` to confirm v4.6.2 is still latest stable before committing. If a newer v4.x exists, use its SHA instead, keeping the `# vX.Y.Z` comment.
- `if: failure()` is the correct condition: D-01 sets `retain-on-failure` for all three artifact types, so meaningful artifacts only exist when the job is already failing. Using `if: always()` would upload empty/trivial artifacts on green runs.
- `if-no-files-found: ignore` prevents this conditional step from itself failing if the Playwright run was cancelled before the reporter created its directory.
- The step goes AFTER the `Run FleetDesk adoption lab` step — appended as the last step in `integration-placeholder`. It must not be inserted inside the `adopter-contract` job that begins at line 202.
- After the edit, run `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` to confirm no YAML parse error.

---

## Shared Patterns

### Failure branch: `|| { ...; exit 1 }` idiom
**Source:** `scripts/demo/smoke.sh` lines 69-72, 76-83, 92-95
**Apply to:** `verify.sh` D-04 failure block only
```bash
<command> || {
  <diagnostic output>
  exit 1
}
```
`exit 1` inside the block re-raises to the outer shell; the outer shell's `trap cleanup EXIT` then handles teardown. Never replace a trap — append with `|| {}` instead.

### Bracketed prefix `echo` style
**Source:** `scripts/demo/smoke.sh` lines 17, 66, 91, 97, 108, 117, 128; `scripts/demo/verify.sh` lines 16, 20, 27, 38, 44
**Apply to:** All new `echo` lines in the D-04 failure block
```bash
echo "[verify] <message>"
```
Failure detail lines may omit the bracket prefix and use indentation instead (as in the D-04 target — `echo "  Frontend URL : ..."`) to visually distinguish diagnostic lines from the narrative log.

### Pinned-action `uses:` convention
**Source:** `.github/workflows/ci.yml` — all existing `uses:` lines
**Apply to:** The D-05 `upload-artifact` step
```
uses: owner/action@<40-char-sha> # vX.Y.Z
```
No floating tags (e.g., `@v4` alone is not acceptable). SHA must be exactly 40 hex characters.

### Conditional step with `if:` in CI job
**Source:** `.github/workflows/ci.yml` `lint` job, lines 125-129 (`if: always()`)
**Apply to:** D-05 upload step (`if: failure()`)
```yaml
      - name: <step name>
        if: <condition>
        uses: <action>
        with:
          <key>: <value>
```

---

## No Analog Found

None — all three modified files have clear analogs in the codebase (two are self-analogs; one draws from a sibling script).

---

## Metadata

**Analog search scope:** `examples/demo/frontend/`, `scripts/demo/`, `.github/workflows/`
**Files read:** 5 (`playwright.config.ts`, `verify.sh`, `smoke.sh`, `ci.yml` in two non-overlapping ranges)
**Pattern extraction date:** 2026-06-16
