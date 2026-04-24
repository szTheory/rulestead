defmodule Rulestead.CredoFixtures.MutationOutsideMulti do
  alias Rulestead.Flag
  alias Rulestead.Repo

  def write do
    Repo.insert(%Flag{})
  end
end
