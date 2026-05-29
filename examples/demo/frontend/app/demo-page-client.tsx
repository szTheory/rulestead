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

const shellStyle = {
  minHeight: "100vh",
  padding: "32px 20px 80px",
  background:
    "radial-gradient(circle at top left, rgba(15, 118, 110, 0.12), transparent 42%), #f4f1ea",
  color: "#1f2937",
  fontFamily: 'ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif',
};

const frameStyle = {
  margin: "0 auto",
  maxWidth: "1120px",
  display: "grid",
  gap: "20px",
};

const heroCardStyle = (enabled: boolean) =>
  ({
    borderRadius: "28px",
    padding: "32px",
    border: "1px solid rgba(30, 26, 22, 0.08)",
    background: enabled
      ? "linear-gradient(135deg, #0f766e 0%, #164e63 100%)"
      : "linear-gradient(135deg, #f8fafc 0%, #dbe4f0 100%)",
    color: enabled ? "#f8fafc" : "#1f2937",
    boxShadow: enabled
      ? "0 28px 60px rgba(15, 118, 110, 0.22)"
      : "0 28px 60px rgba(71, 85, 105, 0.12)",
  }) as const;

const gridStyle = {
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
  gap: "16px",
};

const cardStyle = {
  borderRadius: "22px",
  padding: "20px",
  background: "rgba(255, 255, 255, 0.86)",
  border: "1px solid rgba(30, 26, 22, 0.08)",
  boxShadow: "0 20px 40px rgba(30, 26, 22, 0.08)",
};

const labelStyle = {
  display: "block",
  fontSize: "0.78rem",
  textTransform: "uppercase" as const,
  letterSpacing: "0.12em",
  color: "rgba(30, 26, 22, 0.6)",
  marginBottom: "8px",
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

  return (
    <main style={shellStyle}>
      <section style={frameStyle}>
        <header style={{ ...cardStyle, padding: "24px 28px" }}>
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              gap: "12px",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <div>
              <p style={{ ...labelStyle, marginBottom: "4px" }}>Adoption lab</p>
              <h1 style={{ margin: 0, fontSize: "1.8rem", letterSpacing: "-0.03em" }}>
                FleetDesk dispatch
              </h1>
              <p style={{ margin: "8px 0 0", maxWidth: "52ch", lineHeight: 1.6 }}>
                A minimal B2B fleet-ops host app exercising Rulestead across rollout,
                experiment, remote config, explain, and kill-switch journeys.
              </p>
            </div>
            <div style={{ minWidth: "240px" }}>
              <label htmlFor="persona-select" style={labelStyle}>
                Persona
              </label>
              <select
                id="persona-select"
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
                style={{
                  width: "100%",
                  borderRadius: "12px",
                  border: "1px solid rgba(30, 26, 22, 0.12)",
                  padding: "10px 12px",
                  fontSize: "0.95rem",
                  background: "#fff",
                }}
              >
                {(personas.length > 0
                  ? personas
                  : [
                      {
                        targetingKey: config.targetingKey,
                        label: "Dispatch operator",
                        summary: "Default demo persona",
                      },
                    ]
                ).map((persona) => (
                  <option key={persona.targetingKey} value={persona.targetingKey}>
                    {persona.label}
                  </option>
                ))}
              </select>
              <p style={{ margin: "8px 0 0", fontSize: "0.88rem", opacity: 0.75 }}>
                {personas.find((persona) => persona.targetingKey === config.targetingKey)
                  ?.summary ?? `${config.plan} plan · ${config.tenantKey}`}
              </p>
            </div>
          </div>
        </header>

        {banner ? (
          <article
            style={{
              ...cardStyle,
              borderColor:
                banner.severity === "warning"
                  ? "rgba(217, 119, 6, 0.35)"
                  : "rgba(30, 26, 22, 0.08)",
              background:
                banner.severity === "warning"
                  ? "rgba(254, 243, 199, 0.92)"
                  : cardStyle.background,
            }}
          >
            <span style={labelStyle}>Operations banner · remote config</span>
            <strong style={{ display: "block", fontSize: "1.05rem" }}>
              {banner.message}
            </strong>
            {banner.cta ? (
              <p style={{ margin: "8px 0 0", opacity: 0.8 }}>{banner.cta}</p>
            ) : null}
          </article>
        ) : null}

        <article style={heroCardStyle(cockpitEnabled)}>
          <p style={{ ...labelStyle, color: cockpitEnabled ? "rgba(248,250,252,0.72)" : labelStyle.color }}>
            Primary journey · kill switch ({PRIMARY_FLAG_KEY})
          </p>
          <h2
            style={{
              margin: "0 0 12px",
              fontSize: "clamp(2rem, 5vw, 3.4rem)",
              lineHeight: 1.02,
              letterSpacing: "-0.04em",
            }}
          >
            {primaryHeadline(cockpitEnabled)}
          </h2>
          <p style={{ margin: 0, maxWidth: "62ch", lineHeight: 1.7, opacity: 0.92 }}>
            Dispatch headline:{" "}
            <strong>{typeof copySnapshot?.value === "string" ? copySnapshot.value : "—"}</strong>
            {" · "}
            Map renderer:{" "}
            <strong>{mapSnapshot?.enabled ? "vector map v2" : "legacy tiles"}</strong>
          </p>
        </article>

        <section style={gridStyle}>
          {viewState.snapshots.map((snapshot) => (
            <article key={snapshot.flagKey} style={cardStyle}>
              <span style={labelStyle}>{snapshot.label}</span>
              <strong style={{ display: "block", fontSize: "1rem", marginBottom: "8px" }}>
                {snapshot.flagKey}
              </strong>
              <p style={{ margin: "0 0 8px", lineHeight: 1.5 }}>
                {formatValue(snapshot.value)}
              </p>
              <p style={{ margin: 0, fontSize: "0.88rem", opacity: 0.72 }}>
                {snapshot.reason}
                {snapshot.matchedRule ? ` · ${snapshot.matchedRule}` : ""}
              </p>
            </article>
          ))}
        </section>

        <article style={cardStyle}>
          <span style={labelStyle}>Support journey · explain API</span>
          <p style={{ margin: "0 0 10px", lineHeight: 1.7, whiteSpace: "pre-wrap" }}>
            {viewState.explain?.explanation ??
              "Explain trace will appear after the bridge hydrates."}
          </p>
          <p style={{ margin: 0, fontSize: "0.88rem", opacity: 0.72 }}>
            Targeting key {config.targetingKey} · plan {config.plan} · tenant{" "}
            {config.tenantKey}
          </p>
        </article>

        <article style={cardStyle}>
          <span style={labelStyle}>Bridge status</span>
          <p style={{ margin: "0 0 10px", lineHeight: 1.7 }}>
            {viewState.error
              ? `Bridge refresh failed: ${viewState.error}`
              : viewState.isBootstrapping
                ? "Connecting to the backend bridge and hydrating tracked flags."
                : "Listening for configuration-changed events from /api/flags/stream."}
          </p>
          <p style={{ margin: 0, opacity: 0.72 }}>
            Environment {config.environmentKey} · API {config.apiBase} · Last refresh{" "}
            {viewState.refreshedAt ?? "server snapshot only"}
          </p>
        </article>
      </section>
    </main>
  );
}
