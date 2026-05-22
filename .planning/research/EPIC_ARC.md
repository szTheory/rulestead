# Rulestead Strategic Arc: Path to v1.0.0

**Date:** 2026-05-17
**Goal:** Map out a multi-milestone gameplan to deliver meaty, expected features that make Rulestead a production-ready, batteries-included platform without hitting diminishing returns.

## Overview
We have completed the foundational milestones (v0.1.0 - v0.4.0) establishing deterministic evaluation, an admin UI, governance workflows, OpenFeature integration, lifecycle hygiene, and experimentation. To reach a stable, deeply trusted v1.0.0, the platform must solve the hardest remaining operational challenges for Elixir teams: **distributed scaling**, **multi-environment promotion**, and **enterprise-grade authorization**.

This Arc establishes the prerequisite flow: 
1. Scale the data layer first (v0.5.0)
2. Solve environment syncing and tenancy second (v0.6.0)
3. Finalize API stability and UX for GA (v1.0.0)

---

## Milestone v0.5.0: Advanced Delivery & Distributed Scale
**Theme:** The Infrastructure Release
**Focus:** Ensuring Rulestead can safely handle massive distributed load across multiple Phoenix nodes without polling bottlenecks. 

### Why this is next:
Currently, the system relies on Ecto polling and ETS snapshots. For high-scale deployments, developers expect an external, centralized cache (Redis) and immediate cache invalidation to prevent cross-node drift. This is a hard prerequisite before adding multi-tenant or heavy payload features.

### Scope:
- **Redis Adapter:** An official `rulestead_redis` package (or built-in adapter) to serve as a fast external state store and cache.
- **Distributed Invalidation (Streaming Deltas):** A PubSub-based invalidation mechanism (e.g., via Redis PubSub or Phoenix.PubSub) so nodes receive push notifications for flag updates instantly, removing the need for heavy DB polling.
- **Infrastructure Observability:** Exposing cache age, hit/miss ratios, and node topology health in the Admin UI so SREs can trust the sync state at 3am.

---

## Milestone v0.6.0: Multi-environment Sync & Tenancy
**Theme:** The Enterprise Release
**Focus:** Workflows for deploying configurations across environments and isolating tenant data.

### Why this follows v0.5.0:
Once the infrastructure can handle scale, the operator workflow needs to scale. Teams expect to safely promote flags from Dev -> Staging -> Prod. Doing this requires stable underlying state sync (built in v0.5.0).

### Scope:
- **Environment Promotion & Diffing:** Visual diffs between environments and 1-click promotion of rules/segments across boundaries.
- **Import / Export GitOps:** Formalizing state export to JSON/YAML to support GitOps pipelines.
- **First-class Multi-tenant Helpers:** Providing explicit data structures and API seams to isolate tenant flag state (e.g., distinct salts or overrides per tenant).

---

## Milestone v1.0.0: General Availability (GA)
**Theme:** The Polish Release
**Focus:** API lockdown, documentation perfection, and security hardening.

### Why this is the finish line:
We avoid diminishing returns by stopping feature creep here. v1.0.0 represents a complete, reliable tool that fulfills the original research brief.

### Scope:
- **Comprehensive RBAC:** Fleshing out strict Role-Based Access Control in the Admin UI.
- **API Stability Lockdown:** Finalizing the OpenFeature mapping and core `Rulestead` public API.
- **E2E Demo Environments:** Providing reference architectures and comprehensive migration guides from FunWithFlags.

---

## Prerequisites Chain
```text
(v0.4.0) Experimentation Data Model
  ↳ (v0.5.0) Needs robust caching (Redis/PubSub) to prevent DB overload from experiment rule evaluations.
      ↳ (v0.6.0) Needs stable, distributed state to safely allow environment promotions without race conditions.
          ↳ (v1.0.0) Needs all features locked to finalize RBAC constraints around them.
```