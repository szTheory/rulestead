#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

. scripts/demo/compose-env.sh

cleanup() {
  if [ "${DEMO_SMOKE_KEEP_STACK:-0}" = "1" ]; then
    return
  fi

  docker compose down --remove-orphans >/dev/null 2>&1 || true
}

dump_failure_logs() {
  echo "[smoke] dumping compose logs after failure" >&2
  docker compose ps >&2 || true
  docker compose logs --no-color backend frontend postgres redis >&2 || true
}

trap cleanup EXIT INT TERM

wait_for_health() {
  service="$1"
  attempts="${2:-60}"
  count=0

  while [ "$count" -lt "$attempts" ]; do
    container_id="$(docker compose ps -q "$service")"

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

echo "[smoke] building and starting demo stack"
demo_prepare_compose_env
docker compose down --remove-orphans --volumes >/dev/null 2>&1 || true
docker compose up -d --build || {
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

demo_export_urls_from_compose
demo_print_urls

cookie_jar="$(mktemp)"
trap 'rm -f "$cookie_jar"; cleanup' EXIT INT TERM

echo "[smoke] checking backend home"
BACKEND_URL="$DEMO_BACKEND_URL" retry_command 15 sh -c 'curl -fsS "$BACKEND_URL/" >/dev/null' || {
  dump_failure_logs
  exit 1
}

echo "[smoke] checking seeded runtime bridge"
BACKEND_URL="$DEMO_BACKEND_URL" retry_command 15 sh -c '
  bridge_payload="$(curl -fsS "$BACKEND_URL/api/flags?env=production&flag_key=enable-new-dashboard")" &&
    printf "%s\n" "$bridge_payload" | grep -q "\"enabled\":true"
' || {
  dump_failure_logs
  exit 1
}

echo "[smoke] checking deterministic admin sign-in"
COOKIE_JAR="$cookie_jar" BACKEND_URL="$DEMO_BACKEND_URL" retry_command 15 sh -c '
  curl -fsS -c "$COOKIE_JAR" -b "$COOKIE_JAR" -L "$BACKEND_URL/demo/sign-in" |
    grep -q "Flag inventory"
' || {
  dump_failure_logs
  exit 1
}

echo "[smoke] checking frontend render"
FRONTEND_URL="$DEMO_FRONTEND_URL" retry_command 15 sh -c '
  curl -fsS "$FRONTEND_URL" | grep -q "FleetDesk" &&
    curl -fsS "$FRONTEND_URL" | grep -q "View as"
' || {
  dump_failure_logs
  exit 1
}

echo "[smoke] demo stack is healthy"
