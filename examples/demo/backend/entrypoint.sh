#!/bin/sh
set -eu

POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-rulestead_demo_dev}"
REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"
RULESTEAD_MIGRATIONS_PATH="${RULESTEAD_MIGRATIONS_PATH:-../../../rulestead/priv/repo/migrations}"

echo "[demo-backend] waiting for postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}"
until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 1
done

echo "[demo-backend] waiting for redis at ${REDIS_HOST}:${REDIS_PORT}"
until redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping >/dev/null 2>&1; do
  sleep 1
done

echo "[demo-backend] running migrations"
mix ecto.migrate --migrations-path "$RULESTEAD_MIGRATIONS_PATH"

echo "[demo-backend] seeding demo data"
mix run priv/repo/seeds.exs

if [ -n "${RULESTEAD_REDIS_URL:-}" ]; then
  echo "[demo-backend] syncing runtime snapshots to redis"
  mix rulestead.redis.sync
fi

echo "[demo-backend] starting application"
exec "$@"
