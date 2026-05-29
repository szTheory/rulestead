# Explainability

Rulestead explainability is for support, operators, and incident response. The
goal is not raw internal trace dumping. The goal is a bounded answer to "why
did this subject get this result in this environment?"

## Two Explain Paths

Use the path that matches where you are standing:

- `Rulestead.explain(flag_payload, context)` when you already have the authored
  flag payload and want a pure, human-readable explanation
- `Rulestead.explain_flag(flag_key, environment_key, context, opts \\ [])` when
  an operator needs the mounted admin-safe runtime seam for one live flag

The root `explain/2` call stays payload-first. The admin-safe `explain_flag/4`
adds environment lookup, authorization, and redaction at the package boundary.

## What A Good Explanation Tells You

A useful explanation answers:

- which flag and environment were evaluated
- whether a rule matched or the default applied
- which rule matched
- whether deterministic bucketing affected the outcome
- what the final value or variant decision was

That is enough for support and operator workflows without exposing raw actor
payloads.

## Keep Context Bounded

Explain requests should carry only the bounded context fields the runtime uses:

```elixir
context =
  Rulestead.Context.new(
    targeting_key: "user_123",
    environment: "prod",
    attributes: %{country: "US", plan: "pro"}
  )
```

Avoid passing whole application structs or raw user payloads. The explain path
is designed around explicit context and redacted metadata.

## Operator Workflow

From the mounted admin package, the stable explain route is:

- `/admin/flags/:key/simulate?env=:environment`

Use it like this:

1. choose the flag
2. choose the environment through `?env=`
3. enter the bounded targeting context
4. read the explanation and matched-rule outcome
5. share the operator-facing URL or summarize the explanation in a ticket

The URL and environment convention are stable. Internal LiveView implementation
details are not.

**Try it in FleetDesk:** open the adoption lab UI at `http://localhost:3000` and
read the **Support journey · explain API** panel, or use `/admin/flags/:key/simulate`
after signing in at `/demo/sign-in`. See [Adoption Lab](../introduction/adoption-lab.md#support--explain-one-outcome).

## Lifecycle Evidence For Support And SRE

Support and SRE should not use explainability in isolation when lifecycle
questions appear. Use three bounded surfaces together:

- explain output for one decision path
- lifecycle evidence from mounted review or `mix rulestead.lifecycle`
- audit history for who changed what and why

That combination answers the real operator questions:

- is the flag still expected to be active?
- was it an archive candidate or blocked by missing evidence?
- did a recent cleanup or owner handoff happen?
- who changed the lifecycle posture?

This keeps lifecycle evidence, explain traces, and audit history aligned for
support handoff without turning explainability into a second lifecycle system.

## Redaction Rules

Explain and simulation workflows should stay redacted by default:

- do not surface raw traits or PII unless the host explicitly allowlists a
  bounded key
- prefer `targeting_key` and a small set of business-safe attributes
- keep screenshots and support notes focused on the explanation, not the full
  input payload

The admin-safe explain seam returns redacted context metadata alongside the
explanation so operators can confirm what was actually used without dumping the
full trait bag.

## Audience Trace In Explain Output

Explain and simulate output includes **Audience** trace steps for reusable
targeting: `matched`, `missed`, `missing from snapshot`, and `archived`.
Resolution is **snapshot-local** — no live database reads, mounted-admin
lookups, host identity resolution, or observability queries during audience
evaluation.

Support-safe explain permalinks include flag, environment, tenant, and
targeting key only — never raw traits.

When audience questions exceed one explain call, escalate through explain +
dependency inventory + audit history. Rulestead does not provide built-in
observability dashboards or package-owned metrics for this path.

## Simulation And Explain Belong Together

Simulation is the operator workflow for asking "what would happen for this
context right now?" Explainability is the readable trace that answers it.

Use that pair when:

- support needs to answer a customer report
- an operator wants to verify a rollout step before publishing
- on-call needs to understand whether a flag or rule caused an incident

## Escalation Boundary

If an explanation is not enough, escalate to:

- the timeline route for change history
- lifecycle evidence from `mix rulestead.lifecycle` or the mounted queue
- telemetry for aggregate runtime signals
- the authored ruleset itself for exact rule order and conditions

Do not escalate by depending on `RulesteadAdmin.Live.*` internals. That would
couple your workflow to implementation details the package does not stabilize.
