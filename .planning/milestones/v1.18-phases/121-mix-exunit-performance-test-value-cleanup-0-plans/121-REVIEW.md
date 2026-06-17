---
phase: 121-mix-exunit-performance-test-value-cleanup
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - rulestead/test/test_helper.exs
  - rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs
  - scripts/ci/test.sh
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 121: Code Review Report

**Reviewed:** 2026-06-16T00:00:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

This change set defers the dominant ~28s live-hex.pm smoke test behind a
default-excluded ExUnit tag (`:published_hex_smoke`), tags the test with an
explicit `timeout: 300_000`, and re-opts the proof back in inside the
`guarded_rollout_foundations` CI scope. The core efficiency goal is achieved:
the env-var → exclude wiring in `test_helper.exs` is correct and symmetric with
the pre-existing `install_integration` opt-in (that opt-in was extended, not
broken), and no blind retry was introduced — only the sanctioned explicit
timeout.

The substantive defect is in the CI re-inclusion path: the smoke test is
re-run with `run_mix` instead of `run_mix_logged`, so its output never lands in
the shared `${log_file}`. That silently disables the brand-new
`published_hex_smoke failure` categorization branch (WR-01). A second
robustness gap (WR-02) is that the smoke run is invoked redundantly through two
mechanisms (env var + `--include`) where only one is needed, and the test file
is executed twice in the same scope. Findings below are scoped to correctness
and robustness; none rise to BLOCKER.

## Warnings

### WR-01: Published-Hex smoke run bypasses the log file, defeating its own failure categorizer

**File:** `scripts/ci/test.sh:231-232` (categorizer at `scripts/ci/test.sh:201-216`)
**Issue:**
The new smoke invocation runs through `run_mix`, which does NOT `tee` output to
`${log_file}`:

```bash
if RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke \
  test/rulestead/mix/tasks/verify_release_publish_test.exs; then
```

Every other gated step in `run_guarded_rollout_foundations` uses
`run_mix_logged ... "${log_file}"`. Because the smoke step uses bare `run_mix`,
its stdout/stderr is never captured. On failure, `status=$?` is set correctly
(so the scope still fails — exit propagation is fine), but
`guarded_rollout_foundations_failure_category` greps `${log_file}` for the
string `"admin consumer fixture compiles against published Hex packages"` plus
an assertion marker. Since the smoke output is absent from the log, that branch
can never match. A genuine published-hex smoke failure is therefore
mis-categorized as `"unknown guarded-rollout-foundations failure"`, and the
carefully-authored `published_hex_smoke failure` guidance (hex.pm reachability
hint + targeted opt-in rerun command at lines 184-186) becomes dead/unreachable
code. This is a correctness defect in the new wiring: the diagnostic feature
added in this phase does not actually fire.

**Fix:** Route the smoke run through `run_mix_logged` so its output is captured,
and set the opt-in env var inline for the captured subshell:

```bash
if RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix_logged rulestead "${log_file}" \
  test --include published_hex_smoke \
  test/rulestead/mix/tasks/verify_release_publish_test.exs; then
```

Note `run_mix_logged` uses `cd "${RULESTEAD_REPO}/${package_dir}"` in a
subshell, so the leading env-var assignment must be confirmed to propagate into
that subshell. Setting it on the same command line (as above) is inherited by
the subshell ExUnit process, but verify against the actual `run_mix_logged`
definition (lines 40-51) before merging.

### WR-02: Smoke proof opted in via two redundant mechanisms and runs the file twice

**File:** `scripts/ci/test.sh:225-232`
**Issue:**
The opt-in is expressed twice for the same run: `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`
(which makes `test_helper.exs` omit the tag from the exclude set) AND
`--include published_hex_smoke` on the CLI. Either alone is sufficient — the env
var path removes the exclusion entirely, and ExUnit `--include` overrides an
exclude for matching tests. Carrying both is harmless but obscures intent and
invites future drift (e.g., someone removes the env var assuming `--include`
covers it, or vice versa).

More importantly, `verify_release_publish_test.exs` is executed twice within
this single scope: once at lines 225-230 (default run, smoke excluded) and again
at lines 231-232 (smoke-only re-include). The second run re-executes the entire
file, not just the tagged test, because no filter narrows it to the single
`published_hex_smoke` test beyond `--include`. With `--include`, ExUnit runs all
non-excluded tests PLUS the included ones — so the ~10 already-passing tests in
that file run a second time. This partially undercuts the phase's efficiency
goal (the file's non-smoke tests pay double cost in this scope).

**Fix:** Pick one opt-in mechanism and narrow the second run to only the smoke
test. Preferred: drop the redundant env var and constrain to the tag with
`--only`, which runs ONLY tests matching the tag:

```bash
if run_mix_logged rulestead "${log_file}" test --only published_hex_smoke \
  test/rulestead/mix/tasks/verify_release_publish_test.exs; then
```

`--only` both re-includes the tag and excludes everything else, so the file's
other tests do not re-run. (`--only` implies the include and adds a global
exclude of untagged tests.)

## Info

### IN-01: Two-level `then/2` pipe in test_helper is harder to read than a list comprehension

**File:** `rulestead/test/test_helper.exs:1-12`
**Issue:**
The exclude list is built by threading an accumulator through two `then/2`
closures. It is correct and symmetric across both tags, but the nested-closure
shape is denser than needed for what is conceptually "conditionally collect tag
filters."
**Fix:** Optional readability improvement — express as a filtered list:

```elixir
default_excludes =
  [
    {:install_integration, System.get_env("RULESTEAD_RUN_INSTALL_INTEGRATION") != "1"},
    {:published_hex_smoke, System.get_env("RULESTEAD_RUN_PUBLISHED_HEX_SMOKE") != "1"}
  ]
  |> Enum.filter(fn {_tag, excluded?} -> excluded? end)
  |> Enum.map(fn {tag, _} -> {tag, true} end)
```

Behavior is identical; this is style only, not a defect.

### IN-02: Opt-in env contract relies on exact string `"1"` with no documentation at the call site

**File:** `rulestead/test/test_helper.exs:4,9`
**Issue:**
The gate is `== "1"`, so `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=true`,
`=yes`, or `=ON` silently fall through to "excluded." This matches the existing
`install_integration` convention (consistency is good), but there is no comment
documenting that only the literal `"1"` opts in. A contributor reading the CI
guidance lines (`scripts/ci/test.sh:181,186`) sees `=1` and may assume any
truthy value works.
**Fix:** Add a one-line comment above the block, e.g.
`# Opt-in requires the literal value "1"; any other value keeps the tag excluded.`

### IN-03: Magic literal published version `0.1.4` duplicated between test and CI guidance

**File:** `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs:199` and `scripts/ci/test.sh:185`
**Issue:**
The smoke test pins `@published_smoke_version "0.1.4"`, while the CI failure
guidance hardcodes the same version in prose:
`"...rulestead 0.1.4/rulestead_admin 0.1.4 are still live on Hex."`. These two
literals must be bumped in lockstep on every release; nothing enforces it, so
the guidance string will silently go stale when the test constant is bumped.
**Fix:** Acceptable as-is given they live in different languages, but consider
softening the CI prose to avoid the duplicated literal, e.g.
`"...the pinned smoke version is still live on Hex (see @published_smoke_version
in verify_release_publish_test.exs)."`

---

_Reviewed: 2026-06-16T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
