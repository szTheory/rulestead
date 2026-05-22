# Rulestead v0.6.0 DX Research: Promotion, GitOps, and Tenancy

**Project:** Rulestead  
**Date:** 2026-05-18  
**Scope:** Developer ergonomics and host-app integration implications for multi-environment promotion, GitOps import/export, and tenancy  
**Overall confidence:** HIGH for Elixir/Phoenix patterns and workflow split, MEDIUM for adjacent ecosystem transfer

## Executive Summary

Rulestead should feel like an Elixir library first, not like an external control plane awkwardly embedded into Phoenix. For Phoenix teams, the unsurprising model is: the mounted admin is the visual operator console, Mix tasks are the deterministic automation surface, and host app config defines the security and topology seam. That matches how Phoenix teams already think about `live_dashboard`, Oban Web, `mix ecto.*`, and generator/install workflows.

For v0.6.0, the best recommendation is not "make everything possible from everywhere." That creates drift, duplicate auth surfaces, and conflicting writers. The right split is narrower:

- **Admin** for draft authoring, visual diffing, simulation, review, and "prepare promotion/import" flows.
- **CLI/Mix tasks** for export, validate, diff, import, and promote in local dev, CI, and incident playbooks.
- **Host app config** for auth, layout, environment catalog, tenancy resolution, and safety policy.
- **Library API** as the implementation seam that powers admin and Mix equally.

GitOps should be introduced as a reproducible artifact and workflow, not as a second runtime mode that takes over the product. Rulestead should export a canonical, deterministic environment bundle, validate it offline, diff it against a target, and then import/promote it transactionally. That gives teams a clean CI surface without turning `rulestead_admin` into a standalone product or making the host surrender auth, routing, or release control.

## Starting Constraints from Current Rulestead Shape

- The repo already has a mounted admin macro and policy seam in [`rulestead_admin/lib/rulestead_admin/router.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:1).
- The mounted admin already carries environment in session/URL and treats production as a higher-risk context in [`rulestead_admin/lib/rulestead_admin/live/session.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:1).
- The project already leans on Mix tasks for install and ops, such as [`rulestead/lib/mix/tasks/rulestead.install.ex`](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:1) and [`rulestead/lib/mix/tasks/rulestead.redis.sync.ex`](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.redis.sync.ex:1).
- The host-app seam explicitly says host owns auth and layout, installer edits must stay explicit, and umbrella support matters.
- The current milestone goal in `PROJECT.md` is promotion, GitOps-friendly import/export, and explicit tenancy helpers, without publishing `rulestead_admin` as a separate product.

These constraints strongly favor an additive DX model that extends existing Mix/admin seams instead of inventing a parallel HTTP management product.

## Direct Answers

### 1. Best DX patterns for import/export and promotion

**Recommendation:** Use a **plan/apply workflow** with canonical artifacts.

Best-fitting pattern:

1. `mix rulestead.export`
2. `mix rulestead.validate`
3. `mix rulestead.diff`
4. `mix rulestead.import --plan`
5. `mix rulestead.import --apply`
6. `mix rulestead.promote --plan`
7. `mix rulestead.promote --apply`

Why this fits Phoenix teams:

- It feels like `mix ecto.migrate`, `mix ecto.dump`, and `mix ecto.load`: explicit, scriptable, reviewable.
- It gives CI stable exit codes and text output.
- It keeps destructive operations behind explicit `--apply`.
- It makes "what would happen?" available before mutation.

**Canonical artifact recommendation:** export **semantic environment state**, not database state.

The bundle should include:

- flag definitions that belong in source control
- env-specific targeting/ruleset state
- rollout configuration
- kill-switch state when intentionally exported
- tenancy scope metadata
- schema/version metadata

The bundle should exclude:

- DB primary keys
- inserted/updated timestamps
- audit rows
- runtime health/snapshot metadata
- ephemeral counters
- host-owned auth/session state

**Format recommendation:** start with a **canonical JSON bundle** as the supported machine format, even if admin can render friendlier previews.

Reasoning:

- deterministic ordering is straightforward
- native Elixir support is simple
- CI diffing is reliable
- schema validation is easier to keep strict

If a more human-authored GitOps format is added later, add it as a second format after the JSON contract is stable.

### 2. What should be admin-driven vs CLI-driven vs host-app-config-driven

**Admin-driven**

- create/edit draft promotion or import operations
- inspect diffs between source and target environments
- simulate impact before import/promotion
- select subsets for export
- review validation failures in operator-friendly language
- turn a reviewed plan into a copyable CLI command
- submit change requests / approvals around mutations

**CLI-driven**

- export bundles for Git commits
- validate bundles in CI
- diff source bundle vs target environment
- import/apply bundles non-interactively
- promote dev -> staging -> prod in release pipelines
- run batch operations across explicit env/tenant selections
- emit machine-readable output for CI (`--format json`)

