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

Run repo-level checks from the root when possible. As the package surface
lands, per-package commands should also work from each sibling directory.

Current Phase 1 baseline commands:

```bash
mix format
mix credo --strict
mix docs
```

When the package skeletons and CI aliases land later in the phase, the
maintainer path is expected to converge on a root `mix ci.all` style flow.

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
