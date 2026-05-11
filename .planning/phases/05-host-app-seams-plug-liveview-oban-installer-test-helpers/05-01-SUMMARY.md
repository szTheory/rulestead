---
phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
plan: 01
subsystem: host-seams
tags: [plug, phoenix, liveview, oban, context, runtime]
requires:
  - phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
    provides: explicit runtime facade over local snapshots
provides:
  - explicit request, socket, and job context builders
  - runtime-backed LiveView flag assignment helper
  - bounded Oban context serialization and worker recovery seam
  - scoped context propagation recipe
affects: [phase-05-installer, phase-05-test-helpers, host-app-integration]
tech-stack:
  added: []
  patterns:
    - explicit source-driven context normalization at framework boundaries
    - LiveView flag assignment through Rulestead.Runtime only
    - bounded job payload serialization for cross-process context handoff
key-files:
  created:
    - rulestead/lib/rulestead/plug.ex
    - rulestead/lib/rulestead/phoenix.ex
    - rulestead/lib/rulestead/live_view.ex
    - rulestead/lib/rulestead/oban.ex
    - rulestead/lib/rulestead/oban/middleware.ex
    - rulestead/lib/rulestead/oban/worker.ex
    - rulestead/test/rulestead/plug_test.exs
    - rulestead/test/rulestead/live_view_test.exs
    - rulestead/test/rulestead/oban_test.exs
  modified:
    - guides/recipes/context-propagation.md
key-decisions:
  - "Kept the seam modules free of hard Plug, Phoenix LiveView, and Oban compile-time dependencies by treating host structs as edge maps and restoring only bounded context fields."
  - "Made context extraction fully source-driven so targeting, request, session, and tenant fields come from explicit caller-visible sources instead of ambient lookup."
  - "Routed LiveView eager assignment through Rulestead.Runtime projections only, preserving the Phase 4 runtime boundary."
patterns-established:
  - "Framework seams normalize into %Rulestead.Context{} first and only then call runtime APIs."
  - "Oban propagation serializes bounded context payloads into job args and restores them explicitly in workers."
requirements-completed: [CTX-02, CTX-03, CTX-04, CTX-05, INST-04, INST-05, INST-06]
duration: 34min
completed: 2026-04-24
---

# Phase 5 Plan 01 Summary

**Explicit Plug, LiveView, and Oban seams over `Rulestead.Runtime` with bounded context propagation and worker-side recovery helpers**

## Performance

- **Duration:** 34 min
- **Started:** 2026-04-24T00:35:00Z
- **Completed:** 2026-04-24T01:09:12Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added `Rulestead.Phoenix.context_from_conn/2` and `Rulestead.Plug` so request data is normalized into `conn.assigns[:rulestead_context]` from explicit configured sources only.
- Added `Rulestead.LiveView.context_from_socket/2` and `assign_flags/3` so LiveView sockets can rebuild context and eager-assign multiple runtime-backed flag projections without bypassing `Rulestead.Runtime`.
- Added `Rulestead.Oban`, `Rulestead.Oban.Middleware`, and `Rulestead.Oban.Worker` so bounded context payloads can be serialized onto jobs and restored inside workers without boilerplate.
- Replaced the Phase 8 placeholder recipe with the shipped Phase 5 propagation guidance covering the supported Plug -> LiveView -> Oban handoff chain and its explicit limits.

## Task Commits

No task commits were created in this forked-workspace execution.

## Files Created/Modified

- `rulestead/lib/rulestead/plug.ex` - conn seam that assigns a normalized rulestead context.
- `rulestead/lib/rulestead/phoenix.ex` - source-driven conn-to-context projection helpers.
- `rulestead/lib/rulestead/live_view.ex` - socket context builder and runtime-backed `assign_flags/3`.
- `rulestead/lib/rulestead/oban.ex` - bounded job context serialization and restoration helpers.
- `rulestead/lib/rulestead/oban/middleware.ex` - explicit enqueue seam for attaching serialized context.
- `rulestead/lib/rulestead/oban/worker.ex` - `use Rulestead.Oban.Worker` recovery helpers for worker modules.
- `rulestead/test/rulestead/plug_test.exs` - request seam coverage for conn normalization and plug assignment.
- `rulestead/test/rulestead/live_view_test.exs` - socket normalization and runtime-backed flag assignment coverage.
- `rulestead/test/rulestead/oban_test.exs` - job restoration, middleware attachment, and worker macro coverage.
- `guides/recipes/context-propagation.md` - Phase 5 propagation recipe with explicit supported and unsupported patterns.

## Decisions Made

- Chose explicit source descriptors (`{:assign, key}`, `{:session, key}`, `{:header, name}`, and similar) instead of hidden framework inference so host apps control which request or socket values become runtime context.
- Kept the seam implementation compile-light and framework-agnostic at the core package boundary, which lets the package expose the helpers without forcing direct Phoenix or Oban dependencies into this phase.
- Used bounded serialized context maps for Oban propagation so later job evaluation can rebuild the same `%Rulestead.Context{}` without carrying raw host structs across process boundaries.

## Deviations from Plan

None - plan executed exactly as written within the owned file set.

## Issues Encountered

- The initial Oban serialization round-trip surfaced that `Rulestead.Context` normalizes atom-key fields, so the Oban seam now translates its string-key payload back into the bounded atom-key form before calling `Context.normalize/1`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Installer work in `05-02` can now inject `Rulestead.Plug` and Oban middleware against a stable explicit seam.
- Test-helper work in `05-03` can build on the same explicit context and runtime boundary without introducing ambient propagation behavior.

## Known Stubs

None.

## Self-Check

PASSED

- Found `rulestead/lib/rulestead/plug.ex`
- Found `rulestead/lib/rulestead/phoenix.ex`
- Found `rulestead/lib/rulestead/live_view.ex`
- Found `rulestead/lib/rulestead/oban.ex`
- Found `rulestead/lib/rulestead/oban/middleware.ex`
- Found `rulestead/lib/rulestead/oban/worker.ex`
- Found `rulestead/test/rulestead/plug_test.exs`
- Found `rulestead/test/rulestead/live_view_test.exs`
- Found `rulestead/test/rulestead/oban_test.exs`
- Found `guides/recipes/context-propagation.md`

---
*Phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers*
*Completed: 2026-04-24*
