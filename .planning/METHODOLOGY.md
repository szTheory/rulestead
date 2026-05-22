# Planning Methodology

This file captures project-level planning lenses that downstream GSD workflows should apply before reopening routine decisions.

## Recommendation-First Lens

### Intent

Bias toward coherent, recommendation-heavy output by default. Treat the user as wanting a strong proposed path unless a choice is truly high-impact.

### Use this lens when

- multiple plausible implementation shapes exist but only one clearly fits the current codebase and milestone goals
- a decision would not materially change public contract, security posture, product scope, or release shape
- repeated questioning would slow down planning without improving the result

### What this lens recommends

- present one recommended path first
- synthesize one coherent recommendation set across API, architecture, UX, testing, and operations instead of making the user reconcile disconnected local optimizations
- include alternatives only as tradeoff context
- keep recommendations internally consistent across API, UX, architecture, and testing
- prefer least-surprise defaults and explicit failure modes
- avoid pushing routine tradeoff sorting back onto the user; resolve it in-agent unless the choice hits the high-impact exception below

### High-impact exception

Do **not** auto-lock choices that materially change:

- product scope
- public API or wire contract
- security or governance posture
- release model
- package boundary

Those still deserve explicit user confirmation.
