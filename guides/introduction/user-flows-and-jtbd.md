# User Flows And Jobs To Be Done

Rulestead is not just "feature flags for Elixir." Teams hire it when they want
to ship code early, release it carefully, explain decisions clearly, and keep
the runtime contract boring in the best possible way.

This guide is the fast mental model. Read it when you want to understand what
Rulestead is for before you disappear into API details or mounted-admin screens.

## Why Teams Hire Rulestead

The core job is simple:

**Let the app keep moving while the release stays under control.**

That turns into a few concrete promises:

- developers can gate a new path without building a control plane first
- leads can roll out a change in steps instead of gambling on one big release
- operators can change live behavior without SSH sessions or ad hoc scripts
- support can answer "why did this user see that?" without guessing
- on-call engineers can stop the blast radius fast

Rulestead earns its keep when one product change needs all of those people to
work on the same system without stepping on each other.

## The Six People In The Story

Think of Rulestead as one shared system seen from six angles.

### 1. The App Developer

This person wants to ship `checkout_v2` without turning a routine feature into a
week-long infrastructure project.

Their job:

- gate one code path
- read a variant or typed config value
- test behavior locally without depending on Postgres in the hot loop

What good looks like:

- one explicit runtime call
- one explicit context
- deterministic results
- safe defaults when a flag is missing or not ready

### 2. The Tech Lead

This person is less worried about the `if` statement and more worried about the
release shape.

Their job:

- roll out in stages
- decide who can mutate production state
- require preview, approval, and audit where it matters
- keep flag debt from turning into archaeology

What good looks like:

- rollout intent is visible
- governance rules are explicit
- production changes leave evidence behind

### 3. The Operator

This is the person living in the mounted admin UI during normal business hours.

Their job:

- browse what is live
- adjust a rollout
- submit or execute a change through the right path
- review audit history without reading code

What good looks like:

- the UI feels like an operator workbench, not a toy dashboard
- environment scope is obvious
- risky actions show preview, confirmation, and reason fields

### 4. The Support Engineer

This person gets the ticket that says, "why did user `u_123` get the new
checkout?"

Their job:

- explain one decision for one actor
- share a link with engineering
- quote evidence without re-running the incident in their head

What good looks like:

- one explain flow
- one human-readable answer
- one shareable URL

### 5. The SRE Or On-Call Engineer

This person meets Rulestead when something is already going wrong.

Their job:

- kill a risky path quickly
- confirm the system is healthy enough to trust the result
- leave an audit trail for the post-mortem

What good looks like:

- kill switch is immediate
- diagnostics are legible
- rollback and audit do not require tribal knowledge

### 6. The Maintainer Or Contributor

This person is extending the library itself or integrating it into a broader
platform shape.

Their job:

- use the supported seams instead of patching internals
- understand what is public contract versus implementation detail
- keep the runtime story coherent as the system grows

What good looks like:

- narrow extension seams
- clear package boundaries
- docs that say where to plug in and where not to

## The Everyday Flows

The best way to understand the product is to watch one feature move through it.
Use a concrete example: a team is rolling out `checkout_v2`.

### Flow 1: Ship Behind A Flag

The developer adds the new checkout path behind a runtime call.

In this moment, Rulestead is doing the smallest valuable job:

- keep the code deployable before the feature is fully released
- let the host app pass explicit context
- return a deterministic decision

This is the "I need a safe seam in application code" job.

### Flow 2: Target The Right Audience

Now the team wants more than on/off.

They need to answer questions like:

- only for US users?
- only for premium accounts?
- 10% of eligible traffic first?
- one config payload in staging and another in production?

This is where flags stop being a boolean convenience and become a release
control surface.

### Flow 3: Preview Before You Regret It

Before a risky production change, the operator or lead wants to know what will
happen before it happens.

That creates a different JTBD:

- author rules
- simulate or review the decision path
- push changes through an explicit approval path when needed

This is not just "make a change." It is "make a reversible, reviewable change."

### Flow 4: Roll Out Without Holding Your Breath

The feature is ready, but the team does not want an all-at-once launch.

They want:

- staged rollout
- a reason attached to each change
- audit history that explains who changed what
- a fast escape hatch if signals go sideways

This is the operational heart of the system: release code separately from
release exposure.

Operators may enable **auto-advance** on a guarded rollout: they author the
next stage and observation window, the host supplies guardrail signal facts, and
Rulestead schedules a fail-closed tick at window close. In protected environments,
automation submits a change request instead of auto-applying; the timeline labels
**`guardrail_automation`** separately from manual advances. See
[Rollout](../flows/rollout.md) and [Admin UI](../flows/admin-ui.md).

### Flow 5: Explain One User's Reality

Support gets a ticket. A PM asks what is live. An engineer wonders whether the
rule order is doing what they thought.

The question is no longer "what did we configure?"

It is:

**What happened for this actor, in this environment, at this point in time?**

That is why explainability matters so much in Rulestead. It turns a flag system
from a black box into a supportable system.

### Flow 6: Survive The 3am Moment

Every mature flag system eventually gets judged during an incident.

The important jobs are brutally practical:

- disable the risky path
- confirm the change took effect
- understand whether the system is degraded or healthy
- hand clean evidence to the next human

If the library cannot do that, it does not matter how elegant the rule engine
looks in daylight.

## How The Flows Connect

The memorable model is:

**build, release, explain, recover**

Rulestead starts with build-time developer safety, grows into release-time
operator control, proves itself through support-time explainability, and earns
trust during recovery-time incident handling.

Those are not separate products. They are one chain:

1. a developer gates a feature
2. an operator rolls it out
3. support explains the outcome
4. SRE kills it if needed
5. audit and telemetry tell the story afterward

When the chain is intact, the library feels calm. When one link is missing,
teams fall back to Slack messages, emergency scripts, and folklore.

## What Rulestead Deliberately Is Not

Rulestead has boundaries. Those boundaries are part of the product shape, not a
missing paragraph in the docs.

- It is a sibling-package system, not a standalone SaaS control plane.
- The host app owns auth, actor identity, and final authorization policy.
- The mounted admin is optional; runtime-only adopters do not have to carry it.
- Context stays explicit; the runtime is not built around hidden global state.
- The goal is trustworthy release control for Phoenix teams, not infinite
  platform sprawl.

Those choices keep the system aligned with normal Elixir and Phoenix ownership
rules.

## Where To Go Next

If you are adopting Rulestead in your own app, the usual reading path is:

1. [Getting Started](getting-started.md) for the first-success loop
2. [Evaluation](../flows/evaluation.md) for the runtime mental model
3. [Admin UI](../flows/admin-ui.md) for operator-facing workflows
4. [Explainability](../flows/explainability.md) for support and debugging
5. [Testing](../recipes/testing.md) for fake-backed application tests

If you remember only one line, make it this:

**Rulestead helps one team ship one feature safely from first gated commit to
incident-response rollback, with an explanation available at every step.**
