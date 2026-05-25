# Phase 41: Release Truth Alignment - Discussion Log

**Date:** 2026-05-24
**Mode:** discuss-all, recommendation-first
**Method:** codebase-first analysis, prompt-anchor review, and parallel subagent research across four gray areas

## Inputs used

- Active milestone and requirement context from `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`
- Current public surfaces:
  - `README.md`
  - `rulestead/README.md`
  - `rulestead_admin/README.md`
  - `open_feature_rulestead/README.md`
  - `guides/introduction/installation.md`
  - `guides/introduction/getting-started.md`
  - `examples/demo/README.md`
- Package/version truth from:
  - `rulestead/mix.exs`
  - `rulestead_admin/mix.exs`
  - `open_feature_rulestead/mix.exs`
- Prompt anchors:
  - `prompts/rulestead-release-engineering-and-ci.md`
  - `prompts/rulestead-personas-jtbd-and-onboarding.md`
  - `prompts/rulestead-engineering-dna-from-prior-libs.md`
  - `prompts/rulestead-host-app-integration-seam.md`
  - `prompts/rulestead-domain-language-field-guide.md`

## User direction captured

- Discuss all identified gray areas.
- Use subagents and deep tradeoff research.
- Return one coherent recommendation set so routine choices do not come back to the user.
- Favor least surprise, strong DX, strong architecture/engineering, bounded honesty, and good UX.
- Shift the collaboration style left inside GSD where possible so routine choices are synthesized in-agent and only very impactful ones are escalated.

## Area 1: Release headline

### Options compared

1. Explicit dual-track truth everywhere
2. Softer post-GA framing
3. Split-front-door narrative
4. Version-parity-first story

### Recommendation locked

- **Chosen:** Split-front-door narrative
- **Why:** It is the best balance between truth and readability:
  - root README explains once that repo GA shipped in `v1.0.0` on 2026-05-21 while current installable linked packages are `0.1.x`
  - sibling package READMEs stay package-first, with a short factual note and a link back to root/upgrading docs
  - avoids both hidden surprise and overloading package READMEs with release-history exposition

### Ecosystem lessons retained

- Elixir package front doors usually lead with what can be installed now, not repo-history narrative
- Mature companion-package docs keep the package contract primary and broader release framing centralized
- Hiding branch/version truth creates support footguns; repeating it everywhere makes the surface feel less settled than it is

## Area 2: Default install path

### Options compared

1. Runtime-first, mounted-admin second
2. Full-stack-first, runtime-only second
3. Segmented by JTBD from the top

### Recommendation locked

- **Chosen:** Runtime-first default quickstart, followed immediately by mounted-admin as the optional Phoenix-host path, while retaining the JTBD split below
- **Why:**
  - fastest time-to-first-value
  - consistent with project personas and current install guide
  - least-surprise fit for a sibling model where `rulestead_admin` is optional
  - avoids pushing router/auth/browser-pipeline concerns into the default first-success path

### Ecosystem lessons retained

- Core library value should land before mounted/UI companion setup
- Mounted operational surfaces are usually introduced as follow-on steps, not as the universal default
- Full-stack-first quickstarts create avoidable security and optional-dependency footguns when the admin surface is not mandatory

## Area 3: Proof posture

### Options compared

1. Explicit bounded caveats tied to demo + verify seams
2. Softer confidence language with buried caveats
3. Hard verification-matrix truth everywhere
4. Layered posture with bounded proof section and small appendix

### Recommendation locked

- **Chosen:** Layered proof posture
- **Why:**
  - keeps the landing narrative calm and usable
  - makes exact proof limits explicit close to the front door
  - fits the milestone’s support-truth purpose without turning README copy into procurement-grade matrices
  - anchors claims to concrete repo evidence:
    - `examples/demo/`
    - `mix verify.release_publish <version>`
    - `mix verify.release_parity <version>`

### Ecosystem lessons retained

- Mature projects are explicit about supported/proven seams
- Buried caveats create support debt and reputational drift
- Matrices are useful only when the support contract itself is a primary product surface

## Area 4: Companion surfaces

### Options compared

1. Prominent companion callouts in root README
2. Clearly secondary companion/proof surfaces positioning
3. Near-omission until later phases close truth gaps
4. Dedicated integrations/examples index with minimal root mention

### Recommendation locked

- **Chosen:** Clearly secondary companion/proof surfaces positioning
- **Why:**
  - preserves discoverability without overstating maturity
  - keeps `open_feature_rulestead` and the local demo visible but bounded
  - matches the repo’s current truth: the demo is runnable proof, the OpenFeature bridge exists but is not yet fully documented/proven at the level reserved for later phases

### Ecosystem lessons retained

- Core docs should stay centered on the primary package and primary path
- Bridges, providers, examples, and integrations should be discoverable but secondary until their proof/support posture is stronger
- Omitting existing companion surfaces entirely creates a different kind of trust gap

## Cohesive recommendation set

The four decisions were deliberately locked as one system:

1. Root README carries the full release-truth explanation once.
2. Default quickstart starts with runtime value, then branches into mounted admin.
3. A bounded “Proof today” section clarifies exactly what is runnable and verified now.
4. Demo and OpenFeature bridge are discoverable as secondary companion/proof surfaces, not equal headline entrypoints.

This combined posture best satisfies:

- `DOC-01` / `DOC-02`
- linked-version sibling-package design
- mounted-companion guardrails
- recommendation-first methodology
- least surprise for Elixir/Phoenix adopters
- support-truth credibility ahead of later proof-closure phases

## Methodology note

The user explicitly requested a stronger “synthesize more, ask less” collaboration style. The current `.planning/METHODOLOGY.md` already encodes that preference through:

- `Recommendation-First Lens`
- `Research-Then-Recommend Lens`
- explicit high-impact exceptions

No methodology change was required to honor the request for this phase; the phase context locks Phase 41 to apply that style directly.
