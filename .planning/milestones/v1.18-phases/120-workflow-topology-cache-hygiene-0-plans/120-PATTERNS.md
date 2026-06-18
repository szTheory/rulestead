# Phase 120: Workflow Topology + Cache Hygiene - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4 modified (`ci.yml`, `scripts/ci/test.sh` + `lint.sh`, `MAINTAINING.md`)
**Analogs found:** 7 / 7 (every planned change mirrors an in-repo precedent)

> EDIT-ONLY phase. No new files. Each change below points at an EXISTING
> in-repo analog to replicate verbatim in shape. No new conventions are
> introduced. All analogs are in the same files being edited, so "copy from"
> means "mirror the adjacent established block," not "import from elsewhere."

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` — `release_gate.needs` + Evaluate gate (D-03) | config (workflow gate) | event-driven (needs fan-in) | `mounted-proof` wiring in same file (`ci.yml:302,313,321-323,332`) | exact |
| `.github/workflows/ci.yml` — `test` restore-keys (D-05) | config (cache) | batch (build cache) | matrix-scoped restore-key `ci.yml:176` (the line kept) | exact (in-block) |
| `.github/workflows/ci.yml` — `lint` + PLT cache keys (D-06) | config (cache) | batch (build cache) | single-package cache `path:` scope `ci.yml:106-108,115`; `lint.sh:6` cd-scope | exact |
| `.github/workflows/ci.yml` — `openfeature-companion` cache key (D-06, discretionary) | config (cache) | batch (build cache) | single-package cache `path:` scope `ci.yml:254-256` | exact |
| `scripts/ci/test.sh` / `lint.sh` — observability (D-08) | utility (CI script) | transform (log/summary emit) | lane banner `test.sh:500-502`; failure microcopy `test.sh:67-90` | role+flow match |
| `MAINTAINING.md` — cache-busting rules (D-07) | docs | request-response (reference) | "CI caching" section `MAINTAINING.md:54-63` | exact |
| `MAINTAINING.md` — branch-protection reconciliation (D-11) | docs | request-response (reference) | "Branch protection settings" section `MAINTAINING.md:32-52` | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` — wire `openfeature-companion` into `release_gate` (D-03)

**Role:** config (required-check aggregation) · **Data flow:** event-driven (`needs` fan-in)
**Analog:** the `mounted-proof` job already wired through `release_gate` in the SAME file. Mirror it exactly; the only difference is the job id and the `changes` output key.

**Analog 1 — add to `needs:` list** (`ci.yml:296-302`). Append a new list item mirroring `- mounted-proof` (line 302):
```yaml
  release_gate:
    name: release_gate
    needs:
      - changes
      - lint
      - test
      - integration-placeholder
      - adopter-contract
      - mounted-proof
      # D-03 ADD: - openfeature-companion
```

**Analog 2 — result var + not-relevant→success transform** (`ci.yml:311-313` for bracket-accessor form; `ci.yml:321-323` for the transform). The hyphenated job id REQUIRES bracket syntax exactly like `needs['mounted-proof']` and `needs['integration-placeholder']`:
```bash
# ci.yml:313 — bracket accessor precedent for hyphenated job id
mounted_proof_result="${{ needs['mounted-proof'].result }}"

# ci.yml:321-323 — the EXACT transform template to mirror
if [[ "${{ needs.changes.outputs.mounted-proof }}" != "true" && "${mounted_proof_result}" == "skipped" ]]; then
  mounted_proof_result="success"
fi
```
D-03 mirror (planner writes, shape locked in CONTEXT line 25 / RESEARCH 167-172):
```bash
openfeature_result="${{ needs['openfeature-companion'].result }}"
if [[ "${{ needs.changes.outputs.openfeature-companion }}" != "true" && "${openfeature_result}" == "skipped" ]]; then
  openfeature_result="success"
fi
```

**Analog 3 — pass the pair into the gate script** (`ci.yml:325-332`). Mirror the final `"mounted-proof=${mounted_proof_result}"` argument (line 332):
```bash
scripts/ci/release_gate.sh \
  --skip-phase7 \
  "changes=${{ needs.changes.result }}" \
  "lint=${lint_result}" \
  "test=${test_result}" \
  "integration-placeholder=${integration_result}" \
  "adopter-contract=${adopter_result}" \
  "mounted-proof=${mounted_proof_result}"
  # D-03 ADD: "openfeature-companion=${openfeature_result}"
```

