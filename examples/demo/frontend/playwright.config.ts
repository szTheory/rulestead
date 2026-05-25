import { defineConfig } from "@playwright/test";

const frontendUrl = process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000";
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  use: {
    baseURL: frontendUrl,
    trace: "on-first-retry",
  },
  metadata: {
    frontendUrl,
    backendUrl,
  },
});
