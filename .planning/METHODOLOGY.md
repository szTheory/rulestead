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

## Architect-Default Discuss Lens

### Intent

Treat discuss workflows as recommendation synthesis by default for this repo. The user should not need to manually sort routine tradeoffs when the codebase, prompt anchors, and ecosystem evidence already point to a clear winner.

### Use this lens when

- a discuss-phase touches architecture, operator UX, proof posture, CI, public contract, or package-boundary-adjacent behavior
- multiple gray areas are connected enough that isolated answers would produce a weaker overall design
- prompt anchors and prior phase context already provide enough signal to narrow the option set substantially before asking anything

### What this lens recommends

- research all major gray areas together before returning to the user so the recommendation set is cohesive across architecture, UX, testing, CI, and docs
- default to prompt-first and codebase-first analysis instead of question-first analysis
- when delegation is permitted, use subagents for bounded gray-area research and then synthesize one recommendation set locally
- treat relevant `prompts/` docs as required design inputs and pull them into the recommendation before asking the user anything
- for each gray area, resolve the routine tradeoff work in-agent: compare the viable shapes, weigh pros/cons, check ecosystem norms, and discard weaker options before surfacing the winner
- prefer one-shot recommendation sets that already include Elixir/Phoenix/Ecto/Plug idioms, adjacent-ecosystem lessons, DX implications, and likely footguns
- emphasize idiomatic Elixir / Plug / Phoenix / Ecto patterns, least surprise, explicit failure modes, maintainability, and strong maintainer/adopter DX
- use adjacent successful libraries and products as evidence, but adapt them to Rulestead's bounded mounted-companion posture rather than copying broader product shapes blindly
- write context and plans as if the audience were a senior/staff architect: tradeoffs should be real, concise, and justified, with the recommended path clearly favored
- escalate only the rare decisions that a staff-level architect would reasonably expect to personally confirm because the consequence is materially user-facing or structurally hard to reverse
- if no such high-impact decision remains after research, do not ask; lock the recommendation directly into CONTEXT.md and downstream plans
- treat prompt anchors under `prompts/` as first-class evidence, not optional flavor text, whenever they cover the current phase surface
- prefer one-shot recommendation sets that already account for pros/cons, ecosystem lessons, DX, support truth, and operator UX so the user does not need to manually reconcile local tradeoffs
- when the repo already has enough evidence to produce a clear winner, do not present a menu for its own sake; present the winner, note the discarded alternatives briefly, and move on

### High-impact exception

Do **not** auto-lock choices that materially change:

- product scope
- public API or wire contract
- security or governance posture
- release model
- package boundary
- other unusually high-impact user-facing semantics that would be surprising to decide without confirmation

Those still deserve explicit user confirmation.
