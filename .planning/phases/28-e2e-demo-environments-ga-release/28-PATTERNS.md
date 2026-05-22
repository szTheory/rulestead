# Phase 28: E2E Demo Environments & GA Release - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 10
**Analogs found:** 8 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docker-compose.yml` | config | request-response + streaming infra | `docker-compose.yml`, `guides/recipes/deployment.md` | strong |
| `README.md` | documentation | static | `README.md`, `guides/introduction/getting-started.md` | exact |
| `examples/demo/backend/mix.exs` | config | request-response | `rulestead_admin/mix.exs`, `open_feature_rulestead/mix.exs` | strong |
| `examples/demo/backend/lib/demo/application.ex` | application | event-driven + streaming | `rulestead/lib/rulestead/application.ex` | role-match |
| `examples/demo/backend/lib/demo_web/router.ex` | route | request-response | `rulestead_admin/lib/rulestead_admin/router.ex`, `rulestead_admin/test/support/conn_case.ex` | strong |
| `examples/demo/backend/lib/demo_web/controllers/flag_controller.ex` and API helpers | controller | request-response | `guides/introduction/getting-started.md`, `guides/flows/multi-env.md` | partial |
| `examples/demo/backend/priv/repo/seeds.exs` and boot/entrypoint scripts | utility | batch + file-I/O | `rulestead/lib/mix/tasks/rulestead.install.ex`, `guides/recipes/deployment.md` | role-match |
| `examples/demo/frontend/*` | component/app | request-response + streaming consumer | `open_feature_rulestead/mix.exs`, `README.md` package-boundary docs | partial |
| `examples/demo/backend/Dockerfile` and `examples/demo/frontend/Dockerfile` | config | file-I/O | `guides/recipes/deployment.md` | partial |
| Demo docs under `README.md` or `examples/demo/**/README.md` | documentation | static | `rulestead_admin/README.md`, `guides/introduction/installation.md` | strong |

## Pattern Assignments

### `docker-compose.yml` (config, request-response + streaming infra)

**Analogs:** `docker-compose.yml`, `guides/recipes/deployment.md`

**Minimal service shape** ([docker-compose.yml](/Users/jon/projects/rulestead/docker-compose.yml:1)):
```yaml
services:
  postgres:
    image: postgres:15
    container_name: rulestead-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: rulestead_dev
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d rulestead_dev"]
```

**Deployment posture to preserve** ([guides/recipes/deployment.md](/Users/jon/projects/rulestead/guides/recipes/deployment.md:13)):
```markdown
After adding the package and running `mix rulestead.install`, include the
generated migrations in your normal deploy flow:

```bash
mix ecto.migrate
```
```

**Infra responsibilities** ([guides/recipes/deployment.md](/Users/jon/projects/rulestead/guides/recipes/deployment.md:51)):
```markdown
- Postgres for authored state
- Phoenix.PubSub for snapshot fanout where configured
- Oban only if your app is using the documented Oban seam
```

**Apply to Phase 28**
- Keep the root compose file simple, explicit, and service-first; do not hide orchestration behind bespoke scripts.
- Preserve healthchecks and named infra dependencies for `postgres` and add the same explicitness for `redis`, backend, and frontend.
- Keep the demo infra aligned with shipped seams: Postgres for authored state, Redis/PubSub-backed runtime refresh, host app owns the HTTP bridge.

---

### `examples/demo/backend/mix.exs` (config, request-response)

**Analogs:** `rulestead_admin/mix.exs`, `open_feature_rulestead/mix.exs`

**Sibling path dependency pattern** ([rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:46)):
```elixir
  defp rulestead_dep do
    if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
      {:rulestead, "~> #{@version}"}
    else
      {:rulestead, path: "../rulestead"}
    end
  end
```

**Cross-package local integration pattern** ([open_feature_rulestead/mix.exs](/Users/jon/projects/rulestead/open_feature_rulestead/mix.exs:26)):
```elixir
  defp deps do
    [
      {:open_feature, "~> 0.1.3"},
      {:rulestead, path: "../rulestead"}
    ]
  end