**Host-app-config-driven**

- admin mount path
- auth and actor resolution
- allowed environments and display names
- which environments are protected/critical
- allowed promotion edges, such as `dev -> staging`, `staging -> prod`
- tenancy resolution strategy
- default artifact output path
- whether an environment allows admin writes, CLI writes, or both

**Library API-driven**

- shared implementation for export/import/diff/promotion
- transactionality, validation, conflict detection, audit creation
- host-extensible callbacks without exposing an HTTP management API yet

### 3. Ergonomics that reduce operator error and improve adoption

Most important ergonomics:

- `--plan` before `--apply` everywhere
- explicit `--from`, `--to`, `--env`, and `--tenant`
- no silent environment default for destructive commands
- strong production labeling in both CLI and admin
- canonical diff output with stable sorting
- import/promotion summary counts before apply
- copyable command from admin previews
- machine-readable JSON output for CI and shell-readable text for humans
- transactionality with all-or-nothing apply
- idempotent re-run behavior

Recommended command style:

```bash
mix rulestead.export --env staging --out .rulestead/staging.bundle.json
mix rulestead.validate .rulestead/staging.bundle.json
mix rulestead.diff --from-file .rulestead/staging.bundle.json --to-env prod
mix rulestead.promote --from staging --to prod --plan
mix rulestead.promote --from staging --to prod --apply --reason "release 2026-05-18"
```

Recommended admin style:

- visual preview first
- never mutate immediately from a hidden row action
- "Run in CI" snippet on every promotion/import plan
- environment and tenant always visible in header and confirm modal
- prod mutation confirmation must repeat source, target, tenant scope, and reason

### 4. Common footguns in library/app hybrids here

1. **Multiple write surfaces with no source-of-truth rule**
   If admin, CLI, and Git all mutate the same environment without coordination, drift is guaranteed.

2. **Implicit env or tenant selection**
   Defaulting a destructive command to "current" or "prod" is a 3am mistake factory.

3. **Blurring host concerns with library concerns**
   The library must not start owning auth, layout, or app routing policy.

4. **Treating tenancy and environments as the same axis**
   They are different concerns and should stay different in URLs, APIs, and artifacts.

5. **Exporting DB-shaped state**
   IDs, timestamps, and internal metadata make GitOps noisy and brittle.

6. **Admin-only promotion**
   UI-only mutations are hard to reproduce in CI and incident retrospectives.

7. **CLI-only promotion**
   Pure CLI misses reviewability, simulation, and operator trust for risky changes.

8. **Partial imports**
   Applying only some related objects without a proper dependency/transaction story creates corrupted config.

9. **HTTP management API too early**
   Before RBAC hardening, another mutation surface expands risk faster than value.

10. **Umbrella surprise**
   Tasks that recurse or guess the wrong app/repo in umbrella hosts are adoption killers.

### 5. Coherent recommendation set that best fits Rulestead

**Primary recommendation:** make Rulestead v0.6.0 a **Mix-task-centered GitOps surface with admin-assisted planning**.

That means:

- mounted admin stays the operator UX
- Mix stays the automation UX
- host app keeps auth/layout/pipeline ownership
- environment promotion is modeled as a reviewed diff plus explicit apply
- tenancy is explicit everywhere, never inferred from hidden state
- GitOps is artifact-based, not "database mirrored into Git"

This is the least surprising fit for Elixir/Phoenix teams.

## Recommended DX Surface

### A. Commands

Prefer **separate Mix tasks** over a custom single task with homemade subcommands.

Recommended tasks:

- `mix rulestead.export`
- `mix rulestead.validate`
- `mix rulestead.diff`
- `mix rulestead.import`
- `mix rulestead.promote`

Do **not** use a bespoke CLI grammar like `mix rulestead env promote ...` for the first release. Phoenix and Ecto teams expect discoverable task names with `mix help`.

Why:

- official Mix tasks are documented through `@moduledoc` and `mix help`
- umbrella behavior is explicit via `Mix.Task` conventions
- separate tasks are easier to cite in guides and CI

### B. Artifact Model

Use one export bundle per environment scope.

Recommended metadata at the top level:

- `schema_version`
- `rulestead_version`
- `exported_at`
- `source`
  - environment key
  - tenant scope
- `resources`

Recommended semantics:

- deterministic key ordering
- deterministic resource ordering
- semantic equality rules, so no-op imports remain no-op
- validation that fails before any DB write

### C. Diff Model

Support three diff modes:

- env -> env
- file -> env
- file -> file

Diff output should classify:

- create
- update
- archive/delete if supported
- unchanged
- blocked/conflict

Text output should stay short and CI-readable. JSON output should include structured resource paths.

