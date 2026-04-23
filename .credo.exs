%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: [
          "{mix,.formatter}.exs",
          "rulestead/{config,lib,test}/**/*.{ex,exs}",
          "rulestead_admin/{config,lib,test}/**/*.{ex,exs}"
        ],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      requires: []
    }
  ]
}