**No change to `scripts/ci/release_gate.sh`** — its loop (`release_gate.sh:29-37`) accepts arbitrary `job=result` pairs and `exit 1`s on any non-`success`. Adding a pair needs zero script edit:
```bash
# release_gate.sh:29-37 [VERIFIED — do not edit]
for pair in "$@"; do
  job_name="${pair%%=*}"
  job_result="${pair#*=}"
  if [[ "${job_result}" != "success" ]]; then
    echo "${job_name} did not succeed: ${job_result}" >&2
    exit 1
  fi
done
```

**The job it gates is already defined** (`ci.yml:238-261`): `openfeature-companion` runs only `if: needs.changes.outputs.openfeature-companion == 'true'` (line 241), and the `changes` job already emits that output (`ci.yml:33,75-81`). No new filter, no new job.

---

### `.github/workflows/ci.yml` — remove cross-lane `test` restore-key (D-05)

**Role:** config (cache) · **Data flow:** batch (Mix `_build`/`deps` restore)
**Analog:** the matrix-scoped restore-key that STAYS (`ci.yml:176`) is itself the correctness-safe pattern. The edit deletes only the over-broad sibling beneath it.

**Current block** (`ci.yml:174-177`):
```yaml
          key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-   # KEEP (line 176 — matrix-scoped, correctness-safe)
            ${{ runner.os }}-mix-                                          # REMOVE (line 177 — cross-lane, restores incompatible OTP/Elixir _build)
```
The kept line 176 is the template: a restore-key must stay scoped to the same OS+OTP+Elixir lane it was built under. Beam files are not portable across OTP majors (26 vs 28), so line 177 risks a stale/incompatible `_build`. Per D-04, prefer a known-good rebuild over a possibly-stale restore.

---

### `.github/workflows/ci.yml` — scope `lint` + PLT cache keys to `rulestead/mix.lock` (D-06)

**Role:** config (cache) · **Data flow:** batch (Mix/PLT restore)
**Analog 1 — single-package `path:` scope already established in the same job** (`ci.yml:106-108`, `ci.yml:115`). The cache `path:` proves these lanes build ONLY `rulestead/`:
```yaml
# ci.yml:106-108 — lint cache path (core package only)
          path: |
            rulestead/deps
            rulestead/_build
# ci.yml:115 — PLT cache path (core package only)
          path: rulestead/priv/plts
```
**Analog 2 — the lane script confirms the build scope** (`lint.sh:6`):
```bash
cd "${RULESTEAD_REPO}/rulestead"   # lint builds ONLY rulestead/
```
Because no sibling package's deps affect the lint/PLT build, scoping the key's `hashFiles` from repo-wide `**/mix.lock` (which globs all FOUR lockfiles — `rulestead/`, `rulestead_admin/`, `open_feature_rulestead/`, `examples/demo/backend/`) down to `rulestead/mix.lock` is correctness-safe.

**Current keys to scope** (`ci.yml:109`, `ci.yml:116`, `ci.yml:124`):
```yaml
# ci.yml:109 — lint deps/build key
          key: ${{ runner.os }}-lint-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}
# ci.yml:116 — PLT restore key
          key: ${{ runner.os }}-plt-${{ hashFiles('**/mix.lock', '.tool-versions') }}
# ci.yml:124 — PLT save key (if: always() — KEEP the always-save behavior)
          key: ${{ runner.os }}-plt-${{ hashFiles('**/mix.lock', '.tool-versions') }}
```
Target shape (RESEARCH 191-192): replace `'**/mix.lock'` with `'rulestead/mix.lock'` in all three. The PLT restore key (116) and save key (124) MUST stay byte-identical to each other (save must match restore) — change both or neither. Keep the `if: always()` on the save step (`ci.yml:120`).

**Discretionary (D-06, correctness-safe):** `openfeature-companion` builds only `open_feature_rulestead/` (cache `path:` `ci.yml:254-256`; script `test.sh:124-128` cds into `open_feature_rulestead`), so its key (`ci.yml:257`) MAY be narrowed to `open_feature_rulestead/mix.lock`.

