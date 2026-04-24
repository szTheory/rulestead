# Conventions

This document states the discipline layer for the public `v0.1.0` release.
These rules exist so the docs, tests, runtime behavior, and mounted admin seam
stay aligned.

## Principles

- Runtime decisions must be deterministic for the same inputs
- Rules are evaluated in order, and first match wins
- Tenant and environment scope must be explicit, not ambient
- Merge-blocking tests should prefer fake-backed workflows over live infra
- Telemetry and audit paths must not carry raw PII by default

## Determinism

Evaluation should produce the same result for the same flag definition,
context, and snapshot. Sticky bucketing depends on stable inputs, so callers
should provide explicit targeting identity instead of relying on hidden process
state or request-global magic.

## Precedence

Rulesets are ordered documents. The first rule that matches controls the
decision; the default value applies only when no rule matches. Documentation,
tests, and operator workflows should describe precedence in that order rather
than implying score-based or merge-based behavior.

## Tenancy and environment scope

Scope is always carried through explicit inputs such as
`tenant_key`, `environment`, and host-provided session/query values. Do not
assume cross-tenant defaults or implicit environment switching. If a host app
mounts `rulestead_admin`, preserve the documented `?env=` query convention and
provide the session values the package expects.

## Testing posture

The default test posture is fake first. Use `Rulestead.Fake` and the published
test helpers for merge-blocking coverage, then layer integration tests on top
when a seam specifically needs real framework proof. This keeps runtime tests
fast, reproducible, and independent of live database setup on the hot path.

## Privacy and redaction

Telemetry and audit output should describe what happened without leaking raw
traits, actor payloads, or secrets. The public telemetry contract is documented
in [guides/flows/telemetry.md](guides/flows/telemetry.md); treat its bounded
metadata spine and redaction rules as the default for adjacent instrumentation
and operational docs.

## Mechanical guardrails

These conventions are backed by existing enforcement, not just prose:

- custom Credo checks already block raw trait keys in telemetry metadata
- custom Credo checks already block raw trait keys in logger metadata
- custom Credo checks already push evaluation entrypoints through the intended
  context boundary

When you change a public-facing seam, update the docs and tests in the same
change so the contract remains auditable.
