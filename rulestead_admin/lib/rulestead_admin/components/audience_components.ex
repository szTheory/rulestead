defmodule RulesteadAdmin.Components.AudienceComponents do
  @moduledoc false

  use Phoenix.Component

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
    ~H"""
    <section class="rs-card" aria-label="Impact preview">
      <h2>Impact preview</h2>
      <p><strong>Preview basis:</strong> <%= humanize_preview_basis(@preview.preview_basis) %></p>
      <p :if={@preview.uncertainty && @preview.uncertainty[:authoritative_population_count?] == false}>
        Population impact is estimated from authored references and explicit samples only.
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

  defp humanize_preview_basis(other), do: other || "unknown"

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
