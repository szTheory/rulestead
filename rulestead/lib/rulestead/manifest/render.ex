defmodule Rulestead.Manifest.Render do
  @moduledoc false

  alias Rulestead.Manifest.Result

  @spec render_text(map()) :: String.t()
  def render_text(result) do
    summary_lines =
      result["summary"]
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {key, value} -> "#{key}: #{format_value(value)}" end)

    finding_lines =
      result["findings"]
      |> Result.sort_findings()
      |> Enum.map(fn finding ->
        base = "[#{finding["severity"]}] #{finding["code"]} (#{finding["scope"]})"

        case finding["message"] do
          nil -> base
          message -> base <> " #{message}"
        end
      end)

    [
      "status: #{result["status"]}",
      "command: #{result["command"]}"
      | summary_lines ++
          if(finding_lines == [], do: [], else: ["findings:" | finding_lines])
    ]
    |> Enum.join("\n")
  end

  @spec render_json(map()) :: String.t()
  def render_json(result), do: encode_json(result)

  defp format_value(value) when is_list(value), do: Enum.join(value, ",")
  defp format_value(value), do: to_string(value)

  defp encode_json(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), encode_json(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join(",", fn {key, value} -> Jason.encode!(key) <> ":" <> value end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp encode_json(list) when is_list(list) do
    "[" <> Enum.map_join(list, ",", &encode_json/1) <> "]"
  end

  defp encode_json(value) when is_binary(value), do: Jason.encode!(value)
  defp encode_json(value) when is_boolean(value), do: Jason.encode!(value)
  defp encode_json(value) when is_integer(value), do: Jason.encode!(value)
  defp encode_json(value) when is_float(value), do: Jason.encode!(value)
  defp encode_json(nil), do: "null"
end
