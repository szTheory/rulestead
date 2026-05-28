# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.Shared do
  @moduledoc false

  alias Phoenix.LiveView.Socket
  alias RulesteadAdmin.Live.Session

  @spec mount_path(Socket.t() | map()) :: String.t()
  def mount_path(socket_or_assigns), do: fetch_mount_path(socket_or_assigns)

  @spec audience_base(Socket.t() | map(), String.t()) :: String.t()
  def audience_base(socket_or_assigns, audience_key),
    do: "#{fetch_mount_path(socket_or_assigns)}/audiences/#{audience_key}"

  @spec path(Socket.t() | map(), String.t()) :: String.t()
  def path(socket_or_assigns, suffix),
    do: Session.current_path(socket_or_assigns, "#{fetch_mount_path(socket_or_assigns)}#{suffix}")

  @spec scope_opts(Socket.t()) :: keyword()
  def scope_opts(socket) do
    []
    |> maybe_put(:environment_key, socket.assigns.current_environment.key)
    |> maybe_put(:tenant_key, tenant_key(socket))
    |> maybe_put(:actor, socket.assigns.current_actor)
  end

  @spec dependency_command(Socket.t(), String.t(), keyword()) :: keyword()
  def dependency_command(socket, audience_key, extra \\ []) do
    [
      audience_key: audience_key,
      include_redacted_placeholders?: true,
      limit: 100,
      offset: 0
    ]
    |> Keyword.merge(scope_opts(socket))
    |> Keyword.merge(extra)
  end

  @spec dependency_summary(map()) :: String.t()
  def dependency_summary(%{reference_count: count, hidden_reference_count: hidden})
      when hidden > 0,
      do: "Used by #{count} authored references (#{hidden} hidden by your permissions)"

  def dependency_summary(%{reference_count: count}), do: "Used by #{count} authored references"
  def dependency_summary(_), do: "Used by 0 authored references"

  @spec humanize(atom() | String.t() | nil) :: String.t()
  def humanize(nil), do: "unknown"
  def humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  def humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  @spec query_params(String.t()) :: map()
  def query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  @spec drift_message(String.t() | nil) :: String.t() | nil
  def drift_message("true"),
    do: "Authored state changed since preview — review the latest impact evidence."

  def drift_message(_), do: nil

  @spec stale_preview_error?(term()) :: boolean()
  def stale_preview_error?(%{message: message}) when is_binary(message),
    do: String.contains?(String.downcase(message), "preview")

  def stale_preview_error?(_), do: false

  defp tenant_key(socket) do
    socket.assigns.current_tenant && socket.assigns.current_tenant.key
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp fetch_mount_path(%Socket{} = socket), do: socket.assigns.rulestead_admin_mount_path
  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
end
