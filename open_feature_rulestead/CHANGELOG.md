# Changelog

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 1.0.0 — Promotion, not rewrite

`open_feature_rulestead` graduates to `1.0.0` alongside its sibling packages.
This is the **same battle-tested code** that has been running in production —
now honestly versioned. **Zero breaking changes.**

- **No public API changes.** The provider contract — `initialize/3`,
  `resolve_*_value/4`, `shutdown/1` — is unchanged. The context translation
  and resolution metadata boundaries documented in the README remain the same.
- **Upgrade is a dependency-pin bump only.** Point your `mix.exs` at the `1.x`
  line (`~> 1.0`) and run `mix deps.get`. No call-site audit, config change, or
  host-app integration work is required.
- **Independent versioning.** `open_feature_rulestead` versions independently
  of the `open_feature` SDK. This package ships `1.0.0` while depending on
  `open_feature ~> 0.1.3` — that is intentional and idiomatic. The provider
  version reflects the maturity of this adapter, not the version of the upstream
  OpenFeature SDK it wraps.
- **`rulestead` sibling dependency.** This package is not release-please managed.
  It publishes manually, strictly after `rulestead@1.0.0` is live on Hex, and
  depends on `{:rulestead, "~> 1.0"}` — a loose major pin that floats against
  the stable post-1.0 core rather than coupling to the provider's own version.

The `1.0.0` tag is a statement of confidence, not a migration event.
