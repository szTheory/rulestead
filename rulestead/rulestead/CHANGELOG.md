# Changelog

## [0.1.1](https://github.com/szTheory/rulestead/compare/rulestead-v0.1.0...rulestead-v0.1.1) (2026-05-25)


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
* **admin:** complete phase 18 experimentation ui and reporting ([d222da0](https://github.com/szTheory/rulestead/commit/d222da0661bffeb3925350cb2349e3b916d54171))
* **admin:** implement canonical RBAC vocabulary and compatibility boundary ([d381dca](https://github.com/szTheory/rulestead/commit/d381dca03a8faa4889f6e38ccaa420ce9f9b1622))
* land v1.3.0 support-truth worktree ([935c9d5](https://github.com/szTheory/rulestead/commit/935c9d5fa3d8d915fa118007edb08cd2ccb2e4a9))
* **security:** align facade and command surfaces with canonical RBAC vocabulary ([f25c0c4](https://github.com/szTheory/rulestead/commit/f25c0c45f4ff489acbc18a554195b474cff602f4))
* **tenancy:** implement explicit tenancy seam and single-tenant default ([26ebe21](https://github.com/szTheory/rulestead/commit/26ebe217e2a54eddafae589bf9b7d483b58d1a6b))


### Bug Fixes

* **13:** resolve test regressions from phase 13 execution ([ef45db8](https://github.com/szTheory/rulestead/commit/ef45db8dc5c7e7dd8db400bd8d92c29f06754ecb))

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
