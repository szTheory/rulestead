import {
  type AnyProviderEvent,
  ErrorCode,
  type EvaluationContext,
  type EventContext,
  type EventDetails,
  type EventHandler,
  type FlagMetadata,
  type JsonValue,
  type Logger,
  type Provider,
  ProviderEvents,
  type ResolutionDetails,
  StandardResolutionReasons,
} from "@openfeature/web-sdk";

type BoundedErrorResponse = {
  error: {
    code: string;
    message: string;
  };
};

type FlagApiResponse = {
  flagKey: string;
  environmentKey: string;
  enabled: boolean;
  value: JsonValue;
  variant?: string | null;
  reason?: string | null;
  flagVersion?: string | number | null;
  cacheAgeMs?: number | null;
  matchedRule?: string | null;
};

type StreamEventPayload = {
  type: "configuration-changed";
  environmentKey: string;
  snapshotVersion: string | number;
};

export type TrackedFlagDefinition<T extends JsonValue = JsonValue> = {
  flagKey: string;
  defaultValue: T;
};

type EventSourceLike = {
  addEventListener(
    type: string,
    listener: (event: { data?: string }) => void | Promise<void>,
  ): void;
  close(): void;
};

type FetchLike = (input: string | URL, init?: RequestInit) => Promise<Response>;
type EventSourceFactory = (url: string) => EventSourceLike;

type ProviderOptions = {
  apiBase: string;
  environmentKey: string;
  trackedFlags: ReadonlyArray<TrackedFlagDefinition>;
  fetch?: FetchLike;
  eventSourceFactory?: EventSourceFactory;
};

type CachedResolution = ResolutionDetails<JsonValue>;

const DEFAULT_PROVIDER_NAME = "rulestead-demo-web-provider";

function trimTrailingSlash(value: string) {
  return value.endsWith("/") ? value.slice(0, -1) : value;
}

function createDefaultEventSource(url: string): EventSourceLike {
  return new EventSource(url);
}

function encodeTargetingKey(context: EvaluationContext) {
  return typeof context.targetingKey === "string" && context.targetingKey.length > 0
    ? context.targetingKey
    : null;
}

function normalizeErrorCode(code?: string | null): ErrorCode {
  if (!code) {
    return ErrorCode.GENERAL;
  }

  const candidate = code.toUpperCase() as ErrorCode;
  const knownCodes = new Set<string>(Object.values(ErrorCode));

  return knownCodes.has(candidate) ? candidate : ErrorCode.GENERAL;
}

function normalizeReason(reason?: string | null) {
  if (!reason) {
    return StandardResolutionReasons.DEFAULT;
  }

  return reason;
}

function getJsonValueType(value: JsonValue) {
  if (value === null) {
    return "null";
  }

  if (Array.isArray(value)) {
    return "object";
  }

  return typeof value;
}

function matchesExpectedType<T extends JsonValue>(value: JsonValue, defaultValue: T) {
  const expectedType = getJsonValueType(defaultValue);
  const actualType = getJsonValueType(value);

  if (expectedType === "object") {
    return actualType === "object";
  }

  return expectedType === actualType;
}

function buildFlagMetadata(response: FlagApiResponse): FlagMetadata {
  const metadata: FlagMetadata = {
    enabled: response.enabled,
    environmentKey: response.environmentKey,
  };

  if (response.flagVersion !== undefined && response.flagVersion !== null) {
    metadata.flagVersion = response.flagVersion;
  }

  if (typeof response.cacheAgeMs === "number") {
    metadata.cacheAgeMs = response.cacheAgeMs;
  }

  if (response.matchedRule) {
    metadata.matchedRule = response.matchedRule;
  }

  return metadata;
}

function buildErrorResolution<T extends JsonValue>(
  defaultValue: T,
  errorCode: ErrorCode,
  errorMessage: string,
): ResolutionDetails<T> {
  return {
    value: defaultValue,
    reason: StandardResolutionReasons.ERROR,
    errorCode,
    errorMessage,
  };
}

function toResolutionDetails<T extends JsonValue>(
  response: FlagApiResponse,
  defaultValue: T,
): ResolutionDetails<T> {
  if (!matchesExpectedType(response.value, defaultValue)) {
    return buildErrorResolution(
      defaultValue,
      ErrorCode.TYPE_MISMATCH,
      `Expected ${getJsonValueType(defaultValue)} for ${response.flagKey}, received ${getJsonValueType(response.value)}.`,
    );
  }

  return {
    value: response.value as T,
    variant: response.variant ?? undefined,
    reason: normalizeReason(response.reason),
    flagMetadata: buildFlagMetadata(response),
  };
}

