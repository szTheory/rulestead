# Phase 44: OpenFeature Bridge Proof & Final Support Audit - Discussion Log

**Captured:** 2026-05-25
**Mode:** discuss-all, recommendation-first, subagent-backed synthesis
**User intent:** research all remaining gray areas, compare approaches deeply, incorporate prompt-anchor guidance and ecosystem lessons, and return one coherent recommendation set without unnecessary back-and-forth

## Boundary Presented

- Phase 44 closes the final `v1.3.0` support-truth gap for the optional OpenFeature companion.
- Scope is bounded to package proof, docs/support wording, and verification truth.
- Out of scope: new OpenFeature capabilities, browser-productization, and broader package-boundary changes.

## Carry-forward Decisions Applied

- Phase 14 locked the provider contract: context translation, scalar metadata export, and explicit environment-key requirement.
- Phase 41 locked the root docs/support hierarchy: runtime-first front door, companion surfaces secondary, bounded proof wording.
- Phase 43 reinforced the repo pattern that support truth must be tied to named proof surfaces rather than prose-only claims.
- `.planning/METHODOLOGY.md` already matches the user’s “shift preference left” request, so the discussion used recommendation-first synthesis instead of iterative questionnaires.

## Gray Areas Resolved

### 1. Proof bar for `open_feature_rulestead`

**Options researched**

1. Package-local Elixir provider proof only (`mix test` + README setup)
2. Demo/browser bridge proof only
3. Layered proof: package-local provider proof as merge-blocking, demo/browser proof distinct and advisory
4. Strongly coupled end-to-end proof where both package and demo/browser path are mandatory

**Research summary**

- Hex/Elixir package norms favor a package-local proof bar for a companion library.
- Demo-only proof would leave package-local drift possible and blur support ownership.
- Full coupled E2E would overstate support scope and make the optional provider hostage to Docker/Next.js/browser churn.
- Adjacent ecosystems generally separate provider proof from sample-application proof.

**Locked recommendation**

- Use a **layered proof bar**:
  - package-local provider proof is merge-blocking
  - demo/browser path remains secondary and clearly labeled

**Why this won**

- Best fit for sibling-package truth
- Most honest support posture
- Strongest DX for Hex readers without widening the milestone

### 2. Bridge boundary and support wording

**Options researched**

1. One blended “OpenFeature bridge” story
2. Strict separation with minimal cross-linking
3. Package-first README with demo as secondary proof path
4. Demo-first README with package details secondary

**Research summary**

- Blended wording creates high surprise because the browser path depends on demo-specific TypeScript and host-owned HTTP endpoints.
- Strict separation is safest but can be too cold and fragmented for evaluators.
- Package-first README plus secondary demo path matches HexDocs/package norms while preserving one discoverable runnable example.

**Locked recommendation**

- Make `open_feature_rulestead` **package-first and install-first**, with the demo linked as a secondary proof path.
- Keep wording strict:
  - the Elixir package is the provider
  - the browser/demo bridge is a host-owned example

**Why this won**

- Least surprise for package consumers
- Keeps the support story coherent with Phase 41
- Preserves discoverability without silently widening the contract

### 3. Verification and CI surface

**Options researched**

1. Leave proof manual/local-only
2. Add `open_feature_rulestead` to the default sibling-package test lane
3. Add a named targeted CI proof lane for the companion
4. Make the full demo/frontend/backend path merge-blocking

**Research summary**

- Manual-only proof is not credible once README posture says the package is runnable.
- Adding it to the default core lane overstates prominence and taxes unrelated PRs.
- A named targeted lane matches the repo’s existing bounded-proof philosophy and keeps contributor mental models clear.
- Full demo E2E as a required gate is too broad for an optional companion package.

**Locked recommendation**

- Add a **named targeted verification/CI lane** for `open_feature_rulestead`.
- Keep it outside the default core `rulestead` + `rulestead_admin` gate.

**Why this won**

- Gives the package a durable runnable proof bar
- Preserves bounded support truth
- Aligns with existing scripts-first, named-lane repo discipline

## Ecosystem Lessons Folded Into the Recommendation Set

- OpenFeature provider guidance expects provider docs to spell out configuration, context transformation, and behavior boundaries explicitly.
- LaunchDarkly-style OpenFeature docs separate provider packages from sample apps instead of collapsing everything into one support claim.
- Successful companion integrations name their proof surface clearly; docs-only support is the common drift trap.
- Optional integrations become contributor footguns when CI never exercises them but docs imply they are runnable.
- Browser/OpenFeature stories often rely on host-owned transport glue; blending that into a server-side/Elixir package claim creates support confusion.

## Prompt-Anchor Lessons Applied

- `rulestead-engineering-dna-from-prior-libs.md`: keep sibling-package boundaries explicit, prefer named CI surfaces, and keep package READMEs narrow.
- `rulestead-release-engineering-and-ci.md`: verification surfaces should be explicit, scripts-first, and citable by name.
- `rulestead-testing-and-e2e-strategy.md`: use merge-blocking bars for the package contract and keep broader demo proof bounded.
- `rulestead-host-app-integration-seam.md`: preserve host-owned integration boundaries and avoid magic claims about what the package owns.
- `rulestead-personas-jtbd-and-onboarding.md`: give adopters one obvious first-success package path without obscuring the cross-stack demo example.

## Local Repo Evidence Used

- `open_feature_rulestead` already has real provider code and tests.
- Local verification confirmed:
  - `cd open_feature_rulestead && mix deps.get && mix test`
  - result: `7 tests, 0 failures`
- `open_feature_rulestead/README.md` still frames the demo as the current bounded proof path and under-describes the package-local runnable path.
- `examples/demo/frontend/lib/openfeature/rulestead-web-provider.ts` proves the browser story is a separate demo-owned provider surface, not the Hex package itself.
- `scripts/ci/test.sh` currently exposes named proof lanes only for core/all and mounted-admin contract surfaces.

## Final Recommendation Set Handed To Planning

1. Treat Phase 44 as a bounded support-truth phase, not a new OpenFeature capability phase.
2. Strengthen `open_feature_rulestead` as a package-first companion with explicit setup, boundary, and command-path docs.
3. Add a named targeted proof/CI surface for the companion package.
4. Keep the demo/browser OpenFeature path as a secondary proof path, clearly marked as host-owned demo glue.
5. Close `OFE-01` by making the package runnable and honestly verified, not by widening the product contract.

## Deferred / Explicitly Rejected Directions

- Reframing the browser demo path as the package contract
- Making the demo/browser path the only or primary proof bar
- Pulling the OpenFeature companion into the default core merge gate
- Broadening into relay/proxy/browser-product work or other future-scope OpenFeature capabilities

---

*Phase: 44-openfeature-bridge-proof-final-support-audit*
*Discussion captured: 2026-05-25*
