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

  test "typed confirmation renders before the reason field" do
    html =
      render_confirm(%{
        typed_confirmation_label: "Type production flag key",
        typed_confirmation_value: "checkout-flow",
        typed_confirmation_required: true,
        typed_confirmation_help: "Production archive requires the exact key."
      })

    assert html =~ "Type production flag key"
    assert html =~ ~s(name="confirmation")
    assert html =~ ~s(value="checkout-flow")
    assert html =~ "Production archive requires the exact key."

    {typed_position, _} = :binary.match(html, "Type production flag key")
    {reason_position, _} = :binary.match(html, "Reason (required)")

    assert typed_position < reason_position
  end

  test "disabled and unavailable states explain why controls cannot proceed" do
    html =
      render_confirm(%{
        submit_label: "Unavailable action",
        unavailable_reason: "Host evidence is stale. Refresh the preview before mutating.",
        back_href: "/admin/flags/checkout/cleanup/preview",
        back_label: "Return to preview"
      })

    assert html =~ ~s(data-state="unavailable")
    assert html =~ "Action unavailable"
    assert html =~ "Host evidence is stale. Refresh the preview before mutating."
    assert html =~ "Return to preview"
    assert html =~ ~s(disabled)
    assert html =~ "Unavailable action"

    disabled_html =
      render_confirm(%{
        disabled?: true,
        disabled_reason: "A reviewer must approve the change request first."
      })

    assert disabled_html =~ ~s(data-state="disabled")
    assert disabled_html =~ "Action disabled"
    assert disabled_html =~ "A reviewer must approve the change request first."
  end

  test "read-only states distinguish policy review from unavailable actions" do
    html =
      render_confirm(%{
        read_only?: true,
        read_only_reason: "Your role can inspect this audience but cannot mutate it.",
        back_href: "/admin/flags/audiences/vip"
      })

    assert html =~ ~s(data-state="read-only")
    assert html =~ "Read-only action"
    assert html =~ "Your role can inspect this audience but cannot mutate it."
    assert html =~ "/admin/flags/audiences/vip"
    assert html =~ ~s(disabled)
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
