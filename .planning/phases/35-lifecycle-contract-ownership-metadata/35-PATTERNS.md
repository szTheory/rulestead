# Phase 35: Lifecycle Contract & Ownership Metadata - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 9 likely implementation targets
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead/flag.ex` | model | CRUD | `rulestead/lib/rulestead/flag.ex` | exact |
| `rulestead/lib/rulestead/admin/lifecycle.ex` | service | transform | `rulestead/lib/rulestead/admin/lifecycle.ex` | exact |
| `rulestead/lib/rulestead/audit_event.ex` | utility | transform | `rulestead/lib/rulestead/audit_event.ex` | exact |
| `rulestead/lib/rulestead/store/command.ex` | utility | transform | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | `rulestead/lib/rulestead/store/ecto.ex` | exact |
| `rulestead/lib/rulestead/fake.ex` | service | CRUD | `rulestead/lib/rulestead/fake.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | component | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | exact |
| `rulestead/priv/repo/migrations/*phase35*ownership*lifecycle*.exs` | migration | batch | `rulestead/priv/repo/migrations/20260424210000_add_phase6_admin_lifecycle_fields.exs` | role-match |

## Pattern Assignments

### `rulestead/lib/rulestead/flag.ex` (authored schema and changeset)

**Analog:** `rulestead/lib/rulestead/flag.ex`

**Use this pattern for bounded authored truth, not derived guidance.**

**Schema + cast pattern** (`flag.ex` lines 21-62):
```elixir
schema "flags" do
  field(:owner, :string)
  field(:expected_expiration, :date)
  field(:permanent, :boolean, default: false)
end

def changeset(flag, attrs) do
  flag
  |> cast(attrs, [...])
  |> update_change(:owner, &normalize_string/1)
  |> validate_required([..., :owner])
  |> validate_lifecycle_mode()
end
```

**Why it matters for Phase 35**
- Keep owner/lifecycle fields in `Flag` as explicit authored facts.
- Extend this changeset with normalized ownership fields the same way `owner`, `tags`, and lifecycle mode are normalized and validated now.
- Preserve the current invariant style: authored contract is enforced in the changeset, not later in admin projection code.

**Closest compatibility precedent**
- Current code still treats `owner` as a single authored field; Phase 35 should layer normalized owner contract beside it and treat the freeform string as migration input, not long-term truth.

### `rulestead/lib/rulestead/admin/lifecycle.ex` (derived projection seam)

**Analog:** `rulestead/lib/rulestead/admin/lifecycle.ex`

**Projection pattern** (`admin/lifecycle.ex` lines 17-30, 43-50):
```elixir
def classify(flag, flag_environment, opts \\ []) do
  %{
    state: state(flag, flag_environment, last_evaluated_at, opts),
    mode: if(permanent, do: :permanent, else: :expiring),
    owner: flag[:owner],
    expected_expiration: expected_expiration,
    permanent: permanent
  }
end
```

**Why it matters for Phase 35**
- Keep authored ownership/lifecycle facts separate from computed posture.
- Add normalized owner/lifecycle summary fields to the projection here rather than persisting computed lifecycle status.
- This is the right seam for “admin computes guidance from authored facts” after the schema contract lands.

### `rulestead/lib/rulestead/audit_event.ex` (audit envelope + bounded summary blocks)

**Analog:** `rulestead/lib/rulestead/audit_event.ex`

**Central metadata builder pattern** (`audit_event.ex` lines 36-79):
```elixir
%{
  "before" => normalize_map(...),
  "after" => normalize_map(...),
  "diff" => normalize_map(...),
  "links" => normalize_map(...),
  "context" => context
}
|> maybe_put("tenant", tenant)
|> maybe_put("request_id", ...)
|> maybe_put("source", ...)
```

**Normalization pattern** (`audit_event.ex` lines 152-179, 205-233):
```elixir
defp normalize_map(map) when is_map(map) do
  Map.new(map, fn
    {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
    {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
    {key, value} -> {to_string(key), normalize_value(value)}
  end)
end
```

**Why it matters for Phase 35**
- Add lifecycle/ownership transition summaries as bounded first-class metadata inside `AuditEvent.metadata/1`.
- Keep `before`/`after`/`diff` as canonical detail; summary blocks should be compact hints like tenant provenance, not a second source of truth.
- Centralize summary generation here so Ecto, Fake, governance, replay, and scheduled execution all inherit the same vocabulary.

### `rulestead/lib/rulestead/store/command.ex` (bounded metadata normalization seam)

**Analog:** `rulestead/lib/rulestead/store/command.ex`

**Best reusable precedent for normalized metadata blocks:** `GovernanceSupport.normalize_tenant_provenance/1` and `tenant_provenance/2` (`store/command.ex` lines 62-138, 226-278).

**Pattern to copy**
```elixir
provenance =
  %{}
  |> maybe_put("tenant_key", ...)
  |> maybe_put("scope_source", normalize_enum(...))
  |> maybe_put("validation", validation)
```

