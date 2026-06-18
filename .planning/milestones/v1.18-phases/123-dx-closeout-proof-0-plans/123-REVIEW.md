---
phase: 123-dx-closeout-proof-0-plans
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - MAINTAINING.md
  - brandbook/admin-foundations-contract.md
  - rulestead/test/rulestead/release_contract_test.exs
  - scripts/check_admin_foundations.py
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 123: Code Review Report

**Reviewed:** 2026-06-17T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files from the phase 123 DX closeout were reviewed: the MAINTAINING.md CI Failure Triage table addition, the D-14 guard assertions in release_contract_test.exs, the CONTRACT_PATH repoint in check_admin_foundations.py, and the restored brandbook/admin-foundations-contract.md.

The contract file is sound: YAML frontmatter is valid (confirmed via python3 yaml.safe_load), all nine required `## ` section headers are present, and the path repoint in check_admin_foundations.py correctly targets `brandbook/admin-foundations-contract.md`. The test module stays `async: true` and has no DB dependency.

Two warnings were found:

1. The triage table column header declares "ci.yml job id" for three rows whose jobs do not live in ci.yml, and one of those rows uses the workflow-level job _name_ rather than the YAML job _id_ key. This will mislead a maintainer trying to rerun or reference a job by id.

2. The "adopter-contract" triage row's "Exact rerun" command (`cd rulestead && mix verify.adopter`) omits the `deps.get` and DB-setup steps that the actual CI lane runs, so the label "Exact rerun" is not exact.

Two informational findings note assertion precision weaknesses in the D-14 guard (the "mounted-proof" and "openfeature-companion" pins pass against the CI-caching table even if the triage table itself were deleted) and a latent error-masking risk in check_admin_foundations.py's file-read helper.

## Warnings

### WR-01: Triage table column "ci.yml job id" is wrong for three rows; one row uses job name not job id

**File:** `MAINTAINING.md:127`

**Issue:** The triage table header is `| Lane (ci.yml job id) | ...`. Three of the nine rows refer to jobs that are not in `ci.yml` at all — they live in separate workflow files — and one of those rows additionally uses the job _name_ rather than the YAML job _id_ key:

| Triage row label | Where the job actually lives | Actual YAML job `id` |
|---|---|---|
| `publish-hex` | `publish-hex.yml` | No single job called `publish-hex`; closest run jobs are `publish-core` / `publish-admin` |
| `verify-published-release` | `verify-published-release.yml` | `verify-published-release` (correct label, wrong workflow attribution) |
| `repo-hygiene` | `repo-hygiene.yml` | `hygiene-check` (label in table matches job `name:`, not job `id:`) |

The table description also says "Rows are in `release_gate` pipeline order", which is accurate for the first six rows (`lint` through `openfeature-companion`) but inaccurate for the trailing three (`publish-hex`, `verify-published-release`, `repo-hygiene`) which are not in the `release_gate` pipeline at all.

A maintainer searching for a failing `repo-hygiene` job id in ci.yml will not find it; a maintainer trying to reference `hygiene-check` from the docs will not find the term.

**Fix:** Either split the table into two — "ci.yml lanes (in release_gate order)" and "post-merge / scheduled workflows" — or change the column header to `Lane` / `Job label` and add a `Workflow file` column. For `repo-hygiene`, the row's lane label should document that the YAML job id is `hygiene-check` inside `repo-hygiene.yml`, or use `hygiene-check` as the lane label. Minimal one-line fix for the header:

```markdown
| Lane | Workflow file | What failed | ...
|---|---|---|...
| `lint` | `ci.yml` | ...
| `publish-hex` | `publish-hex.yml` | ...
| `repo-hygiene` (`hygiene-check`) | `repo-hygiene.yml` | ...
```

---

### WR-02: "Exact rerun" for adopter-contract lane is missing deps.get and DB setup

**File:** `MAINTAINING.md:132`

**Issue:** The "Exact rerun" cell for the `adopter-contract` row is:

```
cd rulestead && mix verify.adopter
```

The actual CI lane (`adopter-contract` job, ci.yml line 253) runs:

```
RULESTEAD_TEST_SCOPE=post_ga_band_closure scripts/ci/test.sh
```

That shell function (`run_post_ga_band_closure` in `scripts/ci/test.sh`) executes `deps.get` for both sibling packages and prepares the test database before calling `mix verify.phase82` (which `mix verify.adopter` delegates to). In a fresh checkout or CI-cold environment, `cd rulestead && mix verify.adopter` will fail with dependency or database errors before reaching the actual contract tests, making "Exact rerun" misleading for someone encountering this lane cold.

This is distinct from the command-ladder note on line 114, which describes `mix verify.adopter` as the alias; the triage table explicitly labels its rerun as "Exact".

**Fix:** Change the "Exact rerun" cell to match what CI actually does, or note the prerequisite:

```markdown
`RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh` (handles deps.get and DB setup); or `cd rulestead && mix deps.get && mix ecto.create && mix ecto.migrate && mix verify.adopter` for manual rerun
```

---

## Info

### IN-01: D-14 "mounted-proof" and "openfeature-companion" pins are not specific to the triage table

**File:** `rulestead/test/rulestead/release_contract_test.exs:295-296`

**Issue:** Two of the five new D-14 assertions pin strings that also appear in the unrelated CI Caching table (the `## CI caching` section above the triage table):

- `assert maintaining =~ "mounted-proof"` passes if the CI caching row (line 74) is present, even if the entire `## CI Failure Triage` section is deleted.
- `assert maintaining =~ "openfeature-companion"` has the same weakness (appears at line 73 in the caching table).

The other three new assertions (`"## CI Failure Triage"`, `"RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh"`, `"release-trust gate"`) are specific enough that they will fail if the triage table is removed or materially changed.

The weak assertions are not tautological — they would fail if both the caching table _and_ the triage table references were removed — but they do not guard specifically that the job ids appear in the triage table as intended by the D-14 design.

**Fix:** If precise triage-table pinning is desired, assert against the full triage row format that is unique to the table, e.g.:

```elixir
assert maintaining =~ "| `mounted-proof` |"
assert maintaining =~ "| `openfeature-companion` |"
```

These match the backtick-in-pipe-cell format of the triage table and will not be satisfied by the caching table prose.

---

### IN-02: check_admin_foundations.py read_text() silently swallows non-FileNotFoundError OS errors

**File:** `scripts/check_admin_foundations.py:61-65`

**Issue:** The `read_text` helper catches only `FileNotFoundError`:

```python
def read_text(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        return None
```

A `PermissionError` (or any other `OSError` subclass) on the CSS or contract file will propagate as an unhandled exception rather than being reported as a structured failure message. This is inconsistent with the deliberate soft-fail design for `FileNotFoundError` and would produce a raw Python traceback in CI stdout instead of the `ADMIN FOUNDATION DRIFT DETECTED` output format that `lint.sh` expects to parse.

This is pre-existing behavior, not introduced in phase 123, but the contract-path relocation (the phase 123 change) makes the file-missing path more relevant — if the `brandbook/` directory is unreadable due to a permissions issue the error will surface as an exception rather than a structured lint failure.

**Fix:**

```python
def read_text(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        return None
    except OSError as exc:
        # PermissionError, etc. — surface as structured failure rather than raw traceback
        return None  # caller appends f"missing CSS/contract file: {path}" via existing None check
```

Or more precisely, distinguish "missing" from "unreadable" in the failure message by re-raising only unexpected errors:

```python
def read_text(path):
    try:
        return path.read_text()
    except (FileNotFoundError, PermissionError):
        return None
```

---

_Reviewed: 2026-06-17T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
