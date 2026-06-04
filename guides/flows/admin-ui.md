# Admin UI

`rulestead_admin` is the mounted operator package for Rulestead. Its stable
host-facing surface is deliberately narrow: mount the package, supply a policy
module, provide bounded session inputs, and treat the documented route and
query conventions as the operator contract.

## Mount Seam

Mount the package from the host Phoenix router:

```elixir
scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The `policy:` option is required. Host apps own authorization through
`Rulestead.Admin.Policy.can?/4`.

## Canonical Role Model

`rulestead_admin` maps its views and capabilities to three conceptual roles. Your `Rulestead.Admin.Policy.can?/4` implementation enforces these boundaries:

1. **Viewer**: Can read flags, review change requests, explore environments, and inspect infrastructure diagnostics.
2. **Editor**: Can propose changes, create/update flags, submit change requests, and author draft state. Editors cannot publish directly to production.
3. **Admin**: Can publish flag changes, execute approved change requests, bypass approval rules (if configured), and manage webhook settings.

The UI gracefully degrades based on the actor's capabilities in the requested environment.

## What The Host Owns

The mounted package expects the host session to provide:

- `"current_actor"`
- `"rulestead_admin_environments"`
- `"rulestead_admin_last_env"`

The host application also owns:

- browser authentication
- actor identity and session lifecycle
- `can?/4` policy decisions defining viewer, editor, and admin capabilities per environment

That split is intentional. `rulestead_admin` is a mounted package, not a
bundled auth system.

## Stylesheet

Admin LiveViews render semantic `rs-*` classes. Include the packaged stylesheet in
your host root layout (alongside your own app CSS):

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/css/rulestead_admin.css"} />
```

Copy `priv/static/css/rulestead_admin.css` from the `rulestead_admin` Hex package into
your host asset pipeline during build (see the FleetDesk demo under
`examples/demo/backend/` for a reference `assets.copy_admin` alias).

## Design Token Contract

`rulestead_admin.css` uses a two-level token model. **Theme-invariant** tokens
(typography, spacing, radius, z-index, motion, control sizing) are declared
once in `:root` and never change between themes. **Theme-variant** tokens
(color, surface, border, shadow, focus, overlay) are declared per-cascade-block
inside `.rs-shell` / `[data-rulestead]`. All design tokens carry the `--rs-`
prefix.

### Cascade blocks

| Selector | When active |
|----------|-------------|
| `.rs-shell, [data-rulestead]` | Light default (no explicit pin or `@media`) |
| `@media (prefers-color-scheme: dark) .rs-shell:not([data-theme])` | System dark — OS is dark and no explicit pin |
| `.rs-shell[data-theme="dark"]` | Explicit dark pin — overrides OS in both directions |
| `.rs-shell[data-theme="light"]` | Explicit light pin — re-asserts light over dark OS |

The `:not([data-theme])` guard means an explicit pin (Blocks 3 or 4) always
wins over the `@media` rule regardless of OS setting.

### SYNCED-PAIR rule

Blocks 1 and 4 (light) and Blocks 2 and 3 (dark) are kept verbatim-identical
within each pair. When you modify a token value, update both members of the
pair. The CSS header comment in the THEME LAYER section includes a Python
verification command that must print `SYNCED PAIR IDENTICAL` before committing.

### Adding a token

- **Invariant** (same value in both themes): add to `:root` only.
- **Theme-sensitive**: add the light value to Blocks 1 and 4; add the dark value
  to Blocks 2 and 3 (same value within each pair).
- Run the SYNCED-PAIR check from the CSS comment header before committing.
- Add the token to `priv/static/design-system.html` and re-run
  `design-system.spec.ts` to keep the regression gate green.

The complete token catalog (exact names and values) lives in
`rulestead_admin/priv/static/css/rulestead_admin.css` under the INVARIANT
TOKENS and THEME LAYER sections.

## Stable Mounted Seam

Operators and host apps can treat these URL shapes as the stable v0.1.0
mounted seam:

- `/admin/flags`
- `/admin/flags/new`
- `/admin/flags/audit`
- `/admin/flags/:key`
- `/admin/flags/:key/edit`
- `/admin/flags/:key/rules`
- `/admin/flags/:key/simulate`
- `/admin/flags/:key/rollouts`
- `/admin/flags/:key/kill`
- `/admin/flags/:key/timeline`
- `/admin/audiences`
- `/admin/audiences/:key`
- `/admin/audiences/:key/edit` (preview → confirm → audit)
- `/admin/audiences/:key/archive` (preview → confirm → audit)

