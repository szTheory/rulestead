import { expect, test } from "@playwright/test";

import { backendUrl } from "./support/admin";

const requiredRouteNames = [
  "overview",
  "inventory",
  "rules",
  "kill",
  "audience",
  "audit",
  "explain",
  "simulate",
] as const;

const adminFlowRoutes: Array<{ name: string; path: string }> = [];

test.describe("admin flow IA route evidence", () => {
  test("covers the selected primary admin route clusters", () => {
    expect(backendUrl).toBeTruthy();
    expect(adminFlowRoutes.map((route) => route.name)).toEqual(requiredRouteNames);
  });
});
