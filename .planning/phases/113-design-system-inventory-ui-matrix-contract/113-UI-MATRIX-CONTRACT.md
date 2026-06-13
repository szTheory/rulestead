# Phase 113 UI Matrix Contract

**Status:** Task 1 state/evidence contract complete
**Scope:** Documentation-only DSM-03 contract. Phase 113 does not add a UI matrix route, PhoenixStorybook, JavaScript Storybook, Playwright implementation, checked-in pixel baselines, external AI judging, runtime code, CSS, schemas, package changes, release workflow changes, FleetDesk branding changes, or `rulestead_admin` publish-prep work.

## Contract Rules

- Phase 114 must render real admin components and seeded LiveView flows with representative fixed assigns.
- Static fixtures remain token, theme, logo, focus, and contrast guard inputs. They must not become the primary component contract because static HEEx can drift from the mounted admin.
- Evidence remains curated screenshots plus deterministic assertions: fixture health, no horizontal overflow, focus visibility, keyboard flow, selected ARIA roles, selected contrast pairs, reduced-motion behavior, and light/dark/system mode rendering.
- Human review remains the qualitative layer. The repeatable evidence layer is source assertions, browser assertions, and curated screenshots, not broad checked-in pixel baselines.

## Required State Matrix

| State | Required Phase 114 coverage | Representative source anchors | Evidence expectation | Notes |
| --- | --- | --- | --- | --- |
| normal | Baseline rendering for primitives, composites, shell, navigation, route pages, and governed workflows. | `RulesteadAdmin.Components.OperatorComponents`, `RulesteadAdmin.Components.FlagComponents`, `RulesteadAdmin.Components.Shell`, LiveView route families | Screenshot and assertion coverage in light, dark, system-dark, desktop, and mobile/narrow contexts where visible behavior differs. | Establishes the baseline before dense or rare states. |
| dense | High-count rows, compact metadata, dense filters, audit/timeline entries, rule lists, and technical detail. | Flag inventory, audit/timeline, rules workspace, rollout panels, schedule/webhook rows | No horizontal page overflow, stable actions, readable metadata, and preserved scan rhythm on desktop and mobile. | Dense is a required stress state, not optional polish. |
| empty | No flags, no audiences, no audit rows, no evidence, no tasks, or no available related records. | `empty_state/1`, home attention band, flag/audience/audit route pages | Empty heading/body/action copy visible in light/dark/system-dark and mobile/narrow contexts. | Empty states should explain next step or why no action exists. |
| loading | Pending async, refresh, or route-load state where the existing source supports it. | Home loading attention band and future seeded LiveView flow examples | Loading content must not cause layout breakage, focus traps, or misleading disabled/unavailable affordances. | Phase 113 names the contract; Phase 114 decides concrete seeded flow coverage. |
| error | Failed load, validation error, unavailable dependency, guardrail error, or form error. | `rs-form-error`, rule editor errors, diagnostics, simulate/explain dependency surfaces | Error state names the problem and recovery path; visible in light/dark/system-dark and narrow-width/mobile when behavior differs. | Phase 114 should prefer deterministic fixture/fixed-assign errors over flaky external failures. |
| permission-denied | Capability denied, hidden action, denied route, denied dependency, or production risk that the actor cannot proceed through. | `RulesteadAdmin.Components.Shell` policy state, governed mutation routes, audience/flag destructive flows | Denied messaging and disabled/unavailable affordances remain legible and keyboard reachable where applicable. | The matrix must include denied examples without weakening auth policy. |
| read-only | Archived/read-only records, unavailable env/tenant scope, or visible data with mutation controls suppressed. | Audience archive/delete routes, flag detail routes, shell environment/tenant controls | Read-only surface is visibly different from editable normal state and still supports navigation/focus. | Can share examples with permission-denied only when the outcome is explicitly named. |
| long-label | Long command palette labels, owner names, team names, environment names, tenant names, button labels, and section headings. | Shell command palette, environment/tenant controls, task links, record rows | Text wraps or truncates intentionally without occluding adjacent controls in desktop and mobile/narrow widths. | Must include labels long enough to stress real operator copy, not lorem ipsum. |
| long-key | Long flag keys, audience keys, JSON/code values, audit reasons, fingerprints, and raw technical detail. | Detail grids, audit diff/raw detail, simulate/explain traces, mutation confirm scope lines | Long code/value content stays readable, scroll behavior is local where needed, and page-level horizontal overflow remains absent. | Long-key coverage should include monospace/detail contexts. |
| narrow-width | Mobile/narrow layout for shell, navigation, tables, cards, command palette, destructive flows, and dense technical rows. | `brand-ui-evidence.spec.ts` mobile viewport, `rulestead_admin.css` responsive selectors, LiveView routes | `expectNoHorizontalOverflow(page)` style assertion plus screenshot artifacts for representative route clusters. | Primary actions must remain reachable. |
| mobile | Same stress family as narrow-width, with touch target, stacking, and viewport-height concerns included where relevant. | Admin route screenshots at 390px width and real mounted admin pages | No horizontal page overflow; shell, rail, context controls, and primary actions remain usable. | Use mobile as the evidence dimension and narrow-width as the behavioral stress state. |
| destructive-action | Kill switch, cleanup/archive/delete, risky rollout jump, governed execute, and production typed-confirm flows. | `RulesteadAdmin.Components.ConfirmComponents.mutation_confirm/1`, kill, cleanup, archive/delete, change-request execution routes | Shared preview -> confirm -> audit expectations, required reason, back link, danger emphasis, and disabled/unavailable handling. | Destructive flows are a first-class state family. |
| disabled | Disabled buttons, disabled form controls, unavailable env/tenant options, blocked submit actions, and read-only mutation controls. | Shell env options, mutation confirm actions, static fixture disabled probes, route-specific forms | Disabled state is perceivable, not mistaken for loading, and does not remove necessary explanatory context. | Must be tested with keyboard/focus expectations where controls are reachable. |
| unavailable | Missing dependency, missing host evidence, no configured environment, blocked guardrail, or unavailable action. | Diagnostics, simulate/explain, rollout guardrail panels, shell context controls | Unavailable copy explains why the operator cannot proceed and what evidence is missing. | May overlap with error or disabled but must be explicitly labeled. |
| focus | Visible `:focus-visible` ring for links, buttons, forms, tabs, command palette options, task links, and destructive actions. | CSS focus ring tokens, `theme-harness.html`, shell command palette, route controls | Focus visibility remains clear in light, dark, system-dark, desktop, mobile/narrow, and reduced-motion contexts. | Focus state is deterministic assertion material. |
| keyboard | Keyboard path through shell controls, rail links, command palette, filters/forms, tabs/subnav, and confirm forms. | Theme control spec, shell command palette, flag subnav, mutation confirm form | Keyboard navigation should not trap focus, lose action context, or require pointer-only interaction. | Phase 114 should choose a small set of high-value keyboard paths. |

