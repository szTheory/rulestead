# Phase 43: Mounted Contract & Verification Closure - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead_admin/README.md` | public contract doc | host integration | `guides/flows/admin-ui.md` | role-match |
| `guides/flows/admin-ui.md` | workflow doc | operator contract | `guides/flows/flag-lifecycle.md` | exact |
| `guides/flows/flag-lifecycle.md` | shared lifecycle doc | operator narrative | `guides/flows/admin-ui.md` | exact |
| `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` | integration test | public mounted seam | `rulestead_admin/test/rulestead_admin/router_test.exs` | role-match |
| `rulestead_admin/test/rulestead_admin/live/flag_live/form_test.exs` | LiveView contract test | manual authored payload | current file | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | LiveView queue test | seeded lifecycle state -> route-backed queue UI | `cleanup_test.exs` | role-match |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` | LiveView read-surface test | seeded lifecycle state -> advisory review UI | `cleanup_preview_test.exs` | role-match |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` | LiveView mutation-preview test | seeded lifecycle state -> execute-gated preview | `cleanup_confirm_test.exs` | role-match |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` | LiveView mutation-confirm test | preview signature -> governed archive | `cleanup_preview_test.exs` | role-match |
| `rulestead_admin/lib/rulestead_admin/router.ex` | mounted route seam | host router -> LiveView workflow | current file | exact |
| `scripts/ci/test.sh` | verification entrypoint | test orchestration | current file | exact |
| `rulestead/test/rulestead/admin_lifecycle_test.exs` | core lifecycle proof | runtime/admin contract | `rulestead/test/rulestead/admin_contract_test.exs` | role-match |

## Pattern Assignments

### `rulestead_admin/README.md`, `guides/flows/admin-ui.md`, `guides/flows/flag-lifecycle.md`

**Analog:** existing shared-doc split between root/package README and workflow guides

**Core Pattern: Stable seam first, workflow second**
Public docs should describe the mount seam and host-owned contract first, then explain the supported cleanup flow without freezing every nested route or implementation detail:

```md
## Stable Operator Navigation

- mount through `rulestead_admin`
- host-owned `policy:` module
- required session keys
- canonical `?env=` selector
- queue-preserving `return_to`

## Lifecycle Review Workflow

cleanup -> preview -> confirm -> audit

This is the supported route-backed workflow.
It is not a promise that every internal LiveView route detail is stable API.
```

### `rulestead_admin/test/rulestead_admin/live/flag_live/form_test.exs`

**Analog:** current file

**Core Pattern: Manual authored payload as truth**
Use the passing form suite as the seed/source-of-truth pattern for all lifecycle fixtures:

```elixir
%{
  owner_ref: "team:platform",
  owner_kind: "team",
  owner_display: "Platform Team",
  lifecycle_mode: "permanent",
  review_by: ""
}
```

This is the safest analog because it already proves the public mounted authoring contract after the Phase 42 schema change.

### `index_test.exs`, `cleanup_test.exs`, `cleanup_preview_test.exs`, `cleanup_confirm_test.exs`

**Analog:** current cleanup-family suites plus `form_test.exs`

**Core Pattern: Embedded authored-state seed helper**
The failing suites should stop seeding top-level legacy fields and instead centralize a helper that produces the embed-based authored contract expected by current code:

```elixir
defp seeded_flag_attrs(overrides \\ %{}) do
  %{
    key: "ops-cleanup",
    flag_type: :release,
    value_type: :boolean,
    default_value: %{value: false},
    ownership: %{
      owner_ref: "ops",
      owner_kind: :team,
      owner_display: "Ops"
    },
    lifecycle: %{
      mode: :expiring,
      review_by: ~D[2026-04-20]
    },
    environment_keys: ["prod"],
    tags: ["infra"]
  }
  |> deep_merge(overrides)
end
```

The exact merge helper can vary, but the key pattern is one canonical embed-based seed shape reused across queue, cleanup, preview, and confirm tests.

### `cleanup_test.exs`

**Analog:** current file

**Core Pattern: Read-only cleanup review**
The cleanup page stays a readable advisory surface even for viewer-class actors:

```elixir
Application.put_env(:rulestead, :admin_policy, ReadOnlyPolicy)
{:ok, _view, html} = live(conn, "/admin/flags/ops-cleanup/cleanup?env=prod")
assert html =~ "Cleanup review"
refute html =~ "Preview archive"
```

### `cleanup_preview_test.exs` and `cleanup_confirm_test.exs`

**Analog:** current files

**Core Pattern: Execute-gated destructive flow**
Preview and confirm should keep live-redirect behavior for unauthorized actors and keep preview-signature revalidation before mutation:

```elixir
assert {:error, {:live_redirect, %{to: "/admin/flags"}}} =
         live(read_only_conn, "/admin/flags/ops-cleanup/cleanup/preview?env=prod")

assert {:drifted, detail} = validate_preview_signature(signature, detail)
```

### `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`

**Analog:** current file plus `router_test.exs`

**Core Pattern: Public mounted seam proof**
Integration proof should assert only the host-facing contract:

```elixir
assert {:error, {:live_redirect, %{to: "/admin/flags?env=prod"}}} = live(conn, "/admin/flags")
{:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/cleanup?env=prod&return_to=...")
assert html =~ "Back to queue"
```

This proves `?env=` normalization and cleanup workflow availability without asserting internal module names or DOM internals outside the stable doc seam.

### `scripts/ci/test.sh`

**Analog:** current script

**Core Pattern: Narrow targeted verification entry**
If CI wiring changes are needed, prefer adding or clarifying a narrow mounted-lifecycle/admin proof entry rather than broadening the whole suite:

```sh
mix test \
  test/rulestead_admin/live/flag_live/form_test.exs \
  test/rulestead_admin/live/flag_live/index_test.exs \
  test/rulestead_admin/live/flag_live/cleanup_test.exs \
  test/rulestead_admin/live/flag_live/cleanup_preview_test.exs \
  test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs \
  test/rulestead_admin/integration/admin_mount_test.exs
```

## Shared Patterns

### Mounted companion boundary
**Source:** `rulestead_admin/README.md`, `guides/flows/admin-ui.md`, `prompts/rulestead-host-app-integration-seam.md`
**Apply to:** docs, router tests, mount integration proof

Describe the host-owned `policy:`, session inputs, `?env=`, and `return_to` seams explicitly; avoid standalone-product language.

### Supported workflow, narrower stable API
**Source:** Phase 43 context + current lifecycle docs
**Apply to:** admin docs and integration tests

Document cleanup -> preview -> confirm -> audit as the supported workflow, while keeping the stable API claim narrower than every internal route step.

### Embedded authored-state fixture truth
**Source:** Phase 42 schema change + current passing `form_test.exs`
**Apply to:** lifecycle/admin-contract test seeds

All mounted lifecycle/admin tests should seed ownership/lifecycle via the embed-based payload, not via legacy top-level fields.

## Metadata

**Analog search scope:** `rulestead_admin/lib/`, `rulestead_admin/test/`, `guides/flows/`, `scripts/`
**Files scanned:** ~20
**Pattern extraction date:** 2026-05-25