```

**Apply to Phase 28**
- Keep the demo backend as a host app consuming public package seams through path deps; do not move code into `rulestead/` or `rulestead_admin/`.
- Mirror the repo’s linked-version posture by depending on sibling packages locally, not by reaching into internals or copying package source.
- If the demo needs OpenFeature on the backend, treat it as another package dependency beside `:rulestead`, not as a core-library change.

---

### `examples/demo/backend/lib/demo_web/router.ex` (route, request-response)

**Analogs:** `rulestead_admin/lib/rulestead_admin/router.ex`, `rulestead_admin/test/support/conn_case.ex`

**Mount the admin through the macro seam** ([rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:10)):
```elixir
  defmacro rulestead_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      policy = Keyword.fetch!(opts, :policy)
      live_session_name = Module.concat(policy, AdminSession)

      scope path, as: :rulestead_admin do
        live_session live_session_name,
          session: %{
            "policy" => policy,
            "mount_path" => path
          },
          on_mount: [{RulesteadAdmin.Live.Session, :default}] do
```

**Host router integration shape** ([rulestead_admin/test/support/conn_case.ex](/Users/jon/projects/rulestead/rulestead_admin/test/support/conn_case.ex:27)):
```elixir
defmodule RulesteadAdmin.TestRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  use RulesteadAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
  end

  scope "/" do
    pipe_through :browser

    rulestead_admin "/admin/flags", policy: RulesteadAdmin.TestPolicy
  end
end
```

**Apply to Phase 28**
- The demo backend should look like a normal host Phoenix app mounting `rulestead_admin`; that is the product story Phase 28 is proving.
- Add the custom `/api/flags` bridge beside the mounted admin routes, not inside `rulestead_admin`.
- Keep the route boundary explicit: browser pipeline for admin mount, separate API pipeline for frontend flag fetches.

---

### `examples/demo/backend/lib/demo_web/controllers/flag_controller.ex` and API helpers (controller, request-response)

**Analogs:** `guides/introduction/getting-started.md`, `guides/flows/multi-env.md`, `README.md`

**Evaluation entrypoint pattern** ([guides/introduction/getting-started.md](/Users/jon/projects/rulestead/guides/introduction/getting-started.md:29)):
```elixir
if Rulestead.enabled?("checkout_v2", conn) do
  render_v2(conn)
else
  render_v1(conn)
end
```

**Typed value / variant access pattern** ([guides/introduction/getting-started.md](/Users/jon/projects/rulestead/guides/introduction/getting-started.md:42)):
```elixir
variant = Rulestead.get_variant("pricing_experiment", conn)
config = Rulestead.get_value("checkout_config", conn, default: %{"timeout_ms" => 1_000})
```

**Environment-explicit runtime contract** ([guides/flows/multi-env.md](/Users/jon/projects/rulestead/guides/flows/multi-env.md:55)):
```markdown
- `Rulestead.Runtime.evaluate(environment_key, flag_key, context)`
- `Rulestead.Runtime.enabled?(environment_key, flag_key, context)`
- `Rulestead.Runtime.get_value(environment_key, flag_key, context, default)`
- `Rulestead.Runtime.get_variant(environment_key, flag_key, context)`
- `Rulestead.Runtime.explain(environment_key, flag_key, context)`
```

**Apply to Phase 28**
- Keep the bridge endpoint thin and host-owned: parse request context, choose environment explicitly, delegate to public Rulestead runtime APIs, return JSON.
- Preserve the environment-explicit model in the HTTP API instead of inventing hidden environment defaults for the frontend.
- Demonstrate booleans, variants, or typed config through public APIs only; do not query storage tables directly from the controller.

---

### `examples/demo/backend/priv/repo/seeds.exs` and container boot scripts (utility, batch + file-I/O)

**Analogs:** `rulestead/lib/mix/tasks/rulestead.install.ex`, `guides/introduction/installation.md`, `guides/recipes/deployment.md`

**Boot task style** ([rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:12)):
```elixir
  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

    case Install.run(opts) do
      {:ok, messages} ->
        shell = Mix.shell()
        Enum.each(messages, fn message -> shell.info(message) end)
```

**Install + migrate sequence** ([guides/introduction/installation.md](/Users/jon/projects/rulestead/guides/introduction/installation.md:37)):
```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

**Safe release order** ([guides/recipes/deployment.md](/Users/jon/projects/rulestead/guides/recipes/deployment.md:69)):
```markdown
1. migrate the database
2. deploy the application release
3. verify runtime refresh and evaluation behavior
4. then publish or mutate new rulesets if needed
```

