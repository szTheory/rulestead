import {
  OpenFeature,
  type Client,
  type EvaluationDetails,
  type FlagValue,
  type JsonValue,
} from "@openfeature/web-sdk";

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
export const DEMO_PLAN = process.env.NEXT_PUBLIC_DEMO_PLAN ?? "pro";
export const DEMO_TENANT_KEY =
  process.env.NEXT_PUBLIC_DEMO_TENANT_KEY ?? "acme-logistics";

export const PRIMARY_FLAG_KEY = "enable-new-dashboard";

export type DemoPersona = {
  id: string;
  label: string;
  company: string;
  tenantKey: string;
  plan: string;
  targetingKey: string;
  summary: string;
};

export type DemoRuntimeConfig = {
  apiBase: string;
  environmentKey: string;
  targetingKey: string;
  tenantKey: string;
  plan: string;
};

export type DemoFlagSnapshot = {
  flagKey: string;
  label: string;
  enabled: boolean;
  value: unknown;
  reason: string;
  variant: string | null;
  environmentKey: string;
  flagVersion: string | number | null;
  cacheAgeMs: number | null;
  matchedRule: string | null;
};

export type DemoExplainSnapshot = {
  flagKey: string;
  explanation: string;
  matchedRule: string | null;
  reason: string;
};

export const DEMO_FLAG_DEFINITIONS: ReadonlyArray<{
  flagKey: string;
  label: string;
  defaultValue: JsonValue;
}> = [
  {
    flagKey: PRIMARY_FLAG_KEY,
    label: "Fleet map v2 cockpit",
    defaultValue: false,
  },
  {
    flagKey: "fleet-map-v2",
    label: "Vector map renderer",
    defaultValue: false,
  },
  {
    flagKey: "dispatch-ops-copy",
    label: "Dispatch headline",
    defaultValue: "Standard dispatch queue",
  },
  {
    flagKey: "ops-banner-config",
    label: "Operations banner",
    defaultValue: { message: null, severity: "info", cta: null },
  },
];

const trackedFlags: ReadonlyArray<TrackedFlagDefinition> =
  DEMO_FLAG_DEFINITIONS.map(({ flagKey, defaultValue }) => ({
    flagKey,
    defaultValue,
  }));

let currentBootstrapKey: string | null = null;
let currentBootstrapPromise:
  | Promise<{ client: Client; provider: RulesteadWebProvider }>
  | null = null;
let currentProvider: RulesteadWebProvider | null = null;

function runtimeKey(config: DemoRuntimeConfig) {
  return `${config.apiBase}::${config.environmentKey}::${config.targetingKey}::${config.plan}::${config.tenantKey}`;
}

function readStringMetadata(
  details: Pick<EvaluationDetails<FlagValue>, "flagMetadata">,
  key: string,
) {
  const value = details.flagMetadata[key];
  return typeof value === "string" ? value : null;
}

function readNumberMetadata(
  details: Pick<EvaluationDetails<FlagValue>, "flagMetadata">,
  key: string,
) {
  const value = details.flagMetadata[key];
  return typeof value === "number" ? value : null;
}

function readVersionMetadata(
  details: Pick<EvaluationDetails<FlagValue>, "flagMetadata">,
) {
  const value = details.flagMetadata.flagVersion;
  return typeof value === "string" || typeof value === "number" ? value : null;
}

function readBooleanMetadata(
  details: Pick<EvaluationDetails<FlagValue>, "flagMetadata">,
  key: string,
) {
  const value = details.flagMetadata[key];
  return typeof value === "boolean" ? value : null;
}

export function toDemoFlagSnapshot(
  flagKey: string,
  label: string,
  details: Pick<
    EvaluationDetails<FlagValue>,
    "value" | "reason" | "variant" | "flagMetadata"
  >,
  environmentKey: string,
): DemoFlagSnapshot {
  return {
    flagKey,
    label,
    enabled:
      readBooleanMetadata(details, "enabled") ?? Boolean(details.value),
    value: details.value,
    reason: details.reason ?? "DEFAULT",
    variant: details.variant ?? null,
    environmentKey:
      readStringMetadata(details, "environmentKey") ?? environmentKey,
    flagVersion: readVersionMetadata(details),
    cacheAgeMs: readNumberMetadata(details, "cacheAgeMs"),
    matchedRule: readStringMetadata(details, "matchedRule"),
  };
}

