#!/bin/sh
set -eu

POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-rulestead_demo_dev}"
REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo "[demo-backend] waiting for postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}"
until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 1
done

echo "[demo-backend] waiting for redis at ${REDIS_HOST}:${REDIS_PORT}"
until redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping >/dev/null 2>&1; do
  sleep 1
done

echo "[demo-backend] running ecto.setup"
mix ecto.setup

echo "[demo-backend] starting application"
exec "$@"
