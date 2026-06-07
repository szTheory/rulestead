#!/bin/sh

demo_sanitize_name() {
  printf "%s" "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9_-]/_/g; s/__*/_/g; s/^_//; s/_$//'
}

demo_sanitize_dns_label() {
  label="$(printf "%s" "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"

  if [ -n "$label" ]; then
    printf "%.63s" "$label" | sed 's/-$//'
  fi
}

demo_default_project_name() {
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf "local")"
  user="${USER:-dev}"
  name="$(demo_sanitize_name "rulestead_demo_${user}_${branch}")"

  if [ -n "$name" ]; then
    printf "%s" "$name"
  else
    printf "rulestead_demo_local"
  fi
}

demo_default_host_slug() {
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf "local")"
  slug="$(demo_sanitize_dns_label "$branch")"

  case "$slug" in
    "" | main | master)
      printf "local"
      ;;
    *)
      printf "%s" "$slug"
      ;;
  esac
}

demo_port_is_free() {
  port="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.bind(("127.0.0.1", port))
    except OSError:
        sys.exit(1)
PY
    return $?
  fi

  if command -v lsof >/dev/null 2>&1; then
    ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi

  return 0
}

demo_find_free_port() {
  preferred="$1"

  if [ -n "$preferred" ] && demo_port_is_free "$preferred"; then
    printf "%s" "$preferred"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 <<'PY'
import socket

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
    return 0
  fi

  port="$preferred"
  while [ "$port" -lt 65535 ]; do
    port=$((port + 1))
    if demo_port_is_free "$port"; then
      printf "%s" "$port"
      return 0
    fi
  done

  echo "Unable to find a free localhost port" >&2
  return 1
}

demo_running_proxy_container() {
  for candidate in "${DEMO_PROXY_PROJECT_NAME}-traefik-1" "${DEMO_PROXY_PROJECT_NAME}_traefik_1"; do
    if docker inspect "$candidate" >/dev/null 2>&1 &&
      [ "$(docker inspect --format '{{.State.Running}}' "$candidate" 2>/dev/null || printf "false")" = "true" ]; then
      printf "%s" "$candidate"
      return 0
    fi
  done

  return 1
}

demo_proxy_container_on_network() {
  container="$1"

  docker inspect "$container" \
    --format '{{range $name, $_ := .NetworkSettings.Networks}}{{println $name}}{{end}}' 2>/dev/null |
    grep -Fx "$DEMO_PROXY_NETWORK" >/dev/null
}

demo_proxy_container_publishes_80() {
  container="$1"

  [ "$(demo_proxy_container_http_port "$container")" = "80" ]
}

demo_proxy_container_http_port() {
  container="$1"

  docker port "$container" 80/tcp 2>/dev/null |
    sed 's/.*://' |
    head -n 1
}

demo_shared_proxy_container() {
  container="$(demo_running_proxy_container || true)"

  if [ -z "$container" ]; then
    return 1
  fi

  if demo_proxy_container_on_network "$container" &&
    demo_proxy_container_publishes_80 "$container"; then
    printf "%s" "$container"
    return 0
  fi

  return 1
}

demo_existing_proxy_port() {
  container="$(demo_running_proxy_container || true)"

  if [ -z "$container" ]; then
    return 1
  fi

  if ! demo_proxy_container_on_network "$container"; then
    return 1
  fi

  port="$(demo_proxy_container_http_port "$container")"

  if [ -z "$port" ]; then
    return 1
  fi

  printf "%s" "$port"
}

demo_resolve_proxy_port() {
  if [ -n "${DEMO_PROXY_HTTP_PORT:-}" ]; then
    export DEMO_PROXY_HTTP_PORT
    return 0
  fi

  if port="$(demo_existing_proxy_port)"; then
    DEMO_PROXY_HTTP_PORT="$port"

    if [ "$port" = "80" ]; then
      DEMO_PROXY_MODE="shared"
    else
      DEMO_PROXY_MODE="fallback-existing"
    fi
  elif demo_port_is_free 80; then
    DEMO_PROXY_HTTP_PORT="80"
    DEMO_PROXY_MODE="bundled"
  else
    DEMO_PROXY_HTTP_PORT="$(demo_find_free_port 80)"
    DEMO_PROXY_MODE="fallback-port"
  fi

  export DEMO_PROXY_HTTP_PORT
  export DEMO_PROXY_MODE
}

