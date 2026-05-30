"use client";

import { ProviderEvents } from "@openfeature/web-sdk";
import { startTransition, useEffect, useMemo, useState } from "react";

import {
  bannerFromSnapshot,
  bootstrapDemoClient,
  buildDemoSnapshots,
  fetchExplainSnapshot,
  findFlagSnapshot,
  primaryHeadline,
  PRIMARY_FLAG_KEY,
  type DemoExplainSnapshot,
  type DemoFlagSnapshot,
  type DemoPersona,
  type DemoRuntimeConfig,
} from "../lib/openfeature/client";

import "./fleetdesk.css";

type DemoPageClientProps = {
  config: DemoRuntimeConfig;
  initialSnapshots: DemoFlagSnapshot[];
  initialExplain: DemoExplainSnapshot;
  personas: DemoPersona[];
};

type ViewState = {
  isBootstrapping: boolean;
  snapshots: DemoFlagSnapshot[];
  explain: DemoExplainSnapshot | null;
  error: string | null;
  refreshedAt: string | null;
};

function formatValue(value: unknown) {
  if (typeof value === "string") {
    return value;
  }

  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }

  return JSON.stringify(value, null, 2);
}

export default function DemoPageClient({
  config: initialConfig,
  initialSnapshots,
  initialExplain,
  personas,
}: DemoPageClientProps) {
  const [config, setConfig] = useState(initialConfig);
  const [devToolsOpen, setDevToolsOpen] = useState(false);
  const [viewState, setViewState] = useState<ViewState>({
    isBootstrapping: true,
    snapshots: initialSnapshots,
    explain: initialExplain,
    error: null,
    refreshedAt: null,
  });

  const primarySnapshot = useMemo(
    () => findFlagSnapshot(viewState.snapshots, PRIMARY_FLAG_KEY),
    [viewState.snapshots],
  );
  const mapSnapshot = useMemo(
    () => findFlagSnapshot(viewState.snapshots, "fleet-map-v2"),
    [viewState.snapshots],
  );
  const copySnapshot = useMemo(
    () => findFlagSnapshot(viewState.snapshots, "dispatch-ops-copy"),
    [viewState.snapshots],
  );
  const bannerSnapshot = useMemo(
    () => findFlagSnapshot(viewState.snapshots, "ops-banner-config"),
    [viewState.snapshots],
  );
  const banner = useMemo(
    () => bannerFromSnapshot(bannerSnapshot),
    [bannerSnapshot],
  );

  const activePersona = personas.find(
    (persona) => persona.targetingKey === config.targetingKey,
  );

  useEffect(() => {
    let disposed = false;
    let removeHandler: (() => void) | undefined;
    let pollInterval: ReturnType<typeof setInterval> | undefined;

    async function boot() {
      try {
        const { client } = await bootstrapDemoClient(config);
        if (disposed) {
          return;
        }

        const syncSnapshots = async () => {
          const [snapshots, explain] = await Promise.all([
            buildDemoSnapshots(config),
            fetchExplainSnapshot(config, PRIMARY_FLAG_KEY),
          ]);

          if (disposed) {
            return;
          }

          startTransition(() => {
            setViewState({
              isBootstrapping: false,
              snapshots,
              explain,
              error: null,
              refreshedAt: new Date().toISOString(),
            });
          });
        };

        await syncSnapshots();

        const refreshHandler = () => {
          if (disposed) {
            return;
          }

          void syncSnapshots();
        };

        client.addHandler(ProviderEvents.ConfigurationChanged, refreshHandler);
        removeHandler = () => {
          client.removeHandler(ProviderEvents.ConfigurationChanged, refreshHandler);
        };

        pollInterval = setInterval(() => {
          if (disposed) {
            return;
          }

          void syncSnapshots();
        }, 5_000);
      } catch (error) {
        if (disposed) {
          return;
        }

        const message =
          error instanceof Error ? error.message : "Unable to hydrate demo flags.";

        setViewState((current) => ({
          ...current,
          isBootstrapping: false,
          error: message,
        }));
      }
    }

    void boot();

    return () => {
      disposed = true;
      removeHandler?.();
      if (pollInterval) {
        clearInterval(pollInterval);
      }
    };
  }, [config]);

  const cockpitEnabled = primarySnapshot?.enabled ?? false;
  const mapV2Enabled = mapSnapshot?.enabled ?? false;
  const dispatchCopy =
    typeof copySnapshot?.value === "string"
      ? copySnapshot.value
      : "Review today's dispatch queue";

  return (
    <div className="fd-app">
      <header className="fd-header">
        <div className="fd-brand">
          <div className="fd-brand-mark" aria-hidden="true">
            FD
          </div>
          <p className="fd-brand-name">FleetDesk</p>
        </div>

        <nav className="fd-nav" aria-label="Primary">
          <span className="fd-nav-link fd-nav-link--active">Dispatch</span>
          <span className="fd-nav-link fd-nav-link--disabled">Routes</span>
          <span className="fd-nav-link fd-nav-link--disabled">Alerts</span>
        </nav>

        <div className="fd-user-area">
          <div className="fd-view-as">
            <label htmlFor="view-as-select">View as</label>
            <select
              id="view-as-select"
              value={config.targetingKey}
              onChange={(event) => {
                const persona = personas.find(
                  (entry) => entry.targetingKey === event.target.value,
                );

                if (!persona) {
                  return;
                }

                setConfig({
                  ...config,
                  targetingKey: persona.targetingKey,
                  tenantKey: persona.tenantKey,
                  plan: persona.plan,
                });
              }}
            >
              {(personas.length > 0
                ? personas
                : [
                    {
                      targetingKey: config.targetingKey,
                      label: "Jordan Lee · Acme Logistics (Pro)",
                      summary: "Dispatch lead",
                    },
                  ]
              ).map((persona) => (
                <option key={persona.targetingKey} value={persona.targetingKey}>
                  {persona.label}
                </option>
              ))}
            </select>
            <p className="fd-view-as-summary">
              {activePersona?.summary ?? `${config.plan} plan · ${config.tenantKey}`}
            </p>
          </div>
        </div>
      </header>

      <main className="fd-main">
        {banner ? (
          <section className="fd-alert" role="status">
            <div>
              <strong>{banner.message}</strong>
            </div>
            {banner.cta ? (
              <button type="button">{banner.cta}</button>
            ) : null}
          </section>
        ) : null}

        <section
          className={`fd-hero ${cockpitEnabled ? "fd-hero--live" : "fd-hero--steady"}`}
        >
          <h1>{primaryHeadline(cockpitEnabled)}</h1>
          <p className="fd-hero-sub">{dispatchCopy}</p>
        </section>

        <section className="fd-workspace">
          <article className="fd-map-panel">
            <h2>Live map</h2>
            <div className="fd-map-preview">
              <div>
                <strong>{mapV2Enabled ? "Vector map v2" : "Legacy map tiles"}</strong>
                <span>
                  {mapV2Enabled
                    ? "Enterprise rollout — sharper routes and live traffic overlays"
                    : "Standard tile renderer for this account"}
                </span>
              </div>
            </div>
          </article>

          <article className="fd-routes-panel">
            <h2>Active routes</h2>
            <ul className="fd-route-list">
              <li className="fd-route-item">
                <div>
                  <strong>Route 14 · North warehouse loop</strong>
                  <span>Driver: Ana Reyes · ETA 18 min</span>
                </div>
                <span className="fd-status-pill">On time</span>
              </li>
              <li className="fd-route-item">
                <div>
                  <strong>Route 22 · Airport express</strong>
                  <span>Driver: Marco Silva · ETA 6 min</span>
                </div>
                <span className="fd-status-pill">Priority</span>
              </li>
              <li className="fd-route-item">
                <div>
                  <strong>Route 31 · Suburban returns</strong>
                  <span>Driver: Priya Nair · ETA 42 min</span>
                </div>
                <span className="fd-status-pill">Delayed</span>
              </li>
            </ul>
          </article>
        </section>

        <div className="fd-dev-toggle">
          <button
            type="button"
            aria-expanded={devToolsOpen}
            onClick={() => setDevToolsOpen((open) => !open)}
          >
            {devToolsOpen ? "Hide developer tools" : "Developer tools"}
          </button>
        </div>

        {devToolsOpen ? (
          <section className="fd-dev-panel" aria-label="Developer tools">
            <div>
              <h3>Explain trace</h3>
              <p>
                {viewState.explain?.explanation ??
                  "Explain trace will appear after the bridge hydrates."}
              </p>
              <p>
                Targeting key {config.targetingKey} · plan {config.plan} · tenant{" "}
                {config.tenantKey}
              </p>
            </div>

            <div>
              <h3>Flag snapshots</h3>
              <div className="fd-flag-grid">
                {viewState.snapshots.map((snapshot) => (
                  <article key={snapshot.flagKey} className="fd-flag-card">
                    <code>{snapshot.flagKey}</code>
                    <p>{formatValue(snapshot.value)}</p>
                    <p>
                      {snapshot.reason}
                      {snapshot.matchedRule ? ` · ${snapshot.matchedRule}` : ""}
                    </p>
                  </article>
                ))}
              </div>
            </div>

            <div>
              <h3>Bridge status</h3>
              <p>
                {viewState.error
                  ? `Bridge refresh failed: ${viewState.error}`
                  : viewState.isBootstrapping
                    ? "Connecting to the backend bridge and hydrating tracked flags."
                    : "Listening for configuration-changed events from /api/flags/stream."}
              </p>
              <p>
                Environment {config.environmentKey} · API {config.apiBase} · Last refresh{" "}
                {viewState.refreshedAt ?? "server snapshot only"}
              </p>
            </div>
          </section>
        ) : null}
      </main>
    </div>
  );
}