**Why it matters for Phase 35**
- Model normalized owner/provenance blocks the same way: bounded enums, `normalize_string`, `normalize_map`, `maybe_put`, and `normalize_enum`.
- This is the closest analog for replacing a freeform admin field with a stable normalized contract while preserving host-owned semantics.
- Recommended Phase 35 shape: add an ownership normalizer here or beside it, not inline inside Ecto/Fake/admin views.

### `rulestead/lib/rulestead/store/ecto.ex` (real adapter payload construction)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Create/update write path pattern** (`store/ecto.ex` lines 237-260, 278-298, 4518-4525 via search):
- `create_flag/1` builds a bounded attrs map from typed command fields, then persists through `Flag.changeset/2`.
- `update_flag/1` uses `maybe_put_update_field` and only carries changed metadata into the changeset.

**Admin payload builder pattern** (`store/ecto.ex` lines 2255-2296):
```elixir
defp build_flag_detail_payload(flag, environment, flag_environment, include_ruleset?) do
  build_flag_payload(flag, environment, flag_environment, include_ruleset?)
  |> decorate_payload(flag, environment, flag_environment)
end

defp build_create_payload(flag) do
  %{
    flag: flag_summary(flag),
    archived?: not is_nil(flag.archived_at),
    environment_keys: ...,
    environments: ...,
    recent_owners: recent_owners(flag.owner)
  }
end
```

**Recent-owner normalization pattern** (`store/ecto.ex` lines 4252-4280, 4495-4502):
```elixir
defp recent_owners(current_owner, extra_owner \\ nil) do
  [normalize_owner(current_owner), normalize_owner(extra_owner) | ...]
  |> Enum.reject(&is_nil/1)
  |> Enum.uniq()
  |> Enum.take(5)
end
```

**Promotion/import compatibility pattern** (`store/ecto.ex` lines 1757-1775, 1956-1967 via search):
- promoted/imported authored state is denormalized once, then mapped through explicit per-field normalizers before upsert
- current fields carried through this path: `owner`, `expected_expiration`, `permanent`, `tags`

**Why it matters for Phase 35**
- Add normalized owner/lifecycle authored contract in the Ecto adapter once, then reuse the same summarized/admin payload shape across fetch/list/create/update/import/promotion paths.
- Extend the existing promotion/import field-mapping blocks instead of inventing a separate compatibility path.
- `recent_owners` is the closest analog for lifecycle/owner audit summary history: bounded, normalized, and admin-facing.

### `rulestead/lib/rulestead/fake.ex` (adapter parity)

**Analog:** `rulestead/lib/rulestead/fake.ex`

**Parity payload builder pattern** (`fake.ex` lines 3836-3865):
```elixir
defp build_flag_detail_payload(state, flag, environment, flag_environment, include_ruleset?) do
  build_flag_payload(flag, environment, flag_environment, include_ruleset?)
  |> decorate_payload(state, flag, environment, flag_environment)
end

defp build_create_payload(state, flag) do
  %{..., recent_owners: recent_owners(state, flag.owner)}
end
```

**Compatibility/history pattern** (`fake.ex` lines 4440-4456):
```elixir
flag
|> Map.put(:owner, updated_flag.owner)
|> Map.put(:expected_expiration, updated_flag.expected_expiration)
|> Map.put(:permanent, updated_flag.permanent)
|> Map.put(:tags, updated_flag.tags)
|> Map.put(:previous_owners, [flag.owner | Map.get(flag, :previous_owners, [])] |> Enum.uniq())
```

**Filter parity pattern** (`fake.ex` lines 4238-4268):
```elixir
defp recent_owners(state, current_owner) do
  state.flags
  |> Map.values()
  |> Enum.flat_map(fn flag -> [flag.owner | Map.get(flag, :previous_owners, [])] end)
end
```

**Why it matters for Phase 35**
- Any new normalized owner/lifecycle contract added to Ecto payloads must be mirrored here immediately.
- The fake already keeps compatibility state (`previous_owners`) explicitly; use that same approach for legacy owner-field migration behavior in tests.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` (mounted authoring surface)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex`

**Mounted authoring pattern** (`form.ex` lines 48-57, 92-128, 162-194, 205-228):
- form state is plain `form_data`
- local validation runs before persist
- `persist/3` translates form data into the public facade call
- `to_form_data/1` is the readback seam for edit mode

**Concrete fields already wired**
```elixir
<input type="text" name="flag[owner]" ... />
<input type="date" name="flag[expected_expiration]" ... />
<input type="checkbox" name="flag[permanent]" ... />
```

**Why it matters for Phase 35**
- This is where owner ref/kind/display inputs and lifecycle suggestion/override controls should mount.
- Keep the pattern of translating UI inputs into a bounded payload in `persist/3`; do not let normalization logic live in the template.
- `default_form_data/0` and `to_form_data/1` are the practical seams for introducing backward-compatible legacy-field hydration.

