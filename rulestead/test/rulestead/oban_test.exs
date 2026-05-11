unless Code.ensure_loaded?(Oban.Job) do
  defmodule Oban.Job do
    defstruct args: %{}, meta: %{}, worker: nil
  end
end

defmodule Rulestead.ObanTest do
  use ExUnit.Case, async: true

  alias Rulestead.Context
  alias Rulestead.Oban, as: RulesteadOban
  alias Rulestead.Oban.Middleware

  defmodule ExampleWorker do
    use Rulestead.Oban.Worker
  end

  test "context_from_job/1 rebuilds context only from serialized job payload" do
    Process.put(
      :rulestead_context,
      Context.new(targeting_key: "ambient-user", environment: "ambient")
    )

    job = %Oban.Job{
      args: %{
        "task" => "ship",
        "rulestead_context" => %{
          "actor" => %{"id" => "worker-1"},
          "targeting_key" => "job-user",
          "tenant_key" => "tenant-9",
          "environment" => "prod",
          "attributes" => %{"queue" => "critical"},
          "request_id" => "req-job",
          "session_id" => "session-job",
          "strict?" => true
        }
      }
    }

    context = RulesteadOban.context_from_job(job)

    assert %Context{} = context
    assert context.targeting_key == "job-user"
    assert context.environment == "prod"
    assert context.tenant_key == "tenant-9"
    assert context.request_id == "req-job"
    assert context.session_id == "session-job"
    assert context.attributes == %{"queue" => "critical"}
    assert context.strict? == true
  after
    Process.delete(:rulestead_context)
  end

  test "middleware attaches serialized context and worker macro exposes recovery without boilerplate" do
    context =
      Context.new(
        actor: %{id: "system:oban"},
        targeting_key: "job-user",
        tenant_key: "tenant-1",
        environment: "prod",
        attributes: %{"source" => "checkout"},
        request_id: "req-oban",
        session_id: "session-oban",
        strict?: true
      )

    job = %Oban.Job{args: %{"task" => "send_email"}, worker: "MyApp.Worker"}

    attached_job = Middleware.attach(job, context: context)

    assert attached_job.args["rulestead_context"]["targeting_key"] == "job-user"
    assert attached_job.args["rulestead_context"]["environment"] == "prod"
    assert ExampleWorker.rulestead_context(attached_job) == context
    assert ExampleWorker.context_from_job(attached_job) == context
  end
end
