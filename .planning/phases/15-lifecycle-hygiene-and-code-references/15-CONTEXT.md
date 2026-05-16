# Phase 15: Lifecycle Hygiene & Code References - Context

## Objective
Operators can confidently identify and remove obsolete flags to eliminate technical debt, ensuring a clean and manageable platform.

## Decisions

### Locked Decisions
- **D-01 (Code Reference Detection):** Implement a **Passive (External CI Scanner)** approach. Rulestead will provide a Mix task (e.g., `mix rulestead.code_refs`) that the host application runs within its existing CI/CD pipeline to parse the Elixir AST and push results to Rulestead via an API endpoint. This ensures a minimal security blast radius and VCS independence. (Requirements: LCH-02)
- **D-02 (Stale Flag Identification):** Use a **Type-Aware Hybrid Model (Telemetry + State)**. A flag is identified as stale if its configuration has been in a terminal state (e.g., 100% rollout) for > 30 days AND a lightweight telemetry check (`last_evaluated_at` via ETS write-behind + Oban worker) confirms it has only served one variant. "Kill Switch" and "Operational" flags are structurally exempt. (Requirements: LCH-01)
- **D-03 (Admin UI Cleanup Workflow):** Use **Contextual Manual Action**. The Admin UI will use passive drift detection (displaying a subtle "possibly stale" badge) and enforce a strict pre-flight checklist modal when the operator manually initiates the archival process. The modal dynamically surfaces remaining code references to ensure safe archival without auto-generating system Change Requests. (Requirements: LCH-03)

### Scope and Boundaries
- This phase focuses exclusively on discovering stale flags and capturing code references for presentation.
- Do not automate the removal or archiving of flags. The operator must always remain in the loop (preview -> confirm -> audit).
- Code parsing is restricted to the host application's environment (passive). Rulestead should not clone repositories or read source code directly.
