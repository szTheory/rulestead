FROM elixir:1.19 AS app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl git postgresql-client redis-tools && \
    rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

WORKDIR /workspace

RUN mix local.hex --force && mix local.rebar --force

RUN mkdir -p rulestead rulestead_admin examples/demo/backend

COPY rulestead/mix.exs rulestead/mix.lock ./rulestead/
COPY rulestead_admin/mix.exs rulestead_admin/mix.lock ./rulestead_admin/
COPY examples/demo/backend/mix.exs examples/demo/backend/mix.lock ./examples/demo/backend/
COPY examples/demo/backend/config ./examples/demo/backend/config

WORKDIR /workspace/examples/demo/backend

RUN mix deps.get --only prod
RUN mix assets.setup

WORKDIR /workspace

COPY rulestead ./rulestead
COPY rulestead_admin ./rulestead_admin
COPY examples/demo/backend ./examples/demo/backend

WORKDIR /workspace/examples/demo/backend

RUN mix deps.compile
RUN mix compile
RUN mix assets.deploy

RUN chmod +x entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["mix", "phx.server"]
