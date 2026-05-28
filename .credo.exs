fixture_probe? =
  System.argv()
  |> Enum.any?(&String.contains?(&1, "test/support/credo_fixtures/"))

local_check_files =
  [
    {Rulestead.Credo.NoRawTraitsInTelemetryMeta, "lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex"},
    {Rulestead.Credo.NoRawTraitsInLogger, "lib/rulestead/credo/no_raw_traits_in_logger.ex"},
    {Rulestead.Credo.NoMutationOutsideMulti, "lib/rulestead/credo/no_mutation_outside_multi.ex"},
    {Rulestead.Credo.NoSocketCapturedInAsync, "lib/rulestead/credo/no_socket_captured_in_async.ex"},
    {Rulestead.Credo.NoEvalOutsideContext, "lib/rulestead/credo/no_eval_outside_context.ex"}
  ]

local_check_requires =
  Enum.flat_map(local_check_files, fn {module, path} ->
    if Code.ensure_loaded?(module), do: [], else: [path]
  end)

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
        excluded:
          [~r"/_build/", ~r"/deps/"] ++
            if(fixture_probe?, do: [], else: [~r"/test/support/credo_fixtures/"])
      },
      requires: local_check_requires,
      checks: [
        # Reason: contract tests call Rulestead.Fake.Control and similar nested
        # modules inline; per-file aliases add noise without safety gain.
        # Tracking: permanent (mailglass .credo.exs parity)
        {Credo.Check.Design.AliasUsage, false},
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
