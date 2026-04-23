# Stack — Rulestead

**Confidence:** High. All choices ported verbatim from `prompts/rulestead-engineering-dna-from-prior-libs.md` (validated across 7 prior shipped Elixir OSS libs).

## Core

| Component | Choice | Version | Rationale |
|---|---|---|---|
| Language | Elixir | `~> 1.17` (matrix: 1.17 + 1.19) | Matches prior lib DNA; OTP 26+ stable; 1.19 testbed for next release cycle |
| Web | Phoenix | `~> 1.7` | Current stable; host-app integration target |
| LiveView | Phoenix.LiveView | `~> 1.0` | Admin UI substrate |
| Data | Ecto + ecto_sql | `~> 3.11` | Authoring store, migrations |
| DB | PostgreSQL | `>= 15` | Partial unique indexes, triggers (for lifecycle + audit), `gen_random_uuid()` |
| Jobs | Oban | `~> 2.17` (optional dep) | Scheduled snapshot refresh, future scheduled-changes; context propagation middleware |
| HTTP | Plug | `~> 1.15` | Integration seam |
| Telemetry | telemetry | `~> 1.2` | Primary instrumentation |
| Config | NimbleOptions | `~> 1.0` | Validated config schemas (lattice_stripe pattern) |
| Snapshot encode | `:erlang.term_to_binary` + `Jason` (optional) | stdlib + `~> 1.4` | Binary-packed ETS payload + JSON export |
| Testing | ExUnit + Mox + StreamData | stdlib + `~> 1.0` + `~> 1.0` | Behavior mocks + property tests for bucketing determinism |

## Dev tooling

| Component | Choice | Rationale |
|---|---|---|
| Format | `mix format` | Stdlib; `.formatter.exs` imports `:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug` |
| Lint | Credo strict + custom checks | `Rulestead.Credo.*` checks enforce domain rules (no-eval-outside-context, no-raw-traits-in-telemetry, etc.) |
| Types | Dialyzer | PLT cache split restore→build-if-miss→save |
| Docs | ExDoc | `mix docs --warnings-as-errors` as CI gate; 3-folder guides split |
| Release | release-please (google-github-actions) | Linked-versions for `rulestead` + `rulestead_admin` siblings |
| CI | GitHub Actions | Lint + test matrix + integration + installer path-gate + release-please + publish-hex + post-publish verify + daily drift |
| E2E | Playwright | GitHub Pages daily demo host app |

## Optional / deferred

| Component | When | Rationale |
|---|---|---|
| Redis adapter | v0.3+ | Useful for multi-node deployments without DB polling; core runs on Postgres + ETS only |
| OpenTelemetry bridge | v0.2 or v0.3 | Opt-in behind `Code.ensure_loaded?(OpenTelemetry)` guard; primary signal is `:telemetry` |
| OpenFeature provider | v0.3+ | Bridge to OpenFeature Elixir SDK when that ecosystem matures |
| Multi-tenant scoping | v0.2 | Behavior pattern from mailglass DNA (`Rulestead.Tenancy` + `SingleTenant` no-op default) |

## What NOT to use

- **Hex namespace squatting** — don't register `rulestead_*` packages beyond core + admin until we ship them.
- **Deep Phoenix auth dependency** — admin integrates via host-app-supplied `Rulestead.Admin.Policy` behavior. No bundled auth stack.
- **Per-request DB reads for evaluation** — always go through snapshot + ETS cache.
- **Process dictionary magic for context** — prefer explicit Context struct + optional process-tree helpers with documented scope.
- **Custom Credo checks for style only** — every custom check must enforce a domain rule (evaluation determinism, tenancy scoping, telemetry PII hygiene).

---
*Confidence levels: all High unless noted. Rationale traces back to DNA doc §2 (convergent patterns adopted without debate).*
