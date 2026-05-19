# rulestead v0.1.0 - API Reference

## Modules

- [Rulestead.Credo.NoEvalOutsideContext](Rulestead.Credo.NoEvalOutsideContext.md): ## Basics
- [Rulestead.Credo.NoMutationOutsideMulti](Rulestead.Credo.NoMutationOutsideMulti.md): ## Basics
- [Rulestead.Credo.NoRawTraitsInLogger](Rulestead.Credo.NoRawTraitsInLogger.md): ## Basics
- [Rulestead.Credo.NoRawTraitsInTelemetryMeta](Rulestead.Credo.NoRawTraitsInTelemetryMeta.md): ## Basics
- [Rulestead.Credo.NoSocketCapturedInAsync](Rulestead.Credo.NoSocketCapturedInAsync.md): ## Basics
- [Rulestead.Store.Command](Rulestead.Store.Command.md): Shared key-first command structs for `Rulestead.Store` adapters.

- Public API
  - [Rulestead](Rulestead.md): Root public module for the `rulestead` package.
  - [Rulestead.Error](Rulestead.Error.md): Stable public error envelope for all non-bang and bang APIs.
  - [Rulestead.Flag](Rulestead.Flag.md)
  - [Rulestead.Result](Rulestead.Result.md): Stable Phase 3 evaluation result.

  - [Rulestead.Ruleset](Rulestead.Ruleset.md)

- Store Adapters
  - [Rulestead.Store.Ecto](Rulestead.Store.Ecto.md)
  - [Rulestead.Store.Redis](Rulestead.Store.Redis.md)

- Extensibility
  - [Rulestead.Runtime.Snapshot](Rulestead.Runtime.Snapshot.md)
  - [Rulestead.Store](Rulestead.Store.md): Key-first authoring store behavior for the Rulestead public API.
  - [Rulestead.Tenancy](Rulestead.Tenancy.md): Explicit seam for resolving and bounding tenant scope across runtime helpers.