### D. Promotion Model

Treat promotion as a specialized import, not a separate mutation engine.

Recommended semantics:

- `promote` exports from source, validates, diffs, and then imports into target
- `--plan` prints the exact changes
- `--apply` executes in one transaction
- target environment policy decides whether direct apply is allowed or whether a change request must be created

Promotion should default to env-scoped state. Do **not** silently promote global flag-definition fields that affect multiple environments unless the operator explicitly requests that scope.

This mirrors a real footgun seen in larger ecosystems: global definition changes and env-specific targeting changes are not operationally equivalent.

### E. Tenancy Model

Keep **environment** and **tenant** as separate dimensions.

Recommendation:

- environment remains the deployment axis
- tenant is an optional targeting/scope axis layered on top
- host provides tenant resolution and catalog helpers
- every mutation surface shows both env and tenant scope

Recommended CLI rules:

- no implicit tenant filtering
- `--tenant acme` or `--all-tenants` must be explicit
- if host is single-tenant, config can mark that and simplify prompts/output

Recommended admin rules:

- tenant selector always visible when tenancy is enabled
- no "all tenants" default
- URLs should encode tenant scope

## What to Copy from Adjacent Ecosystems

### Copy

**Ecto / Mix**

- explicit tasks with stable names
- `mix help` documentation model
- options like `-r/--repo` and explicit path arguments
- plan/apply mental model from migration-style workflows

**Phoenix LiveDashboard**

- mounted-inside-host routing
- host-auth-first production story
- do not own the host app's auth stack

**Phoenix LiveView**

- use `live_session` boundaries and `on_mount` for admin auth/state
- keep admin inside a host-owned security and layout boundary

**Oban Web**

- embedded admin surface inside the host app
- clear split between interactive dashboard and operational runtime

**Unleash**

- import/export with validation before commit
- if workflow approvals exist, turn mutation into a draft rather than applying immediately
- distinct Client/Admin/API roles

**Flipt**

- GitOps as declarative artifact flow
- offline validation as a first-class command
- schema extension hooks are a good future idea for host-specific policy checks

### Avoid

**LaunchDarkly/Terraform split-brain**

- their provider docs warn that environment-specific Terraform can overwrite experiment-managed changes
- lesson: avoid two equally-authoritative writers to the same mutable surface

**Flipt namespaces as overloaded abstraction**

- namespaces can represent env or org/team; for Rulestead that would blur tenancy and environment
- Rulestead should keep those axes explicit

**Premature full Admin API parity**

- Unleash has a large Admin API because it is a full control plane product
- Rulestead is still a library with a mounted admin and host-owned auth seam
- before RBAC hardening, a full public mutation API is the wrong priority

## Recommended Responsibility Split

| Surface | Owns | Should Not Own |
|---|---|---|
| Admin UI | review, simulation, visual diff, change-request-friendly planning | headless automation, Git authority, host auth |
| Mix tasks | deterministic export/import/diff/promotion, CI, incident playbooks | browser UX, session-driven auth |
| Host config | auth, layout, environment/tenant policy, safety defaults | feature content, mutable operator actions |
| Library API | shared logic, validation, transactionality, audit | standalone external product semantics |

## Concrete DX Recommendations

### Recommendation 1: Make `plan` the default safety posture

For import and promote, support:

- `--plan` or default dry-run
- `--apply` to mutate
- `--format text|json`

If a command is destructive and `--apply` is absent, it should exit `0` after printing the plan.

### Recommendation 2: Generate admin-to-CLI handoff

Every admin promotion/import preview should show:

- exact environment and tenant scope
- summary counts
- exact command to reproduce via Mix
- bundle path or temp artifact if applicable

This is one of the highest-leverage adoption moves because it aligns operators and CI instead of forcing them into separate workflows.

### Recommendation 3: Add a host policy callback for promotion safety

Host config should be able to say:

- protected environments
- allowed promotion edges
- whether prod accepts direct apply or only change-request creation
- whether tenant-wide mutations require extra confirmation

Keep this in host config, not in mutable admin settings.

### Recommendation 4: Keep public HTTP management API out of v0.6.0

Use library functions internally so a future API is possible, but do not bless a new public remote mutation surface before v1.0.0 RBAC/security work.

### Recommendation 5: Make import transactional and dependency-aware

Imports/promotions should validate:

- referenced flags exist when required
- referenced audiences/segments/variants are present
- source and target schema versions are compatible
- target environment policy permits the change

Then apply in one transaction with one audit narrative.

### Recommendation 6: Treat "global flag shape" and "environment targeting" as distinct scopes

Operators need to understand whether they are changing:

- flag schema/variants globally
- env-specific targeting/rules
- rollout state
- tenant-specific overlays