function evaluationContext(config: DemoRuntimeConfig) {
  return {
    targetingKey: config.targetingKey,
    tenant_key: config.tenantKey,
    plan: config.plan,
  };
}

export async function fetchDemoPersonas(
  apiBase: string,
): Promise<DemoPersona[]> {
  const response = await fetch(`${apiBase}/api/demo/personas`, {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Unable to load demo personas (${response.status}).`);
  }

  const payload = (await response.json()) as { personas: DemoPersona[] };
  return payload.personas;
}

export async function buildDemoSnapshots(
  config: DemoRuntimeConfig,
): Promise<DemoFlagSnapshot[]> {
  const context = evaluationContext(config);

  return Promise.all(
    DEMO_FLAG_DEFINITIONS.map(async ({ flagKey, label, defaultValue }) => {
      const details = await fetchFlagEvaluation({
        apiBase: config.apiBase,
        environmentKey: config.environmentKey,
        flagKey,
        defaultValue,
        context,
      });

      return toDemoFlagSnapshot(
        flagKey,
        label,
        {
          value: details.value,
          reason: details.reason,
          variant: details.variant,
          flagMetadata: details.flagMetadata ?? {},
        },
        config.environmentKey,
      );
    }),
  );
}

export async function buildInitialDemoSnapshots(
  config: DemoRuntimeConfig,
): Promise<DemoFlagSnapshot[]> {
  return buildDemoSnapshots(config);
}

export async function fetchExplainSnapshot(
  config: DemoRuntimeConfig,
  flagKey: string = PRIMARY_FLAG_KEY,
): Promise<DemoExplainSnapshot> {
  const params = new URLSearchParams({
    env: config.environmentKey,
    flag_key: flagKey,
    targeting_key: config.targetingKey,
    tenant_key: config.tenantKey,
    plan: config.plan,
  });

  const response = await fetch(
    `${config.apiBase}/api/flags/explain?${params.toString()}`,
    { cache: "no-store" },
  );

  if (!response.ok) {
    throw new Error(`Explain request failed (${response.status}).`);
  }

  const payload = (await response.json()) as {
    flagKey: string;
    explanation: string;
    matchedRule: string | null;
    reason: string;
  };

  return {
    flagKey: payload.flagKey,
    explanation: payload.explanation,
    matchedRule: payload.matchedRule,
    reason: payload.reason,
  };
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
      tenant_key: config.tenantKey,
      plan: config.plan,
    }).then(() => ({
      client: OpenFeature.getClient(),
      provider: currentProvider as RulesteadWebProvider,
    }));
  }

  return currentBootstrapPromise;
}

export function findFlagSnapshot(
  snapshots: DemoFlagSnapshot[],
  flagKey: string,
): DemoFlagSnapshot | undefined {
  return snapshots.find((snapshot) => snapshot.flagKey === flagKey);
}

export function primaryHeadline(enabled: boolean) {
  return enabled
    ? "Fleet map v2 is live for your dispatch desk."
    : "Classic dispatch map is holding steady.";
}

export function bannerFromSnapshot(
  snapshot: DemoFlagSnapshot | undefined,
): { message: string; severity: string; cta: string | null } | null {
  if (!snapshot || typeof snapshot.value !== "object" || snapshot.value === null) {
    return null;
  }

  const value = snapshot.value as Record<string, unknown>;
  const message = typeof value.message === "string" ? value.message : null;

  if (!message) {
    return null;
  }

  return {
    message,
    severity: typeof value.severity === "string" ? value.severity : "info",
    cta: typeof value.cta === "string" ? value.cta : null,
  };
}
