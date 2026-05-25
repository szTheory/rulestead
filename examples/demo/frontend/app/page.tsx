import DemoPageClient from "./demo-page-client";
import {
  buildInitialDemoSnapshot,
  type DemoRuntimeConfig,
  DEMO_ENVIRONMENT_KEY,
  DEMO_TARGETING_KEY,
  FLAGS_API_BASE,
  SERVER_FLAGS_API_BASE,
} from "../lib/openfeature/client";

export const dynamic = "force-dynamic";

export default async function Page() {
  const config: DemoRuntimeConfig = {
    apiBase: FLAGS_API_BASE,
    environmentKey: DEMO_ENVIRONMENT_KEY,
    targetingKey: DEMO_TARGETING_KEY,
  };

  const initialSnapshot = await buildInitialDemoSnapshot({
    ...config,
    apiBase: SERVER_FLAGS_API_BASE,
  });

  return <DemoPageClient config={config} initialSnapshot={initialSnapshot} />;
}
