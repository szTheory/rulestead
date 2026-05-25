# Flag Lifecycle

Rulestead's lifecycle story is one operator loop from birth to retirement:
author explicit intent, review the shared queue, inspect evidence, run the
archive preview, confirm with a reason, and keep the audit trail intact.

This guide is the canonical lifecycle narrative for the sibling-package
release. `rulestead` owns the shared docs surface, while `rulestead_admin`
remains the mounted companion inside your host Phoenix app.

## What This Guide Assumes

- your host app owns identity, authorization, and session truth
- owner references are host-owned metadata, not a Rulestead directory
- lifecycle defaults are advisory scaffolding, not hidden policy
- archive readiness is evidence, not permission
- archive and cleanup stay explicit, previewable, and audited

If you only need the runtime evaluator, stay in `rulestead`. If your team also
needs the mounted operator workflow, add `rulestead_admin` and keep it mounted
inside the host app rather than treating it as a standalone product.

## The Operator Order

Use this sequence as the least-surprise default:

1. create a flag with explicit ownership and lifecycle intent
2. review the lifecycle queue in mounted admin or `mix rulestead.lifecycle`
3. inspect readiness evidence before mutating anything
4. run the cleanup preview
5. confirm the archive action with a reason
6. remove the dead host code on purpose
7. keep audit, support, and maintainer evidence easy to trace later

The order matters. The lifecycle system is not an auto-archive engine and it is
not a background policy bot. Operators author facts, and Rulestead computes
guidance from those facts plus bounded evidence.

## Birth: Create With Explicit Intent

Every new flag should start with two explicit pieces of metadata:

- who owns the lifecycle outcome
- what lifecycle posture the flag is expected to have

The host owns identity. Rulestead stores bounded lifecycle metadata, but it
does not create a user or team directory for you. The owner reference should be
a stable host-owned value such as `team-growth`, `svc-checkout`, or a person id
that your own systems understand.

Use the lifecycle defaults as recommendations:

- `release`, `experiment`, and `migration` usually start as expiring work
- `kill_switch`, `operational`, and `permission` usually need permanent posture
- `remote_config` should force an explicit choice instead of assuming a default

Those defaults are there to teach good hygiene. They are not policy and they do
not mutate flags on their own.

### What To Record Up Front

Capture:

- `owner_ref` as the stable ownership truth
- a bounded owner kind such as person, team, or service
- a display snapshot when readability helps operators
- the authored lifecycle mode and expected review horizon
- enough context for future reviewers to understand why the flag exists

This is the beginning of the lifecycle story. If ownership is vague at birth,
cleanup becomes guesswork later.

## Daily Work: Review The Queue First

Most lifecycle work is not archive work. Most lifecycle work is queue review:
which flags are active, who owns them, what evidence exists, and what deserves
attention next.

The canonical review surfaces are:

- the mounted admin workbench inside `rulestead_admin`
- the read-only CLI report from `mix rulestead.lifecycle`

Mounted admin gives operators a shareable, URL-backed queue. The CLI gives
maintainers and scripts the same lifecycle vocabulary in text or JSON.

### Mounted Review Flow

The mounted companion keeps lifecycle review inside the host app:

1. open the mounted flag inventory
2. preserve `?env=` in the URL so queue state stays shareable
3. filter by owner, lifecycle posture, readiness, or archived visibility
4. open the detail page when one flag needs deeper context
5. enter cleanup only after the evidence says that review is worthwhile

That keeps the primary workflow calm and explicit. The detail page is still a
read surface first. It should link operators into cleanup rather than turning
every detail page into a mutation console.

### CLI Review Flow

`mix rulestead.lifecycle` is the public read-only lifecycle report.

Use it when:

- you want the same lifecycle posture without opening mounted admin
- you need machine-readable JSON for scripts or release checks
- you are verifying that docs, admin, and release tooling all use one contract

The task should help answer:

- which flags are active or archived
- who owns them
- what readiness category they are in
- which evidence is strong, partial, weak, or missing
- what next action is recommended

The CLI is intentionally read-only. It reports; it does not archive.

## Readiness: Evidence, Not Permission

Archive readiness is advisory. `archive_candidate` is not permission. It is a
bounded recommendation built from lifecycle intent, evaluation evidence, and
code-reference evidence.

That distinction is central to Rulestead's operator trust model:

- authored lifecycle facts remain the durable truth
- readiness categories describe what the evidence currently suggests
- missing evidence must remain visible as uncertainty

