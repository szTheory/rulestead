#!/bin/sh

demo_sanitize_name() {
  printf "%s" "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9_-]/_/g; s/__*/_/g; s/^_//; s/_$//'
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

demo_prepare_compose_env() {
  backend_port_was_set=0
  frontend_port_was_set=0

  if [ -z "${COMPOSE_PROJECT_NAME:-}" ]; then
    COMPOSE_PROJECT_NAME="$(demo_default_project_name)"
    export COMPOSE_PROJECT_NAME
  fi

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
}
