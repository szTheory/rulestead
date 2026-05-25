"use client";

import { ProviderEvents } from "@openfeature/web-sdk";
import { startTransition, useEffect, useState } from "react";

import {
  bootstrapDemoClient,
  buildInitialDemoSnapshot,
  type DemoFlagSnapshot,
  type DemoRuntimeConfig,
} from "../lib/openfeature/client";

type DemoPageClientProps = {
  config: DemoRuntimeConfig;
  initialSnapshot: DemoFlagSnapshot;
};

type ViewState = {
  isBootstrapping: boolean;
  snapshot: DemoFlagSnapshot;
  error: string | null;
  refreshedAt: string | null;
};

const shellStyle = {
  minHeight: "100vh",
  padding: "48px 20px 80px",
};

const frameStyle = {
  margin: "0 auto",
  maxWidth: "1040px",
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

const chipsStyle = {
  display: "flex",
  flexWrap: "wrap" as const,
  gap: "10px",
};

const chipStyle = (strong?: boolean) =>
  ({
    borderRadius: "999px",
    padding: "8px 14px",
    background: strong ? "rgba(255, 255, 255, 0.16)" : "rgba(30, 26, 22, 0.07)",
    border: strong ? "1px solid rgba(255, 255, 255, 0.28)" : "1px solid rgba(30, 26, 22, 0.08)",
    fontSize: "0.9rem",
    letterSpacing: "0.02em",
  }) as const;

const gridStyle = {
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
  gap: "16px",
};

const cardStyle = {
  borderRadius: "22px",
  padding: "20px",
  background: "rgba(255, 255, 255, 0.72)",
  border: "1px solid rgba(30, 26, 22, 0.08)",
  boxShadow: "0 20px 40px rgba(30, 26, 22, 0.08)",
};

const labelStyle = {
  display: "block",
  fontSize: "0.8rem",
  textTransform: "uppercase" as const,
  letterSpacing: "0.12em",
  color: "rgba(30, 26, 22, 0.6)",
  marginBottom: "8px",
};

export default function DemoPageClient({
  config,
  initialSnapshot,
}: DemoPageClientProps) {
  const [viewState, setViewState] = useState<ViewState>({
    isBootstrapping: true,
    snapshot: initialSnapshot,
    error: null,
    refreshedAt: null,
  });

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

        const syncSnapshot = async () => {
          const snapshot = await buildInitialDemoSnapshot(config);

          if (disposed) {
            return;
          }

          startTransition(() => {
            setViewState({
              isBootstrapping: false,
              snapshot,
              error: null,
              refreshedAt: new Date().toISOString(),
            });
          });
        };

        await syncSnapshot();

        const refreshHandler = () => {
          if (disposed) {
            return;
          }

          void syncSnapshot();
        };

        client.addHandler(ProviderEvents.ConfigurationChanged, refreshHandler);
        removeHandler = () => {
          client.removeHandler(ProviderEvents.ConfigurationChanged, refreshHandler);
        };

        pollInterval = setInterval(() => {
          if (disposed) {
            return;
          }

          void syncSnapshot();
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

  const { snapshot } = viewState;
  const rolloutEnabled = snapshot.enabled;

  return (
    <main style={shellStyle}>
      <section style={frameStyle}>
        <article style={heroCardStyle(rolloutEnabled)}>
          <div style={chipsStyle}>
            <span style={chipStyle(true)}>OpenFeature web provider</span>
            <span style={chipStyle(true)}>
              {config.environmentKey} environment
            </span>
            <span style={chipStyle(true)}>
              {rolloutEnabled ? "New dashboard on" : "Classic dashboard on"}
            </span>
          </div>

          <h1
            style={{
              margin: "18px 0 12px",
              fontSize: "clamp(2.4rem, 7vw, 4.8rem)",
              lineHeight: 0.94,
              letterSpacing: "-0.05em",
            }}
          >
            {rolloutEnabled ? "The new operator cockpit is live." : "The classic cockpit is holding."}
          </h1>

          <p
            style={{
              margin: 0,
              maxWidth: "60ch",
              fontSize: "1.08rem",
              lineHeight: 1.7,
              opacity: 0.9,
            }}
          >
            Toggle <code>enable-new-dashboard</code> in the mounted Admin UI and
            this screen should update through the backend bridge plus OpenFeature
            provider stream path.
          </p>
        </article>

        <section style={gridStyle}>
          <article style={cardStyle}>
            <span style={labelStyle}>Flag Key</span>
            <strong style={{ fontSize: "1.2rem" }}>enable-new-dashboard</strong>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Reason</span>
            <strong style={{ fontSize: "1.2rem" }}>{snapshot.reason}</strong>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Variant</span>
            <strong style={{ fontSize: "1.2rem" }}>
              {snapshot.variant ?? "default"}
            </strong>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Matched Rule</span>
            <strong style={{ fontSize: "1.2rem" }}>
              {snapshot.matchedRule ?? "none"}
            </strong>
          </article>
        </section>

        <section style={gridStyle}>
          <article style={cardStyle}>
            <span style={labelStyle}>Bridge Base</span>
            <div style={{ fontFamily: 'ui-monospace, "SFMono-Regular", monospace' }}>
              {config.apiBase}
            </div>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Targeting Key</span>
            <strong>{config.targetingKey}</strong>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Flag Version</span>
            <strong>{snapshot.flagVersion ?? "n/a"}</strong>
          </article>

          <article style={cardStyle}>
            <span style={labelStyle}>Cache Age</span>
            <strong>
              {typeof snapshot.cacheAgeMs === "number"
                ? `${snapshot.cacheAgeMs} ms`
                : "n/a"}
            </strong>
          </article>
        </section>

        <article
          style={{
            ...cardStyle,
            background: rolloutEnabled
              ? "rgba(15, 118, 110, 0.08)"
              : "rgba(71, 85, 105, 0.08)",
          }}
        >
          <span style={labelStyle}>Live Status</span>
          <p style={{ margin: "0 0 10px", fontSize: "1rem", lineHeight: 1.7 }}>
            {viewState.error
              ? `Bridge refresh failed: ${viewState.error}`
              : viewState.isBootstrapping
                ? "Connecting to the backend bridge and hydrating tracked flags."
                : "Listening for configuration-changed events from /api/flags/stream."}
          </p>
          <p style={{ margin: 0, color: "rgba(30, 26, 22, 0.7)" }}>
            Last client refresh: {viewState.refreshedAt ?? "server snapshot only"}
          </p>
        </article>
      </section>
    </main>
  );
}
