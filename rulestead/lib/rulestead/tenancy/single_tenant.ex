defmodule Rulestead.Tenancy.SingleTenant do
  @moduledoc """
  Default single-tenant seam implementation.

  Always resolves a `nil` tenant scope, allows all operations as `same_tenant?`,
  and returns the unmodified base topic for PubSub operations.
  """

  @behaviour Rulestead.Tenancy

  @impl true
  def resolve_tenant(_input), do: nil

  @impl true
  def same_tenant?(_a, _b), do: true

  @impl true
  def tenant_topic(base_topic, _tenant), do: base_topic

  @impl true
  def compose_bucket_identity(_context, _bucket_by, default_identity), do: default_identity
end
