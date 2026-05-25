defmodule Mix.Tasks.Rulestead.CodeRefs do
  @moduledoc false
  # Scans application code for Rulestead flag references and pushes them to the Rulestead API.

  # ## Examples

  #     mix rulestead.code_refs --token secret_token
  #     mix rulestead.code_refs --dir lib --url http://example.com/api/webhooks/rulestead/code_refs

  use Mix.Task

  alias Rulestead.CodeRefs.Scanner

  @shortdoc "Scans application code for Rulestead flag references and pushes them to the Rulestead API"

  @switches [dir: :string, url: :string, token: :string]

  @impl Mix.Task
  def run(args) do
    # Ensure dependencies are available (like Jason and Req/HTTPoison/inets)
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

    dir = Keyword.get(opts, :dir, "lib")

    url =
      Keyword.get(opts, :url) || System.get_env("RULESTEAD_API_URL") ||
        "http://localhost:4000/api/webhooks/rulestead/code_refs"

    token = Keyword.get(opts, :token) || System.get_env("RULESTEAD_CI_TOKEN")

    if is_nil(token) do
      Mix.raise(
        "A CI token is required. Pass --token <token> or set RULESTEAD_CI_TOKEN environment variable."
      )
    end

    shell = Mix.shell()
    shell.info("Scanning #{dir} for Rulestead flag references...")

    references = Scanner.scan_dir(dir)

    shell.info("Found #{length(references)} references. Pushing to #{url}...")

    payload = Jason.encode!(%{references: references})

    headers = [
      {~c"content-type", ~c"application/json"},
      {~c"authorization", String.to_charlist("Bearer #{token}")}
    ]

    case :httpc.request(
           :post,
           {String.to_charlist(url), headers, ~c"application/json", payload},
           [],
           []
         ) do
      {:ok, {{_, status_code, _}, _, _response_body}} when status_code in 200..299 ->
        shell.info("Successfully pushed references to Rulestead!")

      {:ok, {{_, status_code, _}, _, response_body}} ->
        Mix.raise(
          "Failed to push references. Server returned status #{status_code}: #{response_body}"
        )

      {:error, reason} ->
        Mix.raise("Failed to connect to Rulestead API: #{inspect(reason)}")
    end
  end
end
