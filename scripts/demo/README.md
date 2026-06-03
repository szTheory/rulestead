# Demo scripts

Helpers for running the FleetDesk adoption-lab stack (Phoenix backend +
Next.js frontend + Postgres + Redis) locally via Docker Compose.

## Quick reference

| Command | What it does |
|---|---|
| `scripts/demo/up.sh` | Start the stack. Auto-selects free host ports, namespaces the Compose project per git branch, and prints the URLs. |
| `scripts/demo/down.sh` | Stop the stack for the current branch/project. Pass `--volumes` to also drop demo DB/Redis state. |
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

## Optional: one proxy for many demos (`*.localhost`)

If you routinely run several sibling demos at once and want stable hostnames
instead of remembering ports, a shared reverse proxy is an option — but it is
**not** wired up here, and it is deliberately not the default (it adds friction
for adopters who just want `docker compose up` + a browser). Treat the following
as a power-user recipe.

Shape: run one Traefik project that owns ports `:80`/`:443` and watches the
Docker socket; every demo joins a shared external network and routes by
hostname (`rulestead.localhost`, `cairnloop.localhost`, …) instead of publishing
host ports.

```bash
docker network create web        # once, shared across all demos
# proxy/compose.yaml runs traefik with restart: always, ports 80/443,
# and /var/run/docker.sock mounted read-only.
```

Each demo then drops its `ports:` blocks, joins `web` (`external: true`), and
adds `traefik.http.routers.*` labels pointing at the container port.

Honest caveats before you go down this road:

- **`*.localhost` resolves in browsers but not reliably in `curl`, `ping`, or
  Docker's internal DNS on macOS.** So the smoke/verify scripts (which `curl`
  the URLs) and any Next.js server-side rendering would break unless they keep
  using the Docker **service name** (`http://backend:4000`) rather than the
  public hostname. The current frontend split — `FLAGS_API_BASE` = service name
  for SSR, `NEXT_PUBLIC_FLAGS_API_BASE` = public host for the browser — is
  already the correct shape and must be preserved.
- **Phoenix/LiveView behind a proxy** needs `PHX_HOST` set to the routed host and
  that host added to `check_origin` (in `examples/demo/backend/config/`), or the
  LiveView WebSocket upgrade fails its origin check.
- Custom TLDs via `dnsmasq` + `/etc/resolver` are fragile on recent macOS;
  trusted local HTTPS needs `mkcert`.
- Postgres has no SNI, so a TCP proxy can't replace its port mapping — databases
  here stay internal anyway, so that's moot for this stack.

Because this spans every sibling lib (one proxy + one shared network they all
join), it belongs in a separate cross-repo setup, not in rulestead's demo.
