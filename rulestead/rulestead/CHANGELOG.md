# Changelog

## [0.1.8](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.7...rulestead-v0.1.8) (2026-06-13)


### Miscellaneous Chores

* **rulestead:** Synchronize rulestead-monorepo versions

## [0.1.7](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.6...rulestead-v0.1.7) (2026-06-04)


### Features

* **admin:** information-architecture and design-system iteration ([#31](https://github.com/szTheory/rulestead/issues/31)) ([41a8d80](https://github.com/szTheory/rulestead/commit/41a8d8052dec84a1b9a1a47ef3e394a8912a7b24))

## [0.1.6](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.5...rulestead-v0.1.6) (2026-05-30)


### Documentation

* cut 0.1.6 for contributor hygiene and guide updates ([#28](https://github.com/szTheory/rulestead/issues/28)) ([301e64a](https://github.com/szTheory/rulestead/commit/301e64ada1362e89720d3a24b99c39945d6c7b31))

## [0.1.5](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.4...rulestead-v0.1.5) (2026-05-30)


### Bug Fixes

* **ci:** unblock release PR warnings-as-errors and demo smoke ([2fdccfc](https://github.com/szTheory/rulestead/commit/2fdccfcf7d9c11089d5842b5a26baf03590440be))
* **release:** align manifest with 0.1.4 and prep Unreleased changelog ([673a7df](https://github.com/szTheory/rulestead/commit/673a7dfba9404329b9267c6e2076b2e79e925f0e))

## [Unreleased]

### Features

* **adoption-lab:** realistic FleetDesk UI with collapsible developer tools drawer

### Bug Fixes

* **rulestead_admin:** ship packaged stylesheet for mounted admin UI styling

### Documentation

* **docs:** evaluator-first Hex READMEs with absolute HexDocs links
* **docs:** trim root README proof wall and sync version truth across guides
* **docs:** add doc link contract tests to prevent Hex.pm link regressions

## [0.1.4](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.3...rulestead-v0.1.4) (2026-05-30)


### Features

* **adoption-lab:** ship v1.12 adoption evidence depth ([52751c5](https://github.com/szTheory/rulestead/commit/52751c5e942f741981f84f856b0782e4a619fa3a))


### Bug Fixes

* **ci:** unblock FleetDesk adoption lab pipeline ([c012c6e](https://github.com/szTheory/rulestead/commit/c012c6e0e7e8f747836af7580fad5ab892e1f7b2))
* **ci:** unblock FleetDesk Playwright proofs on PR [#21](https://github.com/szTheory/rulestead/issues/21) ([32bec5f](https://github.com/szTheory/rulestead/commit/32bec5f979e4f87817b78da1565ff566626d3835))

## [0.1.3](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.2...rulestead-v0.1.3) (2026-05-28)


### Bug Fixes

* **deps:** require ecto_sql ~&gt; 3.14 for Hex 0.1.3 ([68f5108](https://github.com/szTheory/rulestead/commit/68f5108ace8c6fd6b96a050eaa52515e49b29263))

## [0.1.2](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.1...rulestead-v0.1.2) (2026-05-28)


### Bug Fixes

* restore post-publish verification trio for linked releases ([7bfea96](https://github.com/szTheory/rulestead/commit/7bfea96236c2abb981bdccd165fa64bcb15c808d))
* unblock CI lint gate and release-pr-ci dispatch ([64798ef](https://github.com/szTheory/rulestead/commit/64798efb160a8a30e7a99935302d9d883e945675))

## [0.1.1](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.0...rulestead-v0.1.1) (2026-05-28)


### Features

* **15-01:** implement Oban worker to flush telemetry cache ([f0717a1](https://github.com/szTheory/rulestead/commit/f0717a159789b42b3cc3a55be40412f31ddb7bf6))
* **15-01:** implement telemetry cache ([e99c466](https://github.com/szTheory/rulestead/commit/e99c4667bba064b7507563012d2f8714c8b9355e))
* **15-01:** implement telemetry ETS cache for high-throughput tracking ([b411def](https://github.com/szTheory/rulestead/commit/b411def27a8fdf32d7356d5e961a16a70274f4a3))
* **15-01:** wire up telemetry cache to main evaluator and add summary ([f10f512](https://github.com/szTheory/rulestead/commit/f10f5122bf6ac02267848afea6fbcc27e54d6a93))
* **15-02:** implement AST Code Reference Scanner ([0f1eed0](https://github.com/szTheory/rulestead/commit/0f1eed03e784da1fd07fe24fa7f3d7f8340fcd5b))
* **15-02:** implement code refs ingress plug ([0880e63](https://github.com/szTheory/rulestead/commit/0880e630ab3b901c57fe91132c6a9c31be2e3d9a))
* **15-02:** implement Code Refs Mix Task ([7bc5cea](https://github.com/szTheory/rulestead/commit/7bc5cea74fb2ea6dfd13a3e2ae410e214e96f6e5))
* **15-03:** add stale flag UI badges ([a1c6613](https://github.com/szTheory/rulestead/commit/a1c6613658b948461c2a5bbb2e005dcf26aa03b9))
* **16-01:** Compile-Time Reduction Commands (EXP-03) ([da132ae](https://github.com/szTheory/rulestead/commit/da132aeaf571b40ac4182bf90bfbeaef3a2df685))
* **16-01:** Deterministic Bucketing & Telemetry (EXP-02) ([6a4a187](https://github.com/szTheory/rulestead/commit/6a4a187fe05aef5b9f868d3268f6909d6a4b26f0))
* **16-01:** Experiment Data Model (EXP-01) ([5ad5d3a](https://github.com/szTheory/rulestead/commit/5ad5d3a42b565f5089e745751ee7081a95f5fa00))
* **17-01:** implement analytics event schema, migration, and mapper ([9763892](https://github.com/szTheory/rulestead/commit/9763892f733071082071df8c47b523ee43a06580))
* **17-02:** implement high-throughput analytics batcher and telemetry handler ([1a5f441](https://github.com/szTheory/rulestead/commit/1a5f441b92749b842a2f8e95cfaf108086b23c0e))
* **17-03:** implement public analytics track/3 ([d6987ba](https://github.com/szTheory/rulestead/commit/d6987ba87f469b9b2b2761970109ea9deed52d44))
* **18-01:** implement experiment metrics query grouping by variation ([131ce1a](https://github.com/szTheory/rulestead/commit/131ce1a0662639e0e977c782e72ddf0a32580668))
* **18-01:** implement statistical significance engine ([bd091aa](https://github.com/szTheory/rulestead/commit/bd091aa00325155d87ef37a31ec80f729f55b8d3))
* **20-02:** wire runtime invalidation through notifier seam ([4de38ce](https://github.com/szTheory/rulestead/commit/4de38ce207a2f4fa7c7a75da5eccb73c79beda00))
* **21-01:** add bounded runtime health snapshot ([ec56d90](https://github.com/szTheory/rulestead/commit/ec56d90e26a185ec48b9bc44cc9a6ef48bfb2f63))
* **21-01:** add invalidation telemetry aliases ([1d43a17](https://github.com/szTheory/rulestead/commit/1d43a178e2239da69f43ada355dbafd97379cdcc))
* **22-01:** add authored environment compare contract ([4cfdb0e](https://github.com/szTheory/rulestead/commit/4cfdb0e0baddb74e78010a73e4e7013f3a39b7fa))
* **35-01:** add authored ownership lifecycle foundation ([8781192](https://github.com/szTheory/rulestead/commit/8781192772c29dc35b9b2b424ebbf91221ecc41e))
* **36-01:** persist code reference scan receipts ([9077516](https://github.com/szTheory/rulestead/commit/90775160ce5fe81d8d7431cf9b67d988f9695fb0))
* **36-01:** project archive readiness through stores ([4ff75ca](https://github.com/szTheory/rulestead/commit/4ff75cabe1530a8dc109b6c32758f4d5e513495a))
* **36-02:** expose lifecycle advisory surfaces ([c254fe2](https://github.com/szTheory/rulestead/commit/c254fe201df75ddbf98d33c7b8b54da5c5e254cc))
* **53-01:** implement audience dependency summaries ([8392d79](https://github.com/szTheory/rulestead/commit/8392d79499527f75368c2749fad14acd6c2fe67f))
* **53-01:** implement audience impact preview contract ([6b14949](https://github.com/szTheory/rulestead/commit/6b14949853d25bd396b973a8bbcd523d41881c78))
* **53-02:** compile audiences in runtime snapshots ([cf5a0a2](https://github.com/szTheory/rulestead/commit/cf5a0a21885863ee896fbc5327b888870a3dd725))
* **53-02:** resolve segment matches from snapshot audiences ([1b7bdc5](https://github.com/szTheory/rulestead/commit/1b7bdc501834ad8e67aff421555b778804ccd88e))
* **53-03:** define audience impact command contracts ([4f593eb](https://github.com/szTheory/rulestead/commit/4f593ebe5835b608c710422a6a7d920a244fca1e))
* **53-03:** implement fake audience impact parity ([f902a18](https://github.com/szTheory/rulestead/commit/f902a18634b1810c8e61b350045557a896394a06))
* **53-03:** route audience impact facade through admin envelopes ([125a2d4](https://github.com/szTheory/rulestead/commit/125a2d4addbe5384a7303961903e4c5365652241))
* **53-04:** enforce Ecto audience preview applies ([716f912](https://github.com/szTheory/rulestead/commit/716f91291312d747034534c1ea58daa516503eb3))
* **53-04:** include audiences in Ecto runtime snapshots ([ac79316](https://github.com/szTheory/rulestead/commit/ac7931678ceee04d55edb4baeada3b48614643e3))
* **53-04:** persist audience mutation audit evidence ([dd7e216](https://github.com/szTheory/rulestead/commit/dd7e216d3fe5e1dac20e8ffced380ab44462d4a0))
* **54-01:** add projection-backed audience dependency seams ([7f8e4d8](https://github.com/szTheory/rulestead/commit/7f8e4d854a3c522cb39896dd432afaf1566997c6))
* **54-01:** expose authorized dependency inventory read APIs ([1db0f9c](https://github.com/szTheory/rulestead/commit/1db0f9cbe45aa8d35437ed15d2ce850e01c69f04))
* **54-01:** implement dependency inventory normalization contract ([038cdf8](https://github.com/szTheory/rulestead/commit/038cdf8cebc1a24dd9435cd438178e7bc0998aab))
* **54-02:** add shared dependency validator contract ([06d94b7](https://github.com/szTheory/rulestead/commit/06d94b7625a1a3ec584f94e609fd2e5cc90c5012))
* **54-02:** enforce dependency blockers on ruleset publish ([342789e](https://github.com/szTheory/rulestead/commit/342789e59f5d612e8a82c8cc0171ca8532033ca5))
* **54-02:** gate audience mutations with dependency validation ([934c059](https://github.com/szTheory/rulestead/commit/934c0597e62303e960747a155293a3b30c61c8b2))
* **54-03:** add scoped dependency findings to compare previews ([46e2f4d](https://github.com/szTheory/rulestead/commit/46e2f4d439df9a62bef09a80965688f1398583a3))
* **54-03:** revalidate promotion dependencies at apply time ([f283006](https://github.com/szTheory/rulestead/commit/f2830062377795095eb173b4eaf39f9a03b994ef))
* **54-03:** wire shared dependency findings into manifest flows ([c0f383c](https://github.com/szTheory/rulestead/commit/c0f383cf1929430755b1ab364e1fef1166e58b0d))
* **61-01:** add rollout auto-advance policy migration and schema ([4cb8967](https://github.com/szTheory/rulestead/commit/4cb896735041999b04a578afec27455e6d786816))
* **61-01:** add rollout auto-advance store command structs ([4af1d8e](https://github.com/szTheory/rulestead/commit/4af1d8e59af8a2ade7e58b0ed0367e76c43b90ed))
* **61-02:** add pure AutoAdvance eligibility evaluator ([9674098](https://github.com/szTheory/rulestead/commit/9674098a6a47e870ad816adb51cd7dd1747e2283))
* **61-03:** add Ecto store auto-advance policy callbacks ([9a2973d](https://github.com/szTheory/rulestead/commit/9a2973d75ca3b142b2fddedf18822048bb1f89ef))
* **61-03:** add Fake store auto-advance policy callbacks ([20e5da9](https://github.com/szTheory/rulestead/commit/20e5da9cc0fd25706be8899d040db27d9df034e2))
* **61-03:** add Rulestead auto-advance policy facade wrappers ([c5d3b87](https://github.com/szTheory/rulestead/commit/c5d3b87ece790e15da8115372f2e1bf3b4f2a53e))
* **62-01:** add idempotency_key to ScheduleGovernedAction ([0a236c9](https://github.com/szTheory/rulestead/commit/0a236c9e26df615f5b480d328cf5cc8874417881))
* **62-01:** mirror auto-advance schedule hook in Fake adapter ([d79a0cf](https://github.com/szTheory/rulestead/commit/d79a0cf4e8d92547e1846b0658973d29b7a9c077))
* **62-01:** schedule auto-advance tick after advance_rollout ([a27c506](https://github.com/szTheory/rulestead/commit/a27c5065b3ba190baf8c95658569677fc46be3a4))
* **62-02:** add RolloutAutoAdvance execute orchestration module ([c5190e8](https://github.com/szTheory/rulestead/commit/c5190e8bd54e516d3dfa9b722fcb3bee86f8dde1))
* **62-02:** wire RolloutAutoAdvance into Ecto scheduled execution ([1b618fa](https://github.com/szTheory/rulestead/commit/1b618fac11eee4ff5b87b25e1ac5a41d22e3a362))
* **62-02:** wire RolloutAutoAdvance into Fake scheduled execution ([ba8e8d4](https://github.com/szTheory/rulestead/commit/ba8e8d43dd27ad16b3faead95356fb9098c84a4d))
* **62-03:** add Fake.Control list_change_requests test helper ([8bc6293](https://github.com/szTheory/rulestead/commit/8bc629331ed331519f090e86e0690ee6d5a9a1ad))
* **62-03:** finalize automation ticks with blocked and CR-submitted metadata ([9b9aca9](https://github.com/szTheory/rulestead/commit/9b9aca9611c4a185c7f9cfb904caa09e8b329df3))
* **62-03:** route protected auto-advance ticks through change request submit ([9d845f1](https://github.com/szTheory/rulestead/commit/9d845f16580bdae4ec08a62b94a056794b6a3ba5))
* **64-01:** add mix verify.phase64 merge gate ([f5a54f2](https://github.com/szTheory/rulestead/commit/f5a54f253b21b0b487295d8c72d7eda06fe2fa1f))
* **65-01:** add fail-closed preview evidence limits and redaction ([89e47c6](https://github.com/szTheory/rulestead/commit/89e47c6c53d7b3cbdcb37d78c6068c917a145ce7))
* **65-01:** add PreviewEvidence behaviour, facade, and query normalization ([ee63750](https://github.com/szTheory/rulestead/commit/ee637501c3e3db45c801a67ae37a41ed8f5f9fd3))
* **65-02:** bump ImpactPreview to schema v2 with impression evidence ([d58cf25](https://github.com/szTheory/rulestead/commit/d58cf25bffad956d2f8ec3f04e9d97106bceaff6))
* **65-03:** wire preview evidence assembly into Fake and Ecto stores ([7e56d2f](https://github.com/szTheory/rulestead/commit/7e56d2f333a482e88f3f49173f76a64f35383be4))
* **66:** evidence carry-through and GOV-05 governance boundary ([6c1e63b](https://github.com/szTheory/rulestead/commit/6c1e63bf471b415e802fa15af3bed76d33776d98))
* **68-01:** add Mix.Tasks.Verify.Phase68 merge gate ([8affb1f](https://github.com/szTheory/rulestead/commit/8affb1f425aa1972ef6f9494a6d6f487c6cd9196))
* **73-01:** promote traits to attributes and lock quickstart doc honesty ([b272185](https://github.com/szTheory/rulestead/commit/b27218530c0224f5a75bb238a1b425cbf6be1269))
* **75-01:** add mix verify.phase73 flat post-GA proof union ([0e04d77](https://github.com/szTheory/rulestead/commit/0e04d7704762278b8508ff17c2ef4d8278a15d9e))
* **75-01:** retarget adopter and CI to verify.phase73 ([39c9af7](https://github.com/szTheory/rulestead/commit/39c9af791f48184b7a4d6fa57ea966ba9d259c26))
* **admin:** complete phase 18 experimentation ui and reporting ([d222da0](https://github.com/szTheory/rulestead/commit/d222da0661bffeb3925350cb2349e3b916d54171))
* **admin:** implement canonical RBAC vocabulary and compatibility boundary ([d381dca](https://github.com/szTheory/rulestead/commit/d381dca03a8faa4889f6e38ccaa420ce9f9b1622))
* land v1.3.0 support-truth worktree ([935c9d5](https://github.com/szTheory/rulestead/commit/935c9d5fa3d8d915fa118007edb08cd2ccb2e4a9))
* **phase-60-01:** add mix verify.phase60 and governance proof dependencies ([7c94781](https://github.com/szTheory/rulestead/commit/7c94781ded500c3ed68ed83126053429c62ebe0f))
* **security:** align facade and command surfaces with canonical RBAC vocabulary ([f25c0c4](https://github.com/szTheory/rulestead/commit/f25c0c45f4ff489acbc18a554195b474cff602f4))
* **tenancy:** implement explicit tenancy seam and single-tenant default ([26ebe21](https://github.com/szTheory/rulestead/commit/26ebe217e2a54eddafae589bf9b7d483b58d1a6b))
* **v1.11:** ship integration spine docs and verify.phase76 adopter bar ([286077d](https://github.com/szTheory/rulestead/commit/286077da64cc14dd6139aead7bb799e1ac26a6df))
* **v1.6.0:** complete mounted audience workflows and proof/docs closeout ([20a5295](https://github.com/szTheory/rulestead/commit/20a5295a258cad7f46d0a77d6cf6c966655dfb66))


### Bug Fixes

* **13:** resolve test regressions from phase 13 execution ([ef45db8](https://github.com/szTheory/rulestead/commit/ef45db8dc5c7e7dd8db400bd8d92c29f06754ecb))
* **53:** evaluate store-shaped audience conditions ([35206a5](https://github.com/szTheory/rulestead/commit/35206a56165a46398ce856588acdbbc7d43122f4))
* **53:** harden preview and audience condition evaluation ([3229bd7](https://github.com/szTheory/rulestead/commit/3229bd7711e2239f07fadecf8e160e9b7c828bee))
* **53:** include audiences in fake runtime snapshots ([afee5c1](https://github.com/szTheory/rulestead/commit/afee5c1116f69114537b3e3b4171f6206ce1c8dc))
* **53:** preserve false evaluator values ([ffbd945](https://github.com/szTheory/rulestead/commit/ffbd945cffa236b50a6f1ac9904d5ba10f1ca126))
* **53:** verify audience preview references ([efe080b](https://github.com/szTheory/rulestead/commit/efe080be7cd1824ad293453728356f0d7045b3ed))
* **54-04:** close regression and verifier coverage gaps ([519a916](https://github.com/szTheory/rulestead/commit/519a916a5e8dacd1e50b250e0b3bc8ac89890a08))
* **54-04:** forward audiences in list-first dependency validation ([67ced4c](https://github.com/szTheory/rulestead/commit/67ced4ca106693a0ca603d40b197478523c9e624))
* **62-04:** flatten orchestration signal facts and Fake reentrancy ([9d07283](https://github.com/szTheory/rulestead/commit/9d0728344ba2253a9901626354f73416385507b1))
* green core and admin test suites for release gate ([de25000](https://github.com/szTheory/rulestead/commit/de25000b6e7c2496b2be4df249f14acafa4f9def))
* green lint lane and seed default audience in contract tests ([4fbb63e](https://github.com/szTheory/rulestead/commit/4fbb63ee87995c2ef3b056e8f61742f2e8277232))
* restore ex_doc and install golden for v1.11 docs band ([0de74c3](https://github.com/szTheory/rulestead/commit/0de74c30b47147c0c9cfc5d3fa2f88f5647c8bbc))

## 0.1.0 (2026-05-11)


### Features

* **01-02:** add core package metadata and docs surface ([2dc5ba9](https://github.com/szTheory/rulestead/commit/2dc5ba9ec70ebf3ebbf9e64f1563919296c4735b))
* **02-01:** add ecto repo foundation ([2ed1468](https://github.com/szTheory/rulestead/commit/2ed1468ae51d63537dd8bf8ca27426dbfc92b30e))
* **02-01:** add shared repo sandbox harness ([461b4d8](https://github.com/szTheory/rulestead/commit/461b4d81372ba27030f7f92563e2ea8136a783a5))
* **02-02:** define key-first store contract ([f0806a6](https://github.com/szTheory/rulestead/commit/f0806a6a69773c5b40c1ab71a989b27bdfdd5f66))
* **02-02:** lock public error envelope ([cd085e9](https://github.com/szTheory/rulestead/commit/cd085e90d5cafc16a46a296c2c89d73824b0daac))
* **02-02:** reserve public bang and evaluator conventions ([b96f21f](https://github.com/szTheory/rulestead/commit/b96f21fa7565f4d52fa36c06ddd0191536696938))
* **02-03:** add authoring store migrations ([757cfa2](https://github.com/szTheory/rulestead/commit/757cfa2efe5c81d3b241a5c1ac15662e7c23c665))
* **02-03:** add immutable ruleset schemas ([53edc3e](https://github.com/szTheory/rulestead/commit/53edc3eb791180824c37ef3b8972862c574699a8))
* **02-03:** add relational authoring schemas ([6d8d83b](https://github.com/szTheory/rulestead/commit/6d8d83baa66fedce9a5b871deec06465e7ef0294))
* **02-04:** add contract-faithful fake adapter ([841ef98](https://github.com/szTheory/rulestead/commit/841ef98cc45c3aa6080645793997411743d56abd))
* **02-05:** add ecto-backed store adapter ([ec24b94](https://github.com/szTheory/rulestead/commit/ec24b94a4c11fdc861853b5285f3b0f19abb265a))
* **02-05:** add minimal install task ([c16b6ee](https://github.com/szTheory/rulestead/commit/c16b6ee113f57fee0fedd34e979b9f2e5715981f))
* **04-01:** add persisted runtime snapshot contract ([fdf3802](https://github.com/szTheory/rulestead/commit/fdf380219beee3ad716ea003ef1c691306cc52dc))
* **04-01:** publish runtime snapshots in store adapters ([a7e8c3a](https://github.com/szTheory/rulestead/commit/a7e8c3a4767765cd4930c0a3c338d0ba7341e340))
* **04-02:** add runtime diagnostics and explain facade ([b477ba4](https://github.com/szTheory/rulestead/commit/b477ba4c6762e2fe6f78ff705bec708a3813de16))
* **04-02:** compile snapshots into ETS runtime cache ([e09c590](https://github.com/szTheory/rulestead/commit/e09c5909f4bf99083910226001d33f9acd694e78))
* **04-03:** add hybrid runtime refresh orchestration ([dc383d5](https://github.com/szTheory/rulestead/commit/dc383d5e61655f4bea0db3b3a91e950c9f0bdc09))
* **04-03:** wire supervised degraded runtime startup ([e62c8d0](https://github.com/szTheory/rulestead/commit/e62c8d0b97c64b6660e1bd0663141ba06ede8b7f))
* **04-04:** add runtime disk backup bootstrap ([4b2f0a8](https://github.com/szTheory/rulestead/commit/4b2f0a86dfb3f426d11113c8653d111c9f663c10))
* **04-04:** prove stale serving and cluster convergence ([53c9bc6](https://github.com/szTheory/rulestead/commit/53c9bc6bfd7443afa31b20fded79332d081df8ab))
* **04-05:** instrument phase 4 telemetry surface ([d308879](https://github.com/szTheory/rulestead/commit/d308879304d1cf60cd5719e651dd968ca1e4637c))
* **04-05:** publish telemetry guide and ecto hot path wiring ([07c26c0](https://github.com/szTheory/rulestead/commit/07c26c0670c28b97270fd122aab4955a3a3b92a5))
* **05-03:** add fake-backed public test helpers ([3e3b36d](https://github.com/szTheory/rulestead/commit/3e3b36d4fa1c9a650971ae26efd680fd2b638e66))
* **05-03:** default tests to fake-first harness ([4564580](https://github.com/szTheory/rulestead/commit/4564580144ffbf197d7676b7c9bf872827b95c4d))
* **06-01:** add lifecycle persistence contracts ([eae0991](https://github.com/szTheory/rulestead/commit/eae09911813686b725506aeb2be09c6cb1be4970))
* **06-01:** add phase 6 admin core contracts ([412d1df](https://github.com/szTheory/rulestead/commit/412d1df3a0084e244d05f72ab4637a39ab251705))
* **06-02:** implement admin payloads and stale tracker ([a91ee7a](https://github.com/szTheory/rulestead/commit/a91ee7adbf1a1551bba1066f8efcde140168f1d4))
* **06-05:** build dedicated rules workspace ([e7208f1](https://github.com/szTheory/rulestead/commit/e7208f130f542b282c877830df9f56f01bef5507))
* **07-01:** add admin auth and redaction contracts ([ccce959](https://github.com/szTheory/rulestead/commit/ccce9592f7d96af0540d8ad96451d8dda567173b))
* **07-01:** implement admin kill switch audit flows ([c64ec8d](https://github.com/szTheory/rulestead/commit/c64ec8daf64cd5c81143df632cba3ccd2bc1e07b))
* **07-06:** add phase 7 credo checks ([64bbb7c](https://github.com/szTheory/rulestead/commit/64bbb7c80e7ba681b784e8f9327ea2d2e5549dc6))
* **07-07:** publish runtime and audit truth for admin writes ([4fa2bd1](https://github.com/szTheory/rulestead/commit/4fa2bd1c98e6c848f56209515710b351b4fcb854))
* **07-07:** seal admin authorization envelope ([981026e](https://github.com/szTheory/rulestead/commit/981026e3ad8ececba91f8e78d87324f7d5680a5d))
* **08-05:** add shared published release fixture harness ([6e6e0be](https://github.com/szTheory/rulestead/commit/6e6e0be7ca34fa96a83666a89349a8d23d3087e3))
* **08-05:** implement verification trio mix tasks ([f7848f3](https://github.com/szTheory/rulestead/commit/f7848f370a19cc7c29251f014664d9a5db2d0ef6))
* **09-01:** add governance domain contracts ([59a78a0](https://github.com/szTheory/rulestead/commit/59a78a035987d84ee782c2b81a3d34be21ad39c6))
* **09-01:** serialize governance approvals ([be2aa20](https://github.com/szTheory/rulestead/commit/be2aa204cbe1b323023272979c41ea15e36f4c86))
* **09-02:** add governance persistence and audit correlation ([2ef95a6](https://github.com/szTheory/rulestead/commit/2ef95a6db87477481b15cae00ace88fc39292d90))
* **09-02:** expand governance store command contracts ([1426b4f](https://github.com/szTheory/rulestead/commit/1426b4fc73df4327271aef0844a97cf5066998ee))
* **09-03:** add governance policy hooks to the host seam ([744662d](https://github.com/szTheory/rulestead/commit/744662d9296aa5aeb31ed436bfa4b7129dd23e16))
* **09-03:** resolve governance policy in the authorizer ([839d919](https://github.com/szTheory/rulestead/commit/839d9190df68b0f5648008771962f4116a195594))
* **09-04:** add governance facade verbs and auth entrypoints ([4d60dad](https://github.com/szTheory/rulestead/commit/4d60dada3af14a911ed2ca9ceb7093d609eba4d4))
* **09-04:** implement governance adapter parity ([e602844](https://github.com/szTheory/rulestead/commit/e602844da08dd2fd6dd84e1654e6408de0c203d4))
* **09-05:** enforce governance safety facade rules ([97a4998](https://github.com/szTheory/rulestead/commit/97a4998370b9125f38ef447d51e6db298983aff0))
* **10-01:** add durable scheduled execution contracts ([3fc950f](https://github.com/szTheory/rulestead/commit/3fc950f23408284fcf0e064a72c5e858dfa18319))
* **10-01:** extend schedule-first store contracts ([dc6ffd9](https://github.com/szTheory/rulestead/commit/dc6ffd9311a70ae2769f7c6d7d984ba880f66666))
* **10-02:** implement durable scheduled execution worker ([1f53c3f](https://github.com/szTheory/rulestead/commit/1f53c3f2eca4f2efe1e318650b5a75075df1497e))
* **10-03:** enforce bounded scheduled execution conflicts ([b18d947](https://github.com/szTheory/rulestead/commit/b18d94726f4daab38928f7ff2440f6fae92846a7))
* **10-03:** expose governed scheduling facade ([79623a1](https://github.com/szTheory/rulestead/commit/79623a121f1bceb75fec7de73736f12591f6731b))
* **10-04:** add phase 10 scheduling verifier ([f5e4088](https://github.com/szTheory/rulestead/commit/f5e408831efde50647301e3b9dbf2cb14cb4707a))
* **10-04:** add scheduled execution audit and telemetry ([3f1a83c](https://github.com/szTheory/rulestead/commit/3f1a83cb027bf821ba21c80a1b09f36d71e6411e))
* **11-02:** add governed review surfaces ([0c2b67c](https://github.com/szTheory/rulestead/commit/0c2b67caddd6b0ad0ee7bf8973bf01bab477de77))
* **11-04:** verify mounted governance admin flows ([1cfaab2](https://github.com/szTheory/rulestead/commit/1cfaab21e78840403d4332c32b671f1ca8982e37))
* **12-01:** add durable inbound webhook receipt contracts ([0678fcd](https://github.com/szTheory/rulestead/commit/0678fcd63ea7ba405911cb3481f9dfecf4f1d04f))
* **12-01:** add webhook ingress verification boundary ([159f83b](https://github.com/szTheory/rulestead/commit/159f83be85665e3ad8a2eaea88583734742681ff))
* **12-02:** add inbound webhook audit metadata ([1ffb5c7](https://github.com/szTheory/rulestead/commit/1ffb5c7b229727c71a424c2c9a149f9decc5b66c))
* **12-02:** normalize inbound webhook governance ([5c77edd](https://github.com/szTheory/rulestead/commit/5c77eddd2e690e78af2776f4824662ad5bdc0870))
* **12-06:** finalize webhook visibility and governance, update state ([10f0168](https://github.com/szTheory/rulestead/commit/10f016826de988c9fab9f23c7c4b20cf097f1263))


### Bug Fixes

* **07-08:** isolate phase 7 credo checks from runtime builds ([d2d4485](https://github.com/szTheory/rulestead/commit/d2d4485968d262cc909d139fc1b2d9f1a467353c))
* **09:** close governance review findings ([82d09c2](https://github.com/szTheory/rulestead/commit/82d09c2a344dd8ff60c5ab34593b8ed864c87ee2))
* **09:** restore governance adapter parity ([7f394a4](https://github.com/szTheory/rulestead/commit/7f394a4d7a9abd7e42cef9e982f13b02602014ed))
* **ci:** update release contract tests and fix credo warning ([c57df70](https://github.com/szTheory/rulestead/commit/c57df70b4626107d4adfe08d75f0fc9b4f426a7b))


### Miscellaneous Chores

* **ci:** unblock phase 1 bootstrap verification ([e5106d0](https://github.com/szTheory/rulestead/commit/e5106d0f0f2245f668f41d8ebc795b2a8d66ed17))
