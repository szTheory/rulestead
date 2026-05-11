# rulestead v0.1.0 - API Reference

## Modules

- [Rulestead](Rulestead.md): Root public module for the `rulestead` package.
- [Rulestead.Admin.Authorizer](Rulestead.Admin.Authorizer.md): Central policy gate for Phase 7 admin reads and writes.

- [Rulestead.Admin.Lifecycle](Rulestead.Admin.Lifecycle.md): Derives persisted admin lifecycle state from authored flag data.

- [Rulestead.Admin.Policy](Rulestead.Admin.Policy.md): Host-owned authorization seam for mounted admin actions.
- [Rulestead.Admin.Redaction](Rulestead.Admin.Redaction.md): Allowlist-driven redaction for admin telemetry and audit metadata.

- [Rulestead.AuthError](Rulestead.AuthError.md): Constructors for auth-domain `Rulestead.Error` values.

- [Rulestead.Config](Rulestead.Config.md): Validated Phase 5 host-app seam configuration.
- [Rulestead.ConfigError](Rulestead.ConfigError.md): Constructors for config-domain `Rulestead.Error` values.

- [Rulestead.Context](Rulestead.Context.md): Canonical runtime context used by the Phase 3 evaluator surface.

- [Rulestead.Credo.NoEvalOutsideContext](Rulestead.Credo.NoEvalOutsideContext.md): ## Basics
- [Rulestead.Credo.NoMutationOutsideMulti](Rulestead.Credo.NoMutationOutsideMulti.md): ## Basics
- [Rulestead.Credo.NoRawTraitsInLogger](Rulestead.Credo.NoRawTraitsInLogger.md): ## Basics
- [Rulestead.Credo.NoRawTraitsInTelemetryMeta](Rulestead.Credo.NoRawTraitsInTelemetryMeta.md): ## Basics
- [Rulestead.Credo.NoSocketCapturedInAsync](Rulestead.Credo.NoSocketCapturedInAsync.md): ## Basics
- [Rulestead.EvaluationError](Rulestead.EvaluationError.md): Constructors for evaluation-domain `Rulestead.Error` values.

- [Rulestead.Fake](Rulestead.Fake.md): Contract-faithful in-memory store adapter for tests.
- [Rulestead.Fake.Control](Rulestead.Fake.Control.md): Test-only controls for `Rulestead.Fake`.
- [Rulestead.KillSwitchError](Rulestead.KillSwitchError.md): Constructors for kill-switch-domain `Rulestead.Error` values.

- [Rulestead.LiveView](Rulestead.LiveView.md): Explicit LiveView helpers for carrying `%Rulestead.Context{}` and eagerly
assigning runtime-backed flag values onto a socket.

- [Rulestead.Oban](Rulestead.Oban.md): Explicit Oban-facing helpers for serializing and restoring
`%Rulestead.Context{}` values across job boundaries.

- [Rulestead.Oban.Middleware](Rulestead.Oban.Middleware.md): Explicit enqueue seam for attaching a serialized rulestead context to jobs.

- [Rulestead.Oban.Worker](Rulestead.Oban.Worker.md): Worker-side seam that restores the serialized `%Rulestead.Context{}` from an
Oban job without repeating helper boilerplate in each worker module.

- [Rulestead.Phoenix](Rulestead.Phoenix.md): Explicit Phoenix-facing helpers for building `%Rulestead.Context{}` values.
- [Rulestead.Plug](Rulestead.Plug.md): Plug-facing seam that assigns a normalized `%Rulestead.Context{}` onto
`conn.assigns[:rulestead_context]`.

- [Rulestead.Result](Rulestead.Result.md): Stable Phase 3 evaluation result.

- [Rulestead.RulesetError](Rulestead.RulesetError.md): Constructors for ruleset-domain `Rulestead.Error` values.

- [Rulestead.Store](Rulestead.Store.md): Key-first authoring store behavior for the Rulestead public API.
- [Rulestead.Store.Command](Rulestead.Store.Command.md): Shared key-first command structs for `Rulestead.Store` adapters.
- [Rulestead.StoreError](Rulestead.StoreError.md): Constructors for store-domain `Rulestead.Error` values.

- [Rulestead.Telemetry](Rulestead.Telemetry.md): Shared telemetry helpers for the locked Phase 4 public event catalog.

- [Rulestead.TestHelpers](Rulestead.TestHelpers.md): Public fake-backed test helpers for host app tests.

- Exceptions
  - [Rulestead.Error](Rulestead.Error.md): Stable public error envelope for all non-bang and bang APIs.

## Mix Tasks

- [mix rulestead.install](Mix.Tasks.Rulestead.Install.md)

