# credo:disable-for-this-file
defmodule Rulestead.Manifest.Import do
  @moduledoc false

  alias Rulestead.Manifest
  alias Rulestead.Manifest.{Plan, Result}
  alias Rulestead.Promotion.Compare
  alias Rulestead.Store.Command
  alias Rulestead.StoreError

  @spec plan(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def plan(content, opts \\ []) do
    with {:ok, manifest} <- Manifest.load(content),
         {:ok, target_environment_key} <- resolve_target_environment(manifest, opts),
         {:ok, preview} <- preview_manifest(manifest, target_environment_key, opts),
         plan <- build_plan(manifest, target_environment_key, preview) do
      {:ok,
       Result.new(%{
         status: preview.status,
         command: "rulestead.import.plan",
         summary: %{
           "target_environment_key" => target_environment_key,
           "flag_count" => length(plan["flag_keys"]),
           "plan_token" => plan["plan_token"]
         },
         findings: preview.findings,
         details: %{"plan" => plan}
       })}
    end
  end

  @spec apply(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def apply(plan_content, opts \\ []) do
    with {:ok, plan} <- Plan.load(plan_content),
         :ok <- validate_import_mode(plan),
         {:ok, reason} <- require_reason(opts),
         :ok <- validate_target_tenant(plan, opts),
         :ok <- validate_plan_dependency_closure(plan),
         {:ok, current_manifest} <-
           Rulestead.export_manifest(plan["target_environment_key"], opts),
         :ok <- validate_target_fingerprint(plan, current_manifest),
         :ok <- validate_target_lifecycle(plan, current_manifest),
         :ok <- validate_referenced_audiences(plan),
         :ok <- validate_governance_posture(plan),
         {:ok, result} <- dispatch_apply(plan, reason, opts) do
      {:ok,
       Result.new(%{
         status: "applied",
         command: "rulestead.import.apply",
         summary: %{
           "target_environment_key" => plan["target_environment_key"],
           "flag_count" => length(plan["flag_keys"]),
           "plan_token" => plan["plan_token"]
         },
         details: %{"apply" => Manifest.normalize_map(result), "plan" => plan}
       })}
    else
      {:error, %Rulestead.Error{message: "manifest import target fingerprint drifted"}} ->
        stale_result(plan_content)

      {:error, %Rulestead.Error{} = error} ->
        map_apply_error(plan_content, error)
    end
  end

  @spec preview(map(), map(), keyword()) :: map()
  def preview(source_manifest, target_manifest, opts \\ []) do
    target_environment_key =
      Keyword.get(opts, :target_environment_key, target_manifest["environment_key"])

    tenant_key = Manifest.normalize_string(Keyword.get(opts, :tenant_key))

    proposed_target_bundle = to_proposed_target_bundle(source_manifest, target_environment_key)
    dependency_closure_keys = Plan.dependency_closure_from_bundle(proposed_target_bundle)

    diff_result =
      case Rulestead.Manifest.Diff.diff(source_manifest, target_manifest: target_manifest) do
        {:ok, result} -> result
        {:error, _error} -> Result.new(%{status: "error", command: "rulestead.import.plan"})
      end

    findings =
      diff_result["findings"] ++
        additive_findings(source_manifest, target_manifest, proposed_target_bundle) ++
        dependency_findings(dependency_closure_keys) ++
        governance_findings(target_environment_key, diff_result["status"]) ++
        tenant_findings(tenant_key, source_manifest, target_manifest)

    normalized_findings = Result.sort_findings(findings)
    status = derive_status(normalized_findings, diff_result["status"], target_environment_key)

    %{
      status: status,
      findings: normalized_findings,
      target_fingerprint: Plan.fingerprint(target_manifest),
      dependency_closure_keys: dependency_closure_keys,
      proposed_target_bundle: proposed_target_bundle,
      tenant_key: tenant_key
    }
  end

  @spec preview_manifest(map(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def preview_manifest(manifest, target_environment_key, opts \\ []) do
    with {:ok, target_manifest} <- Rulestead.export_manifest(target_environment_key, opts) do
      {:ok,
       preview(
         manifest,
         target_manifest,
         Keyword.put(opts, :target_environment_key, target_environment_key)
       )}
    end
  end

  defp build_plan(manifest, target_environment_key, preview) do
    Plan.build_import(%{
      source_environment_key: manifest["environment_key"],
      target_environment_key: target_environment_key,
      status: preview.status,
      target_fingerprint: preview.target_fingerprint,
      dependency_closure_keys: preview.dependency_closure_keys,
      proposed_target_bundle: preview.proposed_target_bundle,
      tenant_key: preview.tenant_key
    })
  end

  defp resolve_target_environment(manifest, opts) do
    case Manifest.normalize_string(
           Keyword.get(opts, :target_environment, manifest["environment_key"])
         ) do
      nil -> {:error, Manifest.invalid("import requires a target environment key")}
      value -> {:ok, value}
    end
  end

  defp to_proposed_target_bundle(manifest, target_environment_key) do
    manifest["flags"]
    |> Enum.map(fn flag ->
      {
        flag["flag_key"],
        %{
          "flag" =>
            flag["flag"]
            |> Manifest.normalize_map()
            |> Map.put("key", flag["flag_key"]),
          "flag_environment" =>
            flag["environment"]
            |> Manifest.normalize_map()
            |> Map.put("environment_key", target_environment_key),
          "active_ruleset" => Manifest.normalize_map(flag["active_ruleset"])
        }
      }
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Map.new()
  end

  defp additive_findings(source_manifest, target_manifest, proposed_target_bundle) do
    target_flags = Map.new(target_manifest["flags"], &{&1["flag_key"], &1})

    source_manifest["flags"]
    |> Enum.flat_map(fn source_flag ->
      flag_key = source_flag["flag_key"]
      target_flag = Map.get(target_flags, flag_key)
      proposed_state = Map.get(proposed_target_bundle, flag_key, %{})

      []
      |> maybe_add_archived_target_flag(flag_key, target_flag)
      |> maybe_add_archived_plan_state(flag_key, proposed_state)
    end)
  end

  defp dependency_findings(dependency_closure_keys) do
    audience_map =
      case Rulestead.list_audiences(include_archived?: true, limit: 10_000) do
        {:ok, audiences} -> Map.new(audiences, &{"audience:" <> &1.key, &1})
        {:error, _error} -> %{}
      end

    dependency_closure_keys
    |> Enum.flat_map(fn key ->
      case Map.get(audience_map, key) do
        nil ->
          [
            Result.finding("missing_dependency", "blocker", key,
              message: "referenced audience was not found"
            )
          ]

        audience ->
          archived_at = Map.get(audience, :archived_at) || Map.get(audience, "archived_at")

          if is_nil(archived_at) do
            []
          else
            [
              Result.finding("archived_dependency", "blocker", key,
                message: "referenced audience is archived"
              )
            ]
          end
      end
    end)
  end

  defp governance_findings(_target_environment_key, "no_changes"), do: []

  defp governance_findings(target_environment_key, _status) do
    if Compare.protected_target?(target_environment_key) do
      [
        Result.finding("protected_target_environment", "warning", target_environment_key,
          message: "target environment requires governed apply"
        )
      ]
    else
      []
    end
  end

  defp derive_status(findings, "no_changes", _target_environment_key) do
    if blocker_findings?(findings), do: "blocked", else: "no_changes"
  end

  defp derive_status(findings, _diff_status, target_environment_key) do
    cond do
      blocker_findings?(findings) -> "blocked"
      Compare.protected_target?(target_environment_key) -> "governance_required"
      true -> "changes"
    end
  end

  defp blocker_findings?(findings) do
    Enum.any?(findings, &(&1["severity"] == "blocker"))
  end

  defp maybe_add_archived_target_flag(findings, _flag_key, nil), do: findings

  defp maybe_add_archived_target_flag(findings, flag_key, target_flag) do
    case get_in(target_flag, ["environment", "status"]) do
      "archived" ->
        [
          Result.finding("archived_target_flag_environment", "blocker", flag_key,
            message: "target environment state is archived and cannot be revived by import"
          )
          | findings
        ]

      _other ->
        findings
    end
  end

  defp maybe_add_archived_plan_state(findings, flag_key, proposed_state) do
    case get_in(proposed_state, ["flag_environment", "status"]) do
      "archived" ->
        [
          Result.finding("archived_manifest_state", "blocker", flag_key,
            message: "manifest import cannot apply archived environment state"
          )
          | findings
        ]

      _other ->
        findings
    end
  end

  defp validate_import_mode(plan) do
    if plan["mode"] == "import" do
      :ok
    else
      {:error, Manifest.invalid("apply plan is not an import plan")}
    end
  end

  defp require_reason(opts) do
    case Manifest.normalize_string(Keyword.get(opts, :reason)) do
      nil -> {:error, Manifest.invalid("import apply requires an explicit reason")}
      value -> {:ok, value}
    end
  end

  defp validate_plan_dependency_closure(plan) do
    if plan["dependency_closure_keys"] ==
         Plan.dependency_closure_from_bundle(plan["proposed_target_bundle"]) do
      :ok
    else
      {:error, StoreError.invalid_command("manifest import dependency closure drifted")}
    end
  end

  defp validate_target_fingerprint(plan, current_manifest) do
    if plan["target_fingerprint"] == Plan.fingerprint(current_manifest) do
      :ok
    else
      {:error, StoreError.invalid_command("manifest import target fingerprint drifted")}
    end
  end

  defp validate_target_tenant(plan, opts) do
    live_tenant = Manifest.normalize_string(Keyword.get(opts, :tenant_key))
    plan_tenant = plan["tenant_key"]

    if live_tenant == plan_tenant do
      :ok
    else
      {:error, StoreError.invalid_command("manifest import target tenant drifted")}
    end
  end

  defp tenant_findings(tenant_key, source_manifest, _target_manifest) do
    source_tenant = source_manifest["tenant_key"]

    cond do
      source_tenant == tenant_key ->
        []

      is_nil(source_tenant) and not is_nil(tenant_key) ->
        []

      not is_nil(source_tenant) and is_nil(tenant_key) ->
        [
          Result.finding("widened_tenant_scope", "blocker", source_manifest["environment_key"],
            message: "import preview would widen tenant scope from specific to all tenants"
          )
        ]

      true ->
        [
          Result.finding("mismatched_tenant_scope", "blocker", source_manifest["environment_key"],
            message: "import preview would mix different tenant scopes"
          )
        ]
    end
  end

  defp validate_target_lifecycle(plan, current_manifest) do
    current_flags = Map.new(current_manifest["flags"], &{&1["flag_key"], &1})

    case Enum.find(plan["flag_keys"], fn flag_key ->
           case Map.get(current_flags, flag_key) do
             %{"environment" => %{"status" => "archived"}} -> true
             _other -> false
           end
         end) do
      nil ->
        :ok

      flag_key ->
        {:error,
         StoreError.invalid_command("manifest import would revive an archived flag environment",
           metadata: %{flag_key: flag_key}
         )}
    end
  end

  defp validate_referenced_audiences(plan) do
    findings = dependency_findings(plan["dependency_closure_keys"])

    if blocker_findings?(findings),
      do:
        {:error,
         StoreError.invalid_command("manifest import has unresolved audience dependencies")},
      else: :ok
  end

  defp validate_governance_posture(plan) do
    if plan["status"] == "governance_required" or
         Compare.protected_target?(plan["target_environment_key"]) do
      {:error,
       StoreError.invalid_command("manifest import to protected targets requires governance")}
    else
      :ok
    end
  end

  defp dispatch_apply(plan, reason, opts) do
    command =
      Command.ApplyManifestImport.new(
        %{
          source_environment_key: plan["source_environment_key"],
          target_environment_key: plan["target_environment_key"],
          tenant_key: plan["tenant_key"],
          plan_token: plan["plan_token"],
          target_fingerprint: plan["target_fingerprint"],
          dependency_closure_keys: plan["dependency_closure_keys"],
          flag_keys: plan["flag_keys"],
          proposed_target_bundle: plan["proposed_target_bundle"]
        },
        actor: Keyword.get(opts, :actor),
        reason: reason,
        metadata: Keyword.get(opts, :metadata, %{})
      )

    store = Application.fetch_env!(:rulestead, :store)
    store.apply_manifest_import(command)
  end

  defp stale_result(plan_content) do
    with {:ok, plan} <- Plan.load(plan_content) do
      {:ok,
       Result.new(%{
         status: "stale",
         command: "rulestead.import.apply",
         summary: %{
           "target_environment_key" => plan["target_environment_key"],
           "plan_token" => plan["plan_token"]
         },
         findings: [
           Result.finding("stale_plan", "blocker", plan["target_environment_key"],
             message: "saved import plan no longer matches live target state"
           )
         ],
         details: %{"plan" => plan}
       })}
    end
  end

  defp map_apply_error(plan_content, %Rulestead.Error{message: message} = error) do
    status =
      cond do
        String.contains?(message, "protected targets requires governance") ->
          "governance_required"

        String.contains?(message, "drifted") or String.contains?(message, "stale") ->
          "stale"

        String.contains?(message, "dependency") or String.contains?(message, "archived") ->
          "blocked"

        true ->
          "invalid"
      end

    with {:ok, plan} <- Plan.load(plan_content) do
      {:ok,
       Result.new(%{
         status: status,
         command: "rulestead.import.apply",
         summary: %{
           "target_environment_key" => plan["target_environment_key"],
           "plan_token" => plan["plan_token"]
         },
         findings: [
           Result.finding(status_code(status), "blocker", plan["target_environment_key"],
             message: message
           )
         ],
         details: %{
           "plan" => plan,
           "error" => Manifest.normalize_map(%{message: error.message, type: error.type})
         }
       })}
    end
  end

  defp status_code("governance_required"), do: "governance_required"
  defp status_code("stale"), do: "stale_plan"
  defp status_code("blocked"), do: "blocked_import"
  defp status_code(_status), do: "invalid_import"
end
