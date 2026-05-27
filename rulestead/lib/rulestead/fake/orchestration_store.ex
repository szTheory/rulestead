defmodule Rulestead.Fake.OrchestrationStore do
  @moduledoc false

  @state_key {__MODULE__, :state}

  alias Rulestead.Fake
  alias Rulestead.Store.Command

  @spec put_state!(map()) :: :ok
  def put_state!(state), do: Process.put(@state_key, state)

  @spec pop_state!() :: map() | nil
  def pop_state!, do: Process.delete(@state_key)

  @spec fetch_guardrail_status(Command.FetchGuardrailStatus.t()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def fetch_guardrail_status(command) do
    with_state(&Fake.fetch_guardrail_status_in_state/2, command)
  end

  @spec fetch_rollout_auto_advance_policy(Command.FetchRolloutAutoAdvancePolicy.t()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def fetch_rollout_auto_advance_policy(command) do
    case with_state(&Fake.fetch_rollout_auto_advance_policy_in_state/2, command) do
      {:ok, policy} -> {:ok, %{policy: policy}}
      other -> other
    end
  end

  @spec fetch_flag(Command.FetchFlag.t()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def fetch_flag(command), do: with_state(&Fake.fetch_flag_in_state/2, command)

  @spec evaluate_rollout_auto_advance(Command.EvaluateRolloutAutoAdvance.t()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def evaluate_rollout_auto_advance(command) do
    case with_state(&Fake.evaluate_rollout_auto_advance_in_state/2, command) do
      {:ok, eligibility} -> {:ok, %{eligibility: eligibility}}
      other -> other
    end
  end

  @spec submit_change_request(Command.SubmitChangeRequest.t()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def submit_change_request(command) do
    case with_state_update(&Fake.submit_change_request_in_state/2, command) do
      {:ok, change_request, _state} -> {:ok, %{change_request: change_request}}
      {:error, error} -> {:error, error}
    end
  end

  defp with_state(fun, command) do
    case Process.get(@state_key) do
      nil ->
        {:error, Rulestead.StoreError.unavailable()}

      state ->
        fun.(state, command)
    end
  end

  defp with_state_update(fun, command) do
    case Process.get(@state_key) do
      nil ->
        {:error, Rulestead.StoreError.unavailable()}

      state ->
        case fun.(state, command) do
          {:ok, result, next_state} ->
            put_state!(next_state)
            {:ok, result, next_state}

          {:error, error} ->
            {:error, error}
        end
    end
  end
end
