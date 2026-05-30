# Contributing

Thanks for contributing to Rulestead.

## Toolchain

The repository pins:

- Elixir `1.19.2-otp-28`
- Erlang/OTP `28.1.2`

Use `asdf install` if you rely on `.tool-versions`.

## Local services

Phase 1 includes a local Postgres bootstrap via `docker-compose.yml`:

```bash
docker compose up -d postgres
```

The service uses:

- user: `postgres`
- password: `postgres`
- database: `rulestead_dev`
- port: `5432`

## Working in the repo

This is a sibling-package monorepo:

- `rulestead/` is the core package
- `rulestead_admin/` is the optional admin package

### Local contributor gate

Before opening a PR, run:

```bash
cd rulestead && mix ci
bash scripts/ci/local.sh          # full monorepo mirror of merge CI
bash scripts/ci/local.sh --fast   # skip mounted/openfeature companion scopes
```

GitHub requires the aggregated `release_gate` check on merge. The local gate
catches the same failures earlier.

Maintainers preparing a release should also run:

```bash
bash scripts/maintainer/repo_hygiene_check.sh
```

See [`MAINTAINING.md`](MAINTAINING.md) for publish choreography and post-publish
verification.

### Formatting and docs

```bash
cd rulestead && mix format
cd rulestead && mix credo --strict
cd rulestead && mix docs
```

## Tests

Run tests from the root and from each package directory:

```bash
# repo root
mix test

# sibling packages
cd rulestead && mix test
cd ../rulestead_admin && mix test
```

If a change depends on Postgres-backed flows, start the local service from
`docker-compose.yml` first.

## Commits and pull requests

Use Conventional Commits for commit messages and PR titles:

- `feat(...)`
- `fix(...)`
- `docs(...)`
- `test(...)`
- `refactor(...)`
- `chore(...)`

PRs should stay narrow, explain the user-facing or operator-facing effect,
and call out any roadmap or requirement IDs that moved.

The project uses squash merge with linear history. The final PR title is
the commit that lands on `main`, so keep the title clean.

## Conduct

By participating in this project, you agree to the
[Code of Conduct](CODE_OF_CONDUCT.md).
