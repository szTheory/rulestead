defmodule RulesteadAdmin.Components.FlagComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Components.FlagComponents

  test "pagination is hidden when there is no previous or next page" do
    html =
      render_component(&FlagComponents.pagination/1,
        page: %{entries: [%{id: 1}]},
        prev_path: nil,
        next_path: nil
      )

    refute html =~ "rs-pagination"
    refute html =~ "Next page"
    refute html =~ "Previous page"
  end

  test "pagination renders only available cursor directions" do
    html =
      render_component(&FlagComponents.pagination/1,
        page: %{entries: [%{id: 1}, %{id: 2}]},
        prev_path: "/admin/flags/flags?before=prev&env=prod&view=all",
        next_path: nil
      )

    assert html =~ "rs-pagination"
    assert html =~ "Previous page"
    refute html =~ "Showing"
    refute html =~ "Next page"
  end
end
