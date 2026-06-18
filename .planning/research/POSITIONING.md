# Positioning, "Why Rulestead?", and the 1.0 Announce/Closeout

**Milestone:** v2.0 — 1.0 GA Release & Adoption (release-truth, no new runtime features)
**Research focus:** R4 — Positioning · the 1.0 announce · closeout-verify
**Researched:** 2026-06-17
**Lens:** product-marketing + creative-direction + developer-community strategist for Elixir OSS, grounded in the canonical brand book, personas/JTBD, and competitor brief
**Overall confidence:** HIGH on brand/persona/competitor grounding (canonical repo docs read in full); HIGH on the two load-bearing launch exemplars (Oban, Req announce threads verified); MEDIUM on broader ecosystem-norm claims (ElixirForum etiquette is community lore, not a single authoritative page).

---

## Recommended decisions (register)

| # | Decision | Recommendation | Confidence | Why (one-liner) |
|---|----------|----------------|------------|-----------------|
| D1 | **One-liner** | "Rulestead is an Elixir-native feature-management runtime and self-hostable Phoenix control plane — deterministic evaluation, explainable decisions, calm at 3am." | HIGH | Locked positioning verbatim ("best runtime + best self-hostable control plane"), brand voice, never "X for Elixir". |
| D2 | **"Why Rulestead?" framing axis** | Frame against *the in-house build* and *outgrowing booleans*, NOT against named vendors. The honest enemy is flag-debt + 3am uncertainty + leaving the BEAM. | HIGH | Brand book §6/§24 forbid copycat/vendor framing; competitor brief §1 says the gap is "the next layer up" past FunWithFlags, not a LaunchDarkly fight. |
| D3 | **Differentiation vs FunWithFlags** | Respect it as the proven incumbent for boolean toggles; position Rulestead as the layer *above* booleans (values, ordered rules, explain, governance, lifecycle) — never "better than". Ship the migration path as the proof of respect. | HIGH | FunWithFlags migration path already shipped (API-02, v1.0.0); brief §2.2 "the gap is not that FWF is bad". |
| D4 | **Differentiation vs SaaS incumbents (LD/Unleash/Flagsmith)** | Differentiate on *self-hostable + Phoenix-native + mounts in your app + no SaaS dependency*, not feature parity. Borrow their governance vocabulary (change requests, approvals, lifecycle) as reasons-to-believe, never as "we're cheaper than X". | HIGH | Brief §4.7 governance "not luxury"; product-boundary.md "not a hosted LaunchDarkly clone". |
| D5 | **1.0 honesty frame** | "1.0 is a *promotion*, not a debut." Tell the real story: API-frozen, RBAC-complete, governance-rich, battle-tested through an internal v1.x band; the Hex version finally tells the truth. Correct the ZeroVer mismatch out loud. | HIGH | This is literally the milestone's stated reason (PROJECT.md §Current Milestone); Oban exemplar proves "earned evolution" framing builds trust. |
| D6 | **ElixirForum post** | Single post in the **Libraries** category (`announcement` tag); lead with the tl;dr one-liner + a real `Rulestead.evaluate/3` snippet; tell the maturity story honestly; end with an open invitation; maintainer replies substantively in-thread. No marketing gloss. | HIGH | Oban + Req both used exactly this shape and the community rewarded it. |
| D7 | **GitHub release notes** | Use `brandbook/RELEASE-TEMPLATE.md` as-is, with the headline `Rulestead 1.0.0: a stable, public contract for the platform you've been building toward`. Operator-consequence-first. Three packages, one coordinated note. | HIGH | Template is canonical and already operator-aware; RELEASE-TEMPLATE microcopy rules align with VOICE.md. |
| D8 | **Timing** | Cut GitHub release + publish all three packages first; verify the trio green + HexDocs front door renders; **only then** post to ElixirForum, linking to live HexDocs/Hex/release. Never announce ahead of a green, installable, rendered artifact. | HIGH | Community-trust footgun: announcing a "1.0" that `mix deps.get` can't resolve or whose docs 404 is the fastest way to burn the launch. |
| D9 | **README badges** | Hex version, HexDocs, CI status, license, Elixir version. In that order. No vanity badges (no "made with love", no Discord-count). | MEDIUM | Idiomatic Elixir OSS badge row; brand book §24 "utility over flash". |
| D10 | **Tagline use** | Use **"Runtime decisions, made clear."** as the recurring line (HexDocs hero, social card, release sub-head) — it is the brand-book default and already in the logo tagline lockup. Do not invent new taglines for the launch. | HIGH | Brand book §8 recommended default; COPY.md already ships it; consistency > novelty. |
| D11 | **What NOT to claim** | No "production-ready" as if new (it's been production-shaped for a year — say *that* instead); no affected-user counts; no "fastest"; no benchmark war; no "drop-in LaunchDarkly replacement"; no AI/growth language. | HIGH | VOICE.md don'ts; product-boundary "Host always owns population truth"; brand guardrails §24. |

**The one-shot recommendation:** ship D1–D11 as a coherent set. They are mutually reinforcing and all sit inside the locked positioning and the calm/exact brand voice. Nothing here requires a microsite, blog, funnel, video, client SDK, or comparison page (all explicitly deferred/out-of-scope).

---

## 1. Messaging hierarchy (one-liner → paragraph → proof bullets)

### One-liner (D1)

> **Rulestead is an Elixir-native feature-management runtime and self-hostable Phoenix control plane: deterministic evaluation, explainable decisions, and an admin UI calm enough to trust at 3am.**

Shorter variants for constrained surfaces (all already canonical — reuse, don't reinvent):

- **Hex/GitHub description (COPY.md):** "Elixir-native feature management for safe rollout, multivariate config, and explainable runtime decisions."
- **Tagline lockup (brand book §8/§14):** "Runtime decisions, made clear."
- **Forum tl;dr:** "Rulestead is a deterministic, explainable feature-management runtime for Phoenix, with an optional mounted admin UI for rollouts, governance, and lifecycle."

**Why this one-liner and not "the LaunchDarkly for Elixir":** the brand book bans copycat framing (§6, §24) and the competitor brief's strategic stance (§1) is explicit — *do not compete head-on as a hosted platform; be the best native runtime + best self-hostable control plane.* "X for Elixir" also psychologically subordinates Rulestead to the incumbent and invites a feature-parity audit it will lose (no edge CDN, no hosted cloud, no stats engine — by design). The two-noun construction ("runtime AND control plane") is the locked positioning and it is also a *trust* signal: it tells a senior engineer you understand the runtime/authoring split they care about.

### Paragraph (the "elevator")

> Rulestead gives Phoenix teams a fast, pure, local evaluator for booleans, variants, and remote config — decisions resolve deterministically from ordered rules with stable bucketing, and every result can explain exactly why it resolved the way it did. When you need more than evaluation, an optional `rulestead_admin` package mounts inside your own Phoenix app: rollouts, kill switches, change requests, audit, audience targeting, and lifecycle cleanup — governed by your auth, deployed on your infrastructure, never a separate SaaS to trust. It's the feature-management platform serious Elixir teams would have built in-house, without the in-house maintenance burden.

This is a tightened synthesis of brand-book §7 "Medium pitch" + the Core Value statement in PROJECT.md. It does the three jobs a paragraph must: names the runtime (Alex/Tova), names the control plane and its self-hosted/host-owned-auth nature (Shiori/Priya/Sam), and lands the "homegrown feel without homegrown burden" hook (Tova's actual buy decision).

### Proof bullets (reasons-to-believe, JTBD-anchored)

Each bullet pairs a *claim* with the *persona who cares* and the *evidence that makes it credible* — this is what converts skepticism toward new infra into trust.

| Proof point | Persona (JTBD) | Reason-to-believe / evidence |
|-------------|----------------|------------------------------|
| **Deterministic, pure evaluation** — same context + payload → same result, every time | Alex (gate a path), Tova (safe rollout) | Property-tested bucketing; `Rulestead.evaluate/3` is a pure function on a payload; no DB read on the hot path. The Flipper "percentage-of-time" footgun is *designed out* (product-boundary explicitly excludes it). |
| **Explain every decision** — `(flag, actor)` → human-readable trace: which rule matched, the bucket, the snapshot version | Sam (answer "why did u_123 see X?"), Shiori (trace a spike) | Explainability is a first-class API + a headline admin page, not a support afterthought (brief §5.3, §21.1). This is the single strongest cross-ecosystem differentiator the brief identifies. |
| **15-minute quickstart** — deps → install → migrate → Plug → first flag flips | Alex | getting-started.md + the Phoenix Integration Spine prove the path; onboarding checkpoint is measured (personas §9, "15 minutes" wow-moment). |
| **A calm admin you trust at 3am** — bookmarkable kill switch, one-field confirm, structured health endpoint | Shiori | Kill switch is its own route per flag; `/rulestead/health` returns structured JSON for alerting (personas §6). Trust-at-3am is the Core Value's literal phrasing. |
| **Governance that prevents mistakes, not enterprise theater** — change requests, approvals, protected-env controls, blast-radius thresholds, signed audit bundles | Tova, Priya, Compliance | Borrowed from the LaunchDarkly lesson that governance reduces production mistakes (brief §4.7); shipped + RBAC-enforced through the host policy seam (SEC-01..03). |
| **Lifecycle hygiene by design** — owner + expiration required at creation; stale detection; advisory cleanup workbench | Tova (avoid flag-debt) | Owner/expiration mandatory at create (getting-started.md); Unleash's lifecycle-state lesson made a product model, not a doc (brief §4.1C). |
| **OpenFeature-compatible** — standard provider via `open_feature_rulestead` | Alex, Tova (avoid lock-in fear) | The provider package exists and publishes at 1.0 with it; OpenFeature is the abstraction boundary the brief says is "worth stealing" (§4.8). |
| **Self-hostable, host-owned** — runs on your Postgres + Phoenix; your auth; your deploy; no population data leaves your app | Shiori, Security, Tova | product-boundary.md "Host always owns identity, observability, population truth"; mounts inside your router, not a standalone control plane. |
| **Elixir-native ergonomics** — Plug / LiveView / Oban seams, Fake adapter for Postgres-free tests | Alex, Omar | `with_flag/3` and friends test without Postgres (personas §2.6, §16.1); this is the real BEAM advantage the brief calls out (§21.2). |

**Discipline note (D11):** none of these bullets claim "fastest", a hosted cloud, an analytics warehouse, affected-user counts, or AI magic. Every bullet is something the repo can demonstrate today. Overclaiming is the fastest way to lose the senior-engineer audience the brand targets (§5 primary audience).

---

## 2. The "Why Rulestead?" narrative (HexDocs landing extra + forum spine)

This is the positioning extra that feeds both the HexDocs front door and the announce. Structure it as a **problem → why the easy answers fall short → the Rulestead answer → honest scope**. This mirrors the brand book's own product narrative (§4) and is the structure both Oban and Req used successfully.

### Outline

**1. The problem (calm, not fear-mongering)**
Shipping safely gets harder as a Phoenix app matures. A few booleans become a tangled web of conditionals. You inherit toggles nobody owns, environments that have quietly drifted, and a dashboard that tells you *what* is on but never *why* a specific user saw it. At 3am, "is it safe to roll this back?" should not be a research project.
*(Lifted from brand book §4 "problem narrative" — keep this paragraph, it is on-voice.)*

**2. Why the usual answers fall short — framed as honest tradeoffs, not attacks**
- **Roll your own:** every team can build flags; few can afford to maintain explainability, governance, lifecycle hygiene, and a calm operator UI *forever*. That's a sub-project disguised as a chore. *(This is the real competitor — name it.)*
- **Stay on boolean toggles:** great until you need variants, typed remote config, or to answer "why did this resolve this way?" The model runs out before your product does. *(Respectful nod to the FunWithFlags-shaped layer.)*
- **Reach for an external SaaS platform:** powerful, but now your runtime decisions depend on a service outside the BEAM, your user data leaves your app, and self-hosting is someone else's roadmap. *(State the tradeoff; don't disparage.)*

**3. The Rulestead answer**
Restate the paragraph pitch + the proof bullets. Lead with determinism and explainability (the things infra-skeptics test first), then the self-hosted control plane, then governance/lifecycle as the "grows with you" promise. Land on the brand mantra: **Rulestead makes change feel governed, not chaotic.**

**4. Honest scope (this paragraph *builds* trust — do not omit it)**
State plainly what Rulestead is *not*: not a hosted cloud, not an edge/CDN evaluator, not a stats engine (impression hooks only — analytics lives in your warehouse), not a standalone control plane (it mounts in your app), and it deliberately omits percentage-of-time rollouts because they're a footgun. Link product-boundary.md.
*Psychology: a precise "here's what we don't do" is the strongest possible signal to a skeptical senior engineer that the maintainers understand the domain and won't overpromise. It is also what separates a calm infra brand from a growth-hack brand (§24).*

**5. Maintenance & longevity (answer the unspoken "will this be maintained?")**
One short paragraph: API frozen since the internal v1.0 GA, a published SemVer + deprecation policy, a documented major-bump runbook (`MAINTAINING.md`), and a verification trio that gates every release. This is the OSS-posture promise (brand book §21) made concrete. *For new infra, "will this still be here in two years?" is the decisive adoption question — answer it explicitly.*

---

## 3. The 1.0 announce — ElixirForum post

### Category, tag, and shape

- **Category:** Libraries (the canonical home for "I built/shipped a library" posts; the dedicated "Announcing" sub-thread is where Oban and Req both landed). Tag `announcement`. *(MEDIUM — forum taxonomy shifts; confirm the current category name at post time.)*
- **One post, one thread.** Do not cross-post or spam. The maintainer then *replies in-thread* to questions — this is where trust is actually built (Oban's author answered every substantive question; the community rewarded it).
- **Length:** medium. Long enough to tell the maturity story and show one real snippet; short enough to read in two minutes. The README and HexDocs carry the depth.

### Tone notes (what the Elixir community rewards vs. what reads as spam)

The Elixir community is notably allergic to marketing gloss and notably warm to *honest, technically-credible, humble-but-confident* posts. Concretely, from the verified Oban and Req threads:

**What works (copy this):**
- **Lead with a plain-language tl;dr** of what it is and the one differentiator (Oban: "reliability and historical observability"; Req: "great out-of-the-box experience and extensibility").
- **Show, don't tell** — a small, real, runnable code snippet beats three paragraphs of adjectives.
- **Earned-evolution framing** — Oban opened by explaining the *prior* failed attempt (Kiq) and what he learned. Rulestead's equivalent is *stronger*: a full internal v1.x band of real governance/rollout/lifecycle work behind this cut. Tell that story.
- **Constructive differentiation** — Req opened with "there are already a lot of HTTP clients, so why another one?" and answered with *positive* differentiators, never disparaging Tesla/HTTPoison. Do the exact same with FunWithFlags.
- **Confident-but-humble close** — Oban ended "let me know what you think!". Invite feedback; don't declare supremacy.

**What reads as hype/spam (avoid — these are also VOICE.md don'ts):**
- Superlatives without evidence ("blazing-fast", "revolutionary", "the only").
- "X for Elixir" framing (subordinating + invites parity audit).
- Growth/AI/marketing verbs ("supercharge", "10x your velocity", "AI-powered").
- Announcing before it's installable + docs render (D8).
- Trash-talking incumbents (the FunWithFlags author and community are *in the room*).
- A wall of feature bullets with no code and no "why".

### Draft structure (fill at write-time, keep on-voice)

```
Title: Rulestead 1.0 — Elixir-native feature management:
       deterministic evaluation, explainable decisions, self-hostable admin

[tl;dr] Rulestead is a feature-management runtime for Phoenix —
booleans, variants, and remote config resolved deterministically from
ordered rules, with a first-class "explain why this resolved" API and an
optional mounted admin UI for rollouts, governance, and lifecycle. Today
we're cutting a real 1.0.0 on Hex across all three packages.

[one real snippet]
    context = Rulestead.Context.new(
      environment: "production",
      targeting_key: "user-123",
      attributes: %{plan: :pro}
    )
    {:ok, result} = Rulestead.evaluate(flag_payload, context)
    result.enabled?   #=> true
    result.reason     #=> matched rule 3 (plan == :pro), bucket 4721

[the honest 1.0 story — 1 short paragraph]
This isn't a brand-new toy. Rulestead has been API-frozen, RBAC-complete,
and governance-rich for some time; it's been shaped through a long internal
band of rollout, audience, lifecycle, and CI/CD hardening work. The Hex
version line (0.1.x) had simply stopped telling the truth about that
maturity. 1.0 is a promotion, not a debut — and a commitment: from here,
Hex SemVer is the public contract.

[why, not just what — 4-6 proof bullets from §1, each one line + benefit]

[honest scope — 2 sentences]
Self-hostable and Phoenix-first: it mounts in your app, runs on your
Postgres, uses your auth. It is not a hosted cloud, an edge evaluator, or a
stats engine — impression hooks only; analytics stays in your warehouse.

[FunWithFlags note — respectful, 1-2 sentences]
If you're on FunWithFlags and outgrowing booleans, there's a migration path
in the docs. Rulestead is the layer above: typed values, ordered rules,
explainability, and governance.

[links] HexDocs · GitHub release · Getting Started (15-min) · Why Rulestead?

[close] Feedback and reproducible issues welcome — happy to answer
questions in the thread.
```

---

## 4. The 1.0 announce — GitHub release notes

Use `brandbook/RELEASE-TEMPLATE.md` verbatim (it is canonical and already operator-aware). Concrete fill:

```
## Headline
Rulestead 1.0.0: a stable, public contract for the platform you've been building toward.

## Summary
All three packages — rulestead, rulestead_admin, and open_feature_rulestead —
now publish at 1.0.0 on Hex. This is a SemVer-truth release: it promotes a
mature, API-frozen, governance-rich platform to a stable public version. No
new runtime features; the public surface is locked as-is.

## What Changed
- Stable 1.0.0 public API contract — the six-function evaluation catalog and
  documented surfaces are now SemVer-protected with a published deprecation policy.
- 1.0-grade HexDocs front door — logo, reordered guides, a "Why Rulestead?"
  positioning extra, and the three previously-undocumented public modules now rendered.
- Adoption guides — troubleshooting + integrations cookbook grounded in real personas.
- Coordinated three-package cut — open_feature_rulestead now depends on rulestead ~> 1.0.

## Operator Impact
- What you build against today is now a stability promise, not a 0.x moving target.
- No behavior changes for mounted admin users, release operators, or support teams —
  evaluation, governance, rollout, kill-switch, and audit semantics are unchanged.

## Upgrade Notes
- No runtime API or schema changes; no renames. Update your dep to {:rulestead, "~> 1.0"}.
- open_feature_rulestead users: bump to ~> 1.0 (manual publish, sequenced after the trio).
- See upgrading.md for the 0.1.x → 1.0 mapping (mechanical; the surface is identical).

## Compatibility
- Runtime: rulestead 1.0.0 · Admin companion: rulestead_admin 1.0.0 · Provider: open_feature_rulestead 1.0.0
- Elixir: <supported range> · Phoenix/LiveView: <range>

## Verification
- release_gate green; post-publish verify trio green (rulestead + rulestead_admin + provider)
- Hex visibility check; HexDocs front-door render confirmed
- scripts/demo/proof.sh

## Links
- Changelog · HexDocs (hexdocs.pm/rulestead) · Getting Started · Why Rulestead?
```

**Microcopy discipline (RELEASE-TEMPLATE + VOICE.md):** start with operator consequence; state what changed *and what did not*; no hype, no apology. The "no behavior changes" line is doing real work — for a SemVer-truth release, the most reassuring thing you can say is "nothing under you moved."

---

## 5. Honest differentiation framing (the table you actually ship in prose, never as a vendor matrix)

> **Do not ship a comparison table.** A literal "Rulestead vs LaunchDarkly" matrix invites the parity audit Rulestead loses by design (no cloud, no edge, no stats engine) and violates brand guardrail §24 ("never position as a copycat"). Differentiate in *prose*, on *axes you own*.

| vs. | Their strength (acknowledge) | Rulestead's honest axis (don't claim parity) | How to say it |
|-----|------------------------------|----------------------------------------------|---------------|
| **FunWithFlags** | The proven, lightweight Elixir-native incumbent for boolean toggles + kill switches | The layer *above* booleans: typed values, ordered rules, explainability, governance, lifecycle — and a migration path | "If you've outgrown booleans, Rulestead is the next layer up. We ship a migration path because FunWithFlags is where many great Elixir apps started." |
| **LaunchDarkly** | Mature hosted platform, edge/CDN, deep analytics | Self-hostable, mounts in *your* Phoenix app, your auth, your data, no SaaS dependency; governance patterns without the cloud | "Rulestead borrows the governance lessons — approvals, audit, scheduled changes — and runs them inside your own app instead of someone else's cloud." |
| **Unleash** | Open-core, strong lifecycle + environment model, polyglot | Elixir-native runtime (no client-server round trip for eval), Phoenix-first control plane, deterministic local evaluation | "Evaluation is a pure local function on the BEAM — no client SDK calling out to a server. The control plane is Phoenix, not a separate service to operate." |
| **Flagsmith** | Open-source, remote config + segments, hosted or self-host | Same self-host axis as above; deterministic/explainable eval; lifecycle-required-at-create | "Self-hostable like Flagsmith, but the runtime *is* your app — and every decision can explain itself." |
| **Flipper (Ruby)** | The ergonomics benchmark FunWithFlags itself learned from | Value-first model + explain + governance, designed to avoid the percentage-of-time footgun Flipper's own docs warn against | "We took Flipper's footgun warnings as design requirements: stable actor bucketing is the default; percentage-of-time isn't offered." |

**User-psychology throughline for all of these:** the target reader is a skeptical senior Elixir engineer or platform owner (brand book §5 primary audience) who has been burned by under-maintained infra and over-promising SaaS. Three fears must be answered, in order:
1. **"Is the runtime actually sound?"** → determinism + purity + property tests + explain. (Lead here. Everything else is moot if this fails — Core Value: "everything else can fail; this cannot.")
2. **"Will I be locked in / will my data leave?"** → self-hostable, host-owned identity/observability/population truth, OpenFeature compat.
3. **"Will this be maintained?"** → the 1.0 promotion story, SemVer commitment, deprecation policy, MAINTAINING runbook, verification trio.

Answer those three honestly and the calm/exact brand voice does the rest. *Do not* try to win on feature breadth, price, or "we're the X for Elixir."

---

## 6. Closeout — what "announced + verified" looks like

The announce is not done when posted; it's done when **the front door is provably live and honest.** Verification gates, in order (this is also the D8 timing chain):

1. **Trio published + resolvable:** `rulestead`, `rulestead_admin`, `open_feature_rulestead` all at `1.0.0` on Hex; a fresh `mix deps.get` against `{:rulestead, "~> 1.0"}` resolves the whole set. (The provider is the manual, sequenced publish — confirm its `rulestead ~> 1.0` dep resolves *after* the trio is up.)
2. **Post-publish verify trio green** (the release_gate + post-publish proof chain already in CI/MAINTAINING).
3. **HexDocs front door renders the new shape:** logo present; `extras:` reordered; the **"Why Rulestead?"** extra is live; the three formerly-`@moduledoc false` public modules now render; module groups reflect the persona-driven IA (personas §11). Open `hexdocs.pm/rulestead` and `hexdocs.pm/rulestead_admin` and eyeball them — a 404 or an un-rendered module on launch day is the credibility-killer.
4. **README badges resolve** (Hex version badge shows 1.0.0, HexDocs badge links, CI badge green).
5. **GitHub release published** with the RELEASE-TEMPLATE content, tag matching the published versions, links live.
6. **ElixirForum post live**, linking only to artifacts confirmed in steps 1–5.
7. **Milestone audit:** record the announce surfaces, the verify evidence, and a screenshot/`file://` or live-URL capture of the rendered HexDocs front door as closeout proof (consistent with this repo's evidence-gated GSD posture).
8. **Maintainer-presence window:** plan to watch the forum thread and GitHub issues for the first 24–72h and reply substantively — this is the highest-leverage trust action of the entire launch (the Oban lesson).

**Definition of done:** all three packages installable at 1.0.0, trio green, HexDocs front door (incl. "Why Rulestead?") rendering correctly, GitHub release + ElixirForum post live and cross-linked, milestone audit captures the evidence — with **zero new runtime APIs** introduced (scope guard).

---

## 7. Confidence & gaps

| Area | Confidence | Note |
|------|------------|------|
| One-liner / messaging hierarchy | HIGH | Direct from locked positioning + brand book §7/§8 + Core Value. |
| Proof bullets ↔ persona mapping | HIGH | Grounded in personas-jtbd doc and product-boundary; all claims demonstrable in-repo. |
| FunWithFlags / SaaS differentiation framing | HIGH | Competitor brief + brand guardrails are explicit and consistent. |
| Launch exemplar lessons (Oban, Req) | HIGH | Both announce threads verified directly; lessons are concrete, not inferred. |
| ElixirForum category/tag mechanics | MEDIUM | Community taxonomy drifts; re-confirm "Libraries"/"Announcing" + `announcement` tag at post time. |
| Exact README badge set / Elixir version range | MEDIUM | Pin the supported Elixir/Phoenix range and CI badge URL from the actual repo at write-time. |

**Open questions to resolve at execution (not blockers):**
- Confirm the live ElixirForum announce category name and any current first-post etiquette pinned in that category.
- Confirm the exact supported Elixir/OTP/Phoenix range to fill the RELEASE-TEMPLATE Compatibility block.
- Decide whether the "Why Rulestead?" narrative is one HexDocs extra reused verbatim in the forum tl;dr, or a longer extra with a condensed forum variant (recommend: one canonical extra, condensed for the forum — single source of truth, consistent with this repo's no-second-source discipline).

---

## Sources

- Canonical repo docs (read in full): `.planning/PROJECT.md`, `brandbook/brand-book.md`, `brandbook/COPY.md`, `brandbook/VOICE.md`, `brandbook/RELEASE-TEMPLATE.md`, `prompts/rulestead-personas-jtbd-and-onboarding.md`, `prompts/elixir_feature_flags_research_brief.md`, `guides/introduction/product-boundary.md`, `guides/introduction/getting-started.md`. (HIGH)
- [Oban — Reliable and Observable Job Processing (ElixirForum announce thread)](https://elixirforum.com/t/oban-reliable-and-observable-job-processing/22449) — earned-evolution framing, tl;dr-first, humble-confident close, maintainer in-thread engagement. (HIGH)
- [Req — A batteries-included HTTP client for Elixir (ElixirForum announce thread)](https://elixirforum.com/t/req-a-batteries-included-http-client-for-elixir/48494) — constructive "why another one?" differentiation without disparaging incumbents. (HIGH)
- [GitHub — wojtekmach/req](https://github.com/wojtekmach/req) and [A Breakdown of HTTP Clients in Elixir — Andrea Leopardi](https://andrealeopardi.com/posts/breakdown-of-http-clients-in-elixir/) — corroborating Req positioning. (MEDIUM)
- [ElixirForum Guidelines](https://elixirforum.com/guidelines) and [Forum Announcements category](https://elixirforum.com/c/announcements/22) — community posting norms; "Library Updates" single-thread convention. (MEDIUM)
