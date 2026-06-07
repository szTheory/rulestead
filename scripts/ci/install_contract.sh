#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
RULESTEAD_DIR="${RULESTEAD_REPO}/rulestead"
RULESTEAD_ADMIN_DIR="${RULESTEAD_REPO}/rulestead_admin"
FIXTURE_ROOT="${RULESTEAD_DIR}/fixtures/install_golden"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rulestead-install-contract-XXXXXX")"
APP_DIR="${TMP_DIR}/host_app"
STDOUT_PATH="${TMP_DIR}/install.stdout"
RERUN_STDOUT_PATH="${TMP_DIR}/install-rerun.stdout"
NORM_STDOUT_PATH="${TMP_DIR}/install.stdout.normalized"
NORM_RERUN_STDOUT_PATH="${TMP_DIR}/install-rerun.stdout.normalized"
DB_BASENAME="rulestead_install_contract_$$"
DB_DEV="${DB_BASENAME}_dev"
DB_TEST="${DB_BASENAME}_test"
DB_USER="${PGUSER:-postgres}"

cleanup() {
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

ensure_phx_new() {
  if ! (cd "${RULESTEAD_DIR}" && mix help phx.new >/dev/null 2>&1); then
    (cd "${RULESTEAD_DIR}" && mix archive.install hex phx_new --force)
  fi
}

normalize_stdout_file() {
  local input_path="$1"
  local output_path="$2"

  python3 - "$input_path" "$output_path" <<'PY'
import pathlib
import re
import sys

src = pathlib.Path(sys.argv[1]).read_text()
src = src.replace("\r\n", "\n")
src = re.sub(r"\d{14}", "TIMESTAMP", src)
lines = []
for line in src.splitlines():
    if line.startswith(("copy ", "write ", "skip ")):
        lines.append(line)
pathlib.Path(sys.argv[2]).write_text(("\n".join(lines) + "\n") if lines else "")
PY
}

normalize_tree_file() {
  local input_path="$1"
  local output_path="$2"

  python3 - "$input_path" "$output_path" <<'PY'
import pathlib
import re
import sys

src = pathlib.Path(sys.argv[1]).read_text().replace("\r\n", "\n")
src = re.sub(r"\d{14}", "TIMESTAMP", src)
src = re.sub(r'signing_salt: "[^"]+"', 'signing_salt: "SIGNING_SALT"', src)
pathlib.Path(sys.argv[2]).write_text(src)
PY
}

compare_fixture_file() {
  local actual_path="$1"
  local fixture_path="$2"
  local normalized_path="${TMP_DIR}/$(basename "${actual_path}").normalized"

  normalize_tree_file "${actual_path}" "${normalized_path}"
  diff -u "${fixture_path}" "${normalized_path}"
}

configure_host_app() {
  python3 - "${APP_DIR}" "${RULESTEAD_DIR}" "${RULESTEAD_ADMIN_DIR}" "${DB_USER}" "${DB_DEV}" "${DB_TEST}" <<'PY'
import pathlib
import re
import sys

app_dir = pathlib.Path(sys.argv[1])
rulestead_dir = sys.argv[2]
rulestead_admin_dir = sys.argv[3]
db_user = sys.argv[4]
db_dev = sys.argv[5]
db_test = sys.argv[6]

mix_path = app_dir / "mix.exs"
mix_src = mix_path.read_text()
needle = "defp deps do\n    ["
replacement = (
    "defp deps do\n"
    "    [\n"
    f'      {{:rulestead, path: "{rulestead_dir}"}},\n'
    f'      {{:rulestead_admin, path: "{rulestead_admin_dir}"}},'
)
mix_path.write_text(mix_src.replace(needle, replacement, 1))

for name, db_name in [("dev.exs", db_dev), ("test.exs", db_test)]:
    path = app_dir / "config" / name
    src = path.read_text()
    src = re.sub(r'database: .+', f'database: "{db_name}",', src, count=1)
    src = re.sub(r'username: "[^"]+"', f'username: "{db_user}"', src)
    path.write_text(src)
PY
}

assert_contains() {
  local needle="$1"
  local haystack_path="$2"
  if ! grep -Fq -- "${needle}" "${haystack_path}"; then
    echo "missing expected content: ${needle} in ${haystack_path}" >&2
    exit 1
  fi
}

assert_all_skip_lines() {
  local normalized_path="$1"
  python3 - "$normalized_path" <<'PY'
import pathlib
import sys

lines = [line for line in pathlib.Path(sys.argv[1]).read_text().splitlines() if line]
if not lines or any(not line.startswith("skip ") for line in lines):
    raise SystemExit(1)
PY
}

run_probe() {
  local probe_output
  probe_output="$(
    cd "${APP_DIR}" && MIX_ENV=dev mix run -e '
      alias HostApp.Repo

      {:ok, _} = Application.ensure_all_started(:ecto_sql)

      case Repo.start_link() do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
      end

      {:ok, _} = Application.ensure_all_started(:host_app)

      {:ok, %{rows: table_rows}} =
        Ecto.Adapters.SQL.query(
          Repo,
          "select table_name from information_schema.tables where table_schema = '\''rulestead'\'' and table_name in ('\''flags'\'', '\''environments'\'', '\''flag_environments'\'', '\''rulesets'\'', '\''audit_events'\'') order by table_name",
          []
        )

      {:ok, %{rows: env_rows}} =
        Ecto.Adapters.SQL.query(Repo, "select key from rulestead.environments order by key", [])

      endpoint_source = File.read!("lib/host_app_web/endpoint.ex")
      router_source = File.read!("lib/host_app_web/router.ex")
      rulestead_config = File.read!("config/rulestead.exs")

      IO.puts("tables=" <> Enum.map_join(table_rows, ",", &hd/1))
      IO.puts("envs=" <> Enum.map_join(env_rows, ",", &hd/1))
      IO.puts("admin_mount=" <> to_string(String.contains?(router_source, ~s(rulestead_admin "/flags"))))
      IO.puts("plug_wired=" <> to_string(String.contains?(endpoint_source, "plug Rulestead.Plug")))
      IO.puts("oban_middleware=" <> to_string(String.contains?(rulestead_config, "Rulestead.Oban.Middleware")))
      IO.puts("app_started=true")
    '
  )"

  [[ "${probe_output}" == *"tables=audit_events,environments,flag_environments,flags,rulesets"* ]]
  [[ "${probe_output}" == *"envs=development,production,staging,test"* ]]
  [[ "${probe_output}" == *"admin_mount=true"* ]]
  [[ "${probe_output}" == *"plug_wired=true"* ]]
  [[ "${probe_output}" == *"oban_middleware=true"* ]]
  [[ "${probe_output}" == *"app_started=true"* ]]
}

