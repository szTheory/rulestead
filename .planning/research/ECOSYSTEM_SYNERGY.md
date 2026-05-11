# Rulestead Ecosystem Synergy & Integration Opportunities

**Date:** 2026-05-11
**Context:** Research into high-leverage integration seams between Rulestead and the broader szTheory ecosystem (Parapet, Scoria, and Cairnloop). The goal is to maximize cross-library leverage using clean DDD boundaries, telemetry, and explicit protocol delegation, avoiding tight coupling.

## 1. Rulestead ⟷ Parapet (SRE & Reliability)

### The Synergy
Parapet acts as an SRE substrate that correlates deployments and configuration drifts with reliability regressions in Phoenix apps. Rulestead handles the dynamic configuration, feature flags, and kill-switches that are often the root cause of these regressions.

### Integration Seam: Erlang Telemetry
*   **Opportunity:** Rulestead should emit rigorous, predictable `:telemetry` events whenever a mutation occurs (e.g., `[:rulestead, :mutation, :executed]`, encompassing ruleset publishes, rollout advances, and kill-switch toggles).
*   **Leverage:** Parapet can natively listen to these events to draw vertical "Deploy/Change Markers" directly in generated Grafana dashboards. If latency spikes or error rates surge immediately after a Rulestead kill-switch is thrown, the operator immediately sees the correlation on the timeline without any direct dependency between the two libraries.

## 2. Rulestead ⟷ Scoria (AI Governance & Observability)

### The Synergy
Scoria manages AI agent tool execution, hit-in-the-loop (HITL) approvals, and trace logging. Rulestead is an engine for deterministic routing, targeted rollouts, and contextual gating.

### Integration Seams: MCP Tools & Context Bucketing
*   **Opportunity A (Rulestead as MCP Provider):** Rulestead's core admin APIs can be exposed as lightweight Model Context Protocol (MCP) tools. This empowers a Scoria-governed agent to query the current state of a feature flag or—if explicitly authorized via HITL—toggle an emergency kill-switch.
*   **Opportunity B (Scoria utilizing Rulestead):** Scoria can leverage Rulestead's deterministic evaluator to A/B test system prompts or dynamically route user requests to different foundational models (e.g., Claude vs. GPT-4) based on explicit user context (such as billing tier or role). Rulestead becomes the gating mechanism for risky AI tool usage, ensuring only users with `actor_role: "admin"` can trigger certain MCP tools.

## 3. Rulestead ⟷ Cairnloop (Support OS)

### The Synergy
Cairnloop handles customer support automation and AI-drafted responses within the host app. Rulestead dictates what features or automated capabilities are active.

### Integration Seam: Context Propagation & Policy Delegation
*   **Opportunity:** Cairnloop relies on an `AutomationPolicy` to determine whether an AI is allowed to auto-reply to a ticket. This policy decision can be delegated to Rulestead's bucketing engine.
*   **Leverage:** Operators can use Rulestead's LiveView admin UI to safely roll out an experimental Cairnloop auto-responder. For example, they can configure a Rulestead rule to only enable the auto-responder for 5% of "free-tier" users. Because Rulestead deterministically evaluates context (e.g., `subscription_status` pulled from Accrue/Cairnloop), it serves as the perfect risk-management gatekeeper for support automation.