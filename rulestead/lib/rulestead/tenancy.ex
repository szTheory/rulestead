defmodule Rulestead.Tenancy do
  @moduledoc """
  Explicit seam for resolving and bounding tenant scope across runtime helpers.
  """

  @type tenant_scope :: String.t() | atom() | nil

  @callback resolve_tenant(conn_or_socket_or_params :: term()) :: tenant_scope()
  @callback same_tenant?(a :: tenant_scope(), b :: tenant_scope()) :: boolean()
  @callback tenant_topic(base_topic :: String.t(), tenant :: tenant_scope()) :: String.t()
  @callback compose_bucket_identity(
              context :: Rulestead.Context.t(),
              bucket_by :: atom() | String.t(),
              default_identity :: String.t() | nil
            ) :: String.t() | nil

  @spec module() :: module()
  def module do
    config = Rulestead.Config.load()
    get_in(config, [:tenancy, :module]) || Rulestead.Tenancy.SingleTenant
  end

  @spec resolve_tenant(term()) :: tenant_scope()
  def resolve_tenant(input) do
    module().resolve_tenant(input) |> normalize_tenant()
  end

  @spec same_tenant?(tenant_scope(), tenant_scope()) :: boolean()
  def same_tenant?(a, b) do
    module().same_tenant?(normalize_tenant(a), normalize_tenant(b))
  end

  @spec tenant_topic(String.t(), tenant_scope()) :: String.t()
  def tenant_topic(base_topic, tenant) do
    module().tenant_topic(base_topic, normalize_tenant(tenant))
  end

  @spec compose_bucket_identity(Rulestead.Context.t(), atom() | String.t(), String.t() | nil) ::
          String.t() | nil
  def compose_bucket_identity(context, bucket_by, default_identity) do
    module().compose_bucket_identity(context, bucket_by, default_identity)
  end

  @spec normalize_tenant(term()) :: tenant_scope()
  def normalize_tenant(nil), do: nil
  def normalize_tenant(""), do: nil
  def normalize_tenant(value) when is_binary(value) or is_atom(value), do: value
  def normalize_tenant(_), do: nil
end
