# syntax=docker/dockerfile:1
FROM elixir:1.19 AS app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl git postgresql-client redis-tools && \
    rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

WORKDIR /workspace

RUN mix local.hex --force && mix local.rebar --force

RUN mkdir -p rulestead rulestead_admin examples/demo/backend

# Dependency manifests + config only. These layers cache unless a lockfile or
# config changes, so editing application source never re-downloads hex deps.
COPY rulestead/mix.exs rulestead/mix.lock ./rulestead/
COPY rulestead_admin/mix.exs rulestead_admin/mix.lock ./rulestead_admin/
COPY examples/demo/backend/mix.exs examples/demo/backend/mix.lock ./examples/demo/backend/

WORKDIR /workspace/examples/demo/backend

# Cache mounts persist the hex/rebar download caches across builds, so a lockfile
# change re-uses already-downloaded tarballs instead of hitting the network.
# NOTE: do NOT cache-mount deps/ or _build/ — the container runs `mix phx.server`
# and `mix ecto.migrate` from them at runtime, so they must land in the image.
RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.cache/rebar3 \
    --mount=type=cache,target=/root/.mix \
    mix deps.get --only prod

COPY examples/demo/backend/config ./examples/demo/backend/config

RUN mix assets.setup

# Compile the external hex dependencies BEFORE any application source exists.
# rulestead / rulestead_admin are path deps with only their manifests present at
# this point, so this pass compiles the hex tree; its cache key is the lockfiles
# + config, never application source — so a `.ex` edit cannot recompile hex deps.
RUN mix deps.compile

WORKDIR /workspace

# Path-dep source. Editing these recompiles only the two local libs (next step),
# leaving the hex tree compiled above untouched.
COPY rulestead/lib ./rulestead/lib
COPY rulestead/priv/repo ./rulestead/priv/repo
COPY rulestead/priv/templates ./rulestead/priv/templates
COPY rulestead_admin/lib ./rulestead_admin/lib

WORKDIR /workspace/examples/demo/backend
RUN mix deps.compile rulestead rulestead_admin

# Application source last — edits here only re-run compile + asset deploy.
WORKDIR /workspace
COPY rulestead_admin/priv/static ./rulestead_admin/priv/static
COPY examples/demo/backend ./examples/demo/backend

WORKDIR /workspace/examples/demo/backend
RUN mix compile
RUN mix assets.deploy

RUN chmod +x entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["mix", "phx.server"]