The `env` query parameter is the canonical environment selector across the
mounted UI.

Lifecycle review also relies on preserving `return_to` when operators move from
the queue into detail or cleanup review. Keep those links mounted and
shareable; do not replace them with host-local shortcuts that drop queue
context.

This stable seam is intentionally narrower than every internal route detail.
`rulestead_admin` remains a mounted companion, and the host still owns
authentication, actor identity, session truth, and `can?/4` policy decisions.

## What Operators Can Do

The shipped package supports these bounded workflows:

- browse and filter flags
- review one flag's details and environment state
- create and edit flag metadata
- save draft and publish rulesets
- simulate and explain one flag decision in one environment
- stage rollout changes
- engage or release a kill switch
- review redacted audit timeline entries and roll back supported changes

These are package-level workflows. They do not freeze the internal LiveView
implementation.

## Operator sandbox (FleetDesk)

The [Adoption Lab](../introduction/adoption-lab.md#operator--admin-feel) mounts the same operator
routes in a runnable FleetDesk host. Use it to click through bounded workflows
before wiring `rulestead_admin` into your app:

- sign in at `/demo/sign-in` (deterministic demo session)
- browse `/admin/flags?env=staging`
- advance rollouts at `/admin/flags/:key/rollouts`
- engage kill switch at `/admin/flags/:key/kill`
- filter audit at `/admin/flags/audit`

Run `docker compose up --build` from the repo root, or see
[FleetDesk demo (examples/demo)](https://github.com/szTheory/rulestead/tree/main/examples/demo) for automation commands.

## Lifecycle Review Workflow

The mounted companion is the canonical queue-first lifecycle surface for host
apps that install `rulestead_admin`.

Use this default path:

1. open `/admin/flags?env=prod`
2. keep `?env=` intact as the canonical environment selector
3. review lifecycle guidance from the mounted queue first
4. compare that queue view with `mix rulestead.lifecycle` when CLI parity helps
5. move into cleanup only when the evidence says explicit review is warranted
6. preserve `return_to` so preview, confirm, and audit can land the operator
   back in the same queue

That is the public lifecycle workflow the docs rely on. It is still a mounted
companion, not an independent admin product, and the host continues to own
identity, authorization, and surrounding layout.

## Cleanup Flow

Cleanup is not a hidden button press. The supported workflow is `cleanup ->
preview -> confirm -> audit`.

Mounted admin should make these boundaries obvious:

- lifecycle guidance is read-only review
- cleanup is the viewer-readable advisory step
- preview is the first execute/admin-only mutation surface
- confirm is the final execute/admin-only mutation surface
- archive happens only after preview and confirm
- audit continuity remains part of the operator contract

Use `mix rulestead.lifecycle` for the read-only report and the mounted
companion for the queue and route-backed review flow. Do not promise selector
or DOM stability for any of these screens.

## Audience Workflows

Reusable **Audience** management is a mounted companion workflow. Core
validates dependency, preview, and audit truth; the mounted package renders
policy-aware **used-by** tables and operator copy with redaction when reads
are denied.

Audience mutations follow **preview → confirm → audit** (parallel to cleanup).
Compare surfaces show **dependency findings** as **read-only** — there is no
Apply or Publish action from compare routes.

## What Is Not Public API

The following are intentionally not stable contracts:

- `RulesteadAdmin.Live.*` modules
- `RulesteadAdmin.Components.*` modules
- internal helper modules
- socket assigns
- CSS classes, DOM structure, and test selectors

If you need a stable integration point, use the router seam, policy behaviour,
session keys, and documented URL conventions instead.

## Blast radius governance in protected environments

Protected environments (for example `prod`) trigger blast-radius threshold
evaluation on audience edit and archive mutations. The mounted workflow is:

1. **Preview impact** — assess threshold using preview basis (authored
   references and **explicit samples** only; no affected-user or population counts)
2. **Below threshold** — **Continue to confirm** for direct apply with a fresh
   preview fingerprint
3. **Above threshold** — **Continue to submit** a **change request** for review
4. **Review and execute** on the change-request show surface after approval

**Blocked states** (indeterminate assessment, partial dependency visibility,
stale preview fingerprint) show **Cannot evaluate safely** with back navigation
only — no Continue, Apply, or Submit.

The blast-radius panel shows verdict, threshold line, and breach reasons. It
never surfaces audience predicate or condition definitions. **Host-owned policy**
(`Rulestead.Admin.Policy` / your Authorizer module) governs who may submit and
approve change requests; the mounted companion presents core truth only.

## Auto-advance on the rollouts page

The mounted rollouts page (`/admin/flags/:key/rollouts?env=`) includes an
**Auto-advance** panel between guardrail status and guardrail interventions.
Operators configure opt-in policy there; core owns persistence and eligibility;
the panel renders bounded state only.

### Panel location and fail-closed modes

The panel derives one of six modes on load:

1. **disabled** — auto-advance off or prerequisites not met
2. **blocked_health** — guardrail status is held, pending data, or rollback
   triggered; copy does not imply automation will advance
3. **blocked_policy** — policy save denied or incomplete authored plan
4. **blocked_protected_env** — protected environment; save allowed, execute routes
   through change request (see below)
5. **scheduled** — observation window closed and a governed tick is scheduled
6. **eligible** — policy enabled, prerequisites met, ready for window close or tick

Remediation stays on this rollout stage. The UI does not show fleet health,
Rulestead-owned metrics, or percentage-of-time rollout controls.

### Policy save and authorization

Operators save policy inline: `enabled`, `observation_window_seconds`,
`next_stage`, and `next_percentage`. Save requires `:advance_rollout` capability
through your `Rulestead.Admin.Policy` implementation. Denied saves show the
standard capability explanation — not a silent failure.

**Host-owned policy** governs who may configure auto-advance, submit change
requests, and approve protected-environment advances. The mounted companion
presents core truth; it does not bundle auth.

### Pending observation state

When the monitoring window is still open, the panel shows **pending observation**
copy with `window_ends_at` (for example: observation window open until close;
auto-advance evaluates at window close). When a scheduled execution exists for
this flag, environment, and rollout rule with `metadata.source` of
`guardrail_automation`, the panel shows the tick time and that advance runs only
if guardrails remain healthy after the window.

Refresh after manual advance, hold, or rollback — superseded ticks must not
leave stale scheduled state visible.

### Protected environments

In protected environments where `change_request_required?(:advance_rollout)` is
true, an informational callout explains that eligible automation **submits a
change request for approval** — it will not auto-apply. Operators may still save
and enable policy; execution routing matches manual advance governance.

### Timeline: automation vs manual

The timeline and rollouts intervention excerpt label successful automation with
**`guardrail_automation`** on `rollout.advance` events (title such as "Automatic
rollout advance" with observation-window bounds). Manual hold, advance, and
rollback actions keep distinct manual labels. Support and on-call can see
whether a stage transition was operator-driven or window-close automation
without inferring from ruleset diffs alone.

## Audience preview evidence (mounted admin)

Edit, archive, and delete audience workflows call
`Rulestead.preview_audience_impact/3` from the host app. The mounted companion
does not configure `:preview_evidence_resolver` — the host does.

When the host configures a resolver, `impact_preview` may include:

- a **Sample cohort** table from bounded `sample_evidence` rows
- an **Impression summary** block from `impression_evidence`

`preview_basis` values operators should expect:

- `authored_state_and_explicit_samples`
- `authored_state_with_host_evidence`
- `authored_state_host_evidence_unavailable`

Fail-closed errors (`{:error, error}`) render with `role="alert"` and
`error.message`. Confirm links must preserve `preview_fingerprint` and
`preview_schema_version` so stale evidence cannot slip through apply.

This is **mounted presentation** only — not fleet dashboards, not a population
analytics product, and not a standalone admin control plane.

## Operational Guidance

Treat the admin package as the control surface around runtime truth:

1. author or review the ruleset
2. publish the environment-specific change
3. verify outcome through explainability or telemetry
4. use timeline and rollback when you need to retrace or reverse a change

That keeps the operator story aligned with the core package's deterministic
runtime behavior.

## Related Guides

- [Rollout](rollout.md) for staged release workflows
- [Explainability](explainability.md) for support and simulation usage
- [Multi-env](multi-env.md) for environment selection and promotion habits
- [rulestead_admin on HexDocs](https://hexdocs.pm/rulestead_admin) for the package-local
  host contract
