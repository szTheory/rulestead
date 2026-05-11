# `Rulestead.Credo.NoRawTraitsInTelemetryMeta`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex#L2)

## Basics

> #### This check is disabled by default. {: .neutral}
>
> [Learn how to enable it](`e:credo:config_file.html#checks`) via `.credo.exs`.

This check has a base priority of `high` and works with any version of Elixir.

## Explanation

Telemetry metadata must not include raw trait-like keys such as email or IP.
Emit redacted or allowlisted fields only.

## Check-Specific Parameters

*There are no specific parameters for this check.*

## General Parameters

Like with all checks, [general params](`e:credo:check_params.html`) can be applied.

Parameters can be configured via the [`.credo.exs` config file](`e:credo:config_file.html`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
