import { ErrorCode, ProviderEvents } from "@openfeature/web-sdk";

import {
  buildFlagRequestUrl,
  RulesteadWebProvider,
} from "../lib/openfeature/rulestead-web-provider";

class FakeEventSource {
  private readonly listeners = new Map<
    string,
    Array<(event: { data?: string }) => void | Promise<void>>
  >();

  addEventListener(
    type: string,
    listener: (event: { data?: string }) => void | Promise<void>,
  ) {
    const existing = this.listeners.get(type) ?? [];
    existing.push(listener);
    this.listeners.set(type, existing);
  }

  async emit(type: string, payload: unknown) {
    const listeners = this.listeners.get(type) ?? [];

    await Promise.all(
      listeners.map((listener) =>
        listener({ data: JSON.stringify(payload) }),
      ),
    );
  }

  close() {
    this.listeners.clear();
  }
}

const mockLogger = {
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn(),
};

describe("RulesteadWebProvider", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("hydrates tracked flags from /api/flags and maps OpenFeature details", async () => {
    const fakeEventSource = new FakeEventSource();
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: "enable-new-dashboard",
        environmentKey: "staging",
        enabled: true,
        value: true,
        variant: "rollout",
        reason: "TARGETING_MATCH",
        flagVersion: "17",
        cacheAgeMs: 41,
        matchedRule: "demo-rollout",
      }),
    });

    const provider = new RulesteadWebProvider({
      apiBase: "http://flags.example",
      environmentKey: "staging",
      trackedFlags: [{ flagKey: "enable-new-dashboard", defaultValue: false }],
      fetch: fetchMock,
      eventSourceFactory: () => fakeEventSource,
    });

    await provider.initialize({ targetingKey: "demo-user" });

    expect(fetchMock).toHaveBeenCalledWith(
      buildFlagRequestUrl(
        "http://flags.example",
        "staging",
        "enable-new-dashboard",
        { targetingKey: "demo-user" },
      ),
    );

    const details = provider.resolveBooleanEvaluation(
      "enable-new-dashboard",
      false,
      {},
      mockLogger,
    );

    expect(details).toEqual({
      value: true,
      variant: "rollout",
      reason: "TARGETING_MATCH",
      flagMetadata: {
        enabled: true,
        environmentKey: "staging",
        flagVersion: "17",
        cacheAgeMs: 41,
        matchedRule: "demo-rollout",
      },
    });
  });

  it("returns bounded backend errors as OpenFeature error details", async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: false,
      status: 404,
      json: async () => ({
        error: {
          code: "FLAG_NOT_FOUND",
          message: "Flag was not found.",
        },
      }),
    });

    const provider = new RulesteadWebProvider({
      apiBase: "http://flags.example",
      environmentKey: "staging",
      trackedFlags: [{ flagKey: "enable-new-dashboard", defaultValue: false }],
      fetch: fetchMock,
      eventSourceFactory: () => new FakeEventSource(),
    });

    await provider.initialize({ targetingKey: "demo-user" });

    const details = provider.resolveBooleanEvaluation(
      "enable-new-dashboard",
      false,
      {},
      mockLogger,
    );

    expect(details.value).toBe(false);
    expect(details.errorCode).toBe(ErrorCode.FLAG_NOT_FOUND);
    expect(details.errorMessage).toBe("Flag was not found.");
    expect(details.reason).toBe("ERROR");
  });

  it("refreshes tracked flags and emits configuration-changed from the backend stream", async () => {
    const fakeEventSource = new FakeEventSource();
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          flagKey: "enable-new-dashboard",
          environmentKey: "staging",
          enabled: false,
          value: false,
          variant: "control",
          reason: "DEFAULT",
          flagVersion: "17",
          cacheAgeMs: 5,
          matchedRule: null,
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          flagKey: "enable-new-dashboard",
          environmentKey: "staging",
          enabled: true,
          value: true,
          variant: "rollout",
          reason: "TARGETING_MATCH",
          flagVersion: "18",
          cacheAgeMs: 3,
          matchedRule: "demo-rollout",
        }),
      });

    const provider = new RulesteadWebProvider({
      apiBase: "http://flags.example",
      environmentKey: "staging",
      trackedFlags: [{ flagKey: "enable-new-dashboard", defaultValue: false }],
      fetch: fetchMock,
      eventSourceFactory: () => fakeEventSource,
    });

    const eventHandler = jest.fn();
    provider.events?.addHandler(ProviderEvents.ConfigurationChanged, eventHandler);

    await provider.initialize({ targetingKey: "demo-user" });
    await fakeEventSource.emit("configuration-changed", {
      type: "configuration-changed",
      environmentKey: "staging",
      snapshotVersion: 18,
    });

    const details = provider.resolveBooleanEvaluation(
      "enable-new-dashboard",
      false,
      {},
      mockLogger,
    );

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(eventHandler).toHaveBeenCalledTimes(1);
    expect(eventHandler).toHaveBeenCalledWith({
      flagsChanged: ["enable-new-dashboard"],
    });
    expect(details.value).toBe(true);
    expect(details.variant).toBe("rollout");
  });

  it("ignores configuration-changed events for a different environment", async () => {
    const fakeEventSource = new FakeEventSource();
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: "enable-new-dashboard",
        environmentKey: "staging",
        enabled: false,
        value: false,
        variant: "control",
        reason: "DEFAULT",
        flagVersion: "17",
        cacheAgeMs: 5,
        matchedRule: null,
      }),
    });

    const provider = new RulesteadWebProvider({
      apiBase: "http://flags.example",
      environmentKey: "staging",
      trackedFlags: [{ flagKey: "enable-new-dashboard", defaultValue: false }],
      fetch: fetchMock,
      eventSourceFactory: () => fakeEventSource,
    });

    const eventHandler = jest.fn();
    provider.events?.addHandler(ProviderEvents.ConfigurationChanged, eventHandler);

    await provider.initialize({ targetingKey: "demo-user" });
    await fakeEventSource.emit("configuration-changed", {
      type: "configuration-changed",
      environmentKey: "production",
      snapshotVersion: 18,
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(eventHandler).not.toHaveBeenCalled();
  });

  it("emits an error and skips refresh when the stream payload is malformed", async () => {
    const fakeEventSource = new FakeEventSource();
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: "enable-new-dashboard",
        environmentKey: "staging",
        enabled: false,
        value: false,
        variant: "control",
        reason: "DEFAULT",
        flagVersion: "17",
        cacheAgeMs: 5,
        matchedRule: null,
      }),
    });

    const provider = new RulesteadWebProvider({
      apiBase: "http://flags.example",
      environmentKey: "staging",
      trackedFlags: [{ flagKey: "enable-new-dashboard", defaultValue: false }],
      fetch: fetchMock,
      eventSourceFactory: () => fakeEventSource,
    });

    const errorHandler = jest.fn();
    provider.events?.addHandler(ProviderEvents.Error, errorHandler);

    await provider.initialize({ targetingKey: "demo-user" });
    await fakeEventSource.emit("configuration-changed", {
      type: "configuration-changed",
      environmentKey: "staging",
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(errorHandler).toHaveBeenCalledTimes(1);
    expect(errorHandler).toHaveBeenCalledWith({
      message: "Unexpected configuration-changed payload.",
    });
  });
});
