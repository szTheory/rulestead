# Changelog

Public API stability contract: see [`../guides/api_stability.md`](../guides/api_stability.md).

## 1.0.0 — Promotion, not rewrite

`rulestead` and `rulestead_admin` graduate to `1.0.0` together (linked versions).
This is the **same battle-tested code** that has been running in production — now
honestly versioned. **Zero breaking changes.**

- **No public API changes.** The supported surface documented in
  `guides/api_stability.md` is unchanged — nothing moved, renamed, or changed
  behavior.
- **Upgrade is a dependency-pin bump only.** Point your `mix.exs` at the `1.x` line
  (`~> 1.0`) and run `mix deps.get`. No call-site audit, config change, or host-app
  integration work is required. See `guides/introduction/upgrading.md`.
- **Both sibling packages move together.** `rulestead` and `rulestead_admin` are
  linked versions and graduate in lockstep; `rulestead` publishes first, then
  `rulestead_admin`.

The `1.0.0` tag is a statement of confidence, not a migration event: the version
number is catching up to code that was already stable.

## [1.0.0](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.7...rulestead_admin-v1.0.0) (2026-06-18)


### Features

* **116-01:** add primitive polish helpers ([d0eed8a](https://github.com/szTheory/rulestead/commit/d0eed8a2acbabf52efc15a70fbb93fa06598db19))
* **116-02:** align mutation confirm flows ([0f400f7](https://github.com/szTheory/rulestead/commit/0f400f724e1ec128ceaf8e220df73bec3b17e9b3))
* **116-02:** strengthen mutation confirm states ([0f3d309](https://github.com/szTheory/rulestead/commit/0f3d309695f54e69cd8433fa75bfca64f98aa659))
* **116-03:** polish audit and rollout composites ([eae9092](https://github.com/szTheory/rulestead/commit/eae9092aeb949eaef2bfba4f2d7327552c1bd3f5))
* **116-03:** polish governance and trace composites ([28ed06a](https://github.com/szTheory/rulestead/commit/28ed06aae80234edb3e3715c5c860a54a81b15ce))
* **117-03:** fix home inventory and audience IA ([03c3cbe](https://github.com/szTheory/rulestead/commit/03c3cbe6d5516d8655d37c23164097d986079771))
* **117-03:** fix rules and kill route sequencing ([21384f8](https://github.com/szTheory/rulestead/commit/21384f8275c3718582e263acc117dc78a19515ad))
* **117-04:** fix audit explain and simulate hierarchy ([20c844c](https://github.com/szTheory/rulestead/commit/20c844c39f6523df066e8f4e3f1ec7d983823fb8))
* **126-01:** commit brandbook symlinks in both packages (D-09) ([314be02](https://github.com/szTheory/rulestead/commit/314be021a758d25e2911950eebe46cb65e2cb20d))
* **126-06:** expand admin mix.exs docs to parity (D-21) ([8ed2c33](https://github.com/szTheory/rulestead/commit/8ed2c33a5eb9fcc0c9f650ead83a7c69a040d74f))
* **126-06:** real RulesteadAdmin.Router [@moduledoc](https://github.com/moduledoc) + [@doc](https://github.com/doc) false internals (D-22/D-23) ([80caa6f](https://github.com/szTheory/rulestead/commit/80caa6f659e05a19e13bb962f2d8b2c71f050bee))
* **98-03:** mirror Block 3 → Block 2 (dark synced-pair invariant) + phx.digest ([d6f341c](https://github.com/szTheory/rulestead/commit/d6f341c32fc714b6a23643044fd5b4b437b0487f))
* **98-03:** re-skin Block 3 — 8 dark hex swaps from tokens.json admin_css_mapping.dark ([54d5bfa](https://github.com/szTheory/rulestead/commit/54d5bfa929904e8caf8dd5aff847666c03ed326b))
* **admin:** render winner wordmark lockup in shell header ([9f02a49](https://github.com/szTheory/rulestead/commit/9f02a490ae2b47d16089c4411a90beeea1c3b88f))
* **admin:** replace static rs-mark family with winner d-sigil ([60deace](https://github.com/szTheory/rulestead/commit/60deacec9ce041780e6ed32a18e9c024359b577f))
* **admin:** theme winner lockup via --logo-* vars in all four cascade blocks ([24d227d](https://github.com/szTheory/rulestead/commit/24d227de298dc6dc6ed6e7a15b4ee8702184d29e))
* pre-cut GA-prep band (phases 124–127) for the 1.0.0 release ([1b4fafd](https://github.com/szTheory/rulestead/commit/1b4fafd0a6779aa38ecc2f822ba2c0dd049384da))


### Bug Fixes

* **115-02:** neutralize reduced-motion transforms ([1cb024f](https://github.com/szTheory/rulestead/commit/1cb024f223ff75a04073ce4ad2b6f76006bc0642))
* **117:** close route flow review findings ([fbc7db1](https://github.com/szTheory/rulestead/commit/fbc7db1546531af9f5011d3666802c5d9708dfc9))
* **117:** harden explain simulate evidence paths ([93ebe76](https://github.com/szTheory/rulestead/commit/93ebe76dc0ea36d78c3222ea154cfe425e291d63))
* **117:** preserve explain tenant permalinks ([a834efc](https://github.com/szTheory/rulestead/commit/a834efc78cab94b8dbe3a658e5479514ae170bec))
* **126-06:** add skip_undefined_reference_warnings_on for cross-doc refs in admin ([ab3ad74](https://github.com/szTheory/rulestead/commit/ab3ad744bb1392e4fc5e645b7458bc5596c7a009))
* **release:** correct changelog-path so 1.0.0 notes ship in the real CHANGELOG ([#50](https://github.com/szTheory/rulestead/issues/50)) ([bf282c2](https://github.com/szTheory/rulestead/commit/bf282c2b7aaeebece3c92375a7dd2dd920000dcf))

## [0.1.7](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.6...rulestead_admin-v0.1.7) (2026-06-04)


### Features

* **admin:** information-architecture and design-system iteration ([#31](https://github.com/szTheory/rulestead/issues/31)) ([41a8d80](https://github.com/szTheory/rulestead/commit/41a8d8052dec84a1b9a1a47ef3e394a8912a7b24))

## [0.1.6](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.5...rulestead_admin-v0.1.6) (2026-05-30)


### Documentation

* cut 0.1.6 for contributor hygiene and guide updates ([#28](https://github.com/szTheory/rulestead/issues/28)) ([301e64a](https://github.com/szTheory/rulestead/commit/301e64ada1362e89720d3a24b99c39945d6c7b31))

## [0.1.5](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.4...rulestead_admin-v0.1.5) (2026-05-30)


### Bug Fixes

* **release:** align manifest with 0.1.4 and prep Unreleased changelog ([673a7df](https://github.com/szTheory/rulestead/commit/673a7dfba9404329b9267c6e2076b2e79e925f0e))

## [Unreleased]

### Bug Fixes

* ship packaged `rulestead_admin.css` for mounted admin UI styling

### Documentation

* **docs:** evaluator-first package README with absolute HexDocs links

## [0.1.4](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.3...rulestead_admin-v0.1.4) (2026-05-30)


### Miscellaneous Chores

* **rulestead_admin:** Synchronize rulestead-monorepo versions

## [0.1.3](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.2...rulestead_admin-v0.1.3) (2026-05-28)


### Bug Fixes

* **deps:** require ecto_sql ~&gt; 3.14 for Hex 0.1.3 ([68f5108](https://github.com/szTheory/rulestead/commit/68f5108ace8c6fd6b96a050eaa52515e49b29263))

## [0.1.2](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.1...rulestead_admin-v0.1.2) (2026-05-28)


### Miscellaneous Chores

* **rulestead_admin:** Synchronize rulestead-monorepo versions

## [0.1.1](https://github.com/szTheory/rulestead/compare/rulestead_admin-v0.1.0...rulestead_admin-v0.1.1) (2026-05-28)


### Features

* **15-03:** add stale flag UI badges ([a1c6613](https://github.com/szTheory/rulestead/commit/a1c6613658b948461c2a5bbb2e005dcf26aa03b9))
* **15-03:** implement cleanup confirmation workflow ([edab650](https://github.com/szTheory/rulestead/commit/edab6509ebba82049d5d62cbaf98c19e301e1ae4))
* **21-02:** add mounted diagnostics liveview ([80fff67](https://github.com/szTheory/rulestead/commit/80fff67121ebaa7a456df60648d59644fe6a837d))
* **21-02:** label diagnostics regions for accessibility ([17cd7b2](https://github.com/szTheory/rulestead/commit/17cd7b287a791e83a0ed7a63f13c1a4099b71594))
* **27-03:** project backend-derived capabilities into mounted admin session ([75bac46](https://github.com/szTheory/rulestead/commit/75bac46bae87a16aba8368969a22aadad4d685dd))
* **36-02:** expose lifecycle advisory surfaces ([c254fe2](https://github.com/szTheory/rulestead/commit/c254fe201df75ddbf98d33c7b8b54da5c5e254cc))
* **51-01:** render rollout guardrail status ([bac53c6](https://github.com/szTheory/rulestead/commit/bac53c64a73314d15f3ab82fb9bcdd20493c60c4))
* **51-02:** project guardrail interventions into timelines ([c8dc863](https://github.com/szTheory/rulestead/commit/c8dc863787f4dda46aa3c3fa4507dad137e87eb9))
* **59-01:** add AudienceLive governance context loader ([caaa70f](https://github.com/szTheory/rulestead/commit/caaa70f60209a0223df5568f3f19d0e6758a7f23))
* **59-01:** add GovernanceComponents blast_radius_panel ([5e6d3f0](https://github.com/szTheory/rulestead/commit/5e6d3f034435a1b058ab1382b49ed4722d196c8b))
* **59-02:** mirror governance UX on archive preview ([48f478a](https://github.com/szTheory/rulestead/commit/48f478a5f453380b41d44ba6a63cc845887e1819))
* **59-02:** wire governance panel and CTA on edit preview ([2274f53](https://github.com/szTheory/rulestead/commit/2274f539c2a0257c2c7d2b52c53233159d05796b))
* **59-03:** govern archive confirm apply vs submit change request ([c54f4fd](https://github.com/szTheory/rulestead/commit/c54f4fd62ccdf40aec126dfc8c432dccd2ff50b6))
* **59-03:** govern edit confirm apply vs submit change request ([820fabd](https://github.com/szTheory/rulestead/commit/820fabd0878797c28cd821b374141805f79b3690))
* **59-04:** frozen blast-radius evidence and approve gate on CR show ([4843b66](https://github.com/szTheory/rulestead/commit/4843b660bcb344463dff583ca30b22d0c9ad507c))
* **63-01:** add RolloutComponents.auto_advance_panel/1 ([1ec1613](https://github.com/szTheory/rulestead/commit/1ec161339d85effd8a22734041f864523b85921c))
* **63-01:** load auto-advance assigns and render panel on rollouts ([3b8a165](https://github.com/szTheory/rulestead/commit/3b8a165be294464ef6e91b183319ce4923f4d8f1))
* **63-02:** implement save_auto_advance_policy with advance_rollout gate ([e6a38f6](https://github.com/szTheory/rulestead/commit/e6a38f6aaad8a44c2ba5e759d3180ff227222b0c))
* **63-02:** wire auto-advance form in panel and parse params ([e95cb51](https://github.com/szTheory/rulestead/commit/e95cb51c4d05124062142f249ac51ee7f8488131))
* **63-03:** extend auto-advance redaction allow-lists ([072556d](https://github.com/szTheory/rulestead/commit/072556dd6a5ce716fb2ddacbb07d48984660b3d4))
* **63-03:** extend automation detection for rollout.advance ([56d7a9f](https://github.com/szTheory/rulestead/commit/56d7a9f5d123d9f7b253e27d65494e7a32dcd99e))
* **admin:** complete phase 18 experimentation ui and reporting ([d222da0](https://github.com/szTheory/rulestead/commit/d222da0661bffeb3925350cb2349e3b916d54171))
* land v1.3.0 support-truth worktree ([935c9d5](https://github.com/szTheory/rulestead/commit/935c9d5fa3d8d915fa118007edb08cd2ccb2e4a9))
* **phase-67:** mounted preview evidence workflows (ADM-05) ([9f0229e](https://github.com/szTheory/rulestead/commit/9f0229ec8bb3c84677e7c5a88801b65f4c567693))
* **security:** enforce RBAC capabilities in mounted admin mutation routes ([1c4b38e](https://github.com/szTheory/rulestead/commit/1c4b38e4a279a1e1182e6358b5e28ab027c63ea5))
* **security:** project canonical capability model to read surfaces and docs ([16f6e3a](https://github.com/szTheory/rulestead/commit/16f6e3aa236d8d85601194acde5a81aef4ca956d))
* **v1.6.0:** complete mounted audience workflows and proof/docs closeout ([20a5295](https://github.com/szTheory/rulestead/commit/20a5295a258cad7f46d0a77d6cf6c966655dfb66))


### Bug Fixes

* **13:** resolve test regressions from phase 13 execution ([ef45db8](https://github.com/szTheory/rulestead/commit/ef45db8dc5c7e7dd8db400bd8d92c29f06754ecb))
* **51-01:** preserve rollout guardrails on saves ([53bc654](https://github.com/szTheory/rulestead/commit/53bc6544b1ef73d57a1257af22e15f2e77a03b42))
* **51:** avoid dynamic atom creation in rollout serialization ([128ef55](https://github.com/szTheory/rulestead/commit/128ef55eb6a5aa16280c2957df42e1d698fef161))
* **51:** CR-01 narrow guardrail metadata redaction ([7db1b48](https://github.com/szTheory/rulestead/commit/7db1b480aeff871f61424288ab33e24d4c2d9166))
* **51:** CR-02 use resolved mounted environment scope ([7a74baf](https://github.com/szTheory/rulestead/commit/7a74bafe4d118f5378a397b19b0a0230efbd134d))
* **51:** CR-03 allowlist LiveView session data ([e721388](https://github.com/szTheory/rulestead/commit/e72138810733cdbab9533735af143fba90874c51))
* **51:** guard rollout preview action without rollout rule ([b51795b](https://github.com/szTheory/rulestead/commit/b51795b6e9ca78683e4fa969c4ffbf558855baed))
* **51:** guard rollout preview event without rollout rule ([bc93b03](https://github.com/szTheory/rulestead/commit/bc93b03e705c115dbf7bfd79a03e44b598352bb6))
* **59:** restore test isolation and kill page RBAC fixture ([1df35e7](https://github.com/szTheory/rulestead/commit/1df35e70dd559a00a0a038aa878ee1662ed2d3b2))
* green core and admin test suites for release gate ([de25000](https://github.com/szTheory/rulestead/commit/de25000b6e7c2496b2be4df249f14acafa4f9def))

## 0.1.0 (2026-05-11)


### Features

* **01-03:** add admin package metadata and guardrails ([137c53f](https://github.com/szTheory/rulestead/commit/137c53f58b7cfe0399c87542633c89527d707c9a))
* **06-03:** add admin liveview package wiring ([4ae1883](https://github.com/szTheory/rulestead/commit/4ae1883f195347069403b9ff2fcf724af880d231))
* **06-03:** mount admin liveview placeholder screens ([f4de4ea](https://github.com/szTheory/rulestead/commit/f4de4ea63f2d3f078239acba075ece8dd0fad78c))
* **06-04:** add flag metadata and detail screens ([ecc7479](https://github.com/szTheory/rulestead/commit/ecc7479a892a95ca0066777e3ba0da3c384c4a67))
* **06-04:** build dense flag inventory liveview ([5cb2511](https://github.com/szTheory/rulestead/commit/5cb25116cbce45d17fa4e3c8205fab58284c8129))
* **06-05:** build dedicated rules workspace ([e7208f1](https://github.com/szTheory/rulestead/commit/e7208f130f542b282c877830df9f56f01bef5507))
* **07-02:** add phase 7 admin route and session scaffold ([679d1aa](https://github.com/szTheory/rulestead/commit/679d1aab2d52d014a9702e02976f3dd5447f9b6f))
* **07-02:** scaffold phase 7 operator page shells ([51deec7](https://github.com/szTheory/rulestead/commit/51deec7f6c7e7e05ecf89727c7be0403e31b5d24))
* **07-03:** implement simulation liveview workflow ([db0ce80](https://github.com/szTheory/rulestead/commit/db0ce802fb771835d528368cc31a636741cfe5b8))
* **07-04:** add risky rollout confirmation flow ([de6da02](https://github.com/szTheory/rulestead/commit/de6da02f0139cf5ff94159780c317a421a4bf8c4))
* **07-04:** implement rollout controls page ([be40276](https://github.com/szTheory/rulestead/commit/be4027676774ca40c7dc2039776b0b02ce9089b7))
* **07-05:** add audit timeline operator surfaces ([4eaa601](https://github.com/szTheory/rulestead/commit/4eaa6016ada11bd0ed5cf01259767d409f15b73d))
* **07-05:** add kill switch operator surface ([1fe6828](https://github.com/szTheory/rulestead/commit/1fe68287603b56313fa79922738be42f97eead51))
* **07-09:** honor admin mount and auth seams ([6fe86d2](https://github.com/szTheory/rulestead/commit/6fe86d27d60d7ae3d83e46261f361b66bc5d6f84))
* **11-01:** add governance shell navigation ([3fcc028](https://github.com/szTheory/rulestead/commit/3fcc028fcf91273d406c1989bb6066529fe73bb3))
* **11-01:** add mounted governance route stubs ([41e3941](https://github.com/szTheory/rulestead/commit/41e3941fe8b9274dfdd6a96cd214f8c146b7e92f))
* **11-02:** add governed review surfaces ([0c2b67c](https://github.com/szTheory/rulestead/commit/0c2b67caddd6b0ad0ee7bf8973bf01bab477de77))
* **11-03:** build scheduled execution operator views ([1124c8a](https://github.com/szTheory/rulestead/commit/1124c8afb383dc793fbdfa9ff3f6ff1f1f896ef4))
* **11-04:** verify mounted governance admin flows ([1cfaab2](https://github.com/szTheory/rulestead/commit/1cfaab21e78840403d4332c32b671f1ca8982e37))
* **12-05:** add read-only webhook summary links and accessibility tests ([12f16cd](https://github.com/szTheory/rulestead/commit/12f16cdf5576a89ac1b0e6704610e8d05063b274))
* **12-05:** add the mounted webhook hub routes and route-backed list/detail LiveViews ([e5d1eed](https://github.com/szTheory/rulestead/commit/e5d1eed654911b41ffe5b736bcfe45bf889b9e3b))
* **12-06:** finalize webhook visibility and governance, update state ([10f0168](https://github.com/szTheory/rulestead/commit/10f016826de988c9fab9f23c7c4b20cf097f1263))


### Bug Fixes

* **07-11:** align simulation seed auth contract ([5a847c4](https://github.com/szTheory/rulestead/commit/5a847c4e2d4247572d29a6b8bbb1b0d110779db5))
* **phase-07:** restore dedicated audit route wiring ([86ee0c7](https://github.com/szTheory/rulestead/commit/86ee0c7453d89ff4be6eb970b483fc763a73f9a4))


### Miscellaneous Chores

* **ci:** unblock phase 1 bootstrap verification ([e5106d0](https://github.com/szTheory/rulestead/commit/e5106d0f0f2245f668f41d8ebc795b2a8d66ed17))