Rulestead should make those scopes explicit in diff output and confirms.

### Recommendation 7: Support umbrella apps explicitly

Mix task docs and options should include:

- `--app`
- `--repo`
- possibly `--prefix` if promotion/import touches prefixed tenancy setups

Do not rely on magical recursion. In umbrella hosts, explicit beats clever.

## Common Operator/Error Cases and Mitigations

| Risk | Why It Happens | Mitigation |
|---|---|---|
| Promoting to wrong env | hidden/default env | require `--to`, show env banner, prod tone |
| Applying wrong tenant scope | tenancy inferred from session or defaults | require `--tenant` or `--all-tenants`, show tenant in confirms |
| Drift between admin and Git | same env mutated from both | configurable source-of-truth mode and audit tags |
| Noisy Git diffs | export contains volatile fields | canonical semantic bundle only |
| Partial broken imports | missing dependency graph | validate references and apply transactionally |
| CI scripts hard to read | one giant task with custom parser | separate Mix tasks with standard help |
| Auth seam leakage | library adds its own auth assumptions | keep host policy + mount seam |
| LiveView/auth mismatch | GET endpoints bypass `on_mount` assumptions | match plug auth with live session auth |

## Suggested v0.6.0 Milestone Slices

1. **Promotion Domain Contract**
   Define public library modules, data model, and audit semantics for export/import/diff/promotion.

2. **Canonical Bundle + Validator**
   Ship export bundle format, semantic normalization, and `mix rulestead.validate`.

3. **Diff Engine**
   Add env/file diffing with stable text and JSON output.

4. **Import/Promote Apply Path**
   Add transactional import/promotion with `--plan` and `--apply`, plus change-request integration where policy requires it.

5. **Admin Preview UX**
   Add admin-driven preview flows that produce copyable Mix commands and readable diffs without creating a second automation path.

6. **Tenancy Guardrails**
   Add explicit tenant helpers, selectors, and command flags with no implicit "all tenants" writes.

7. **GitOps/CI Recipes**
   Add guide examples, CI scripts, and example host workflows for exporting, validating, diffing, and promoting through PRs or release jobs.

## What This Should Feel Like for Phoenix Teams

Target feeling:

- "I mounted the admin into my app and it respects my auth and layout."
- "I can review config visually, but the final automation path is still a normal `mix` command."
- "I can run the same promotion locally and in GitHub Actions."
- "Production changes are explicit, auditable, and hard to do accidentally."
- "Tenancy is supported, but not hidden behind magic."

Avoid this feeling:

- "There are three ways to do the same thing and I don't know which is real."
- "The admin seems to own my release process."
- "GitOps means exporting random DB state."
- "Tenants and environments are the same concept with different labels."

## Confidence Notes

### HIGH confidence

- mounted admin + host-owned auth/layout seam
- Mix task based automation surface
- plan/apply flow
- explicit env/tenant safety guards
- no public mutation API yet

### MEDIUM confidence

- canonical JSON as the first artifact format instead of YAML
- exact scope split for global flag definition vs env targeting
- future host-extensible validation schema hooks

These medium-confidence items are still the best fit, but they should be validated against the desired docs/examples experience before locking the public contract.

## Sources

### Primary / official

- Elixir Mix task docs: https://hexdocs.pm/mix/Mix.Task.html
- Ecto migration task docs: https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html
- Phoenix LiveDashboard docs: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html
- Phoenix LiveDashboard router macro: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Phoenix LiveView router docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
- Oban Web overview: https://hexdocs.pm/oban_web/overview.html
- Unleash API overview: https://docs.getunleash.io/api
- Unleash import/export: https://docs.getunleash.io/concepts/import-export
- Flipt GitOps: https://docs.flipt.io/v1/usecases/gitops
- Flipt concepts / namespaces: https://docs.flipt.io/v1/concepts
- Flipt validate command: https://docs.flipt.io/v1/cli/commands/validate
- LaunchDarkly approvals: https://launchdarkly.com/docs/home/releases/approval-config
- LaunchDarkly Terraform environment resource: https://registry.terraform.io/providers/launchdarkly/launchdarkly/latest/docs/resources/feature_flag_environment

### Repository context

- [`PROJECT.md`](/Users/jon/projects/rulestead/.planning/PROJECT.md)
- [`prompts/rulestead-host-app-integration-seam.md`](/Users/jon/projects/rulestead/prompts/rulestead-host-app-integration-seam.md)
- [`prompts/rulestead-release-engineering-and-ci.md`](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md)
- [`prompts/rulestead-engineering-dna-from-prior-libs.md`](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md)
- [`prompts/rulestead-admin-ux-and-operator-ia.md`](/Users/jon/projects/rulestead/prompts/rulestead-admin-ux-and-operator-ia.md)
