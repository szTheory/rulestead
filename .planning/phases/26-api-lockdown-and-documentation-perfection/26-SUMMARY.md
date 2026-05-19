# Phase 26: API Lockdown & Documentation Perfection - Planning Summary

**Phase:** 26
**Status:** Planned
**Plans:** 3
**Waves:** 2

## Overview

Phase 26 focuses on stabilizing the `rulestead` public API and perfecting documentation ahead of the v1.0.0 General Availability release. The goals are strictly type-checking the codebase (zero Dialyzer warnings), enforcing public/private API boundaries via `@moduledoc false` and HexDocs grouping, and providing a seamless migration path for FunWithFlags users.

## Plan Breakdown

### Wave 1

- **26-01-PLAN.md (Strict Typing & Dialyzer Compliance)**
  - Audits all public API and internal modules for comprehensive `@spec` and `@type` annotations.
  - Sets up `.dialyzer_ignore.exs` to skip non-actionable external warnings (like `:inets` in mix tasks).
  - Fixes typespecs and pattern match warnings in `Rulestead.Config`, `Rulestead.ex`, and `Rulestead.Store.Ecto`.
  - Ensures clean `mix dialyzer` runs in both `rulestead` and `rulestead_admin`.
  - *Addresses:* API-02

- **26-02-PLAN.md (Migration Guide Creation)**
  - Authors `guides/recipes/migrating-from-funwithflags.md`.
  - Maps old concepts (Gates, Priority) to new Rulestead features (Rules, Ordered Evaluation).
  - *Addresses:* DOC-02

### Wave 2

- **26-03-PLAN.md (Public Boundary & Hexdocs Configuration)**
  - *Depends on: 01, 02*
  - Mass-applies `@moduledoc false` to all non-public internal modules inside `rulestead/lib/`.
  - Explicitly strips `@moduledoc false` from properly designated public API modules to ensure they appear in Hexdocs.
  - Modifies `rulestead/mix.exs` `docs/0` function to introduce explicit module and extra groupings for the newly finalized public API.
  - *Addresses:* API-01, DOC-01

## Next Steps

Run `/gsd-execute-phase 26` to begin execution of Wave 1 plans.