Do not read `archive_candidate` as "safe to delete." Read it as "the system has
enough bounded evidence that this flag deserves an explicit cleanup review."

### Evidence Questions To Ask

Before you archive, ask:

- is the flag still evaluated recently?
- are code references still present?
- is the evidence quality strong, partial, or weak?
- are there blockers or unknowns that should stop cleanup?
- does the authored posture still match the intended use?

Unknown owner is not archive permission. Missing scans are not archive
permission. Quiet traffic is not archive permission by itself.

## Archive Flow: Preview, Confirm, Audit

Archive is a deliberate operator action. The canonical mounted workflow is
`cleanup -> preview -> confirm -> audit`.

Use this shape every time:

1. review the lifecycle evidence in the queue or cleanup screen
2. open the cleanup review as the advisory read surface
3. run the cleanup preview
4. confirm the action with a reason
5. verify the audit event and resulting archived state

`cleanup`, `preview`, `confirm`, and `audit` are not optional ceremony. They
are how the system stays trustworthy when the evidence is incomplete or when a
support/SRE question lands later.

### What The Preview Should Tell You

The preview should make it obvious:

- what lifecycle posture was authored
- why the system considers the flag ready or not ready
- which evidence supports or weakens that conclusion
- whether code references are still present
- which owner, actor, and environment context the review is happening in

If the preview exposes blockers or uncertainty, stop and resolve them. Do not
turn archive guidance into a race to clean up a queue faster.

### Why Reason Capture Matters

The confirm step should require a reason because the audit trail must explain
intent later:

- support may need to explain why a flag disappeared
- maintainers may need proof that cleanup followed the documented path
- on-call may need to confirm that the archive was deliberate, not hidden

An archived flag still has history. The audit trail is part of the product
surface, not an implementation detail.

## Retirement: Host Cleanup Still Matters

Archiving a flag is not the same as deleting every trace of it from your app.

Archived flags still require deliberate host-code cleanup. Remove:

- dead evaluation calls
- stale branches and templates
- no-longer-needed tests
- comments, docs, and handoff notes that imply the flag is still live

Rulestead can surface code-reference evidence, but your host repository still
owns the final removal work. That is another reason the host owns identity and
ownership truth: the real cleanup often spans code, rollout history, and team
responsibility outside the library boundary.

## Exception Paths

Not every flag should be archived quickly. Keep the exception cases visible.

### Permanent And Operational Flags

Some flags are meant to stay:

- kill switches
- operational safety controls
- permission gates
- long-lived remote configuration with explicit authored permanence

Those flags still deserve ownership, review, and evidence. They just should not
be pushed toward cleanup by default.

### Unknown Owner Or Weak Evidence

When ownership is missing or evidence quality is weak:

- do not archive from uncertainty alone
- use review-oriented guidance rather than pretending the answer is known
- resolve the owner handoff inside the host team first
- refresh code-reference or evaluation evidence before acting

The honest answer is sometimes "review manually." Rulestead should say that
plainly.

## Support And SRE Appendix

Support and on-call teams usually start from a question, not from a cleanup
plan:

- why did this flag still serve traffic?
- why was this flag archived?
- who owned the decision?
- which evidence supported the recommendation?

Use these three seams together:

- lifecycle evidence from mounted admin or `mix rulestead.lifecycle`
- explainability for one concrete evaluation path
- audit history for who changed what and why

That gives you a bounded, shareable answer without exposing internal
implementation details or private admin internals.

## Choosing The Right Surface

Use this quick routing rule:

- onboarding or product orientation: start here
- runtime semantics and pure evaluation: [evaluation.md](evaluation.md)
- mounted queue and operator routes: [admin-ui.md](admin-ui.md)
- support and incident explanation: [explainability.md](explainability.md)
- release-facing lifecycle verification: [../recipes/testing.md](../recipes/testing.md)

One lifecycle story, many entrypoints. The shared guide is the spine; the other
guides deepen one part of the workflow without creating a second narrative.

## Practical Checklist

For each flag, aim to leave this true:

- ownership is explicit from birth
- lifecycle posture is authored, not implied
- review happens through one canonical queue
- `archive_candidate` is treated as advisory evidence, not permission
- archive runs through preview, confirm, and audit
- host code cleanup happens deliberately after archive

That is the Rulestead lifecycle contract from birth to retirement.
