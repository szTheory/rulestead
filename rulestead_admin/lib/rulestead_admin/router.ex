defmodule RulesteadAdmin.Router do
  @moduledoc false

  defmacro rulestead_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      raise ArgumentError,
            "rulestead_admin: admin UI ships in Phases 6-7 of v0.1.0; track progress at ../../.planning/ROADMAP.md"
    end
  end
end