function isBoundedErrorResponse(payload: unknown): payload is BoundedErrorResponse {
  return (
    typeof payload === "object" &&
    payload !== null &&
    "error" in payload &&
    typeof (payload as BoundedErrorResponse).error?.code === "string" &&
    typeof (payload as BoundedErrorResponse).error?.message === "string"
  );
}

function isFlagApiResponse(payload: unknown): payload is FlagApiResponse {
  return (
    typeof payload === "object" &&
    payload !== null &&
    typeof (payload as FlagApiResponse).flagKey === "string" &&
    typeof (payload as FlagApiResponse).environmentKey === "string" &&
    typeof (payload as FlagApiResponse).enabled === "boolean" &&
    "value" in payload
  );
}

function isStreamEventPayload(payload: unknown): payload is StreamEventPayload {
  return (
    typeof payload === "object" &&
    payload !== null &&
    (payload as StreamEventPayload).type === "configuration-changed" &&
    typeof (payload as StreamEventPayload).environmentKey === "string" &&
    "snapshotVersion" in payload
  );
}

type ProviderEventHandler = EventHandler<AnyProviderEvent>;
type HandlerMap = Map<AnyProviderEvent, Set<ProviderEventHandler>>;

class ProviderEventEmitter {
  private readonly handlers: HandlerMap = new Map();

  addHandler(eventType: AnyProviderEvent, handler: ProviderEventHandler) {
    const existing =
      this.handlers.get(eventType) ?? new Set<ProviderEventHandler>();
    existing.add(handler);
    this.handlers.set(eventType, existing);
  }

  removeHandler(eventType: AnyProviderEvent, handler: ProviderEventHandler) {
    this.handlers.get(eventType)?.delete(handler);
  }

  removeAllHandlers(eventType?: AnyProviderEvent) {
    if (eventType) {
      this.handlers.delete(eventType);
      return;
    }

    this.handlers.clear();
  }

  getHandlers(eventType: AnyProviderEvent) {
    return Array.from(this.handlers.get(eventType) ?? []);
  }

  emit(eventType: AnyProviderEvent, context?: EventContext) {
    const details = context as EventDetails<AnyProviderEvent> | undefined;

    for (const handler of this.handlers.get(eventType) ?? []) {
      void handler(details);
    }
  }

  setLogger(_logger: Logger) {
    return this;
  }
}

export function buildFlagRequestUrl(
  apiBase: string,
  environmentKey: string,
  flagKey: string,
  context: EvaluationContext = {},
) {
  const url = new URL(`${trimTrailingSlash(apiBase)}/api/flags`);
  url.searchParams.set("env", environmentKey);
  url.searchParams.set("flag_key", flagKey);

  const targetingKey = encodeTargetingKey(context);
  if (targetingKey) {
    url.searchParams.set("targeting_key", targetingKey);
  }

  for (const [key, value] of Object.entries(context)) {
    if (key === "targetingKey" || value === undefined || value === null) {
      continue;
    }

    if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
      url.searchParams.set(key, String(value));
    }
  }

  return url.toString();
}

export async function fetchFlagEvaluation<T extends JsonValue>(
  params: {
    apiBase: string;
    environmentKey: string;
    flagKey: string;
    defaultValue: T;
    context?: EvaluationContext;
  },
  fetchImpl: FetchLike = fetch,
): Promise<ResolutionDetails<T>> {
  const response = await fetchImpl(
    buildFlagRequestUrl(
      params.apiBase,
      params.environmentKey,
      params.flagKey,
      params.context,
    ),
  );

  const payload = (await response.json()) as unknown;

  if (!response.ok) {
    if (isBoundedErrorResponse(payload)) {
      return buildErrorResolution(
        params.defaultValue,
        normalizeErrorCode(payload.error.code),
        payload.error.message,
      );
    }

    return buildErrorResolution(
      params.defaultValue,
      ErrorCode.GENERAL,
      `Request failed with status ${response.status}.`,
    );
  }

  if (isBoundedErrorResponse(payload)) {
    return buildErrorResolution(
      params.defaultValue,
      normalizeErrorCode(payload.error.code),
      payload.error.message,
    );
  }

  if (!isFlagApiResponse(payload)) {
    return buildErrorResolution(
      params.defaultValue,
      ErrorCode.PARSE_ERROR,
      "Flag bridge returned an unexpected payload.",
    );
  }

  return toResolutionDetails(payload, params.defaultValue);
}

export class RulesteadWebProvider implements Provider {
  readonly metadata = { name: DEFAULT_PROVIDER_NAME };
  readonly runsOn = "client" as const;
  readonly events = new ProviderEventEmitter();

