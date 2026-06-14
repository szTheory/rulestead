# Phase 118: Evidence + Idempotence Guardrails - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 118 closes the v1.17 Admin Design System Stress Test with reusable evidence and guardrails for VER-01 through VER-04. The phase should prove the UI matrix and selected mounted-admin workflows across light, dark, system-dark, desktop, mobile, and reduced-motion cases; keep deterministic assertions for overflow, focus, ARIA, keyboard, fixture health, and selected contrast pairs; keep the existing brand/token/logo/contrast/brandbook/foundation guard chain green; and record final planning truth before milestone closeout.

This phase must not reopen Phase 115 foundation rules, redo Phase 116 component polish, redo Phase 117 route IA, add public runtime APIs, add schemas or migrations, redesign palette or logo, adopt Storybook or a component framework, add broad checked-in pixel baselines, add external AI visual-review dependency, rebrand FleetDesk, change release workflow, introduce v2 product wedges, prepare `rulestead_admin` for standalone publication, or create Phase 8-only docs.
</domain>

<decisions>
## Implementation Decisions

### Evidence Bundle Shape

- **D-01:** Treat Phase 118 as the milestone evidence and idempotence capstone, not as a new UI polish or visual-regression infrastructure phase.
- **D-02:** Reuse the existing Playwright artifact pattern from `ui-matrix.spec.ts` and `admin-flow-ia.spec.ts`: screenshots are generated artifacts written through `testInfo.outputPath(...)`, not committed baselines or pixel-diff gates.
- **D-03:** Cover both proof surfaces required by VER-01: the repo-native UI matrix and the selected mounted-admin workflow routes handed off by Phase 117.
- **D-04:** Preserve the Phase 117 route sampling set for workflow evidence: overview, inventory, rules, kill, audience, audit, explain, and simulate.
- **D-05:** Include light, dark, system-dark, desktop, mobile, and reduced-motion evidence where those dimensions affect the surface. The reduced-motion case can stay targeted rather than multiplying every route by every motion mode.

### Deterministic Assertions

- **D-06:** Keep browser assertions DOM/behavior based: rendered `.rs-shell`, visible matrix sections or route evidence text, no page-level horizontal overflow, focus/keyboard behavior, key ARIA roles/regions, route ordering, and generated screenshot artifacts.
- **D-07:** Use Playwright for browser-only concerns and ExUnit/source assertions for component/source boundaries, fixture health, route exposure, forbidden tooling posture, and planning traceability.
- **D-08:** Keep selected contrast coverage in the existing static fixture and script layer. Do not turn Phase 118 into exhaustive runtime contrast auditing for every route pixel.
- **D-09:** Browser proof may use an isolated test-mode Phoenix backend and explicit `DEMO_BACKEND_URL` when local port or dev-database state makes the default backend unreliable. The exact command and environment should be recorded in the verification artifact.

### Guardrail Extension Policy

- **D-10:** Keep the current guard chain in `scripts/ci/lint.sh` as the normal durable drift gate: synced theme pairs, brand tokens, token CSS mirror, contrast, generated brandbook HTML, logo assets, admin foundations, package whitelist, and SVG budgets.
- **D-11:** Extend guard scripts only for concrete, repeatable design-system drift classes uncovered by v1.17 evidence. New guards should stay deterministic, stdlib-oriented where practical, and readable in CI output.
- **D-12:** Preserve existing source-posture guards against Storybook, PhoenixStorybook, `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, and checked-in pixel-baseline maintenance.

### Idempotence And Scope Boundaries

- **D-13:** Make reruns additive and safe. Generated Playwright screenshots and test output stay in test artifacts; committed source should be limited to durable tests, source guards, and planning/verification docs.
- **D-14:** Do not add product seed semantics, public routes, package metadata, release workflows, schemas, migrations, runtime APIs, FleetDesk rebranding, or `rulestead_admin` publish-prep work.
- **D-15:** Keep the demo-host UI matrix dev/test-only and outside `RulesteadAdmin.Router.rulestead_admin/2`. Phase 118 may assert that boundary; it should not move the route.
- **D-16:** Preserve the linked-version two-package release design. Phase 118 may document evidence for the sibling packages but must not publish or prepare to publish the `rulestead_admin` stub independently.

### Planning Traceability

- **D-17:** Produce a final Phase 118 verification or evidence artifact that maps VER-01 through VER-04 to proof commands, screenshot artifact patterns, guard outputs, intentional exceptions, and residual risks.
- **D-18:** Update planning truth only after evidence exists. Requirement completion should be recorded in `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and phase artifacts as appropriate during execution/verification, not guessed during planning.
- **D-19:** No external research is required before planning. The repo already contains the relevant Playwright, Phoenix, guard-chain, and planning-trace patterns for this capstone.

### Methodology

