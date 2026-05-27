defmodule RulesteadAdmin.Components.AudienceComponents do
  @moduledoc false

  use Phoenix.Component

  @sample_display_limit 10

  attr :dependencies, :map, required: true
  attr :mount_path, :string, required: true
  attr :environment_key, :string, required: true
  attr :tenant_key, :string, default: nil

  def used_by_table(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Used by references">
      <h2>Used by</h2>
      <p><%= @dependencies.summary %></p>
      <p :if={@dependencies.denied?} role="alert">
        Dependency list unavailable — you do not have permission to view audience dependencies in this scope.
      </p>
      <p :if={@dependencies.hidden_count > 0 and not @dependencies.denied?}>
        At least <%= @dependencies.hidden_count %> references are hidden by your permissions.
      </p>

      <table :if={@dependencies.entries != []}>
        <thead>
          <tr>
            <th>Environment</th>
            <th>Tenant</th>
            <th>Flag</th>
            <th>Rule</th>
            <th>Ruleset</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={entry <- @dependencies.entries}>
            <td><code><%= entry.environment_key %></code></td>
            <td><code><%= entry.tenant_key || "—" %></code></td>
            <td>
              <a :if={visible_flag_key?(entry.flag_key)} href={flag_link(@mount_path, entry, @environment_key, @tenant_key)}>
                <code><%= entry.flag_key %></code>
              </a>
              <span :if={redacted_flag_key?(entry.flag_key)}>Hidden reference</span>
            </td>
            <td><code><%= entry.rule_key %></code></td>
            <td>v<%= entry.ruleset_version %></td>
          </tr>
        </tbody>
      </table>

      <ul :if={@dependencies.redacted_entries != []}>
        <li :for={entry <- @dependencies.redacted_entries}>
          Hidden reference
          <span :if={policy_denied?(entry)}>(policy denied)</span>
        </li>
      </ul>

      <p :if={@dependencies.entries == [] and @dependencies.redacted_entries == [] and not @dependencies.denied?}>
        No authored references in this environment and tenant scope.
      </p>
    </section>
    """
  end

  attr :preview, :map, required: true

  def impact_preview(assigns) do
    samples = sample_evidence_list(assigns.preview)
    {visible_samples, remaining_samples} = display_samples(samples)
    impression = impression_evidence_map(assigns.preview)
    variant_breakdown = variant_breakdown_list(impression)

    assigns =
      assigns
      |> assign(:visible_samples, visible_samples)
      |> assign(:remaining_samples, remaining_samples)
      |> assign(:impression, impression)
      |> assign(:variant_breakdown, variant_breakdown)
      |> assign(:has_samples?, visible_samples != [])
      |> assign(:has_impression?, impression != %{})

    ~H"""
    <section class="rs-card" aria-label="Impact preview">
      <h2>Impact preview</h2>
      <p><strong>Preview basis:</strong> <%= humanize_preview_basis(@preview.preview_basis) %></p>
      <p :if={uncertainty_message(@preview)}>
        <%= uncertainty_message(@preview) %>
      </p>
      <p><strong>Fingerprint:</strong> <code><%= @preview.preview_fingerprint %></code></p>
      <p><strong>Environment:</strong> <code><%= scope_key(@preview.environment_scope, :environment_key) %></code></p>
      <p><strong>Tenant:</strong> <code><%= scope_key(@preview.tenant_scope, :tenant_key) %></code></p>

      <h3>Affected references</h3>
      <ul>
        <li :for={ref <- List.wrap(@preview.affected_references)}>
          <code><%= ref[:reference_key] || ref["reference_key"] %></code>
        </li>
        <li :if={List.wrap(@preview.affected_references) == []}>No authored references affected.</li>
      </ul>

      <div :if={@has_samples?}>
        <h3>Sample cohort</h3>
        <table>
          <thead>
            <tr>
              <th>Actor</th>
              <th>Targeting key</th>
              <th>Matched?</th>
              <th>Reason</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @visible_samples}>
              <td><code><%= sample_row(row).actor_key %></code></td>
              <td><code><%= sample_row(row).targeting_key %></code></td>
              <td><%= sample_row(row).matched? %></td>
              <td><%= sample_row(row).reason %></td>
            </tr>
          </tbody>
        </table>
        <p :if={@remaining_samples > 0}>+<%= @remaining_samples %> more</p>
      </div>

      <div :if={@has_impression?}>
        <h3>Impression summary</h3>
        <p :if={impression_field(@impression, :window_label)}>
          <strong>Window:</strong> <%= impression_field(@impression, :window_label) %>
        </p>
        <p :if={impression_field(@impression, :sampled_impressions)}>
          <strong>Sampled impressions:</strong> <%= impression_field(@impression, :sampled_impressions) %>
        </p>
        <p :if={impression_field(@impression, :matched_impressions)}>
          <strong>Matched impressions:</strong> <%= impression_field(@impression, :matched_impressions) %>
        </p>
        <ul :if={@variant_breakdown != []}>
          <li :for={entry <- @variant_breakdown}>
            <code><%= variant_entry_label(entry) %></code>: <%= variant_entry_count(entry) %>
          </li>
        </ul>
      </div>
    </section>
    """
  end

  defp flag_link(mount_path, entry, current_env, tenant_key) do
    params = %{"env" => entry.environment_key || current_env}
    params = if tenant_key, do: Map.put(params, "tenant", tenant_key), else: params
    "#{mount_path}/#{entry.flag_key}/rules?#{URI.encode_query(params)}"
  end

  defp humanize_preview_basis("authored_state_and_explicit_samples"),
    do: "Authored state and explicit samples"

  defp humanize_preview_basis("authored_state_with_host_evidence"),
    do: "Authored state with host-supplied evidence"

  defp humanize_preview_basis("authored_state_host_evidence_unavailable"),
    do: "Authored state (host evidence unavailable)"

  defp humanize_preview_basis(other), do: other || "unknown"

  defp uncertainty_message(preview) do
    case fetch_preview(preview, :uncertainty) do
      %{} = uncertainty ->
        Map.get(uncertainty, :message) || Map.get(uncertainty, "message")

      _ ->
        nil
    end
    |> case do
      nil -> "authored-state and explicit-sample preview only"
      message when is_binary(message) -> message
      _ -> nil
    end
  end

  defp fetch_preview(preview, key) when is_map(preview) do
    Map.get(preview, key) || Map.get(preview, to_string(key))
  end

  defp fetch_preview(_preview, _key), do: nil

  defp sample_evidence_list(preview) do
    preview |> fetch_preview(:sample_evidence) |> List.wrap()
  end

  defp impression_evidence_map(preview) do
    case fetch_preview(preview, :impression_evidence) do
      %{} = map -> map
      _ -> %{}
    end
  end

  defp display_samples(samples) when is_list(samples) do
    visible = Enum.take(samples, @sample_display_limit)
    remaining = max(length(samples) - length(visible), 0)
    {visible, remaining}
  end

  defp sample_row(row) when is_map(row) do
    %{
      actor_key: fetch_preview(row, :actor_key) || "—",
      targeting_key: fetch_preview(row, :targeting_key) || "—",
      matched?:
        format_matched?(
          fetch_preview(row, :matched?) || Map.get(row, "matched?")
        ),
      reason: fetch_preview(row, :reason) || "—"
    }
  end

  defp format_matched?(true), do: "Yes"
  defp format_matched?(false), do: "No"
  defp format_matched?(_), do: "—"

  defp impression_field(impression, key) do
    fetch_preview(impression, key)
  end

  defp variant_breakdown_list(impression) do
    case fetch_preview(impression, :variant_breakdown) do
      list when is_list(list) -> list
      _ -> []
    end
  end

  defp variant_entry_label(entry) when is_map(entry) do
    fetch_preview(entry, :variant) || fetch_preview(entry, "variant") || "—"
  end

  defp variant_entry_count(entry) when is_map(entry) do
    fetch_preview(entry, :count) || fetch_preview(entry, "count") || "—"
  end

  defp scope_key(scope, key) when is_map(scope), do: Map.get(scope, key) || Map.get(scope, to_string(key)) || "—"
  defp scope_key(_scope, _key), do: "—"

  defp policy_denied?(entry) do
    get_in(entry, [:visibility, :reason]) == "policy_denied" ||
      get_in(entry, ["visibility", "reason"]) == "policy_denied"
  end

  defp visible_flag_key?(key), do: is_binary(key) and key != "" and not redacted_flag_key?(key)
  defp redacted_flag_key?("[REDACTED]"), do: true
  defp redacted_flag_key?(_), do: false
end
