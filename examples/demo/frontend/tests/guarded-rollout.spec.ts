import { expect, test } from "@playwright/test";

import { openAdminPage } from "./support/admin";

const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://localhost:4000";

test("guarded rollout panel renders honest guardrail copy", async ({ browser }) => {
  const adminPage = await openAdminPage(browser);

  await adminPage.goto(
    `${backendUrl}/admin/flags/dispatch-guarded-rollout/rollouts?env=staging`,
  );

  await expect(adminPage.getByText("Rollout controls")).toBeVisible({ timeout: 15_000 });
  await expect(adminPage.getByText("Priority routes split")).toBeVisible();
  await expect(adminPage.getByText("dispatch_error_rate")).toBeVisible();
});
