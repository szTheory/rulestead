# Demo scripts

Helpers for running the FleetDesk adoption-lab stack (Phoenix backend +
Next.js frontend + Postgres + Redis) locally via Docker Compose.

## Quick reference

| Command | What it does |
|---|---|
| `scripts/demo/up.sh` | Start the stack. Auto-selects free host ports, namespaces the Compose project per git branch, and prints the URLs. |
| `scripts/demo/down.sh` | Stop the stack for the current branch/project. Pass `--volumes` to also drop demo DB/Redis state. |
| `scripts/demo/proxy-up.sh` | Start the stack behind Traefik at `.localhost` hostnames. Preferred for maintainers running several UI demos. |
| `scripts/demo/proxy-down.sh` | Stop the proxy-mode demo stack. Leaves shared Traefik running for other demos. |
| `scripts/demo/proxy-smoke.sh` | Build, start, and smoke-check the `.localhost` proxy path. |
| `scripts/demo/smoke.sh` | Build, start, wait for health, and run endpoint smoke checks. |
| `scripts/demo/proof.sh` | Bounded adopter proof (smoke + adopter verification). |
| `scripts/demo/verify.sh` | Full browser proof (smoke + Playwright e2e). |

`docker compose up --build` from the repo root also works and is the documented
adopter one-liner. It uses fixed ports (backend `4000`, frontend `3000`); use
`up.sh` instead when those are taken or when running other demos at the same
time.

## How port conflicts are avoided

`compose-env.sh::demo_prepare_compose_env` (sourced by every script above):

- Sets `COMPOSE_PROJECT_NAME` to `rulestead_demo_<user>_<branch>` so containers,
  networks, and volumes are isolated per branch.
- Picks free host ports — prefers `4000`/`3000`, falls back to an OS-assigned
  free port if those are busy.
- Wires `NEXT_PUBLIC_FLAGS_API_BASE` to the chosen backend port (the frontend
  bakes this at build time, so the host port and the API base must agree).

Postgres and Redis are never published to the host — they stay on the internal
Compose network, which removes the most common collision source.

To pin values by hand instead, copy `.env.example` to `.env` (Compose auto-loads
it) and set `DEMO_BACKEND_PORT` / `DEMO_FRONTEND_PORT` / `COMPOSE_PROJECT_NAME`.
If you change `DEMO_BACKEND_PORT`, change `NEXT_PUBLIC_FLAGS_API_BASE` to match.

## Stable hostnames with Traefik

Use proxy mode when you are running several sibling library demos and want one
memorable URL per app instead of tracking `3000`, `4000`, `4001`, and friends:

```bash
scripts/demo/proxy-up.sh
```

The script reuses an existing local Traefik proxy named `dev_proxy` on the
external Docker network `proxy` when it finds one. If that shared proxy is not
running, it creates the network and starts a loopback-only bundled proxy. The
normal result is no port in the browser URL:

- FleetDesk: `http://fleetdesk.rulestead.localhost`
- Rulestead admin: `http://rulestead.localhost/demo/sign-in`
- Rulestead API: `http://rulestead.localhost/api/flags`

Stop only this demo:

```bash
scripts/demo/proxy-down.sh
```

Stop this demo and the Traefik proxy only when you intentionally own the shared
proxy and no other local demo is using it:

```bash
DEMO_PROXY_DOWN_TRAEFIK=1 scripts/demo/proxy-down.sh
```

The proxy watches Docker labels through the Docker socket. That is acceptable
for a loopback-only local developer proxy, but it is not deployment guidance.
Traefik is configured with `exposedByDefault=false`, and only the demo frontend
and backend opt in with explicit labels.

If another unrelated process owns port `80`, `proxy-up.sh` falls back to a free
loopback port and includes that port in the printed URLs. That is a compatibility
fallback, not the preferred maintainer setup.

### Proxy knobs

| Variable | Default | Use |
|---|---|---|
| `DEMO_PROXY_NETWORK` | `proxy` | Shared external Docker network watched by local Traefik. |
| `DEMO_PROXY_PROJECT_NAME` | `dev_proxy` | Compose project name/container prefix for Traefik. |
| `DEMO_PROXY_HTTP_PORT` | `80` when available | Host port Traefik binds on `127.0.0.1`; fallback ports are printed. |
| `DEMO_HOST_SLUG` | `local` | Suffix for branch-specific hostnames. |
| `DEMO_BACKEND_HOST` | `rulestead.localhost` | Public Phoenix/admin/API host. |
| `DEMO_FRONTEND_HOST` | `fleetdesk.rulestead.localhost` | Public FleetDesk host. |

If you want to pin the proxy port by hand, set `DEMO_PROXY_HTTP_PORT=8088`.
The printed URLs include the port whenever the selected port is not `80`.
If you run two Rulestead checkouts at once, set `DEMO_HOST_SLUG` on one of them
so its hosts become branch-specific, for example
`rulestead-feature-x.localhost` and
`fleetdesk-feature-x.rulestead.localhost`.

### Caveats worth knowing

- Browsers understand `.localhost` well; some CLI tools do not. The proxy smoke
  script uses `curl --noproxy '*' --resolve ...` so it does not depend on host
  DNS behavior or a developer machine's HTTP proxy settings.
- The frontend keeps two API bases: browser calls use the public backend host,
  while server-side rendering uses the Docker service name.
- Phoenix allows `.rulestead.localhost` LiveView origins and excludes those
  local hosts from its production SSL redirect.
- Postgres and Redis remain internal-only; the proxy only routes HTTP services.
