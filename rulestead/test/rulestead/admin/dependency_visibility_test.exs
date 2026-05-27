defmodule Rulestead.Admin.DependencyVisibilityTest do
  use ExUnit.Case, async: true

  alias Rulestead.Admin.DependencyVisibility

  defmodule AllowReadFlagsPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, :read_flags, _resource, _environment_key), do: true

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def change_request_required?(_, _, _, _), do: false

    @impl true
    def allow_self_approval?(_, _, _, _), do: true
  end

  defmodule DenyReadFlagsPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, :read_flags, _resource, _environment_key), do: false

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def change_request_required?(_, _, _, _), do: false

    @impl true
    def allow_self_approval?(_, _, _, _), do: true
  end

  setup do
    previous = Application.get_env(:rulestead, :admin_policy)
    on_exit(fn -> restore_policy(previous) end)
    :ok
  end

  test "visibility_resolver allows entries when read_flags is permitted" do
    Application.put_env(:rulestead, :admin_policy, AllowReadFlagsPolicy)
    actor = %{id: "viewer", roles: [:viewer]}

    resolver = DependencyVisibility.visibility_resolver(actor)

    entry = %{flag_key: "checkout", environment_key: "test"}

  assert resolver.(entry)
  end

  test "visibility_resolver hides entries when read_flags is denied" do
    Application.put_env(:rulestead, :admin_policy, DenyReadFlagsPolicy)
    actor = %{id: "viewer", roles: [:viewer]}

    resolver = DependencyVisibility.visibility_resolver(actor)

    entry = %{flag_key: "checkout", environment_key: "test"}

    refute resolver.(entry)
  end

  defp restore_policy(nil), do: Application.delete_env(:rulestead, :admin_policy)
  defp restore_policy(value), do: Application.put_env(:rulestead, :admin_policy, value)
end