demo_compose_port_url() {
  service="$1"
  private_port="$2"
  fallback_port="$3"

  published="$(docker compose port "$service" "$private_port" 2>/dev/null | tail -n 1 || true)"

  if [ -n "$published" ]; then
    host="${published%:*}"
    port="${published##*:}"

    case "$host" in
      0.0.0.0 | "::" | "[::]" | 127.0.0.1)
        host="127.0.0.1"
        ;;
      localhost)
        host="localhost"
        ;;
      *)
        host="127.0.0.1"
        ;;
    esac

    printf "http://%s:%s" "$host" "$port"
  else
    printf "http://127.0.0.1:%s" "$fallback_port"
  fi
}

demo_prepare_project_env() {
  if [ -z "${COMPOSE_PROJECT_NAME:-}" ]; then
    COMPOSE_PROJECT_NAME="$(demo_default_project_name)"
    export COMPOSE_PROJECT_NAME
  fi
}

demo_prepare_compose_env() {
  backend_port_was_set=0
  frontend_port_was_set=0

  demo_prepare_project_env

  if [ -n "${DEMO_BACKEND_PORT:-}" ]; then
    backend_port_was_set=1
  else
    DEMO_BACKEND_PORT="$(demo_find_free_port 4000)"
    export DEMO_BACKEND_PORT
  fi

  if [ -n "${DEMO_FRONTEND_PORT:-}" ]; then
    frontend_port_was_set=1
  else
    DEMO_FRONTEND_PORT="$(demo_find_free_port 3000)"
    export DEMO_FRONTEND_PORT
  fi

  if [ "$DEMO_BACKEND_PORT" = "$DEMO_FRONTEND_PORT" ]; then
    if [ "$backend_port_was_set" = "1" ] && [ "$frontend_port_was_set" = "1" ]; then
      echo "DEMO_BACKEND_PORT and DEMO_FRONTEND_PORT must be different" >&2
      return 1
    fi

    DEMO_FRONTEND_PORT="$(demo_find_free_port "$((DEMO_BACKEND_PORT + 1))")"
    export DEMO_FRONTEND_PORT
  fi

  if [ -z "${NEXT_PUBLIC_FLAGS_API_BASE:-}" ]; then
    NEXT_PUBLIC_FLAGS_API_BASE="http://localhost:${DEMO_BACKEND_PORT}"
    export NEXT_PUBLIC_FLAGS_API_BASE
  fi
}

demo_proxy_url() {
  host="$1"
  port="${DEMO_PROXY_HTTP_PORT:-80}"

  if [ "$port" = "80" ]; then
    printf "http://%s" "$host"
  else
    printf "http://%s:%s" "$host" "$port"
  fi
}

