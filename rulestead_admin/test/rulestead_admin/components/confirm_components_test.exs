defmodule RulesteadAdmin.Components.ConfirmComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Components.ConfirmComponents

  defp render_confirm(assigns) do
    assigns =
      Map.merge(
        %{
          submit_event: "apply",
          submit_label: "Apply update",
          evidence: [],
          extra_fields: []
        },
        assigns
      )

    render_component(&ConfirmComponents.mutation_confirm/1, assigns)
  end

  test "renders a primary confirm with a required reason and the submit label" do
    html = render_confirm(%{reason_value: "Promoting checkout"})

    assert html =~ "rs-mutation-confirm"
    assert html =~ ~s(phx-submit="apply")
    assert html =~ "rs-button--primary"
    assert html =~ "Apply update"
    assert html =~ ~s(name="reason")
    assert html =~ "Promoting checkout"
    refute html =~ "rs-button--danger"
  end

  test "danger? swaps the submit to a danger button and tints the form" do
    html = render_confirm(%{danger?: true, submit_label: "Archive audience"})

    assert html =~ "rs-button--danger"
    assert html =~ ~s(data-danger="true")
    refute html =~ "rs-button--primary"
  end

  test "renders the scope line and a back link when provided" do
    html =
      render_confirm(%{
        scope: %{environment: "production", tenant: "acme", fingerprint: "abc123"},
        back_href: "/admin/flags/audiences/vip/edit/preview",
        back_label: "Back to preview"
      })

    assert html =~ "rs-mutation-confirm__scope"
    assert html =~ "production"
    assert html =~ "acme"
    assert html =~ "abc123"
    assert html =~ "Back to preview"
    assert html =~ "/admin/flags/audiences/vip/edit/preview"
  end
end
