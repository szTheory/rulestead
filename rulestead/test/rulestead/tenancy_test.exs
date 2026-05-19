defmodule Rulestead.TenancyTest do
  use ExUnit.Case, async: false

  alias Rulestead.Tenancy

  describe "normalize_tenant/1" do
    test "normalizes nil to nil" do
      assert Tenancy.normalize_tenant(nil) == nil
    end

    test "normalizes empty string to nil" do
      assert Tenancy.normalize_tenant("") == nil
    end

    test "keeps binary and atom values intact" do
      assert Tenancy.normalize_tenant("acme_corp") == "acme_corp"
      assert Tenancy.normalize_tenant(:acme_corp) == :acme_corp
    end

    test "normalizes unexpected types to nil" do
      assert Tenancy.normalize_tenant(%{id: 1}) == nil
      assert Tenancy.normalize_tenant(123) == nil
    end
  end

  describe "SingleTenant defaults" do
    test "resolve_tenant returns nil" do
      assert Tenancy.resolve_tenant(%{any: "input"}) == nil
    end

    test "same_tenant? always returns true" do
      assert Tenancy.same_tenant?(nil, nil) == true
      assert Tenancy.same_tenant?("tenant_a", "tenant_a") == true
      assert Tenancy.same_tenant?("tenant_a", "tenant_b") == true
    end

    test "tenant_topic returns base_topic unmodified" do
      assert Tenancy.tenant_topic("base", "any_tenant") == "base"
    end
  end
end
