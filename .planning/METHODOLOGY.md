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
- after reading the codebase and prompt anchors, lock ordinary implementation decisions directly in context/plans instead of turning them into questionnaires
- treat this as a strong default: do the synthesis and decision sorting in-agent unless a choice is unusually high-impact and likely something the user would specifically want to weigh in on
- treat this as the default collaboration style for this repo: ask less, synthesize more, and escalate only when the user-facing impact is genuinely material
- apply this default inside discuss workflows too: if multiple gray areas are clearly connected, research them together and return one cohesive decision set instead of forcing the user to sort routine tradeoffs area by area

## Research-Then-Recommend Lens

### Intent

When a phase has meaningful design surface area, do the research work first, then return one cohesive recommendation set rather than a menu of loosely-related options.

### Use this lens when

- the phase touches operator workflows, public/admin contracts, or architectural seams with real tradeoffs
- codebase context plus prompt anchors are enough to research deeply without blocking on user input
- outside-ecosystem examples could sharpen the recommendation while still preserving Rulestead’s bounded shape

### What this lens recommends

- read the closest prompt anchors and prior phase context before asking anything
- treat the relevant `prompts/` files as mandatory inputs when they cover the phase domain, operator UX, release posture, security, or host-integration seam
- use subagents or sidecar research when that will improve recommendation quality without blocking the critical path
- compare alternatives internally, then surface the best coherent path as the default answer
- pull in lessons from successful libraries/products in adjacent ecosystems when they reinforce least surprise, auditability, DX, or operator trust
- preserve explicit uncertainty in the recommendation instead of using fake precision
- only escalate a choice to the user when it would materially change public API/wire contract, security/governance posture, release/package shape, or milestone scope

### High-impact exception

Do **not** auto-lock choices that materially change:

- product scope
- public API or wire contract
- security or governance posture
- release model
- package boundary
- other unusually high-impact user-facing semantics that would be surprising to decide without confirmation

Those still deserve explicit user confirmation.