**Apply to Phase 28**
- Keep container startup deterministic and linear: install/setup already baked into the app image, then migrate, seed, boot.
- Seed through public admin/runtime seams where possible so the demo proves the product’s supported host contract instead of private storage shortcuts.
- Emit clear shell output and fail fast on migration/seed errors; do not background setup steps.

---

### `examples/demo/backend/lib/demo/application.ex` and streaming setup (application, event-driven + streaming)

**Analogs:** `rulestead/lib/rulestead/application.ex`, `rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex`

**Optional Redis child pattern** ([rulestead/lib/rulestead/application.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/application.ex:12)):
```elixir
  def start(_type, _args) do
    children =
      redis_children() ++
        [
          StaleTracker,
          Rulestead.Analytics.Batcher,
          {RuntimeSupervisor, Config.runtime_options()}
        ]
```

**Runtime notifier pattern** ([rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex:8)):
```elixir
  @impl true
  def broadcast(notice, opts) do
    case Keyword.get(opts, :pubsub) do
      nil ->
        :ok

      pubsub ->
        if Code.ensure_loaded?(Phoenix.PubSub) do
          Phoenix.PubSub.broadcast(pubsub, Keyword.fetch!(opts, :pubsub_topic), {@event, notice})
          :ok
```

**Apply to Phase 28**
- The demo backend should model streaming as normal Phoenix/PubSub host infrastructure around Rulestead, not as a new core transport abstraction.
- Keep Redis/PubSub optionality and wiring explicit in config and supervision, matching the runtime package’s posture.
- If the frontend receives live updates through the backend, have the host app subscribe/broadcast on top of existing notifier behavior rather than modifying Rulestead internals.

---

### Admin host session and environment contract inside the demo backend (middleware/session, request-response)

**Analogs:** `rulestead_admin/README.md`, `rulestead_admin/lib/rulestead_admin/live/session.ex`

**Host session keys** ([rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:40)):
```markdown
- `"current_actor"` for policy checks
- `"rulestead_admin_environments"` as the environment picker source
- `"rulestead_admin_last_env"` as the remembered fallback when the URL omits `env`
```

**Environment resolution order** ([rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:40)):
```elixir
    {environment, env_source} =
      cond do
        selected = find_environment(environments, url_env) ->
          {selected, :url}

        present?(url_env) ->
          {default_environment(environments), :default}

        selected = find_environment(environments, remembered_env) ->
          {selected, :remembered}
```

**Canonical URL builder** ([rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:74)):
```elixir
  def current_path(socket_or_assigns, base_path, params \\ %{})
      when is_binary(base_path) and is_map(params) do
    env_key =
      socket_or_assigns
      |> fetch_assign(:current_environment, %{})
      |> Map.get(:key, "dev")

    params
    |> Map.put("env", env_key)
```

**Apply to Phase 28**
- The demo backend should seed and expose `staging`/`prod` in the same host session shape the mounted package already expects.
- Preserve `?env=` as the canonical operator selector in demo docs and links.
- Do not invent a demo-only admin mount contract.

---

### `README.md` and demo docs (documentation, static)

**Analogs:** `README.md`, `guides/introduction/installation.md`, `rulestead_admin/README.md`

**Front-door split by package boundary** ([README.md](/Users/jon/projects/rulestead/README.md:7)):
```markdown
Rulestead ships as two sibling Hex packages:

- `rulestead` for the runtime evaluator, installer, context builders, and test helpers
- `rulestead_admin` for the optional host-mounted admin UI
```

**Quickstart command style** ([README.md](/Users/jon/projects/rulestead/README.md:43)):
```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

**Mounted-package framing** ([rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:3)):
```markdown
`rulestead_admin` is the optional mounted admin package for Rulestead.

