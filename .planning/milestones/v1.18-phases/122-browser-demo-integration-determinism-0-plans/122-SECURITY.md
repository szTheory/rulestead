# SECURITY.md — Phase 122 (browser-demo-integration-determinism)

**Audit date:** 2026-06-17
**ASVS Level:** 1
**block_on:** high
**Disposition:** SECURED — 5/5 threats resolved (3 mitigate CLOSED, 2 accept validated)

This audit verifies that every declared mitigation in the PLAN.md `<threat_model>`
block exists in the implemented code. Implementation files were not modified.

---

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-122-01 | Information Disclosure | mitigate | CLOSED | `.github/workflows/ci.yml:206-208` — `path:` block contains exactly `examples/demo/frontend/playwright-report/` and `examples/demo/frontend/test-results/` and nothing else. Both are Playwright output dirs; no repo-root, env, or secret paths. |
| T-122-02 | Tampering | mitigate | CLOSED | `.github/workflows/ci.yml:203` — `uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2`. 40-hex-char SHA pin matching the expected v4.6.2 commit; no bare `@v4` tag. Repo-wide grep confirms all `upload-artifact@` pins are 40-hex SHAs. |
| T-122-03 | Integrity | accept | CLOSED (accepted) | `.github/workflows/ci.yml:202` — step uses `if: failure()` (not `if: always()`). Step performs only an artifact upload; it does not mutate job outcome. Standard GHA semantics: job result is set by the first failing step; a later `if:failure()` step that succeeds does not flip the result. `release_gate` reads `needs['integration-placeholder'].result`, which stays `failure`. See Accepted Risk Log below. |
| T-122-04 | Tampering | mitigate | CLOSED | `scripts/demo/verify.sh:14` — `trap cleanup EXIT INT TERM` present and unmodified (exactly one `trap` declaration in the file). Failure handling at lines 42-53 uses the `\|\| { ...; exit 1 }` idiom; `exit 1` fires the existing trap. No second trap added. |
| T-122-SC | Tampering | accept | CLOSED (accepted) | `git diff 0c2b021~1..cbdb7c1 --name-only` shows only `ci.yml`, `playwright.config.ts`, `verify.sh` changed. No dependency manifest (package.json, package-lock, mix.exs/lock, requirements, Cargo, pnpm/yarn lock) touched. Config/shell/YAML edits only. See Accepted Risk Log below. |

---

## Accepted Risk Log

### T-122-03 — upload-artifact step after failed main step (Integrity)

**Accepted.** A `if: failure()` step that succeeds does not change a job result that
is already `failure`. GitHub Actions sets job conclusion from the first failing step;
a subsequent successful conditional step cannot elevate `failure` to `success`. The
`integration-placeholder` upload step (ci.yml:201-210) only uploads artifacts and does
not run any command that could be interpreted as recovering the job. `release_gate`
consumes `needs['integration-placeholder'].result`, which remains `failure`. The step
deliberately uses `if: failure()` rather than `if: always()`, and `if-no-files-found:
ignore` ensures it never errors on a missing report dir. Behavior is deterministic and
documented. Risk accepted.

### T-122-SC — supply chain / new package installs (Tampering)

**Accepted.** No new dependencies were introduced in this phase. The phase commit range
(`0c2b021~1..cbdb7c1`) modifies only `.github/workflows/ci.yml`,
`examples/demo/frontend/playwright.config.ts`, and `scripts/demo/verify.sh`. No
package.json, lockfile, mix manifest, or other dependency declaration was changed,
verified by `git diff --name-only` over the phase commits. No slopcheck required. Risk
accepted.

---

## Unregistered Flags

None. SUMMARY.md (`122-01-SUMMARY.md`) contains no `## Threat Flags` section. The
executor reported no new attack surface during implementation, and the phase diff
introduces no new entry points (no new exports, no new network listeners, no new
dependency surface). No unmapped attack surface to register.

---

## Notes

- Implementation files were treated as READ-ONLY. This audit created only this SECURITY.md.
- Expected SHA `ea165f8d65b6e75b540449e92b4886f43607fa02` (v4.6.2) for actions/upload-artifact
  was confirmed present in ci.yml, matching the value pre-resolved at Task 3 and cited in PLAN/SUMMARY.
- `threats_open: 0`