**DO NOT narrow** `test` (`ci.yml:174`), `adopter-contract` (`ci.yml:232`), or `mounted-proof` (`ci.yml:284`) to a single lockfile — those lanes build BOTH sibling packages (cache `path:` lists `rulestead/` AND `rulestead_admin/`). Single-lock scoping there causes under-invalidation. If narrowed at all, enumerate both built locks: `hashFiles('rulestead/mix.lock','rulestead_admin/mix.lock','.tool-versions')`; otherwise leave `**/mix.lock` (both are compliant — Open Question 1).

---

### `scripts/ci/test.sh` / `scripts/ci/lint.sh` — observability output (D-08)

**Role:** utility (CI lane script) · **Data flow:** transform (emit log / `$GITHUB_STEP_SUMMARY`)
**Analog 1 — existing version banner reusing `MATRIX_ELIXIR`/`MATRIX_OTP`** (`test.sh:5-6`, `test.sh:500-502`). This is the established observability pattern; extend it, do not replace it:
```bash
# test.sh:5-6 — env already read (passed from ci.yml:158-159)
MATRIX_ELIXIR="${MATRIX_ELIXIR:-}"
MATRIX_OTP="${MATRIX_OTP:-}"

# test.sh:500-502 — existing lane banner (the echo template to mirror)
if [[ -n "${MATRIX_ELIXIR}" || -n "${MATRIX_OTP}" ]]; then
  echo "Running test lane for Elixir ${MATRIX_ELIXIR:-unknown} / OTP ${MATRIX_OTP:-unknown}"
fi
```
**Analog 2 — copy-pasteable rerun microcopy** already shipped throughout the failure-guidance functions (`test.sh:67-90`). Mirror this style for the version/cache summary lines:
```bash
# test.sh:74 — exact "Rerun:" microcopy pattern to mirror
echo "Rerun: RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
```
D-08 additions (scripts-first, no new infra):
- Echo `mix --version` / `elixir --version` alongside the existing `MATRIX_ELIXIR`/`MATRIX_OTP` banner.
- Surface cache hit/miss by giving each `actions/cache` step in `ci.yml` an `id:` and echoing `steps.<id>.outputs.cache-hit` into `$GITHUB_STEP_SUMMARY` (the `cache-hit` output is built into `actions/cache` — do not hand-roll).
- Add a copy-pasteable matrix-specific rerun line for the failed lane, mirroring the `echo "Rerun: ..."` style above.
- Prefer writing summary lines from `scripts/ci/*.sh` (scripts-first per CLAUDE.md:35) or a thin `echo "..." >> "$GITHUB_STEP_SUMMARY"` workflow step. No new reporting system.

---

### `MAINTAINING.md` — per-cache busting rules (D-07)

**Role:** docs · **Analog:** the existing "CI caching" section (`MAINTAINING.md:54-63`) is the home and the structural template. Extend its bullet structure with a one-line busting rule per cache:
```markdown
## CI caching

`ci.yml` restores and saves bounded Mix caches to keep lint and test lanes fast:

- **Mix deps/build** — `rulestead/` (and sibling packages where the job needs them)
  keyed by `mix.lock` plus OTP/Elixir when matrixed.
- **Dialyzer PLTs** — `rulestead/priv/plts/` uses restore → build-if-miss → save in
  the lint job (PLTs are gitignored locally; CI owns the warm cache).

Cache keys intentionally exclude `.planning/`, `prompts/`, and guide-only edits.
```
Add one busting-rule line per cache (which key component change forces a rebuild): e.g., lint/PLT bust on `rulestead/mix.lock` or `.tool-versions` change; test matrix busts on lockfile, OTP, or Elixir change. Planner may instead/also place a one-line comment above each cache `key:` in `ci.yml` (inline-comment precedent: the job-id contract block at `ci.yml:1-3`). Either location satisfies D-07 (Open Question 2 — discretion granted).

---

### `MAINTAINING.md` — branch-protection reconciliation (D-11, docs only)