This README documents the host-facing contract only. Internal LiveView modules,
socket assigns, CSS/DOM structure, and other implementation details are not
part of the public package promise.
```

**Apply to Phase 28**
- Update root docs with the same concise quickstart posture: one command, explicit package roles, and links to deeper docs.
- Describe the demo as a host-app example proving public seams, not as a third package or standalone control plane.
- Keep docs honest about what is product contract versus demo-only glue.

---

### `examples/demo/frontend/*` (app, request-response + streaming consumer)

**Analogs:** `open_feature_rulestead/mix.exs`, `README.md`, `.planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md`

**Existing cross-package integration hint** ([open_feature_rulestead/mix.exs](/Users/jon/projects/rulestead/open_feature_rulestead/mix.exs:26)):
```elixir
  defp deps do
    [
      {:open_feature, "~> 0.1.3"},
      {:rulestead, path: "../rulestead"}
    ]
  end
```

**Locked host-bridge decision** ([28-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md:12)):
```markdown
- **D-03: Bridging API:** The Phoenix demo backend will embed Rulestead and expose a custom `/api/flags` endpoint. The Next.js frontend will communicate with this endpoint via a standard HTTP client or an OpenFeature Web Provider, proving that Rulestead easily backs external frontends through a host's own API.
```

**Apply to Phase 28**
- Treat the frontend as a consumer of the host API, not as a peer talking to Redis/Postgres or to Rulestead internals.
- Mirror the repo’s existing OpenFeature posture conceptually: the integration layer sits at the boundary, while Rulestead remains embedded in the host.
- Keep frontend code thin, demonstrative, and disposable; the durable contract is the backend bridge and the product docs.

## Shared Patterns

### Preserve the sibling-package release shape
**Sources:** [README.md](/Users/jon/projects/rulestead/README.md:9), [guides/introduction/installation.md](/Users/jon/projects/rulestead/guides/introduction/installation.md:3), [rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:46)

- Phase 28 should prove how a host app consumes `rulestead` and `rulestead_admin`; it should not blur those package boundaries.
- Demo code belongs under `examples/demo/`, with path deps back to sibling packages.

### Host owns the admin mount seam
**Sources:** [rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:13), [rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:10), [guides/flows/extending-rulestead.md](/Users/jon/projects/rulestead/guides/flows/extending-rulestead.md:91)

- Mount through `rulestead_admin "/admin/flags", policy: ...`.
- Keep the demo’s auth/session/environment wiring in the host app.
- Do not couple the demo to internal `RulesteadAdmin.Live.*` modules.

### Environment must stay explicit
**Sources:** [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:40), [guides/flows/multi-env.md](/Users/jon/projects/rulestead/guides/flows/multi-env.md:7)

- Preserve `?env=` in admin URLs.
- Make environment explicit in the backend `/api/flags` bridge and in frontend requests.
- Seed and surface `staging` and `prod` as first-class demo environments.

### Compose/demo boot should follow install -> migrate -> run
**Sources:** [guides/introduction/installation.md](/Users/jon/projects/rulestead/guides/introduction/installation.md:37), [guides/recipes/deployment.md](/Users/jon/projects/rulestead/guides/recipes/deployment.md:69), [rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:12)

- Keep the backend container boot path linear and observable.
- Auto-seeding is acceptable for the demo because it is a host-app concern, but it should not mutate core package code.

### Streaming should be shown through host infrastructure, not new core abstractions
**Sources:** [rulestead/lib/rulestead/application.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/application.ex:12), [rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex:8)

- Use Redis/PubSub-backed host wiring to demonstrate refresh propagation.
- Do not propose OFREP in-core or any new standalone Rulestead service in this phase.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/demo/frontend/app/**/*` | component/app | request-response + streaming | The repo has no existing Next.js or JS frontend. Follow Phase 28’s locked host-API decision and keep the frontend thin. |
| `examples/demo/frontend/package.json` and frontend build config | config | build/runtime | No JavaScript package manifests exist in the repo. Use repo-native boundary/docs patterns, but implementation details will be new. |

## Minimal Planner Notes

- Keep Phase 28 split along existing repo responsibilities: root compose/docs, host Phoenix backend, then thin external frontend.
- Prefer proving public seams over inventing reusable abstractions. The strongest repo-native pattern is “host app integrates the packages,” not “Rulestead becomes a platform service.”
- Any fixes inside `rulestead/` or `rulestead_admin/` should be bug-fix exceptions discovered by demo creation, not planned scope.

## Metadata

**Analog search scope:** `README.md`, `docker-compose.yml`, `rulestead*/mix.exs`, `rulestead_admin/lib/**/*.ex`, `rulestead_admin/test/support/*.ex`, `guides/**/*.md`, `.planning/phases/27-*`
**Files scanned:** 18 primary files plus roadmap/context artifacts
**Pattern extraction date:** 2026-05-20
