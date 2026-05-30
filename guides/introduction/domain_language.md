# Domain Language & Concepts

Welcome to Rulestead! Feature flag vocabulary varies widely across the industry. Teams often use *flag*, *feature*, *toggle*, *switch*, *rule*, and *remote config* interchangeably. 

To ensure clear communication and prevent mental model leaks from other systems, Rulestead uses a strict, unified vocabulary. This guide defines the core concepts you will see in the UI, API, and telemetry.

## Core Distinctions

### Flag vs Feature vs Toggle
* **Flag** (Canonical) — A named runtime decision point with an owner, a lifecycle, a value type, and rules that produce a value given a context. This is the term used everywhere in Rulestead.
* **Feature** — The actual product capability the flag gates. *Flags gate features; flags are not features.*
* **Toggle** — A specific *kind* of flag (boolean-typed, release category). Every toggle is a flag, but not every flag is a toggle.

### Rule vs Strategy vs Condition
* **Rule** (Canonical) — One ordered entry in a ruleset. It matches a set of conditions and produces an outcome. Rulestead uses an ordered-rules model (like a firewall) rather than a precedence-based gate model.
* **Condition** — A predicate inside a rule (e.g., `plan == "enterprise"`).
* **Strategy** — How a matched rule produces a value (e.g., forced value, percentage rollout, variant split).

### Audience vs Segment vs Cohort
* **Audience** (Canonical) — A reusable targeting definition, surfaced in the Admin UI. Every audience has a key, description, and targeting criteria.
* **Segment** — Internal implementation detail. Never surfaced in user-facing copy.

### Variant vs Value
* **Variant** — One named option in a multivariate flag (e.g., `:control`, `:treatment_a`), with a value and an optional weight.
* **Value** (Canonical) — The resolved, typed output of an evaluation.

### Rollout
* **Rollout** (Canonical) — The progressive expansion of a flag's exposure (0% → N% → 100%) over time or conditions. A flag can have at most one active rollout at a time. 

### Kill Switch
* **Kill Switch** (Canonical) — An immediate, flag-wide override that forces a specific variant (usually the safe default) regardless of rules. Engaging or releasing a kill switch always generates an audit trail.

### Context & Actor
* **Context** (Canonical) — The full evaluation input, including the actor, tenant, environment, attributes, and request metadata.
* **Actor** (Canonical) — The entity whose experience the flag affects (e.g., a user, service, or job).
* **Targeting Key** (Canonical) — The stable identifier used for deterministic bucketing (usually the actor ID, but can be overridden).

## Architecture Concepts

### Snapshot vs Manifest
* **Snapshot** — The in-memory compiled representation of all flags, rulesets, and audiences for fast local evaluation. Snapshots are versioned, immutable, and automatically refreshed via PubSub.
* **Manifest** — The declarative source-of-truth document (YAML/JSON) used in flag-as-code workflows. Manifests are imported; snapshots are compiled.

## Lifecycle States

* **Draft** — Created, not yet activated.
* **Active** — Being evaluated in the intended environment.
* **Archived** — No longer evaluated; kept for audit history.
* **Killswitched** — Active but forcibly overridden by an engaged kill switch.
* **Potentially Stale** — Nearing its `expected_lifetime_days` without recent evaluations.
* **Stale** — Past expected lifetime, no evaluations recently. Surfaced in the UI for cleanup.
* **Retired** — Explicitly removed from production after cleanup.