**Role:** docs · **Analog:** the existing "Branch protection settings" section (`MAINTAINING.md:32-52`) already documents the triad; reconcile its wording to the exact intended state. NO `gh api` write.
```markdown
## Branch protection settings
Document these settings exactly on `main`:
- Required status checks:
  - `release_gate` (aggregates lint, test, integration-placeholder,
    adopter contract, mounted companion proof from ci.yml)
  - `Validate PR title`
  - `dependency-review`
- `actionlint` is not a required status check because it is path-filtered
  and would sit Pending on non-workflow pull requests.
```
The documented triad is already correct (`release_gate`, `Validate PR title`, `dependency-review`, with `actionlint` explicitly excluded). D-11 adds a note that live `main` currently returns `Branch not protected` (404) and that these settings must be applied manually by a maintainer — no live repo-settings write in this milestone.

## Shared Patterns

### Required-check aggregation (the cross-cutting D-01/D-02/D-03 invariant)
**Source:** `ci.yml:294-332` (`release_gate`) + `release_gate.sh:29-37`
**Apply to:** every gate edit
- One always-triggered workflow (no `on:` `paths:` filters — `ci.yml:6-16`); selectivity lives in job `if:` (`ci.yml:93,129,184,241,266`) + the aggregate skipped→success transform (`ci.yml:315-323`), never in workflow path filters (Pending trap).
- Hyphenated job ids MUST use bracket accessors: `needs['mounted-proof'].result` (`ci.yml:313`), `needs['integration-placeholder'].result` (`ci.yml:311`). Validate with `actionlint`.
- Job ids are an immutable contract (`ci.yml:1-3`): D-03 references the existing `openfeature-companion` id; rename nothing.

### Cache correctness-over-sharing (the D-04/D-05/D-06 invariant)
**Source:** cache `path:` blocks vs lane build scope
**Apply to:** every cache key/restore-key edit
- A key is only narrowable to a single lockfile when the lane's cache `path:` (and its script's `cd`) builds a single package: lint `path:` `ci.yml:106-108` + `lint.sh:6` → `rulestead/`; openfeature `path:` `ci.yml:254-256` → `open_feature_rulestead/`.
- Multi-package lanes (test, adopter, mounted — `path:` lists both `rulestead/` and `rulestead_admin/`) keep both locks or `**/mix.lock`.
- Restore-keys stay lane/lane-version-scoped (`ci.yml:176` kept; `ci.yml:177` removed).
- A cache `save` key must equal its `restore` key (PLT `ci.yml:116` == `ci.yml:124`); change both together.

### Scripts-first observability + failure microcopy
**Source:** `test.sh:500-502` (version banner), `test.sh:67-90` (rerun guidance)
**Apply to:** all D-08 output
- Reuse `MATRIX_ELIXIR`/`MATRIX_OTP` (`test.sh:5-6`, fed by `ci.yml:158-159`); do not rename or add new env.
- Emit a copy-pasteable rerun command per lane, mirroring `echo "Rerun: ..."` (`test.sh:74`).
- Use `actions/cache`'s built-in `cache-hit` step output; do not hand-roll cache-state tracking.

### Supply-chain non-regression (D-09/D-10 — PRESERVE)
**Source:** `publish-hex.yml`, `.github/dependabot.yml`, all `uses:` SHA pins in `ci.yml`, `permissions:` `ci.yml:22-25`
**Apply to:** every plan — assert no diff
- Do NOT touch `publish-hex.yml`, `verify-published-release.yml`, `dependabot.yml`.
- Do NOT re-pin or version-bump any `uses:` action (all full-SHA pinned, e.g. `ci.yml:36,99,104`).
- Do NOT broaden `permissions:` (`ci.yml:22-25` = `contents/actions/checks: read`).
- Verify via `git diff --name-only` that no protected surface changed.

## No Analog Found

None. Every Phase 120 change mirrors an existing in-repo precedent (CONTEXT/RESEARCH constraint: "minimal edits to a working, audited system; every decision mirrors an existing proven pattern"). The planner should NOT fall back to RESEARCH.md generic examples for any change — in-repo analogs exist for all seven.

## Metadata

**Analog search scope:** `.github/workflows/ci.yml`, `scripts/ci/{release_gate,lint,test}.sh`, `MAINTAINING.md`
**Files scanned:** 5 (all read directly; line numbers verified against current source)
**Lockfile count confirmed:** FOUR (`rulestead/`, `rulestead_admin/`, `open_feature_rulestead/`, `examples/demo/backend/`) — matches RESEARCH drift finding; strengthens D-06.
**Skills directory:** none (`.claude/skills` / `.agents/skills` absent)
**Pattern extraction date:** 2026-06-16
