FROM elixir:1.19 AS app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl git postgresql-client redis-tools && \
    rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

WORKDIR /workspace

RUN mix local.hex --force && mix local.rebar --force

COPY rulestead ./rulestead
COPY rulestead_admin ./rulestead_admin
COPY examples/demo/backend ./examples/demo/backend

WORKDIR /workspace/examples/demo/backend

RUN mix deps.get --only prod
RUN mix deps.compile
RUN mix assets.setup
RUN mix compile
RUN mix assets.deploy

RUN chmod +x entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["mix", "phx.server"]
