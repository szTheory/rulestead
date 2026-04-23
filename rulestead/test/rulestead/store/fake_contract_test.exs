defmodule Rulestead.Store.FakeContractTest do
  use Rulestead.StoreContractCase,
    store: Rulestead.Fake,
    control: Rulestead.Fake.Control

  store_contract_tests()
end
