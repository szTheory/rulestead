#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

cleanup() {
  if [ "${DEMO_PROXY_SMOKE_KEEP_STACK:-0}" = "1" ]; then
    return
  fi

  docker compose -f docker-compose.yml -f docker-compose.proxy.yml down --remove-orphans >/dev/null 2>&1 || true
}

dump_failure_logs() {
  echo "[proxy-smoke] dumping compose logs after failure" >&2
  docker compose -f docker-compose.yml -f docker-compose.proxy.yml ps >&2 || true
  docker compose -f docker-compose.yml -f docker-compose.proxy.yml logs --no-color backend frontend postgres redis >&2 || true
}

wait_for_health() {
  service="$1"
  attempts="${2:-60}"
  count=0

  while [ "$count" -lt "$attempts" ]; do
    container_id="$(docker compose -f docker-compose.yml -f docker-compose.proxy.yml ps -q "$service")"

    if [ -n "$container_id" ]; then
      health_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"

      if [ "$health_status" = "healthy" ] || [ "$health_status" = "running" ]; then
        return 0
      fi
    fi

    count=$((count + 1))
    sleep 2
  done

  echo "Timed out waiting for $service health" >&2
  return 1
}

retry_command() {
  attempts="$1"
  shift
  count=0

  while [ "$count" -lt "$attempts" ]; do
    if "$@"; then
      return 0
    fi

    count=$((count + 1))
    sleep 2
  done

  return 1
}

trap cleanup EXIT INT TERM

demo_prepare_proxy_env

echo "[proxy-smoke] building and starting proxy-mode demo stack"
demo_start_proxy
docker compose -f docker-compose.yml -f docker-compose.proxy.yml down --remove-orphans --volumes >/dev/null 2>&1 || true
docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d --build || {
  dump_failure_logs
  exit 1
}

wait_for_health postgres 30
wait_for_health redis 30
wait_for_health backend 60 || {
  dump_failure_logs
  exit 1
}
wait_for_health frontend 60 || {
  dump_failure_logs
  exit 1
}

demo_print_urls

cookie_jar="$(mktemp)"
trap 'rm -f "$cookie_jar"; cleanup' EXIT INT TERM

echo "[proxy-smoke] checking backend home"
BACKEND_HOST="$DEMO_BACKEND_HOST" BACKEND_URL="$DEMO_BACKEND_URL" PROXY_PORT="$DEMO_PROXY_HTTP_PORT" retry_command 15 sh -c '
  curl --noproxy "*" --resolve "$BACKEND_HOST:$PROXY_PORT:127.0.0.1" -fsS "$BACKEND_URL/" >/dev/null
' || {
  dump_failure_logs
  exit 1
}

echo "[proxy-smoke] checking seeded runtime bridge"
BACKEND_HOST="$DEMO_BACKEND_HOST" BACKEND_URL="$DEMO_BACKEND_URL" PROXY_PORT="$DEMO_PROXY_HTTP_PORT" retry_command 15 sh -c '
  bridge_payload="$(curl --noproxy "*" --resolve "$BACKEND_HOST:$PROXY_PORT:127.0.0.1" -fsS "$BACKEND_URL/api/flags?env=production&flag_key=enable-new-dashboard")" &&
    printf "%s\n" "$bridge_payload" | grep -q "\"enabled\":true"
' || {
  dump_failure_logs
  exit 1
}

echo "[proxy-smoke] checking deterministic admin sign-in"
COOKIE_JAR="$cookie_jar" BACKEND_HOST="$DEMO_BACKEND_HOST" BACKEND_URL="$DEMO_BACKEND_URL" PROXY_PORT="$DEMO_PROXY_HTTP_PORT" retry_command 15 sh -c '
  curl --noproxy "*" --resolve "$BACKEND_HOST:$PROXY_PORT:127.0.0.1" -fsS -c "$COOKIE_JAR" -b "$COOKIE_JAR" -L "$BACKEND_URL/demo/sign-in" |
    grep -q "Viewing environment"
' || {
  dump_failure_logs
  exit 1
}

echo "[proxy-smoke] checking frontend render"
FRONTEND_HOST="$DEMO_FRONTEND_HOST" FRONTEND_URL="$DEMO_FRONTEND_URL" PROXY_PORT="$DEMO_PROXY_HTTP_PORT" retry_command 15 sh -c '
  curl --noproxy "*" --resolve "$FRONTEND_HOST:$PROXY_PORT:127.0.0.1" -fsS "$FRONTEND_URL" | grep -q "FleetDesk" &&
    curl --noproxy "*" --resolve "$FRONTEND_HOST:$PROXY_PORT:127.0.0.1" -fsS "$FRONTEND_URL" | grep -q "View as"
' || {
  dump_failure_logs
  exit 1
}

echo "[proxy-smoke] proxy-mode demo stack is healthy"
