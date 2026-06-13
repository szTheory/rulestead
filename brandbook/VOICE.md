# Rulestead Voice and Microcopy

Source: `brandbook/brand-book.md` sections 9, 19, 20, and 21.

Rulestead should sound clear, calm, exact, assured, and practical. In UI copy, state what
happened, what did not happen, and what the operator can do next.

## Say This / Not This

| State | Say this | Not this | Why |
|-------|----------|----------|-----|
| Empty | No rules yet. Start with a default value, then add ordered rules for targeted rollout. | Nothing here. | Constructive and specific. |
| Empty | No snapshots have been published. Publish a snapshot before promoting rollout. | You do not have any data yet. | Names the missing object and next step. |
| Empty | No segments match this environment. Add a segment or evaluate against the default rule. | No results found. | Connects the empty state to an operator path. |
| Error | Snapshot publish failed. The previous snapshot is still active. Check store connectivity and try again. | Oops, something broke. | States what happened, what did not happen, and what to do. |
| Error | Rule was not saved. Add a targeting key before enabling stickiness. | Invalid submission. | Explains the failed validation without blame. |
| Error | Flag archive failed. No changes were applied. Try again after checking store connectivity. | We could not complete your request. | Confirms the system did not partially apply state. |
| Error | Evaluation failed. The fallback value was returned. Check the flag payload and context shape. | Evaluation error. | Names degraded behavior and the next diagnostic step. |
| Success | Snapshot published. | Success! | Concise and factual. |
| Success | Rule saved. | All set! | Names the completed action. |
| Success | Rollout promoted to staging. | You did it. | Keeps the operator consequence visible. |
| Success | Flag archived. Existing snapshots are unchanged. | Flag deleted forever. | Avoids exaggeration and clarifies scope. |

## Writing Rules

- Prefer precise nouns: flag, rule, segment, environment, snapshot, rollout, evaluation.
- Prefer verbs with consequences: publish, archive, promote, simulate, approve.
- Avoid vague labels such as "Continue", "Submit", "Go", and "Done" when a specific action exists.
- Avoid growth-platform language, magic language, and AI-powered claims unless the feature truly depends on them.
- Keep error copy blame-free and short.
- Keep success copy concise; do not add celebration where confirmation is enough.
