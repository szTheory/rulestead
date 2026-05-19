[
  # Mix Tasks external deps and no returns
  {"lib/mix/tasks/rulestead.diff.ex", :no_return},
  {"lib/mix/tasks/rulestead.import.ex", :no_return},
  {"lib/mix/tasks/rulestead.promote.ex", :no_return},
  {"lib/mix/tasks/rulestead.validate.ex", :no_return},
  {"lib/mix/tasks/verify.release_parity.ex", :no_return},

  # Credo custom checks using external Credo modules not in PLT
  {"lib/rulestead/credo/no_eval_outside_context.ex", :callback_info_missing},
  {"lib/rulestead/credo/no_eval_outside_context.ex", :unknown_function},
  {"lib/rulestead/credo/no_mutation_outside_multi.ex", :callback_info_missing},
  {"lib/rulestead/credo/no_mutation_outside_multi.ex", :unknown_function},
  {"lib/rulestead/credo/no_raw_traits_in_logger.ex", :callback_info_missing},
  {"lib/rulestead/credo/no_raw_traits_in_logger.ex", :unknown_function},
  {"lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex", :callback_info_missing},
  {"lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex", :unknown_function},
  {"lib/rulestead/credo/no_socket_captured_in_async.ex", :callback_info_missing},
  {"lib/rulestead/credo/no_socket_captured_in_async.ex", :unknown_function},

  # Ecto Multi opaqueness and complex pattern match warnings
  {"lib/rulestead/store/ecto.ex", :call_without_opaque},
  {"lib/rulestead/webhooks/code_refs_plug.ex", :call_without_opaque},

  # Unfixable pattern match and type warnings
  {"lib/rulestead/fake.ex", :pattern_match},
  {"lib/rulestead/oban.ex", :pattern_match},
  {"lib/rulestead/oban/scheduled_execution_worker.ex", :pattern_match_cov},
  {"lib/rulestead/oban/webhook_delivery_worker.ex", :extra_range},
  {"lib/rulestead/promotion/apply.ex", :pattern_match_cov},
  {"lib/rulestead/runtime/backup/file_store.ex", :pattern_match_cov},
  {"lib/rulestead/runtime/cluster_case.ex", :missing_range},
  {"lib/rulestead/runtime/cluster_case.ex", :call},
  {"lib/rulestead/runtime/refresh.ex", :pattern_match_cov},
  {"lib/rulestead/telemetry.ex", :extra_range}
]