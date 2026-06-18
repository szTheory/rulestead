# Deferred / out-of-scope discoveries — Phase 125

## During 125-02 execution

- **`rulestead/test/rulestead/release_contract_test.exs` was unformatted at HEAD.**
  Origin: committed by Plan 125-01 (`44b6b96`), the upstream dependency of 125-02.
  Discovered while running `bash scripts/ci/lint.sh` for Task 2 verification — the
  `mix format --check-formatted` step (lint.sh L30) failed before reaching the new
  guard at L63. Because the lint lane exiting 0 is a 125-02 success criterion and the
  fix is a trivial, mechanical, auditable `mix format` of the multi-line `for`
  comprehension list, it was applied here as a Rule 1 (coherence) deviation rather
  than deferred. Documented in 125-02-SUMMARY.md.