### `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` (mounted detail surface)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**Detail-projection pattern** (`show.ex` lines 80-103, 204+):
```elixir
<FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} />
<FlagComponents.stat title="Owner" value={@detail.lifecycle.owner} />

<FlagComponents.section_card title="Lifecycle">
  <span>Owner: <%= @detail.lifecycle.owner %></span>
  <%= if @detail.flag.permanent do %>
    Permanent
  <% else %>
    Expected expiration: <%= @detail.flag.expected_expiration %>
  <% end %>
</FlagComponents.section_card>
```

**Why it matters for Phase 35**
- Extend the existing detail projection rather than adding a separate lifecycle page in this phase.
- Show normalized owner and lifecycle-authored facts here first; keep archive-readiness and richer guidance deferred to Phase 36/37.

### `rulestead/priv/repo/migrations/*phase35*.exs` (compatibility migration)

**Analog:** `rulestead/priv/repo/migrations/20260424210000_add_phase6_admin_lifecycle_fields.exs`

**Best migration precedent** (`20260424210000_add_phase6_admin_lifecycle_fields.exs` lines 4-31):
```elixir
alter table(:flags) do
  add(:permanent, :boolean, null: false, default: false)
end

execute("""
UPDATE flags
SET permanent = CASE
  WHEN expected_expiration IS NULL THEN true
  ELSE false
END
""", "UPDATE flags SET permanent = false")
```

**Why it matters for Phase 35**
- Add new normalized owner/lifecycle columns with the same pattern: schema extension, deterministic backfill from legacy fields, then constraint/index additions.
- Preserve compatibility by deriving normalized contract fields from existing `owner` and lifecycle columns in one explicit `execute/2` block.

**Test-only compatibility precedent**
- `rulestead/test/rulestead/store_ecto_admin_test.exs` lines 149-150 uses `ALTER TABLE ... ADD COLUMN IF NOT EXISTS ...` to keep contract tests runnable against older schemas.
- Use the same posture in adapter tests when Phase 35 adds new authored columns.

## Shared Patterns

### Bounded Metadata Normalization
**Source:** `rulestead/lib/rulestead/store/command.ex` lines 28-43, 62-138, 226-278

Apply this to owner-ref/kind/display normalization:
- `normalize_string/1` for trimmed opaque refs and display snapshots
- `normalize_map/1` for durable metadata maps
- `normalize_enum/2` for bounded kinds/status values
- `maybe_put/3` to omit absent optional fields instead of storing empty strings

### Audit Envelope + Summary Blocks
**Source:** `rulestead/lib/rulestead/audit_event.ex` lines 36-79

Apply this to lifecycle/ownership audit metadata:
- keep `before` / `after` / `diff` / `links` / `context`
- add one bounded ownership/lifecycle summary block through `maybe_put`
- continue stripping sensitive context data centrally

### Authored Facts vs Derived Guidance
**Source:** `rulestead/lib/rulestead/flag.ex` lines 41-62 and `rulestead/lib/rulestead/admin/lifecycle.ex` lines 17-30

Phase 35 should preserve this split:
- `Flag.changeset/2` owns durable authored truth
- `Admin.Lifecycle.classify/3` owns mounted/admin projection
- no computed lifecycle status stored as canonical DB truth

### Ecto/Fake Adapter Parity
**Source:** `rulestead/lib/rulestead/store/ecto.ex` lines 2255-2296 and `rulestead/lib/rulestead/fake.ex` lines 3836-3865

Apply to any new admin payload field:
- add it in both payload builders
- add it in both update/create/import/promotion paths
- add adapter-contract coverage before relying on mounted-admin output

### Mounted Admin Surface Extension
**Source:** `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` lines 162-194 and `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` lines 80-103

Apply to lifecycle/owner authoring:
- translate form inputs in `persist/3`
- hydrate edit state in `to_form_data/1`
- present normalized facts in existing detail stats/cards
- defer richer workbench flows to later phases

## No Exact Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `owner_ref` / `owner_kind` normalized authored block | model | CRUD | Current code only has a single `owner` string; tenant provenance is the closest shape analog |
| lifecycle default suggestion seam with override/rationale | service | transform | Current lifecycle code classifies stale state from persisted facts; it does not yet suggest authored defaults |
| first-class lifecycle/ownership audit summary block | utility | transform | Current audit metadata has tenant/governance summaries but no lifecycle/ownership-specific summary block yet |

## Practical Findings For Planning

- Recommend treating `owner` as compatibility input and display fallback, while introducing a centrally normalized owner contract using the same bounded-metadata style as tenant provenance.
- Put normalization in a shared seam near `Store.Command.GovernanceSupport`, then have `Flag.changeset/2`, `Store.Ecto`, `Store.Fake`, and `AuditEvent.metadata/1` consume that seam.
- Extend current detail/form surfaces only enough to author and display owner/lifecycle contract fields; do not add archive-readiness UX in Phase 35.
- Use the Phase 6 migration model: add columns, backfill deterministically from legacy data, then enforce bounded constraints.

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead_admin/lib`, `rulestead/priv/repo/migrations`, `rulestead/test`, `.planning/phases/35-*`
**Files scanned:** 17
**Pattern extraction date:** 2026-05-23
