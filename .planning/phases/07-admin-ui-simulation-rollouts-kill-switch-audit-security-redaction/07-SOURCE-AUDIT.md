# Phase 07 Source Audit

## Execution Gate

Phase 07 planning is complete, but execution remains gated by the roadmap dependency on Phase 06. These plans assume the Phase 06 route/session/admin seams land first and should be revalidated against the repo state after Phase 06 execution.

## GOAL

| Source item | Coverage |
|---|---|
| Phase 7 operator workflows: simulation/explain, rollout controls, kill switch, audit timeline, security envelope | `07-01`, `07-02`, `07-03`, `07-04`, `07-05`, `07-06` |

## REQ

| Requirement | Coverage |
|---|---|
| `ADMIN-04` simulation / explain page | `07-03` |
| `ADMIN-05` rollout controls | `07-04` |
| `ADMIN-06` kill switch | `07-01`, `07-05` |
| `ADMIN-07` audit timeline | `07-01`, `07-05` |
| `ADMIN-09` lifecycle view on operator surfaces | `07-03`, `07-04`, `07-05` |
| `SEC-01` host-supplied `Rulestead.Admin.Policy` seam | `07-01`, `07-05` |
| `SEC-02` environment-sensitive authorization | `07-01`, `07-05` |
| `SEC-03` secure traits / redacted telemetry and audit | `07-01`, `07-03`, `07-06` |
| `SEC-04` `NoRawTraitsInLogger` Credo check | `07-06` |
| `TEL-03` `NoRawTraitsInTelemetryMeta` Credo check | `07-06` |

## RESEARCH-EQUIVALENT INPUTS

Project research agents are disabled for this repo. Phase 07 uses the locked design and anchor-doc guidance as the research-equivalent source.

| Research-equivalent item | Coverage |
|---|---|
| `07-UI-SPEC.md` route-backed screens, summary-first simulation, rollout ladder, typed-key production confirm, audit diff, shared components | `07-02`, `07-03`, `07-04`, `07-05` |
| `prompts/rulestead-admin-ux-and-operator-ia.md` calm operator IA, route-backed admin surfaces, explicit publish/confirm flows | `07-02`, `07-03`, `07-04`, `07-05` |
| `prompts/rulestead-security-privacy-and-threat-model.md` host-owned auth, least privilege, redact-before-persist/emit posture | `07-01`, `07-05`, `07-06` |
| `prompts/rulestead-telemetry-observability-and-audit.md` audit-vs-telemetry boundary, append-only ledger, bounded metadata | `07-01`, `07-05`, `07-06` |
| `prompts/rulestead-personas-jtbd-and-onboarding.md` Sam/Shiori/Tova workflows | `07-03`, `07-04`, `07-05` |
| `prompts/rulestead-engineering-dna-from-prior-libs.md` custom Credo checks, explicit seams, `Ecto.Multi` + audit discipline | `07-01`, `07-06` |
| `prompts/rulestead-domain-language-field-guide.md` canonical kill switch, engage/release, audience, audit language | `07-01`, `07-03`, `07-04`, `07-05` |

## CONTEXT

| Locked decision | Coverage |
|---|---|
| `D-01` dedicated simulation route | `07-02`, `07-03` |
| `D-02` simulation and explain on one screen | `07-03` |
| `D-03` preserve detail/rules/simulation boundaries | `07-02`, `07-03`, `07-04`, `07-05` |
| `D-04` summary-first simulation result | `07-03` |
| `D-05` progressive disclosure for trace detail | `07-03` |
| `D-06` saved archetypes scoped to simulation | `07-03` |
| `D-07` copy-as-test-fixture Elixir literal | `07-03` |
| `D-08` no persisted simulation history | `07-03` |
| `D-09` keep draft/publish rollout boundary | `07-04` |
| `D-10` hybrid rollout editing with explicit publish/high-risk confirm | `07-04` |
| `D-11` rollout widens exposure, not variant composition | `07-04` |
| `D-12` show first-match ordering around rollout rule | `07-04` |
| `D-13` ladder suggestions are recommendations only | `07-04` |
| `D-14` bounded targeting-key sample preview before publish | `07-04` |
| `D-15` no hidden rollout persistence | `07-04` |
| `D-16` no scheduled rollout automation | `07-04` |
| `D-17` dedicated kill-switch route | `07-02`, `07-05` |
| `D-18` per-flag per-environment override record forcing default value | `07-01`, `07-05` |
| `D-19` idempotent restore returns to authored behavior | `07-01`, `07-05` |
| `D-20` detail banner with restore affordance while active | `07-05` |
| `D-21` typed-key confirm in production | `07-05` |
| `D-22` do not mutate authored rules for kill switch | `07-01`, `07-05` |
| `D-23` explicit audit + telemetry for engage/release | `07-01`, `07-05` |
| `D-24` one append-only redacted audit ledger with per-flag + global surfaces | `07-01`, `07-05` |
| `D-25` per-flag and global audit routes | `07-02`, `07-05` |
| `D-26` structured readable diff, raw detail only when useful | `07-05` |
| `D-27` rollback as inverse write linked to prior event | `07-01`, `07-05` |
| `D-28` denied mutations are audit-visible | `07-01`, `07-05` |
| `D-29` actor identity stays on `Rulestead.ActorResolver` seam | `07-01`, `07-05` |
| `D-30` every admin mutation checks `Policy.can?/4` before write | `07-01`, `07-05` |
| `D-31` conservative env-sensitive authz defaults | `07-01`, `07-05` |
| `D-32` typed unauthorized failures + denied audit rows | `07-01`, `07-05` |
| `D-33` allowlist-only traits; redact by default | `07-01`, `07-03`, `07-06` |
| `D-34` redact before persist/emit | `07-01`, `07-06` |
| `D-35` strict Credo checks to ship in Phase 7 | `07-06` |
| `D-36` soften tenancy check until tenancy seam is real | `07-06` |

## Deferred Items Confirmed Absent

- Scheduled or automated rollout ladders
- Persisted simulation history / explanation store
- Cross-flag playgrounds or broad diagnostics consoles
- Compliance-grade trigger/versioning frameworks
- Hard-fail tenancy lint before the tenancy seam exists
