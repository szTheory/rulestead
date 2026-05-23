# Phase 38: Lifecycle Docs, Runbooks, & Verification - Patterns

## Canonical Patterns

### Pattern 1: Root README + shared guides own the product story
- `README.md` is the front door and should route readers into shared guides.
- `rulestead/README.md` and `rulestead_admin/README.md` stay package-local and narrowly scoped.
- New lifecycle narrative docs should follow this shape instead of creating a package-specific docs fork.

### Pattern 2: Mounted-admin public promise stops at mount, policy, session, and URL seams
- `rulestead_admin/README.md` and `guides/flows/admin-ui.md` document the stable host contract.
- `admin_mount_test.exs` proves route and `?env=` behavior without locking internal LiveView implementation details.
- Lifecycle runbooks should reference mounted-admin workflows through those same public seams.

### Pattern 3: Release contract tests treat docs as product surface
- `rulestead/test/rulestead/release_contract_test.exs` validates documented boundaries and explicit public/private claims.
- `verify_release_publish_test.exs` and `verify_release_parity_test.exs` extend this release-surface mindset to published artifacts and sibling-package posture.
- Phase 38 verification should extend these tests before inventing new release checks.

### Pattern 4: Public Mix tasks expose versioned, read-only operator contracts
- `Mix.Tasks.Rulestead.Lifecycle` already provides the lifecycle reporting contract with `schema_version`, text/json output, aligned filters, and read-only failure behavior.
- `rulestead_lifecycle_test.exs` is the natural place to tighten lifecycle CLI guarantees that docs will depend on.

### Pattern 5: Planning closeout artifacts live in `.planning/phases/<phase>/`
- Later planning-heavy phases use `RESEARCH.md`, `PATTERNS.md`, `VALIDATION.md`, and `VERIFICATION.md` or milestone audit docs as explicit evidence carriers.
- Phase 38 should follow that habit with one phase-local artifact that maps `LIF-05` claims to exact checks.

## File Anchors

- `README.md`
  - front-door routing and cross-role discoverability pattern
- `rulestead/README.md`
  - runtime package stays minimal and points upward to shared docs
- `rulestead_admin/README.md`
  - mounted companion posture and stable host seam language
- `guides/flows/admin-ui.md`
  - stable operator workflow phrasing for mounted admin
- `guides/flows/explainability.md`
  - support/operator evidence language already aligned to bounded explanations
- `guides/recipes/testing.md`
  - fake-first, public-surface test guidance pattern
- `rulestead/lib/mix/tasks/rulestead.lifecycle.ex`
  - public lifecycle CLI contract
- `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs`
  - CLI text/json/read-only contract checks
- `rulestead/test/rulestead/release_contract_test.exs`
  - docs as public contract precedent
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
  - mounted-admin host-route verification precedent

## Reusable Helpers

- `Mix.Tasks.Rulestead.Lifecycle.compute_report/1`
- `Mix.Tasks.Rulestead.Lifecycle.render_text/1`
- `capture_io/1` patterns in existing Mix task tests
- route/env assertions already present in `admin_mount_test.exs`
- `rg`-style file-content assertions as used in planning validation docs

## Anti-Patterns

- Creating a second lifecycle documentation taxonomy outside the existing root `guides/` tree
- Documenting `rulestead_admin` as a standalone admin/control-plane product
- Asserting internal LiveView selectors, CSS classes, or socket assigns as lifecycle verification evidence
- Treating `archive_candidate` or unknown-owner status as archive permission in docs language
- Duplicating the same lifecycle walkthrough independently across README, package README, and multiple guides

## Test Anchors

- `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs`
  - lifecycle report vocabulary, schema version, and read-only guarantee
- `rulestead/test/rulestead/release_contract_test.exs`
  - public/private documentation boundary assertions
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs`
  - sibling-package and HexDocs contract verification pattern
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
  - mounted route/env contract assertions

## Practical Direction

- Add one new lifecycle spine guide in shared `guides/`, then route root/package docs into it.
- Update existing admin, explainability, testing, and getting-started surfaces as satellites instead of building net-new parallel docs.
- Extend existing release-contract and lifecycle-task tests to prove the public lifecycle story.
- Finish with one phase-local evidence artifact that maps `LIF-05` to the exact files and commands added or tightened.