## Evidence Dimensions

| Dimension | Required coverage | Existing analog |
| --- | --- | --- |
| light | Explicit light theme or default light token cascade. | `brand-ui-evidence.spec.ts` theme loop and static theme fixtures. |
| dark | Explicit pinned dark mode. | `brand-ui-evidence.spec.ts`, `theme-control.spec.ts`, `theme-cascade.spec.ts`. |
| system-dark | OS dark mode with no pinned theme. | `brand-ui-evidence.spec.ts` system-dark case and CSS media cascade. |
| desktop | Wide enough for dense operator workflows and normal shell layout. | 1280 x 900 browser evidence viewport. |
| mobile/narrow | Narrow viewport evidence for route clusters, shell, command palette, tables/cards, and destructive flows. | 390 x 844 browser evidence viewport and `expectNoHorizontalOverflow(page)`. |
| reduced-motion | Motion-sensitive behavior where animations, transitions, or staged effects affect correctness or comfort. | `prefers-reduced-motion` CSS contract; future Phase 114/118 browser evidence should assert only where behavior differs. |

## Phase 114 Implementation Boundary

Phase 114 may implement a repo-native Phoenix/Playwright matrix, but Phase 113 only defines the contract. The future matrix must use real admin components with fixed assigns, real route examples where seeded LiveView flows are needed, and static fixtures only for low-level guard inputs. It must not duplicate HEEx into a separate static component catalog as the source of truth.
