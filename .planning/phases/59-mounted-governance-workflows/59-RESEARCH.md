# Phase 59: Mounted Governance Workflows — Research

**Researched:** 2026-05-27
**Phase:** 59-mounted-governance-workflows
**Requirements:** ADM-01, ADM-02, ADM-03

## Summary

Phase 59 is **admin-only** (no core contract changes). Phases 57–58 shipped `Rulestead.assess_audience_blast_radius/2`, protected apply blocking, and `apply_audience_mutation` change-request submit/execute. Mounted audience LiveViews still use a single **Apply** path on confirm with no blast-radius UI.

Implementation centers on:

1. **Shared governance context** in `AudienceLive.Shared` (or sibling module) — assess + dependency hidden count → `@governance_mode`, `@visibility_tier`, `@blast_radius_assessment`.
2. **`GovernanceComponents.blast_radius_panel/1`** — verdict strip, threshold line, breach list; frozen vs live variants.
3. **Four LiveViews** — `edit_preview`, `archive_preview`, `edit_confirm`, `archive_confirm` — branch CTA and forms without new routes.
4. **`ChangeRequestLive.Show`** — render frozen metadata for `governed_action == "apply_audience_mutation"`.
5. **Tests** — `env=prod` (protected), seed >2 refs for above-threshold update, policy modules with `change_request_required?` / `allow_self_approval?`.

## Technical Findings

### Protected environment detection

- Core: `Rulestead.Promotion.Compare.protected_target?/1` — `environment_key in ["prod", "production"]`.
- Admin session uses `env=prod` in integration tests (`admin_mount_phase11_test.exs`).
- Tests must seed flags/rules in **prod** (not only `test`) for threshold breach scenarios.

### Assessment inputs

`BlastRadiusThreshold.assess/2` expects map with:

- `environment_key`, `operation` (`"update"` | `"archive"`), `preview_fingerprint`
- `affected_references` from preview
- `hidden_reference_count` from `list_audience_dependencies` redacted result
- `dependency_entries` optional (for auth-denied paths)

Facade: `Rulestead.assess_audience_blast_radius(preview_map, opts)` — no I/O.

### Governance mode mapping (from CONTEXT D-01)

| Condition | `@governance_mode` |
|-----------|-------------------|
| Non-protected env | `:unrestricted` |
| Protected + `:below_threshold` | `:direct_apply` |
| Protected + `:above_threshold` | `:change_request` |
| Protected + `:indeterminate` or assess error | `:blocked` |

### Visibility tiers (ADM-03)

| Tier | Trigger | UX |
|------|---------|-----|
| `:full` | `hidden_reference_count == 0`, deps not `{:error, :auth}` | Full evidence |
| `:partial` | `hidden_reference_count > 0` | Counts + redacted rows; mode → `:blocked` |
| `:denied` | `list_audience_dependencies` auth error | `capability_explanation` only |

Reuse: `Rulestead.list_audience_dependencies/1`, `AudienceComponents.used_by_table/1` patterns, `OperatorComponents.capability_explanation/1`.

### Submit change request payload

From Phase 58 + existing CR tests:

```elixir
Rulestead.submit_change_request(
  Command.SubmitChangeRequest.new(
    %{
      action: :apply_audience_mutation,
      environment_key: "prod",
      resource_type: "audience",
      resource_key: audience_key,
      command: %{
        "audience_key" => audience_key,
        "operation" => "update", # or "archive"
        "preview_schema_version" => preview.preview_schema_version,
        "preview_fingerprint" => preview.preview_fingerprint,
        # ... mutation-specific fields from apply_attrs
      },
      approval_requirement: ApprovalRequirement.new(...)
    },
    actor: socket.assigns.current_actor,
    reason: reason
  )
)
```

Build metadata via store path (core validates); UI should pass same preview fingerprint as confirm load.

`Authorizer.approval_requirement(actor, :submit_change_request, %{resource_type: "audience", resource_key: key}, env_key)` for D-05 display.

Policy gate: `Rulestead.Admin.Authorizer.authorized?(actor, :submit_change_request, resource, env)` — surface `capability_explanation` when denied.

### CR show frozen evidence

Match `change_request.governed_action == "apply_audience_mutation"` (string in persisted row).

Render from `metadata["blast_radius_assessment"]` and `metadata["affected_reference_summary"]` — **no** `assess_audience_blast_radius` on show mount.

Insert panel between "Proposed change" and "Review context" sections.

### Existing patterns to mirror

| Pattern | Location |
|---------|----------|
| Preview → confirm query params | `edit_preview.ex` `confirm_path/1` |
| Stale preview redirect | `Shared.stale_preview_error?/1`, `?drifted=true` |
| Production confirm | `flag_live/cleanup_confirm_test.exs` — `env=prod` |
| CR submit test | `change_request_live/show_test.exs` — `ApprovalRequirement.new` |
| Section cards / callouts | `FlagComponents.section_card`, `FlagComponents.callout` |

### Anti-patterns (do not)

- New `/governance-proposal` route (CONTEXT D-02).
- Merge verdict UI into `impact_preview` (D-07).
- Re-assess on CR show approve (D-07).
- Submit CR when `:partial` visibility / `:indeterminate` (Phase 58 + D-10).
- Auto-approve on submit (D-05).

## Plan decomposition (4 plans)

| Plan | Wave | Focus | Requirements |
|------|------|-------|--------------|
| 59-01 | 1 | `GovernanceComponents` + `AudienceLive.Governance` shared loader | ADM-02 (component) |
| 59-02 | 2 | Preview LiveViews (edit + archive) | ADM-01, ADM-02 |
| 59-03 | 2 | Confirm LiveViews (apply vs submit CR) | ADM-01, ADM-02, ADM-03 |
| 59-04 | 3 | CR show panel + integration tests + roadmap | ADM-02, ADM-03 |

Waves: 59-01 alone; 59-02 and 59-03 parallel after 59-01; 59-04 after 59-02+59-03.

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`rulestead_admin` + `rulestead` Fake) |
| **Config file** | `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/` |
| **Full phase command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/ test/rulestead_admin/live/change_request_live/show_test.exs` |
| **Estimated runtime** | ~45 seconds |

### Per-requirement verification map

| REQ-ID | Verification | Command |
|--------|--------------|---------|
| ADM-01 | Prod env + refs above limit → no Apply, Submit CR + redirect to CR show | `edit_confirm_test.exs` / `archive_confirm_test.exs` |
| ADM-02 | `blast_radius_panel` HTML on preview, confirm, CR show | component + LiveView tests |
| ADM-03 | Hidden refs → blocked + redacted copy; CR approve gated | dedicated test with dependency redaction policy |
| ADM-04 | No new top-level routes; grep router | `governance_route_contract_test.exs` or extend |

### Wave 0 requirements

Existing ConnCase + Fake.Control + TestPolicy modules suffice. Add `RulesteadAdmin.GovernanceTestPolicy` with configurable `change_request_required?` / `allow_self_approval?` for confirm tests.

---

## RESEARCH COMPLETE