demo_prepare_proxy_env() {
  demo_prepare_project_env

  if [ -z "${DEMO_PROXY_NETWORK:-}" ]; then
    DEMO_PROXY_NETWORK="proxy"
    export DEMO_PROXY_NETWORK
  fi

  if [ -z "${DEMO_PROXY_PROJECT_NAME:-}" ]; then
    DEMO_PROXY_PROJECT_NAME="dev_proxy"
    export DEMO_PROXY_PROJECT_NAME
  fi

  demo_resolve_proxy_port

  if [ -z "${DEMO_HOST_SLUG:-}" ]; then
    DEMO_HOST_SLUG="local"
    export DEMO_HOST_SLUG
  fi

  if [ -z "${DEMO_BACKEND_HOST:-}" ]; then
    if [ "$DEMO_HOST_SLUG" = "local" ]; then
      DEMO_BACKEND_HOST="rulestead.localhost"
    else
      DEMO_BACKEND_HOST="rulestead-${DEMO_HOST_SLUG}.localhost"
    fi

    export DEMO_BACKEND_HOST
  fi

  if [ -z "${DEMO_FRONTEND_HOST:-}" ]; then
    if [ "$DEMO_HOST_SLUG" = "local" ]; then
      DEMO_FRONTEND_HOST="fleetdesk.rulestead.localhost"
    else
      DEMO_FRONTEND_HOST="fleetdesk-${DEMO_HOST_SLUG}.rulestead.localhost"
    fi

    export DEMO_FRONTEND_HOST
  fi

  DEMO_BACKEND_URL="$(demo_proxy_url "$DEMO_BACKEND_HOST")"
  DEMO_FRONTEND_URL="$(demo_proxy_url "$DEMO_FRONTEND_HOST")"
  export DEMO_BACKEND_URL
  export DEMO_FRONTEND_URL

  if [ -z "${NEXT_PUBLIC_FLAGS_API_BASE:-}" ]; then
    NEXT_PUBLIC_FLAGS_API_BASE="$DEMO_BACKEND_URL"
    export NEXT_PUBLIC_FLAGS_API_BASE
  fi

  if [ -z "${DEMO_CORS_ORIGINS:-}" ]; then
    DEMO_CORS_ORIGINS="$DEMO_FRONTEND_URL"
    export DEMO_CORS_ORIGINS
  fi

  if [ -z "${DEMO_CHECK_ORIGINS:-}" ]; then
    DEMO_CHECK_ORIGINS="//${DEMO_BACKEND_HOST},//*.rulestead.localhost"
    export DEMO_CHECK_ORIGINS
  fi
}

demo_export_urls_from_compose() {
  DEMO_BACKEND_URL="$(demo_compose_port_url backend 4000 "$DEMO_BACKEND_PORT")"
  DEMO_FRONTEND_URL="$(demo_compose_port_url frontend 3000 "$DEMO_FRONTEND_PORT")"
  export DEMO_BACKEND_URL
  export DEMO_FRONTEND_URL
}

demo_print_urls() {
  echo "[demo] Compose project: ${COMPOSE_PROJECT_NAME}"
  echo "[demo] Frontend: ${DEMO_FRONTEND_URL}"
  echo "[demo] Backend: ${DEMO_BACKEND_URL}"
  echo "[demo] Admin sign-in: ${DEMO_BACKEND_URL}/demo/sign-in"
  echo "[demo] API flags: ${DEMO_BACKEND_URL}/api/flags"
}

demo_ensure_proxy_network() {
  if docker network inspect "$DEMO_PROXY_NETWORK" >/dev/null 2>&1; then
    return 0
  fi

  echo "[demo] creating proxy network ${DEMO_PROXY_NETWORK}"
  docker network create "$DEMO_PROXY_NETWORK" >/dev/null
}

demo_start_proxy() {
  demo_ensure_proxy_network

  if [ "${DEMO_PROXY_HTTP_PORT:-80}" = "80" ]; then
    if container="$(demo_shared_proxy_container)"; then
      echo "[demo] using existing shared Traefik proxy ${container} on ${DEMO_PROXY_NETWORK}"
      return 0
    fi

    echo "[demo] starting shared Traefik proxy ${DEMO_PROXY_PROJECT_NAME} on 127.0.0.1:80"
  else
    if container="$(demo_running_proxy_container)"; then
      if demo_proxy_container_on_network "$container" &&
        [ "$(demo_proxy_container_http_port "$container")" = "$DEMO_PROXY_HTTP_PORT" ]; then
        echo "[demo] using existing Traefik proxy ${container} on 127.0.0.1:${DEMO_PROXY_HTTP_PORT}"
        return 0
      fi

      echo "[demo] found running proxy container ${container} for project ${DEMO_PROXY_PROJECT_NAME}" >&2
      echo "[demo] set DEMO_PROXY_PROJECT_NAME to a different value before starting a fallback proxy" >&2
      return 1
    fi

    echo "[demo] port 80 is occupied by another service; starting ${DEMO_PROXY_PROJECT_NAME} on 127.0.0.1:${DEMO_PROXY_HTTP_PORT}"
  fi

  docker compose \
    -p "$DEMO_PROXY_PROJECT_NAME" \
    -f scripts/demo/traefik-compose.yml \
    up -d
}

demo_proxy_curl() {
  host="$1"
  shift

  curl --noproxy "*" --resolve "${host}:${DEMO_PROXY_HTTP_PORT}:127.0.0.1" "$@"
}
