import DemoPageClient from "./demo-page-client";
import {
  buildInitialDemoSnapshots,
  DEMO_ENVIRONMENT_KEY,
  DEMO_PLAN,
  DEMO_TARGETING_KEY,
  DEMO_TENANT_KEY,
  fetchDemoPersonas,
  fetchExplainSnapshot,
  FLAGS_API_BASE,
  PRIMARY_FLAG_KEY,
  SERVER_FLAGS_API_BASE,
  type DemoPersona,
  type DemoRuntimeConfig,
} from "../lib/openfeature/client";

export const dynamic = "force-dynamic";

export default async function Page() {
  const config: DemoRuntimeConfig = {
    apiBase: FLAGS_API_BASE,
    environmentKey: DEMO_ENVIRONMENT_KEY,
    targetingKey: DEMO_TARGETING_KEY,
    tenantKey: DEMO_TENANT_KEY,
    plan: DEMO_PLAN,
  };

  const serverConfig = { ...config, apiBase: SERVER_FLAGS_API_BASE };

  let personas: DemoPersona[] = [];
  let initialSnapshots = await buildInitialDemoSnapshots(serverConfig);
  let initialExplain = await fetchExplainSnapshot(serverConfig, PRIMARY_FLAG_KEY);

  try {
    personas = await fetchDemoPersonas(SERVER_FLAGS_API_BASE);
  } catch (_error) {
    personas = [];
  }

  return (
    <DemoPageClient
      config={config}
      initialSnapshots={initialSnapshots}
      initialExplain={initialExplain}
      personas={personas}
    />
  );
}