- **D-20:** Apply the project methodology lenses as recommendation-first defaults. The selected capstone shape does not change public API, security/governance posture, package boundary, release model, product scope, FleetDesk branding, or publish posture, so no additional high-impact user decision is required before planning.

### the agent's Discretion

The planner may choose the exact plan split and final artifact names, provided VER-01 through VER-04 receive explicit evidence coverage. Prefer compact evidence maps, source assertions, and command lists over broad new infrastructure. If a guard extension is not clearly preventing real drift, document the existing guard instead of adding a new one.

### Folded Todos

None - no pending todos matched Phase 118.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Prior Phase Artifacts

- `.planning/ROADMAP.md` - Phase 118 goal, requirements, success criteria, and out-of-scope constraints.
- `.planning/REQUIREMENTS.md` - VER-01 through VER-04 and v1.17 future/out-of-scope requirements.
- `.planning/STATE.md` - Current phase state, prior decisions, linked-version sibling-package constraints, and latest verification context.
- `.planning/METHODOLOGY.md` - Recommendation-first and architect-default discuss lenses.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md` - Evidence posture, taxonomy, operator lenses, and no-baseline decisions.
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-ACCEPTANCE-GATES.md` - Guard-chain responsibilities and downstream acceptance expectations.
- `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md` - Demo-hosted real-component matrix decisions.
- `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md` - Matrix Playwright evidence and screenshot posture.
- `.planning/phases/115-foundations-hardening/115-CONTEXT.md` - Foundation guard and evidence boundary decisions.
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` - Breakpoints, focus, reduced motion, radius/elevation, and dense-content rules.
- `.planning/phases/115-foundations-hardening/115-VERIFICATION.md` - FND-01 through FND-06 evidence and guard outputs.
- `.planning/phases/116-primitive-composite-polish/116-CONTEXT.md` - Component/composite evidence posture and Phase 118 deferrals.
- `.planning/phases/116-primitive-composite-polish/116-VERIFICATION.md` - CMP-01 through CMP-05 proof commands and matrix artifact locations.
- `.planning/phases/117-page-flow-ia-pass/117-CONTEXT.md` - Route-flow evidence strategy and Phase 118 handoff decisions.
- `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` - Final route set, proof commands, screenshot naming, decision coverage, and Phase 118 sampling guidance.
- `.planning/phases/117-page-flow-ia-pass/117-VERIFICATION.md` - FLOW-01 through FLOW-04 evidence, automated checks, boundary checks, and residual risks.

### Prompt Anchors

- `prompts/rulestead-testing-and-e2e-strategy.md` - Curated browser evidence posture, deterministic test strategy, and caution around trust-theater browser work.
- `prompts/rulestead-admin-ux-and-operator-ia.md` - Mounted admin UX, keyboard-first operation, mutation lifecycle, accessibility, and no-novelty guidance.
- `prompts/rulestead-personas-jtbd-and-onboarding.md` - Operator/support/SRE/reviewer jobs-to-be-done for route evidence interpretation.
- `prompts/phoenix-live-view-best-practices-deep-research.md` - LiveView testing and component/source-boundary idioms.

### Source Files And Guard Entry Points

- `examples/demo/frontend/package.json` - `npm run test:e2e` entry point.
- `examples/demo/frontend/playwright.config.ts` - Playwright worker, metadata, backend/frontend URL conventions, and no-retry posture.
- `examples/demo/frontend/tests/ui-matrix.spec.ts` - Matrix evidence across themes, viewports, reduced motion, overflow, fixtures, forbidden tooling, and screenshot artifacts.
- `examples/demo/frontend/tests/admin-flow-ia.spec.ts` - Mounted-admin workflow route evidence, route ordering, keyboard/focus, overflow, and screenshot artifacts.
- `examples/demo/frontend/tests/brand-ui-evidence.spec.ts` - Existing route/theme/viewport screenshot pattern and no-overflow assertion precedent.
- `examples/demo/frontend/tests/design-system.spec.ts` - Static fixture load and selected contrast checks.
- `examples/demo/frontend/tests/theme-control.spec.ts` - Theme control browser evidence.
- `examples/demo/frontend/tests/theme-cascade.spec.ts` - Theme cascade browser evidence.
- `examples/demo/frontend/tests/theme-scope.spec.ts` - Mounted admin theme scope browser evidence.
- `examples/demo/frontend/tests/support/admin.ts` - `DEMO_BACKEND_URL` helper for browser specs.
- `examples/demo/frontend/tests/support/contrast-check.ts` - TypeScript WCAG helper used by static fixture specs.
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - Demo-host real-component matrix surface.
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - Deterministic matrix, route, and rare-state fixtures.
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - Backend source/fixture/router-boundary matrix assertions.
- `scripts/ci/lint.sh` - Normal CI guard-chain entry point.
- `scripts/check_synced_pair.py` - Light/dark synced-pair CSS token guard.
- `scripts/check_brand_tokens.py` - Brandbook token to admin CSS drift guard.
- `scripts/check_tokens_css.py` - `tokens.css` mirror guard.
- `scripts/check_contrast.py` - Static brand palette/semantic contrast guard.
- `scripts/check_brandbook_html.py` - Generated brandbook HTML drift and size guard.
- `scripts/check_logo_assets.py` - Copied logo asset and shell marker guard.
- `scripts/check_admin_foundations.py` - Foundation contract/source guard.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/demo/frontend/tests/ui-matrix.spec.ts` already covers matrix sections across light, dark, system-dark, desktop, mobile, and a targeted reduced-motion case, and writes `ui-matrix-overview-shell-${theme}-${viewport}-${motion}.png` artifacts.
- `examples/demo/frontend/tests/admin-flow-ia.spec.ts` already covers the Phase 117 route set across light/dark/system-dark and desktop/mobile, with generated `flow-${route}-${theme}-${viewport}.png` artifacts.
- `examples/demo/frontend/tests/design-system.spec.ts`, `theme-control.spec.ts`, `theme-cascade.spec.ts`, and `theme-scope.spec.ts` preserve low-level static fixture/theme evidence.
- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` can prove route examples, rare-state fixtures, real component usage, and matrix/admin-router isolation quickly without a browser.
- `scripts/ci/lint.sh` already chains the durable brand, token, contrast, brandbook, logo, foundation, package, and SVG budget guards.
- `117-FLOW-IA-REVIEW.md` is the direct route evidence map and Phase 118 sampling handoff.

### Established Patterns

- Playwright screenshots are generated artifacts for human review, not checked-in baselines. Existing specs deliberately avoid `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, and pixel-baseline maintenance.
- Browser specs sign in through `/demo/sign-in`, set `localStorage` theme when needed, navigate to real mounted admin paths or the demo-host matrix route, and assert `.rs-shell`.
- No-horizontal-overflow checks use `document.documentElement.scrollWidth - clientWidth <= 1`.
- Reduced-motion evidence is targeted and behavioral; `ui-matrix.spec.ts` verifies nonessential task-link transforms compute to `none`.
- Source and ExUnit checks are preferred for static boundaries such as dev/test matrix isolation, fixture health, forbidden tooling strings, and real component module usage.
- The admin remains responsive but not mobile-first. Evidence should prove containment and critical-path reachability, not redesign route hierarchy.

