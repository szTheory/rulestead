# Roadmap: v1.0.0 - General Availability (GA)

## Phases

- [ ] **Phase 26: API Lockdown & Documentation Perfection** - Refactoring internal modules to `@moduledoc false`, perfecting Hexdocs, ensuring 100% Dialyzer passing, and freezing the public API.
- [ ] **Phase 27: Comprehensive RBAC & Security Hardening** - Implementing pure Elixir Context-based Policies (like Bodyguard pattern but built-in) for the Admin UI and API.
- [ ] **Phase 28: E2E Demo Environments & GA Release** - Creating a Docker Compose setup with a Next.js/Phoenix demo application showcasing real-time flag streaming and evaluation.

## Phase Details

### Phase 26: API Lockdown & Documentation Perfection
**Goal**: The public API boundary is frozen, strongly typed, and comprehensively documented.
**Depends on**: Phase 25
**Requirements**: API-01, API-02, DOC-01, DOC-02
**Success Criteria** (what must be TRUE):
  1. A developer can view clear public Hexdocs without internal implementation details cluttering the index.
  2. Dialyzer runs cleanly on the project with no warnings, proving type stability.
  3. A developer migrating from FunWithFlags can follow a step-by-step guide to transition to Rulestead.
  4. A host application can depend on the public API without risking breaking changes from internal module shifts.
**Plans**: TBD

### Phase 27: Comprehensive RBAC & Security Hardening
**Goal**: System enforces strict, dependency-free role-based access control for operations.
**Depends on**: Phase 26
**Requirements**: SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. An operator with a "Viewer" role can read flags but is denied from saving changes.
  2. An operator with an "Editor" role can mutate flags but cannot change admin-level system settings.
  3. Host applications can integrate Rulestead's RBAC policies using pure Elixir context mechanisms, without installing new dependencies like Ash or Permit.
**Plans**: TBD
**UI hint**: yes

### Phase 28: E2E Demo Environments & GA Release
**Goal**: Platform engineers can evaluate the entire Rulestead stack locally in under 5 minutes.
**Depends on**: Phase 27
**Requirements**: GA-01, GA-02
**Success Criteria** (what must be TRUE):
  1. A user can run `docker-compose up` and immediately access the Rulestead Admin UI.
  2. The demo environment streams real-time flag evaluations to an external (e.g., Next.js) sample application.
  3. A user can toggle a flag in the Admin UI and observe the change in the sample application via the OpenFeature integration.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 26. API Lockdown & Documentation Perfection | 0/0 | Not started | - |
| 27. Comprehensive RBAC & Security Hardening | 0/0 | Not started | - |
| 28. E2E Demo Environments & GA Release | 0/0 | Not started | - |