%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: [
          "{mix,.formatter}.exs",
          "{config,lib,test}/**/*.{ex,exs}",
          "rulestead/{config,lib,test}/**/*.{ex,exs}",
          "../rulestead_admin/{config,lib,test}/**/*.{ex,exs}",
          "rulestead_admin/{config,lib,test}/**/*.{ex,exs}"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/test/support/credo_fixtures/"]
      },
      requires: [
        "lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex",
        "lib/rulestead/credo/no_raw_traits_in_logger.ex",
        "lib/rulestead/credo/no_mutation_outside_multi.ex",
        "lib/rulestead/credo/no_socket_captured_in_async.ex",
        "lib/rulestead/credo/no_eval_outside_context.ex"
      ],
      checks: [
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Design.TagFIXME, false},
        {Credo.Check.Warning.IoInspect, false},
        {Rulestead.Credo.NoRawTraitsInTelemetryMeta, []},
        {Rulestead.Credo.NoRawTraitsInLogger, []},
        {Rulestead.Credo.NoMutationOutsideMulti, []},
        {Rulestead.Credo.NoSocketCapturedInAsync, []},
        {Rulestead.Credo.NoEvalOutsideContext, []}
      ]
    }
  ]
}