### Integration Points

- Phase 118 plans should extend or consolidate existing evidence specs and guard scripts rather than creating a parallel evidence framework.
- If browser commands require a backend, use the existing `DEMO_BACKEND_URL` convention and record the backend command/port in the verification artifact.
- Any planning docs updated during execution should trace back to VER-01 through VER-04 and the Phase 117 route/matrix handoff.
- Guard additions, if any, should plug into `scripts/ci/lint.sh` and print deterministic pass/fail lines consistent with the existing scripts.
</code_context>

<specifics>
## Specific Ideas

- Preferred evidence artifact: a compact Phase 118 evidence map with rows for requirement, surface, assertion type, command, artifact pattern, status, and intentional exception.
- Matrix sample targets should include `overview-shell`, command palette, raw audit detail, composite state labels, static fixtures, foundation markers, and forbidden visual-baseline source posture.
- Workflow sample targets should include kill for destructive keyboard/focus flow, audit for redacted raw detail/resource links, explain for answer-before-form permalink support, simulate for redacted metadata plus fixture export, and inventory/audience for mobile containment.
- Preserve screenshot naming already established by prior phases: `ui-matrix-${section}-${theme}-${viewport}-${motion}.png` and `flow-${route}-${theme}-${viewport}.png`.
- Verification docs should record generated artifact locations under `examples/demo/frontend/test-results/...`, not commit those screenshots.
- Useful command spine for planning: `python3 scripts/check_admin_foundations.py`; `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts`; static fixture specs; and the relevant guard-chain scripts or `bash scripts/ci/lint.sh` when practical.
</specifics>

<deferred>
## Deferred Ideas

- Broad checked-in pixel baselines, Playwright visual snapshot assertions, pixelmatch/visual-diff tooling, and external AI visual judging remain out of scope.
- PhoenixStorybook or JavaScript Storybook remains deferred until a future maintainer-facing design-system docs need proves the repo-native matrix insufficient.
- Forced-colors/high-contrast OS mode remains `FUT-03`, not Phase 118 scope.
- v2 product wedges, public runtime APIs, schema/migration work, release workflow changes, package publishing, FleetDesk rebranding, and `rulestead_admin` standalone publish preparation remain out of scope.
- Further component polish, foundation redesign, route IA redesign, palette/logo changes, and product seed semantics are out of scope unless a future roadmap explicitly reopens them.

### Reviewed Todos (not folded)

None - no pending todos matched Phase 118.
</deferred>

---

*Phase: 118-evidence-idempotence-guardrails*
*Context gathered: 2026-06-14*
