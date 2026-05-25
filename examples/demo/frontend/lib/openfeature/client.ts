import { OpenFeature, type Client, type EvaluationDetails } from "@openfeature/web-sdk";

import {
  fetchFlagEvaluation,
  RulesteadWebProvider,
  type TrackedFlagDefinition,
} from "./rulestead-web-provider";

export const FLAGS_API_BASE =
  process.env.NEXT_PUBLIC_FLAGS_API_BASE ?? "http://localhost:4000";
export const SERVER_FLAGS_API_BASE =
  process.env.FLAGS_API_BASE ?? FLAGS_API_BASE;
export const DEMO_ENVIRONMENT_KEY =
  process.env.NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY ?? "staging";
export const DEMO_TARGETING_KEY =
  process.env.NEXT_PUBLIC_FLAGS_TARGETING_KEY ?? "demo-user";
export const DEMO_FLAG_KEY = "enable-new-dashboard";

export type DemoRuntimeConfig = {
  apiBase: string;
  environmentKey: string;
  targetingKey: string;
};

export type DemoFlagSnapshot = {
  enabled: boolean;
  reason: string;
  variant: string | null;
  environmentKey: string;
  flagVersion: string | number | null;
  cacheAgeMs: number | null;
  matchedRule: string | null;
};

const trackedFlags: ReadonlyArray<TrackedFlagDefinition> = [
  { flagKey: DEMO_FLAG_KEY, defaultValue: false },
];

let currentBootstrapKey: string | null = null;
let currentBootstrapPromise:
  | Promise<{ client: Client; provider: RulesteadWebProvider }>
  | null = null;
let currentProvider: RulesteadWebProvider | null = null;

function runtimeKey(config: DemoRuntimeConfig) {
  return `${config.apiBase}::${config.environmentKey}::${config.targetingKey}`;
}

function readStringMetadata(
  details: Pick<EvaluationDetails<boolean>, "flagMetadata">,
  key: string,
) {
  const value = details.flagMetadata[key];
  return typeof value === "string" ? value : null;
}

function readNumberMetadata(
  details: Pick<EvaluationDetails<boolean>, "flagMetadata">,
  key: string,
) {
  const value = details.flagMetadata[key];
  return typeof value === "number" ? value : null;
}

function readVersionMetadata(
  details: Pick<EvaluationDetails<boolean>, "flagMetadata">,
) {
  const value = details.flagMetadata.flagVersion;
  return typeof value === "string" || typeof value === "number" ? value : null;
}

export function toDemoFlagSnapshot(
  details: Pick<
    EvaluationDetails<boolean>,
    "value" | "reason" | "variant" | "flagMetadata"
  >,
  environmentKey: string,
): DemoFlagSnapshot {
  return {
    enabled: details.value,
    reason: details.reason ?? "DEFAULT",
    variant: details.variant ?? null,
    environmentKey:
      readStringMetadata(details, "environmentKey") ?? environmentKey,
    flagVersion: readVersionMetadata(details),
    cacheAgeMs: readNumberMetadata(details, "cacheAgeMs"),
    matchedRule: readStringMetadata(details, "matchedRule"),
  };
}

export async function buildInitialDemoSnapshot(
  config: DemoRuntimeConfig,
): Promise<DemoFlagSnapshot> {
  const details = await fetchFlagEvaluation({
    apiBase: config.apiBase,
    environmentKey: config.environmentKey,
    flagKey: DEMO_FLAG_KEY,
    defaultValue: false,
    context: { targetingKey: config.targetingKey },
  });

  return toDemoFlagSnapshot(
    {
      value: details.value,
      reason: details.reason,
      variant: details.variant,
      flagMetadata: details.flagMetadata ?? {},
    },
    config.environmentKey,
  );
}

export async function bootstrapDemoClient(config: DemoRuntimeConfig) {
  const key = runtimeKey(config);

  if (!currentBootstrapPromise || currentBootstrapKey !== key) {
    await currentProvider?.onClose?.();

    currentProvider = new RulesteadWebProvider({
      apiBase: config.apiBase,
      environmentKey: config.environmentKey,
      trackedFlags,
    });

    currentBootstrapKey = key;
    currentBootstrapPromise = OpenFeature.setProviderAndWait(currentProvider, {
      targetingKey: config.targetingKey,
    }).then(() => ({
      client: OpenFeature.getClient(),
      provider: currentProvider as RulesteadWebProvider,
    }));
  }

  return currentBootstrapPromise;
}

export function readDemoFlagSnapshot(client: Client, environmentKey: string) {
  const details = client.getBooleanDetails(DEMO_FLAG_KEY, false);
  return toDemoFlagSnapshot(details, environmentKey);
}
