# Rulestead Copy Kit

Source: `brandbook/brand-book.md` sections 7, 8, 22, 23, 24, and 27, plus
`.planning/research/ECOSYSTEM_SYNERGY.md` for the szTheory suite note.

## GitHub

### Repository Description

Elixir-native feature management for safe rollout, multivariate config, and explainable runtime decisions.

### Suggested Topics

`elixir`, `phoenix`, `feature-flags`, `feature-management`, `remote-config`, `rollout`, `liveview`, `beam`

## Hex.pm

### `rulestead` Package Description

Elixir-native feature management for safe rollout, multivariate config, and explainable runtime decisions.

### `rulestead_admin` Package Description

Optional mounted Phoenix LiveView operator companion for Rulestead feature management.

## Short Blurb

Elixir-native feature management with ordered rules, multivariate values, and explainable runtime decisions for Phoenix teams.

## README Intro / Hero

> Runtime decisions, made clear.

Rulestead is an Elixir-native feature management system for safe rollout, multivariate config, and explainable runtime evaluation. It fits Phoenix and Plug apps while remaining useful as infrastructure for broader BEAM systems.

## Landing Hero

### Headline

Runtime decisions, made clear.

### Subheadline

A self-hostable feature management system for Elixir with ordered rules, local evaluation, and lifecycle-aware governance.

### Primary CTA

Start the quickstart

### Secondary CTA

Read the evaluation guide

## Feature Blurbs

### Ordered rules

Model rollout as ordered, inspectable rules instead of opaque precedence. Teams can see what matched, why it matched, and what value was returned.

### Multivariate values

Use typed values for booleans, variants, and remote config without turning runtime behavior into scattered conditionals.

### Local, explainable evaluation

Evaluate decisions locally in Phoenix and Plug workflows, then inspect the reasoning behind each result when operators need to understand production behavior.

## szTheory Suite Brand Architecture

The szTheory libraries share a technical posture: BEAM-native design, domain-driven boundaries,
explicit `:telemetry` seams, protocol delegation, and no tight coupling between sibling packages.
Each library should feel like part of the same engineering family without borrowing another
library's domain.

| Library | Unique role |
|---------|-------------|
| Rulestead | Feature flags, experiments, multivariate config, deterministic rollout, and explainable runtime decisions. |
| Parapet | SRE and reliability substrate for correlating deploys, config changes, and production regressions. |
| Scoria | AI governance, human-in-the-loop approvals, agent tool execution, and trace logging. |
| Cairnloop | Support OS workflows, customer-support automation, and AI-drafted response governance. |

Rulestead can integrate with the suite through clean boundaries: emit predictable telemetry for
Parapet, expose governed flag state or emergency actions to Scoria through explicit tools, and
serve deterministic policy decisions for Cairnloop rollout. The brand story is shared discipline,
not shared runtime ownership.