ensure_phx_new

(
  cd "${TMP_DIR}"
  printf '\n' | MIX_ENV=dev mix phx.new host_app --no-interactive --no-version-check --database postgres --no-assets --no-dashboard --no-mailer --no-install
) | tee "${STDOUT_PATH}"

configure_host_app

(
  cd "${APP_DIR}"
  MIX_ENV=dev mix deps.get
  MIX_ENV=dev mix rulestead.install --yes --repo HostApp.Repo
) >> "${STDOUT_PATH}"

normalize_stdout_file "${STDOUT_PATH}" "${NORM_STDOUT_PATH}"
diff -u "${FIXTURE_ROOT}/STDOUT.txt" "${NORM_STDOUT_PATH}"

compare_fixture_file "${APP_DIR}/config/config.exs" "${FIXTURE_ROOT}/tree/config/config.exs"
compare_fixture_file "${APP_DIR}/config/rulestead.exs" "${FIXTURE_ROOT}/tree/config/rulestead.exs"
compare_fixture_file "${APP_DIR}/lib/host_app_web/endpoint.ex" "${FIXTURE_ROOT}/tree/lib/host_app_web/endpoint.ex"
compare_fixture_file "${APP_DIR}/lib/host_app_web/router.ex" "${FIXTURE_ROOT}/tree/lib/host_app_web/router.ex"
compare_fixture_file "${APP_DIR}/priv/repo/migrations/"*_create_rulestead_tables.exs "${FIXTURE_ROOT}/tree/priv/repo/migrations/TIMESTAMP_create_rulestead_tables.exs"

assert_contains 'import_config "rulestead.exs"' "${APP_DIR}/config/config.exs"
assert_contains 'plug Rulestead.Plug' "${APP_DIR}/lib/host_app_web/endpoint.ex"
assert_contains 'use RulesteadAdmin.Router' "${APP_DIR}/lib/host_app_web/router.ex"
assert_contains 'rulestead_admin "/flags"' "${APP_DIR}/lib/host_app_web/router.ex"
assert_contains 'middlewares: [{Rulestead.Oban.Middleware, []}]' "${APP_DIR}/config/rulestead.exs"

(
  cd "${APP_DIR}"
  MIX_ENV=dev mix ecto.drop --force -r HostApp.Repo || true
  MIX_ENV=dev mix ecto.create -r HostApp.Repo
  MIX_ENV=dev mix ecto.migrate -r HostApp.Repo
  MIX_ENV=dev mix rulestead.install --yes --repo HostApp.Repo
) > "${RERUN_STDOUT_PATH}"

normalize_stdout_file "${RERUN_STDOUT_PATH}" "${NORM_RERUN_STDOUT_PATH}"
assert_all_skip_lines "${NORM_RERUN_STDOUT_PATH}"

run_probe