  private readonly apiBase: string;
  private readonly environmentKey: string;
  private readonly fetchImpl: FetchLike;
  private readonly eventSourceFactory: EventSourceFactory;
  private readonly trackedFlags = new Map<string, TrackedFlagDefinition>();
  private readonly cache = new Map<string, CachedResolution>();
  private activeContext: EvaluationContext = {};
  private stream: EventSourceLike | null = null;

  constructor(options: ProviderOptions) {
    this.apiBase = trimTrailingSlash(options.apiBase);
    this.environmentKey = options.environmentKey;
    this.fetchImpl = options.fetch ?? fetch;
    this.eventSourceFactory =
      options.eventSourceFactory ?? createDefaultEventSource;

    for (const flag of options.trackedFlags) {
      this.trackedFlags.set(flag.flagKey, flag);
    }
  }

  async initialize(context: EvaluationContext = {}) {
    this.activeContext = context;
    await this.refreshTrackedFlags(context);
    this.connectStream();
  }

  async onContextChange(_oldContext: EvaluationContext, newContext: EvaluationContext) {
    this.activeContext = newContext;
    await this.refreshTrackedFlags(newContext);
  }

  async onClose() {
    this.stream?.close();
    this.stream = null;
  }

  resolveBooleanEvaluation(
    flagKey: string,
    defaultValue: boolean,
    _context: EvaluationContext,
    logger: Logger,
  ) {
    return this.resolveCachedValue(flagKey, defaultValue, logger);
  }

  resolveStringEvaluation(
    flagKey: string,
    defaultValue: string,
    _context: EvaluationContext,
    logger: Logger,
  ) {
    return this.resolveCachedValue(flagKey, defaultValue, logger);
  }

  resolveNumberEvaluation(
    flagKey: string,
    defaultValue: number,
    _context: EvaluationContext,
    logger: Logger,
  ) {
    return this.resolveCachedValue(flagKey, defaultValue, logger);
  }

  resolveObjectEvaluation<T extends JsonValue>(
    flagKey: string,
    defaultValue: T,
    _context: EvaluationContext,
    logger: Logger,
  ) {
    return this.resolveCachedValue(flagKey, defaultValue, logger);
  }

  async refreshTrackedFlags(context: EvaluationContext = this.activeContext) {
    await Promise.all(
      Array.from(this.trackedFlags.values()).map(async (definition) => {
        const resolution = await fetchFlagEvaluation(
          {
            apiBase: this.apiBase,
            environmentKey: this.environmentKey,
            flagKey: definition.flagKey,
            defaultValue: definition.defaultValue,
            context,
          },
          this.fetchImpl,
        );

        this.cache.set(definition.flagKey, resolution as CachedResolution);
      }),
    );
  }

  private resolveCachedValue<T extends JsonValue>(
    flagKey: string,
    defaultValue: T,
    logger: Logger,
  ): ResolutionDetails<T> {
    const cached = this.cache.get(flagKey);

    if (!cached) {
      logger.warn(`Flag ${flagKey} has not been hydrated yet.`);
      return buildErrorResolution(
        defaultValue,
        ErrorCode.PROVIDER_NOT_READY,
        `Flag ${flagKey} is not hydrated in the browser cache.`,
      );
    }

    if (!matchesExpectedType(cached.value, defaultValue)) {
      logger.warn(`Flag ${flagKey} type mismatch for cached resolution.`);
      return buildErrorResolution(
        defaultValue,
        ErrorCode.TYPE_MISMATCH,
        `Cached value for ${flagKey} does not match the requested type.`,
      );
    }

    return cached as ResolutionDetails<T>;
  }

  private connectStream() {
    this.stream?.close();

    const streamUrl = new URL(`${this.apiBase}/api/flags/stream`);
    streamUrl.searchParams.set("env", this.environmentKey);

    this.stream = this.eventSourceFactory(streamUrl.toString());
    this.stream.addEventListener(
      "configuration-changed",
      async (event: { data?: string }) => {
        const rawData = event.data;
        if (!rawData) {
          return;
        }

        let payload: unknown;

        try {
          payload = JSON.parse(rawData);
        } catch (_error) {
          this.events.emit(ProviderEvents.Error, {
            message: "Unable to parse configuration-changed payload.",
          });
          return;
        }

        if (!isStreamEventPayload(payload)) {
          this.events.emit(ProviderEvents.Error, {
            message: "Unexpected configuration-changed payload.",
          });
          return;
        }

        if (payload.environmentKey !== this.environmentKey) {
          return;
        }

        await this.refreshTrackedFlags();
        this.events.emit(ProviderEvents.ConfigurationChanged, {
          flagsChanged: Array.from(this.trackedFlags.keys()),
        });
      },
    );
  }
}
