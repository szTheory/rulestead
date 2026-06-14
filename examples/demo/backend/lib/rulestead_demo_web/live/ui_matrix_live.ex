defmodule RulesteadDemoWeb.UiMatrixLive do
  @moduledoc false

  use RulesteadDemoWeb, :live_view

  alias RulesteadAdmin.Components.AudienceComponents
  alias RulesteadAdmin.Components.AudienceTraceComponents
  alias RulesteadAdmin.Components.AuditComponents
  alias RulesteadAdmin.Components.ConfirmComponents
  alias RulesteadAdmin.Components.FlagComponents
  alias RulesteadAdmin.Components.GovernanceComponents
  alias RulesteadAdmin.Components.OperatorComponents
  alias RulesteadAdmin.Components.RolloutComponents
  alias RulesteadAdmin.Components.RuleEditorComponents
  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Components.SimulateComponents
  alias RulesteadDemoWeb.UiMatrixFixtures

  @impl true
  def mount(_params, _session, socket) do
    shell = UiMatrixFixtures.shell_assigns()
    rule_editor = UiMatrixFixtures.rule_editor_assigns()
    rollout = UiMatrixFixtures.rollout_assigns()

    socket =
      assign(socket,
        page_title: "Rulestead admin UI matrix",
        shell: shell,
        section_index: UiMatrixFixtures.section_index(),
        static_fixture_links: UiMatrixFixtures.static_fixture_links(),
        route_examples: UiMatrixFixtures.route_examples(),
        dense_records: UiMatrixFixtures.dense_records(),
        audit_entries: UiMatrixFixtures.audit_entries(),
        readable_diff_entry: UiMatrixFixtures.readable_diff_entry(),
        rule_editor: rule_editor,
        rollout: rollout,
        auto_advance: UiMatrixFixtures.auto_advance_assigns(),
        impact_preview: UiMatrixFixtures.impact_preview(),
        audience_dependencies: UiMatrixFixtures.audience_dependencies(),
        governance_assessment: UiMatrixFixtures.governance_assessment(),
        simulate_trace: UiMatrixFixtures.simulate_trace(),
        audience_trace_steps: UiMatrixFixtures.audience_trace_steps(),
        mutation_confirm: UiMatrixFixtures.mutation_confirm_assigns(:destructive),
        rare_state_examples: UiMatrixFixtures.rare_state_examples()
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Rulestead admin UI matrix"
      page_kicker="Design-system evidence"
      page_summary="Real admin components rendered with deterministic fixture assigns."
      breadcrumbs={@shell.breadcrumbs}
      current_environment={@shell.current_environment}
      environments={@shell.environments}
      env_options={@shell.env_options}
      current_tenant={@shell.current_tenant}
      tenants={@shell.tenants}
      tenant_links={@shell.tenant_links}
      base_path="/admin/flags"
      current_section={:home}
      policy_state={@shell.policy_state}
      flash={@shell.flash}
      theme_default="system"
    >
      <:header_actions>
        <a class="rs-button rs-button--primary" href="#overview-shell">Review Matrix Evidence</a>
      </:header_actions>

      <section class="rs-card" data-matrix-section="overview-shell" id="overview-shell">
        <h2>Rulestead admin UI matrix</h2>
        <p>
          This demo-hosted route renders real admin components with deterministic fixture assigns.
        </p>
        <OperatorComponents.summary_grid
          items={[
            %{title: "Sections", value: length(@section_index), tone: "neutral"},
            %{title: "Dense rows", value: length(@dense_records), tone: "warning"},
            %{title: "Fixture source", value: "UiMatrixFixtures", tone: "neutral"}
          ]}
          aria_label="Matrix summary"
        />
        <nav class="rs-related-links" aria-label="Matrix sections">
          <a :for={{section, label} <- @section_index} href={"##{section}"}>{label}</a>
        </nav>
      </section>

      <section class="rs-card" data-matrix-section="foundations-reference" id="foundations-reference">
        <h2>Foundations reference</h2>
        <OperatorComponents.detail_grid
          rows={[
            %{label: "Shell wrapper", value: "RulesteadAdmin.Components.Shell.page/1"},
            %{label: "Long flag key", value: UiMatrixFixtures.long_flag_key()},
            %{label: "Long audience key", value: UiMatrixFixtures.long_audience_key()},
            %{label: "Long reason", value: UiMatrixFixtures.long_reason()}
          ]}
        />
        <OperatorComponents.task_link
          title="Review Matrix Evidence"
          summary="Use this route for deterministic Phoenix and Playwright evidence before polish phases."
          href="#static-fixtures"
          tone="neutral"
          primary?
        />
      </section>

      <OperatorComponents.page_section
        title="Primitives"
        summary="Banners, rows, detail grids, task links, signals, empty states, badges, pagination, stats, cards, callouts, and subnav examples."
      >
        <section data-matrix-section="primitives" id="primitives">
          <OperatorComponents.banner
            title="Fixture-only matrix"
            body="No database, cache, environment, filesystem, or network data is read by this route."
            tone="neutral"
            aria_label="Fixture-only matrix notice"
          />
          <OperatorComponents.record_row
            title={UiMatrixFixtures.long_flag_key()}
            href="/admin/flags/enterprise-checkout-redesign-rollout-experiment-long-key-for-wrapping-proof"
            meta="Owner: Checkout Platform Reliability And Release Team With A Long Label"
            tone="warning"
          >
            <OperatorComponents.detail_grid
              rows={[
                %{label: "Environment", value: @shell.current_environment.name},
                %{label: "Tenant", value: @shell.current_tenant.name}
              ]}
            />
            <:actions>
              <FlagComponents.lifecycle_badge state={:active} />
              <FlagComponents.stale_badge state={:stale} last_evaluated_at="2026-06-14T03:00:00Z" />
            </:actions>
          </OperatorComponents.record_row>
          <div class="rs-summary-grid">
            <OperatorComponents.signal label="Guardrail" value="held" tone="warning" />
            <FlagComponents.stat title="References" value="12" tone="warning" />
            <FlagComponents.stat title="Denied examples" value="2" tone="critical" />
          </div>
          <FlagComponents.tag_list tags={["long-label", "keyboard", "focus", "read-only"]} />
          <FlagComponents.pagination
            page={%{limit: 25, has_previous_page?: true, has_next_page?: true, prev_cursor: "prev", next_cursor: "next"}}
            base_path="/admin/flags"
            params={%{"env" => "production-eu-central"}}
          />
          <FlagComponents.section_card title="Lifecycle and subnav">
            <FlagComponents.flag_sub_nav
              flag_key={UiMatrixFixtures.long_flag_key()}
              base_path="/admin/flags"
              env_key="production-eu-central"
              current={:rules}
              show_kill?
            />
          </FlagComponents.section_card>
          <FlagComponents.callout title="Unavailable dependency" tone="warning">
            <p>Host evidence is unavailable, so the action remains disabled until evidence is refreshed.</p>
          </FlagComponents.callout>
          <OperatorComponents.empty_state
            title="No matrix examples match this section"
            body="Add a deterministic fixture for the missing state before planning polish work for this bucket."
            icon="∅"
          >
            <:actions>
              <a class="rs-button rs-button--text" href="#rare-states">Inspect rare states</a>
            </:actions>
          </OperatorComponents.empty_state>
        </section>
      </OperatorComponents.page_section>

      <section class="rs-card" data-matrix-section="composites" id="composites">
        <h2>Composites</h2>
        <AudienceComponents.used_by_table
          dependencies={@audience_dependencies}
          mount_path="/admin/flags"
          environment_key="production-eu-central"
          tenant_key="tenant-enterprise-regional-long-name"
        />
        <AudienceComponents.impact_preview preview={@impact_preview} />
        <GovernanceComponents.blast_radius_panel
          assessment={@governance_assessment}
          variant={:reviewer}
          visibility={:full}
          environment_label="Production EU Central"
          frozen?
        >
          <:impact_preview>
            <p>Impact preview evidence is frozen for reviewer comparison.</p>
          </:impact_preview>
        </GovernanceComponents.blast_radius_panel>
      </section>

      <section class="rs-card" data-matrix-section="mutation-flows" id="mutation-flows">
        <h2>Mutation flows</h2>
        <ConfirmComponents.mutation_confirm {@mutation_confirm}>
          <:evidence>
            <p>Preview destructive fixture: Type the flag key before rendering the disabled or danger action example.</p>
          </:evidence>
          <:extra_fields>
            <label class="rs-form-field">
              <span>Type the flag key</span>
              <input type="text" value={UiMatrixFixtures.long_flag_key()} readonly />
            </label>
          </:extra_fields>
        </ConfirmComponents.mutation_confirm>
      </section>

      <section class="rs-card" data-matrix-section="dense-tables" id="dense-tables">
        <h2>Dense tables</h2>
        <OperatorComponents.record_row
          :for={record <- @dense_records}
          title={record.title}
          href={record.href}
          meta={record.meta}
          tone={record.tone}
        />
      </section>

      <section class="rs-card" data-matrix-section="timelines" id="timelines">
        <h2>Timelines</h2>
        <ol class="rs-event-timeline">
          <AuditComponents.timeline_item :for={entry <- @audit_entries} entry={entry} show_flag show_rollback />
        </ol>
        <AuditComponents.timeline_row entry={@readable_diff_entry} show_flag show_rollback />
        <AuditComponents.raw_detail entry={@readable_diff_entry} />
        <AuditComponents.diff_card entry={@readable_diff_entry} />
        <AuditComponents.readable_diff entry={@readable_diff_entry} />
      </section>

      <section class="rs-card" data-matrix-section="rule-editor" id="rule-editor">
        <h2>Rule editor</h2>
        <RuleEditorComponents.lifecycle_banner
          detail={@rule_editor.detail}
          editable?={@rule_editor.editable?}
          status_message={@rule_editor.status_message}
        />
        <RuleEditorComponents.validation_notices
          error_messages={@rule_editor.error_messages}
          editable?={@rule_editor.editable?}
        />
        <RuleEditorComponents.action_bar
          detail={@rule_editor.detail}
          editable?={@rule_editor.editable?}
          error_messages={@rule_editor.error_messages}
        />
        <RuleEditorComponents.audience_library audiences={@rule_editor.audiences} mount_path="/admin/flags" />
        <RuleEditorComponents.rule_card
          index={0}
          rule={@rule_editor.rule}
          audiences={@rule_editor.audiences}
          mount_path="/admin/flags"
          editable?={@rule_editor.editable?}
        />
        <RuleEditorComponents.audience_picker
          index={1}
          rule={@rule_editor.rule}
          audiences={@rule_editor.audiences}
          editable?={@rule_editor.editable?}
        />
        <RuleEditorComponents.condition_builder rule={@rule_editor.rule} />
        <RuleEditorComponents.variant_editor
          index={2}
          rule={@rule_editor.rule}
          editable?={@rule_editor.editable?}
        />
      </section>

      <section class="rs-card" data-matrix-section="rollout-panels" id="rollout-panels">
        <h2>Rollout panels</h2>
        <RolloutComponents.ladder
          steps={@rollout.ladder_steps}
          current={@rollout.current}
          selected={@rollout.selected}
        />
        <RolloutComponents.guardrail_status
          status={@rollout.guardrail_status}
          definitions={@rollout.guardrail_definitions}
          timeline_path="/admin/flags/enterprise-checkout-redesign-rollout-experiment-long-key-for-wrapping-proof/timeline"
        />
        <RolloutComponents.confirm_panel current={10} target={25} reason={UiMatrixFixtures.long_reason()} />
        <RolloutComponents.auto_advance_panel {@auto_advance} />
      </section>

      <section class="rs-card" data-matrix-section="command-palette" id="command-palette">
        <h2>Command palette</h2>
        <p>
          Shell command search renders from real navigation groups and includes keyboard-relevant options in <code>rs-cmdk</code>.
        </p>
        <OperatorComponents.task_link
          title="Open command palette with a long label for search wrapping proof"
          summary="Use Cmd/Ctrl+K or the shell search button."
          href="/admin/flags?env=production-eu-central"
          tone="neutral"
        />
      </section>

      <section class="rs-card" data-matrix-section="workflow-states" id="workflow-states">
        <h2>Workflow states</h2>
        <SimulateComponents.archetype_chips
          title="Simulation archetypes"
          archetypes={[
            %{id: "vip", label: "Enterprise VIP long label", summary: "Matches regional VIP"},
            %{id: "missing", label: "Missing host evidence", summary: "Unavailable dependency"}
          ]}
          selected_archetype={%{label: "Enterprise VIP long label", summary: "Matches regional VIP"}}
        />
        <SimulateComponents.fixture_export
          fixture_export={inspect(@simulate_trace, pretty: true)}
          environment_key="production-eu-central"
        />
        <SimulateComponents.trace_disclosure trace={@simulate_trace} />
        <AudienceTraceComponents.audience_trace_steps rule_traces={@audience_trace_steps} />
      </section>

      <section class="rs-card" data-matrix-section="rare-states" id="rare-states">
        <h2>Rare states</h2>
        <OperatorComponents.record_row
          :for={example <- @rare_state_examples}
          title={example.label}
          href="#rare-states"
          meta={example.summary}
          tone={if(example.state in [:error, :permission_denied, :destructive], do: "critical", else: "neutral")}
        >
          <p><code>{example.state}</code></p>
        </OperatorComponents.record_row>
      </section>

      <section class="rs-card" data-matrix-section="static-fixtures" id="static-fixtures">
        <h2>Static fixture links</h2>
        <p>Static fixtures remain low-level token, theme, contrast, and focus guards.</p>
        <OperatorComponents.task_link
          :for={link <- @static_fixture_links}
          title={link.label}
          summary="Supporting static guard fixture"
          href={link.path}
          tone="neutral"
        />
        <h3>Seeded route examples</h3>
        <OperatorComponents.task_link
          :for={route <- @route_examples}
          title={route.label}
          summary={route.path}
          href={route.path}
          tone="neutral"
        />
      </section>
    </Shell.page>
    """
  end
end
