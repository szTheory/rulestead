defmodule Mix.Tasks.Rulestead.Lifecycle do
  @moduledoc false

  use Mix.Task

  @shortdoc "Reports lifecycle and archive-readiness guidance for flags"
  @schema_version 1
  @switches [
    env: :string,
    query: :string,
    owner: :string,
    tags: :string,
    lifecycle: :string,
    stale: :string,
    readiness: :string,
    evidence_quality: :string,
    include_archived: :boolean,
    limit: :integer,
    format: :string
  ]
  @allowed_filter_atoms %{
    lifecycle: ~w(active potentially_stale stale archived)a,
    stale: ~w(fresh potentially_stale stale)a,
    readiness: ~w(keep_active needs_review archive_candidate)a,
    evidence_quality: ~w(strong partial weak)a
  }

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)

    opts
    |> compute_report()
    |> emit(Keyword.get(opts, :format, "text"))
  end

  def compute_report(opts) do
    normalized = normalize_opts(opts)

    case Rulestead.list_flags(list_opts(normalized)) do
      {:ok, page} ->
        %{
          "schema_version" => @schema_version,
          "format_version" => @schema_version,
          "generated_at" =>
            DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
          "filters" => filter_payload(normalized),
          "count" => length(page.entries),
          "entries" => Enum.map(page.entries, &entry_payload/1)
        }

      {:error, %Rulestead.Error{} = error} ->
        Mix.raise(error.message)
    end
  end

  defp emit(report, "json"), do: IO.write(Jason.encode!(report, pretty: true) <> "\n")
  defp emit(report, _format), do: Mix.shell().info(render_text(report))

  defp render_text(report) do
    header = [
      "Lifecycle report",
      "Environment: #{report["filters"]["env"] || "all"}",
      "Count: #{report["count"]}"
    ]

    entries =
      Enum.map(report["entries"], fn entry ->
        [
          "",
          "* #{entry["flag_key"]} [#{entry["archive_readiness"]["readiness"]} / #{entry["archive_readiness"]["evidence_quality"]}]",
          "  lifecycle: #{entry["lifecycle"]["state"]}",
          "  owner: #{entry["owner"]}",
          "  code references: #{entry["freshness"]["code_references"]}",
          "  evaluation evidence: #{entry["freshness"]["evaluation"]}",
          "  primary action: #{entry["archive_readiness"]["recommended_next_action"] || "none"}",
          "  reasons: #{render_list(entry["archive_readiness"]["reasons"])}",
          "  unknowns: #{render_list(entry["archive_readiness"]["unknowns"])}",
          "  blockers: #{render_list(entry["archive_readiness"]["blockers"])}",
          "  scan receipt: #{render_scan(entry["freshness"]["code_refs_scan"])}"
        ]
        |> Enum.join("\n")
      end)

    ([Enum.join(header, "\n")] ++ entries)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise(read_only_usage())
    end

    format = Keyword.get(opts, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("rulestead.lifecycle supports only --format text|json")
    end
  end

  defp read_only_usage do
    "usage: mix rulestead.lifecycle [--env <environment_key>] [--query <text>] [--owner <owner>] [--tags <tag1,tag2>] [--lifecycle <state>] [--stale <freshness>] [--readiness <state>] [--evidence-quality <state>] [--include-archived] [--limit <n>] [--format text|json]\nThis task is read-only and does not support plan/apply or archive mutation flags."
  end

  defp normalize_opts(opts) do
    %{
      env: blank_to_nil(Keyword.get(opts, :env)),
      query: blank_to_nil(Keyword.get(opts, :query)),
      owner: blank_to_nil(Keyword.get(opts, :owner)),
      tags: blank_to_nil(Keyword.get(opts, :tags)),
      lifecycle: normalize_filter_atom(:lifecycle, Keyword.get(opts, :lifecycle)),
      stale: normalize_filter_atom(:stale, Keyword.get(opts, :stale)),
      readiness: normalize_filter_atom(:readiness, Keyword.get(opts, :readiness)),
      evidence_quality:
        normalize_filter_atom(:evidence_quality, Keyword.get(opts, :evidence_quality)),
      include_archived?: Keyword.get(opts, :include_archived, false),
      limit: Keyword.get(opts, :limit, 25)
    }
  end

  defp list_opts(opts) do
    [
      environment_key: opts.env,
      query: opts.query,
      owner: opts.owner,
      tags: split_tags(opts.tags),
      lifecycle: opts.lifecycle,
      stale: opts.stale,
      readiness: opts.readiness,
      evidence_quality: opts.evidence_quality,
      include_archived?: opts.include_archived?,
      limit: opts.limit
    ]
  end

  defp filter_payload(opts) do
    %{
      "env" => opts.env,
      "query" => opts.query,
      "owner" => opts.owner,
      "tags" => split_tags(opts.tags),
      "lifecycle" => atom_string(opts.lifecycle),
      "stale" => atom_string(opts.stale),
      "readiness" => atom_string(opts.readiness),
      "evidence_quality" => atom_string(opts.evidence_quality),
      "include_archived" => opts.include_archived?,
      "limit" => opts.limit
    }
  end

  defp entry_payload(entry) do
    %{
      "flag_key" => entry.flag.key,
      "owner" => entry.flag.ownership.owner_ref,
      "environment_key" => entry.environment_key,
      "lifecycle" => %{
        "state" => atom_string(entry.lifecycle.state),
        "mode" => atom_string(entry.lifecycle.mode),
        "review_by" => date_string(entry.lifecycle.review_by)
      },
      "freshness" => %{
        "evaluation" => atom_string(entry.lifecycle.freshness.evaluation),
        "code_references" => atom_string(entry.lifecycle.freshness.code_references),
        "code_refs_scan" => scan_payload(entry.lifecycle.freshness.code_refs_scan)
      },
      "archive_readiness" => %{
        "readiness" => atom_string(entry.lifecycle.archive_readiness.readiness),
        "evidence_quality" => atom_string(entry.lifecycle.archive_readiness.evidence_quality),
        "reasons" => Enum.map(entry.lifecycle.archive_readiness.reasons, &atom_string/1),
        "unknowns" => Enum.map(entry.lifecycle.archive_readiness.unknowns, &atom_string/1),
        "blockers" => Enum.map(entry.lifecycle.archive_readiness.blockers, &atom_string/1),
        "recommended_next_action" =>
          atom_string(entry.lifecycle.archive_readiness.recommended_next_action),
        "secondary_actions" =>
          Enum.map(entry.lifecycle.archive_readiness.secondary_actions, &atom_string/1)
      }
    }
  end

  defp scan_payload(nil), do: nil

  defp scan_payload(%{received_at: received_at, reference_count: reference_count}) do
    %{
      "received_at" => datetime_string(received_at),
      "reference_count" => reference_count
    }
  end

  defp render_scan(nil), do: "none"

  defp render_scan(%{"received_at" => received_at, "reference_count" => reference_count}) do
    "#{received_at} (#{reference_count} references)"
  end

  defp render_list([]), do: "none"
  defp render_list(values), do: Enum.join(values, ", ")

  defp split_tags(nil), do: []

  defp split_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_filter_atom(_field, nil), do: nil

  defp normalize_filter_atom(field, value) when is_atom(value),
    do: normalize_filter_atom(field, Atom.to_string(value))

  defp normalize_filter_atom(field, value) when is_binary(value) do
    value
    |> blank_to_nil()
    |> case do
      nil ->
        nil

      normalized ->
        allowed = Map.fetch!(@allowed_filter_atoms, field)

        case Enum.find(allowed, &(Atom.to_string(&1) == normalized)) do
          nil ->
            Mix.raise(
              "invalid --#{String.replace(to_string(field), "_", "-")} value: #{normalized}"
            )

          atom ->
            atom
        end
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp atom_string(nil), do: nil
  defp atom_string(value) when is_atom(value), do: Atom.to_string(value)
  defp atom_string(value), do: to_string(value)

  defp date_string(nil), do: nil
  defp date_string(%Date{} = date), do: Date.to_iso8601(date)
  defp date_string(value), do: to_string(value)

  defp datetime_string(nil), do: nil
  defp datetime_string(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp datetime_string(value), do: to_string(value)
end
